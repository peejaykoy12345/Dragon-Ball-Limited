local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local GeneralUtilities = Modules.Utilities.General
local StateManager = require(GeneralUtilities.StateManager)

local WCS = require(Modules.Packages.WCS)

local Stun = WCS.RegisterStatusEffect("Stun")

function Stun:OnConstructServer(info)
    self.priority = info.Priority or 4
end

function Stun:OnStartServer()
    self:SetHumanoidData({
        WalkSpeed = {0, "Set"},
        JumpPower = {0, "Set"},
        JumpHeight = {0, "Set"},
    }, self.priority)

    StateManager.SetState(self.Character.Instance, "Stunned", true)
end

function Stun:OnEndServer()
    self:ClearHumanoidData()
    StateManager.RemoveState(self.Character.Instance, "Stunned")
end

return Stun