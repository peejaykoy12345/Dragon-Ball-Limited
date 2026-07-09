local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = require(ReplicatedStorage.Modules.Network)

local IsClient = RunService:IsClient()

local States: {[Model]: {[string]: boolean | number | string}} = {}

local AncestryChangedConnections: {[Model]: RBXScriptConnection} = {}
local HumanoidDiedConnection: {[Model]: RBXScriptConnection} = {}

local StateManager = {}

local initialized = false

function StateManager._PackValue(value: boolean | number | string)
	local valueType = typeof(value)
	if valueType == "string" then
		return { string = value }
	elseif valueType == "boolean" then
		return { uint8 = value and 1 or 0 }
	elseif valueType == "number" then
		if value >= 0 and value <= 255 then
			return { uint8 = value }
		elseif value >= 0 and value <= 65535 then
			return { uint16 = value }
		else
			return { uint32 = value }
		end
	end
	return {}
end

function StateManager._ReplicateState(char: Model, action: "Add" | "Remove", state: string | {string}, value: (boolean | number | string)?)
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end

	if type(state) == "table" then
		Network.Replication.packets.Update.sendTo({
			Name = "State",
			Args = { Action = action },
			Value = { arrayofstrings = state },
		}, player)
	else
		Network.Replication.packets.Update.sendTo({
			Name = "State",
			Args = { Type = state, Action = action },
			Value = if value ~= nil then StateManager._PackValue(value) else {},
		}, player)
	end
end

function StateManager._OnReplicationUpdate(payload)
	if payload.Name ~= "State" then return end

	local char = Players.LocalPlayer.Character
	if not char then return end

	local action = payload.Args and payload.Args.Action
	local value = payload.Value or {}

	if value.arrayofstrings then
		if action == "Remove" and States[char] then
			for _, stateName in ipairs(value.arrayofstrings) do
				States[char][stateName] = nil
			end
		end
		return
	end

	local stateName = payload.Args and payload.Args.Type
	if not stateName then return end

	if action == "Remove" then
		if States[char] then
			States[char][stateName] = nil
		end
	elseif action == "Add" then
		if not States[char] then
			StateManager.InitializeModel(char)
		end
		local resolvedValue = value.string
		if resolvedValue == nil then resolvedValue = value.uint8 end
		if resolvedValue == nil then resolvedValue = value.uint16 end
		if resolvedValue == nil then resolvedValue = value.uint32 end
		States[char][stateName] = resolvedValue
	end
end

function StateManager.InitializeModel(char: Model)
	States[char] = {}
	
	if not AncestryChangedConnections[char] then
		AncestryChangedConnections[char] = char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				States[char] = nil
				if AncestryChangedConnections[char] then
					AncestryChangedConnections[char]:Disconnect()
					AncestryChangedConnections[char] = nil
				end
			end
		end)
	end
	
	if not HumanoidDiedConnection[char] then
		local hum = char:FindFirstChild("Humanoid") :: Humanoid
		if not hum then return end
		
		HumanoidDiedConnection[char] = hum.Died:Connect(function()
			States[char] = nil
			if HumanoidDiedConnection[char] then
				HumanoidDiedConnection[char]:Disconnect()
				HumanoidDiedConnection[char] = nil
			end
		end)
	end
end

function StateManager.RemoveState(char: Model, state: string | {string})
	if not States[char] then return end

	if type(state) == "table" then
		for _, s in ipairs(state) do
			States[char][s] = nil
		end
	else
		States[char][state] = nil
	end

	if not IsClient then
		StateManager._ReplicateState(char, "Remove", state)
	end
end

function StateManager.BulkRemoveState(chars: {Model}, state: string)
	for _, char in ipairs(chars) do
		StateManager.RemoveState(char, state)
	end
end

function StateManager.SetState(char: Model, state: string, value: boolean | number | string)
	if not States[char] then
		StateManager.InitializeModel(char)
	end
	
	States[char][state] = value

	if not IsClient then
		StateManager._ReplicateState(char, "Add", state, value)
	end
end

function StateManager.GetAllStates(char: Model)
	if not States[char] then
		StateManager.InitializeModel(char)
		return {}
	end
	return States[char]
end

function StateManager.BulkSetState(chars: {Model}, state: string, value: boolean | number | string)
	for _, char in ipairs(chars) do
		StateManager.SetState(char, state, value)
	end
end

function StateManager.HasState(char: Model, state: string)
	if not States[char] then
		StateManager.InitializeModel(char)
		return false
	end
	return States[char][state]
end

local RESTRICTED_ACTION_STATES = {
	"CantUse",
	"Stunned",
	"Perfect Block",
	"M1CantUse",
	"Ragdoll",
	"Knockback",
	"FastFlight",
	"Vanish",
	"ChargingKi",
}

function StateManager.isActionBlocked(char: Model, statesToSkip: {string}?): boolean
	for _, state in ipairs(RESTRICTED_ACTION_STATES) do
		if statesToSkip and statesToSkip[state] then continue end
		if StateManager.HasState(char, state) then
			return true
		end
	end
	
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		warn(`{char.Name} has no humanoid`)
		return true
	end

	if humanoid.Health <= 0 then
		return true
	end
	
	return false
end

local INVINCIBLE_STATES = {
	"IFrames",
	"SpawnIFrames",
}

function StateManager.isCharacterInvincible(char: Model, statesToSkip: {string}?): boolean
	for _, state in ipairs(INVINCIBLE_STATES) do
		if statesToSkip and statesToSkip[state] then continue end
		if StateManager.HasState(char, state) then
			return true
		end
	end
	
	local humanoid = char:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		warn(`{char.Name} has no humanoid`)
		return true
	end

	if humanoid.Health <= 0 then
		return true
	end
	
	return false
end

if IsClient and not initialized then
	initialized = true
	Network.Replication.packets.Update.listen(StateManager._OnReplicationUpdate)
end

return StateManager