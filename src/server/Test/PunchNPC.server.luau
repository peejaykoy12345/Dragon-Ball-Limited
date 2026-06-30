local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

task.wait(3)

local WCS_Character = WCS.Character.new(workspace.LivingBeings.PunchRig)

require(ReplicatedStorage.Modules.WCS.Skills.Race.Saiyan.M1).new(WCS_Character)

local skillModule = WCS_Character:GetSkillFromString("Saiyan M1")

while true do
    skillModule:Start()

    task.wait(.1)

    skillModule:End()
end