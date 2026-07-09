local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local DefaultStats = require(Modules.Configs.DefaultStats) 

local PlayerStatsService = {}

local playerStats: { [Player]: { [string]: number } } = {}

function PlayerStatsService:Init()
	Players.PlayerAdded:Connect(function(player)
        local stats = {}
        for statName, config in DefaultStats do
            stats[statName] = config.Default.StartingValue
            stats["Max" .. statName] = config.Default.MaxValue
        end
        playerStats[player] = stats
    end)

	Players.PlayerRemoving:Connect(function(player)
		playerStats[player] = nil
	end)

    InitializePacket.listen(function(data, player)
        local stats = playerStats[player]
        if not stats then return end

        local value = stats[data.Name]
        if value == nil then return end

        UpdatePacket.sendTo({
            Name = data.Name,
            Value = { uint32 = value },
        }, player)
    end)
end

function PlayerStatsService:IncrementStat(player: Player, statName: string, amount: number)
	local stats = playerStats[player]
	if not stats then return end

	local max = stats["Max" .. statName]
	local newValue = (stats[statName] or 0) + amount
	stats[statName] = max and math.clamp(newValue, 0, max) or newValue

	UpdatePacket.sendTo({
		Name = statName,
		Value = { uint32 = stats[statName] },
	}, player)
end

function PlayerStatsService:GetStat(player: Player, statName: string): number?
	local stats = playerStats[player]
	if not stats then return nil end
	return stats[statName]
end

function PlayerStatsService:GetMaxValue(player: Player, statName: string): number?
    local stats = playerStats[player]
    if not stats then return nil end
    return stats["Max" .. statName]
end

return PlayerStatsService