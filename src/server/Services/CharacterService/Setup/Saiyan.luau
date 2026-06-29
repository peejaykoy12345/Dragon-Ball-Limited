local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCSFolder = ReplicatedStorage.Modules.WCS
local SaiyanSkills = WCSFolder.Skills.Race.Saiyan:GetChildren()
local BaseSkills = WCSFolder.Skills.Base:GetChildren()

local Saiyan = {}

function Saiyan.Setup(WCS_Character)
    local registered = {}

    for _, skillModule in ipairs(SaiyanSkills) do
        if skillModule.Name == "Config" then continue end
        require(skillModule).new(WCS_Character)
        registered[skillModule.Name] = true
    end

    for _, skillModule in ipairs(BaseSkills) do
        if registered[skillModule.Name] then continue end
        require(skillModule).new(WCS_Character)
    end
end

return Saiyan