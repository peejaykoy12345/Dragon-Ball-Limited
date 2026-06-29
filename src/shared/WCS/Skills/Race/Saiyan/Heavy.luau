local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local SaiyanM1Anims = Assets.Animations.Characters.Saiyan.M1

local Modules = ReplicatedStorage.Modules
local BufferInput = require(Modules.Utilities.General.BufferInput)
local WCS = require(Modules.Packages.WCS)

local M1_BASE = require(ReplicatedStorage.Modules.Templates.Combat.M1)

local Config = require(script.Parent.Config)

local M1 = setmetatable({}, M1_BASE)
M1.Anims = SaiyanM1Anims:GetChildren()

local Skill = WCS.RegisterSkill("Saiyan Heavy")

function Skill:CanStart(char: Model)
    return M1:CanStart(char)
end

function Skill:OnStartServer(_, buffered)
   
end

return Skill