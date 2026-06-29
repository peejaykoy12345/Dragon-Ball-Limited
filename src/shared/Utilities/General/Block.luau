local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StateManager = require(ReplicatedStorage.Modules.Utilities.General.StateManager)
local ActionSession = require(ReplicatedStorage.Modules.Utilities.General.ActionSession)
local ClientFX = require(ReplicatedStorage.Modules.Utilities.Media.ClientFX)

local CONFIG = {
    BLOCK_DURABILITY = 100,
}

local ActiveBlocks: {[Model]: {BlockHandleId: number, Session: typeof(ActionSession.new({})), Assets: BlockAssets}} = {}

type BlockAssets = {
    IdleAnim: Animation,
    BrokeAnim: Animation,
    BlockVFX: Instance,
    BlockBrokeVFX: Instance,
    BlockHitVFX: Instance?,
}

local Block = {}

function Block:Init()
    RunService.Heartbeat:Connect(function(dt)
        Block:_RegenTick(dt)
    end)
end

function Block:InitCharacter(target: Model)
    target:SetAttribute("BlockDurability", CONFIG.BLOCK_DURABILITY)
end

function Block:CheckBlock(attackerPosition: Vector3, target: Model, angle: number?)
    local root = target:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local threshold = angle and math.cos(math.rad(angle)) or 0.15

    local offset = attackerPosition - root.Position
    local flatOffset = Vector3.new(offset.X, 0, offset.Z)
    if flatOffset.Magnitude <= 0.001 then return true end

    local directionToAttacker = flatOffset.Unit
    local lookVector = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
    local IsBlocking = lookVector:Dot(directionToAttacker) >= threshold

    return IsBlocking
end

function Block:CheckBlockState(attacker: Model, target: Model, info): string?
    local BlockState = if StateManager.HasState(target, "Blocking") then
        "Blocking" else nil

    return BlockState
end

function Block:StartBlock(target: Model, assets: BlockAssets)
    local hrp = target:FindFirstChild("HumanoidRootPart") :: BasePart
    local humanoid = target:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not humanoid then return end

    if target:GetAttribute("BlockDurability") == nil then
        Block:InitCharacter(target)
    end

    local durability = target:GetAttribute("BlockDurability") or 0
    if durability <= 0 then return end

    StateManager.SetState(target, "Blocking", true)

    local session = ActionSession.new({
        attacker = target,
        actionName = "Block",
        actionType = "Default",
        states = {},
    })

    session:Start()
    session:PlayAndAddAnimation(target, assets.IdleAnim)

    session:ApplyCastEffect()

    session.extraStopFunction = function(forceStopped)
        Block:StopBlock(target)
    end

    local handleId = ClientFX:Construct(
        {
            Name = "ToggleParticles",
            Type = "General"
        },
        {
            parent = hrp,
            vfx = assets.BlockVFX,
            shouldWeld = true,
            deletionTime = 99999,
            position = hrp.Position
        }
    )
    ClientFX:Start(handleId)

    ActiveBlocks[target] = {
        BlockHandleId = handleId,
        Session = session,
        Assets = assets,
    }
end

function Block:HitBlock(target: Model, damage: number)
    local blockData = ActiveBlocks[target]
    if not blockData then return end

    if target:GetAttribute("BlockDurability") == nil then
        Block:InitCharacter(target)
    end

    local current = target:GetAttribute("BlockDurability") or 0
    local newDurability = current - damage
    target:SetAttribute("BlockDurability", math.max(newDurability, 0))

    -- play blockData.Assets.BlockHitVFX here

    if newDurability <= 0 then
        Block:_BreakBlock(target)
    end
end

function Block:StopBlock(target: Model)
    local blockData = ActiveBlocks[target]
    if not blockData then return end

    ActiveBlocks[target] = nil

    StateManager.RemoveState(target, "Blocking")

    blockData.Session.extraStopFunction = nil
    blockData.Session:Stop(true)

    ClientFX:Destroy(blockData.BlockHandleId)
end

function Block:_BreakBlock(target: Model)
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local blockData = ActiveBlocks[target]
    if not blockData then return end

    ActiveBlocks[target] = nil

    StateManager.RemoveState(target, "Blocking")

    blockData.Session.extraStopFunction = nil
    blockData.Session:Stop(true)

    ClientFX:Destroy(blockData.BlockHandleId)

    local humanoid = target:FindFirstChildWhichIsA("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildWhichIsA("Animator")
        local brokeTrack = animator:LoadAnimation(blockData.Assets.BrokeAnim)
        brokeTrack:Play()
    end

    ClientFX:RenderToClient(
        {
            Name = "EmitParticles",
            Type = "General"
        },
        {
            parent = hrp,
            vfx = blockData.Assets.BlockBrokeVFX,
            vfxCFrame = hrp.CFrame,
            position = hrp.Position,
        }
    )
end

function Block:_RegenTick(dt)
    for _, plr in Players:GetPlayers() do
        local char = plr.Character
        if not char then continue end
        if ActiveBlocks[char] then continue end

        local current = char:GetAttribute("BlockDurability")
        if not current or current >= CONFIG.BLOCK_DURABILITY then continue end

        local regen = CONFIG.BLOCK_DURABILITY * 0.05 * dt
        char:SetAttribute("BlockDurability", math.min(current + regen, CONFIG.BLOCK_DURABILITY))
    end
end

return Block