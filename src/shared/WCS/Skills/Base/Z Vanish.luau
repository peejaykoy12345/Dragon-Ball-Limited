local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local VFX = Assets.VFX

local ZVanishVFX = VFX.General.ZVanish

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local GeneralUtilities = Utilities.General
local MediaUtilities = Utilities.Media

local Config = require(script.Parent.Config)[script.Name]

local Network = require(Modules.Network)
local SendTarget = Network.Skill.packets.SendTarget

local Cooldown = require(GeneralUtilities.Cooldown)
local MoveUtils = require(GeneralUtilities.MoveUtils)

local ClientFX = require(MediaUtilities.ClientFX)

local WCS = require(Modules.Packages.WCS)

local Skill = WCS.RegisterSkill("Z Vanish")

function Skill:CanStart(char: Model)
    return MoveUtils:CanPerformAction(char, script.Name)
end

function Skill:OnStartClient()
    local char = self.Character.Instance
    local target = char:FindFirstChild("LockOnTarget") and char:FindFirstChild("LockOnTarget").Value
    if not target then return end

    SendTarget.send({
        Name = "Z Vanish",
        Target = target,
    })
end

function Skill:OnStartServer(info, buffered)
    self.disconnect = SendTarget.listen(function(data, plr)
        local char = self.Character.Instance
        local target = data.Target
        local name = data.Name
        if name ~= "Z Vanish" or not char or char == target then return end

        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
        local targetHrp = target:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp or not targetHrp then return end

        self.disconnect()
        self.disconnect = nil

        ClientFX:RenderToClient(
            {
                Name = "EmitParticles",
                Type = "General",
            },
            {
                parent = workspace.Effects.VFX,
                vfx = ZVanishVFX,
                vfxCFrame = hrp.CFrame,
                position = hrp.Position,
            }
        )

        MoveUtils:SetPartsProperties(char:GetChildren(), "Transparency", 1, {hrp})

        task.wait(.2)

        local behindDirection = -targetHrp.CFrame.LookVector
        local desiredPosition = targetHrp.Position + (behindDirection * Config.StudsBehind)

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {char, target}

        local result = workspace:Raycast(targetHrp.Position, behindDirection * Config.StudsBehind, rayParams)
        if result then
            desiredPosition = result.Position + (result.Normal * 3)
        end

        local lookDirection = (targetHrp.Position - desiredPosition).Unit
        hrp.CFrame = CFrame.new(desiredPosition, desiredPosition + Vector3.new(lookDirection.X, 0, lookDirection.Z))

        MoveUtils:SetPartsProperties(char:GetChildren(), "Transparency", 0, {hrp})

        Cooldown:SetCooldown(char, script.Name, Config.Cooldown)
        Cooldown:CancelCooldown(char, "M1")
    end)

    task.delay(0.5, function()
        if self.disconnect then
            self.disconnect()
            self.disconnect = nil
        end
    end)
end

return Skill