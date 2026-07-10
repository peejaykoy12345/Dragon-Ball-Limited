local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local Profiles = require(ServerScriptService.Services.Profiles)

local PlayerStatsService = {}

local playerStats: { [Player]: { [string]: number } } = {}

local PERSISTENT_STATS = {
	"PowerLevel",
	"Level",
	"Ki Control",
	"Ki Damage",
	"Defense",
	"Strength",
}

local RUNTIME_STATS = {
	Ki = {StartingValue = 0},
	Stamina = {StartingValue = 100},
}

local DERIVED_MAX = {
	["MaxKi"] = function(stats)
		return stats["Ki Control"] or 100
	end,
	["MaxStamina"] = function()
		return 100
	end,
}

local PERSISTENT_SET = {}
for _, name in PERSISTENT_STATS do
	PERSISTENT_SET[name] = true
end

function PlayerStatsService:_BuildStats(player: Player): { [string]: number }?
	local savedStats = Profiles:GetSlotData(player, "Stats")
	if not savedStats then return nil end

	local stats = {}

	for _, statName in PERSISTENT_STATS do
		stats[statName] = savedStats[statName] or 0
	end

	for statName, config in RUNTIME_STATS do
        stats[statName] = config.StartingValue
    end

	return stats
end

function PlayerStatsService:_GetMax(stats: { [string]: number }, statName: string): number?
	local fn = DERIVED_MAX["Max" .. statName]
	return if fn then fn(stats) else nil
end

function PlayerStatsService:_SaveStat(player: Player, statName: string, value: number)
	local profile = Profiles:GetProfile(player)
	if not profile then return end
	local slot = Profiles:_EnsureSlot(profile)
	slot.Stats[statName] = value
end

function PlayerStatsService:Init()
	Players.PlayerRemoving:Connect(function(player)
		playerStats[player] = nil
	end)

	InitializePacket.listen(function(data, player)
		local stats = playerStats[player]
		if not stats then return end

		local name = data.Name
		local value = stats[name]

		if value == nil then
			local fn = DERIVED_MAX[name]
			if fn then value = fn(stats) end
		end

		if value == nil then return end

		UpdatePacket.sendTo({
			Name = name,
			Value = { uint32 = value },
		}, player)
	end)
end

function PlayerStatsService:OnProfileReady(player: Player)
	local stats = self:_BuildStats(player)
	if not stats then return end
	playerStats[player] = stats
end

function PlayerStatsService:SetStat(player: Player, statName: string, value: number)
	local stats = playerStats[player]
	if not stats then return end

	local max = self:_GetMax(stats, statName)
	stats[statName] = if max then math.clamp(value, 0, max) else value

	if PERSISTENT_SET[statName] then
		self:_SaveStat(player, statName, stats[statName])
	end

	UpdatePacket.sendTo({
		Name = statName,
		Value = { uint32 = stats[statName] },
	}, player)

	if statName == "Ki Control" then
		local newMax = self:_GetMax(stats, "Ki")
		if newMax and stats["Ki"] > newMax then
			stats["Ki"] = newMax
		end
		UpdatePacket.sendTo({ Name = "MaxKi", Value = { uint32 = newMax } }, player)
		UpdatePacket.sendTo({ Name = "Ki", Value = { uint32 = stats["Ki"] } }, player)
	end
end

function PlayerStatsService:IncrementStat(player: Player, statName: string, amount: number)
	local stats = playerStats[player]
	if not stats then return end
	self:SetStat(player, statName, (stats[statName] or 0) + amount)
end

function PlayerStatsService:GetStat(player: Player, statName: string): number?
	local stats = playerStats[player]
	if not stats then return nil end
	return stats[statName]
end

function PlayerStatsService:GetMaxValue(player: Player, statName: string): number?
	local stats = playerStats[player]
	if not stats then return nil end
	return self:_GetMax(stats, statName)
end

return PlayerStatsService