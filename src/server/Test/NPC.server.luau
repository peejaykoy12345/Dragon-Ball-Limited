local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

task.wait(2)
WCS.Character.new(workspace.LivingBeings.Rig)