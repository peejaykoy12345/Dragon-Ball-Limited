local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCSFolder = ReplicatedStorage.Modules.WCS
local SaiyanSkills = WCSFolder.Skills.Race.Saiyan:GetChildren()

local Saiyan = {}

function Saiyan.Setup(WCS_Character)
    for _, skillModule in ipairs(SaiyanSkills) do
        if skillModule.Name == "Config" then continue end
        require(skillModule).new(WCS_Character)
    end
end

return Saiyan