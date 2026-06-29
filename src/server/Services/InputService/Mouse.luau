local InputUtils = require(script.Parent.Utils) 

local SKILL_NAME = "Saiyan M1"

local Mouse = {}

function Mouse.HandleInput(plr: Player, input: string, started: boolean)
    InputUtils.HandleInput(plr, SKILL_NAME, input, started)
end

function Mouse.PlayerRemoving(plr: Player)
    InputUtils.PlayerRemoving(plr)
end

return Mouse