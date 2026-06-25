local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateManager = require(ReplicatedStorage.Modules.Utilities.General.StateManager)

local Block = {}

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
    local BlockState = if StateManager.HasState(target, "Perfect Block") then 
        "Perfect Block"  elseif StateManager.HasState(target, "Blocking") then
            "Blocking" else nil
    
   return BlockState
end

return Block