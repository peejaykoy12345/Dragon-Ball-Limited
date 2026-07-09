local InputUtils = require(script.Parent.Utils) 

local Keyboard = {}

local SKILL_TO_KEY = {
    F = "Block",
    X = "Z Vanish",
    Z = "Step Vanish",
    C = "Charge Ki",
}

function Keyboard.HandleInput(plr: Player, input: string, started: boolean)
    local skillName = SKILL_TO_KEY[input]
    if not skillName then return end

    InputUtils.HandleInput(plr, skillName, input, started)
end

function Keyboard.PlayerRemoving(plr: Player)
    InputUtils.PlayerRemoving(plr)
end

return Keyboard