local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerPackages = ServerScriptService.ServerPackages
local ProfileStore = require(ServerPackages.ProfileStore)

local Modules = ReplicatedStorage.Modules
local CustomizationUtils = require(Modules.Utilities.Misc.CustomizationUtils)
local RaceDataTemplate = require(Modules.Configs.RaceDataTemplate)

export type ProfileData = {
    Slots: {
        [string]: {
			Customization: {
				Clothing: string,
				Race: string,
				RaceData: {[string]: any},
				Hair: string,
				Eyes: string,          
				NoseAndMouth: string,  
				BodyType: number,
				Height: number,
			},
			Stats: {
				PowerLevel: number,
			},
			Flags: {
				HasCustomized: boolean,
			}
		},
    },
	UnlockedSlots: {string},
	SlotSelected: string,
}

local PROFILE_TEMPLATE: ProfileData = {
	Slots = {
        ["Template"] = {
			Customization = {
				Clothing = "Saiyan(Starter Oufit)",
				Race = "Saiyan",
				RaceData = RaceDataTemplate.Saiyan,
				Hair = "Type 1",
				Eyes = "Type 1",
				NoseAndMouth = "Type 1",
				BodyType = 1,
				Height = 1,
			},
			Stats = {
				PowerLevel = 500,
				Level = 1,
				["Ki Control"] = 100,
				["Ki Damage"] = 25,
				Defense = 100,
				Strength = 25,
			},
			Flags = {
				HasCustomized = true,
			},
        },
    },
	UnlockedSlots = {"1", "2"},
    SlotSelected = "1",
}

local PlayerStore = ProfileStore.New("PlayerData_TESTV15", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}
local module = {}

local function setupPlayer(player, profile)
    local PlayerStatsService = require(ServerScriptService.Services.PlayerStatsService)
    PlayerStatsService:OnProfileReady(player)
end

local function PlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Profile session end - Please rejoin")
		end)
		if player.Parent == Players then
			Profiles[player] = profile
			setupPlayer(player, profile)
		else
			profile:EndSession()
		end
	else
		player:Kick("Profile load fail - Please rejoin")
	end
end

local function PlayerRemoving(player: Player)
	local profile = Profiles[player]
	if not profile then return end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats:Destroy()
	end
	profile:EndSession()
end

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

function module:Init()
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
end

function module:GetProfile(plr: Player)
	local profile = Profiles[plr]
	if profile then return profile end

	local elapsed = 0
	while not Profiles[plr] and elapsed < 1.5 do
		task.wait(0.1)
		elapsed += 0.1
	end

	return Profiles[plr]
end

function module:_DeepCopy(tbl)
	local copy = {}
	for k, v in tbl do
		if type(v) == "table" then
			copy[k] = self:_DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function module:_EnsureSlot(profile)
	local slotKey = profile.Data.SlotSelected
	if profile.Data.Slots[slotKey] then return profile.Data.Slots[slotKey] end

	local template = profile.Data.Slots["Template"]
	local newSlot = self:_DeepCopy(template)

	local raceData = newSlot.Customization.RaceData

	if type(raceData.PowerLevel) == "table" then
		local min, max = raceData.PowerLevel[1], raceData.PowerLevel[2]
		newSlot.Stats.PowerLevel = math.random(min, max)
		raceData.PowerLevel = nil
	end

	profile.Data.Slots[slotKey] = newSlot
	return newSlot
end

function module:GetSlotData(plr: Player, dataName: string)
	local profile = module:GetProfile(plr)
	if not profile then return end

	local slot = self:_EnsureSlot(profile)
	return slot[dataName]
end

function module:SetSlotData(plr: Player, dataName: string, value: any)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = self:_EnsureSlot(profile)
	slot[dataName] = value
end

function module:IncrementSlotData(plr: Player, dataName: string, amount: any)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = self:_EnsureSlot(profile)
	slot[dataName] += amount
end

function module:LoadSlotData(plr: Player)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = self:_EnsureSlot(profile)

	local function applyCustomization(char)
		CustomizationUtils.ApplyCustomizationDataToCharacter(char, slot.Customization)
	end

	plr.CharacterAdded:Connect(applyCustomization)

	local char = plr.Character
	if not char then return end

	applyCustomization(char)
end

return module