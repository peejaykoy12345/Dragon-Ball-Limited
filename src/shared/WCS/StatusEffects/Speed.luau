local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

local Speed = WCS.RegisterStatusEffect("Speed")

export type speedInfo = {
    Speed: number,
    Priority: number?,
}

function Speed:OnConstructServer(info: speedInfo)
    local speed = info.Speed

    self.speed = speed
    self.priority = info.Priority or 2
end

function Speed:OnStartServer()
    self:SetHumanoidData({WalkSpeed = {self.speed, "Set"}}, self.priority)
end

function Speed:OnEndServer()
    self:ClearHumanoidData()
end

return Speed