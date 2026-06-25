local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local WCS = require(Modules.Packages.WCS)

local Cast = WCS.RegisterStatusEffect("Cast")

function Cast:OnConstructServer(info)
    self.priority = info and info.Priority or 2
    self.speed = info and info.Speed or 3
end

function Cast:OnStartServer()
    self:SetHumanoidData({
        WalkSpeed = {self.speed, "Set"},
        JumpPower = {0, "Set"},
        JumpHeight = {0, "Set"},
    }, self.priority)
end

function Cast:OnEndServer()
    self:ClearHumanoidData()
end

return Cast