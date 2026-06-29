local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations
local VFX = Assets.VFX

local BlockAnimations = Animations.Default.Block
local BlockVFX = VFX.General.Block

local Modules = ReplicatedStorage.Modules
local GeneralUtilities = Modules.Utilities.General

local MoveUtils = require(GeneralUtilities.MoveUtils)
local BlockModule = require(GeneralUtilities.Block)

local WCS = require(Modules.Packages.WCS)

local Skill = WCS.RegisterHoldableSkill("Block")

function Skill:CanStart(char: Model)
    return MoveUtils:CanPerformAction(char, script.Name)
end

function Skill:OnStartServer(_, buffered)
    BlockModule:StartBlock(self.Character.Instance, {
        IdleAnim = BlockAnimations.Block,
        BrokeAnim = BlockAnimations.BlockBreak,
        BlockVFX = BlockVFX.Block,
        BlockBrokeVFX = BlockVFX.Break
    })
end

function Skill:OnEndServer()
    BlockModule:StopBlock(self.Character.Instance)
end

return Skill