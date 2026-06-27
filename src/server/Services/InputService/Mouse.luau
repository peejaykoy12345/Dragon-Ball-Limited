local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local BufferInput = require(Modules.Utilities.General.BufferInput)
local WCS = require(ReplicatedStorage.Modules.Packages.WCS)
local Character = WCS.Character

local HeldInputs: {[Player]: {[string]: boolean}} = {}

local Mouse = {}

function Mouse.HandleInput(plr: Player, input: string, started: boolean)
    local char = plr.Character
    if not char then return end

    local WCSCharacter = Character.GetCharacterFromInstance(char)
    if not WCSCharacter then return end

    local skillModule = WCSCharacter:GetSkillFromString("Saiyan M1")
    if not skillModule then return end

    if started then
        HeldInputs[plr] = HeldInputs[plr] or {}
        HeldInputs[plr][input] = true

        if skillModule.CanStart and not skillModule:CanStart(char) then
            BufferInput:Press(plr, input, function()
                skillModule:Start(nil, true)
            end, function()
                return HeldInputs[plr] ~= nil and HeldInputs[plr][input] == true
            end)
            return
        end

        skillModule:Start()
    else
        if HeldInputs[plr] then
            HeldInputs[plr][input] = false
        end

        if not skillModule.End then return end

        if not skillModule:CanStart(char) and not skillModule:GetState().IsActive then
            BufferInput:PressEnd(plr, input, function()
                skillModule:End()
            end)
            return
        end

        skillModule:End()
    end
end

function Mouse.PlayerRemoving(plr: Player)
    HeldInputs[plr] = nil
end

return Mouse