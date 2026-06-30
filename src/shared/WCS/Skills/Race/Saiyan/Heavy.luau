local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local SaiyanAnims = Assets.Animations.Characters.Saiyan

local Modules = ReplicatedStorage.Modules
local BufferInput = require(Modules.Utilities.General.BufferInput)
local WCS = require(Modules.Packages.WCS)

local HEAVY_BASE = require(ReplicatedStorage.Modules.Templates.Combat.Heavy)

local Config = require(script.Parent.Config)

local Heavy = setmetatable({}, HEAVY_BASE)
Heavy.Anim = SaiyanAnims.Heavy

local Skill = WCS.RegisterSkill("Saiyan Heavy")

function Skill:CanStart(char: Model)
    return Heavy:CanStart(char)
end

function Skill:OnStartServer(_, buffered)
    print("Heavy ran")
   Heavy:Start(self.Character, Config.Heavy)
end

return Skill