local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

local AutoRotate = WCS.RegisterStatusEffect("AutoRotate")

function AutoRotate:OnConstructServer(autoRotate)
    self.AutoRotate = autoRotate
end

function AutoRotate:OnStartServer()
    self:SetHumanoidData({ AutoRotate = {self.AutoRotate, "Set" } }, 4)
end

function AutoRotate:OnEndServer()
    self:ClearHumanoidData()
end

return AutoRotate