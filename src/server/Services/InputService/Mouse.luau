local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputUtils = require(script.Parent.Utils)

local M1_BASE = require(ReplicatedStorage.Modules.Templates.Combat.M1)

local SKILL_NAME = "Saiyan M1"
local HEAVY_NAME = "Saiyan Heavy"
local COMBO_RESET_TIME = 1.5

local HEAVY_COMBOS = {
	{"M1", "M1", "M1", "M1", "M2"},
	{"M2", "M1", "M1", "M1", "M1"},
}

local ComboState = {}

M1_BASE.Finished.Event:Connect(function(char)
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr then return end

	local state = ComboState[plr.UserId]
	if not state or not state.PendingInput then return end

	state.LastInput = os.clock()
	table.insert(state.Inputs, state.PendingInput)
	state.PendingInput = nil
end)

local Mouse = {}

function Mouse.HandleInput(plr: Player, input: string, started: boolean)
	if not started then
		InputUtils.HandleInput(plr, SKILL_NAME, input, started)
		return
	end

	local userId = plr.UserId
	local state = ComboState[userId]

	if not state then
		state = { Inputs = {}, LastInput = 0, PendingInput = nil }
		ComboState[userId] = state
	end

	local now = os.clock()
	if now - state.LastInput > COMBO_RESET_TIME then
		table.clear(state.Inputs)
		state.PendingInput = nil
	end

	if #state.Inputs >= 4 then
		for _, combo in HEAVY_COMBOS do
			local match = true
			for i = 1, 4 do
				if state.Inputs[i] ~= combo[i] then
					match = false
					break
				end
			end
			if match and combo[5] == input then
				table.clear(state.Inputs)
				state.PendingInput = nil

				InputUtils.HandleInput(plr, HEAVY_NAME, input, started)
				return
			end
		end
		table.clear(state.Inputs)
	end

	state.PendingInput = input
	InputUtils.HandleInput(plr, SKILL_NAME, input, started)
end

function Mouse.PlayerRemoving(plr: Player)
	ComboState[plr.UserId] = nil
	InputUtils.PlayerRemoving(plr)
end

return Mouse