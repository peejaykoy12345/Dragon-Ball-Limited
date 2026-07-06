local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerPackages = ServerScriptService.ServerPackages
local ProfileStore = require(ServerPackages.ProfileStore)

local Modules = ReplicatedStorage.Modules
local CustomizationUtils = require(Modules.Utilities.Misc.CustomizationUtils)

export type ProfileData = {
    Slots: {
        [string]: {
			[string]: {
				[string]: string | number | boolean
			}
		},
    },
	SlotSelected: string,
}

local PROFILE_TEMPLATE: ProfileData = {
	Slots = {
        ["1"] = {
			Customization = {
				Clothing = "Saiyan(Starter Oufit)",
				Race = "Saiyan",
				Hair = "Type 1",
				BodyType = 1,
				Height = 1,
			},
			Flags = {
				HasCustomized = true,
			}
        },
    },
    SlotSelected = "1",
}

local PlayerStore = ProfileStore.New("PlayerData_TESTV8", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}
local module = {}

local function setupPlayer(player, profile)
	
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

function module:GetSlotData(plr: Player, dataName: string)
	local profile = module:GetProfile(plr)
	if not profile then return end

	local slot = profile.Data.Slots[profile.Data.SlotSelected]
	if not slot then return end

	return slot[dataName]
end

function module:SetSlotData(plr: Player, dataName: string, value: any)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = profile.Data.Slots[profile.Data.SlotSelected]
	if not slot then return end

	slot[dataName] = value
end

function module:IncrementSlotData(plr: Player, dataName: string, amount: any)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = profile.Data.Slots[profile.Data.SlotSelected]
	if not slot then return end

	slot[dataName] += amount
end

function module:LoadSlotData(plr: Player)
	local profile = Profiles[plr]
	if not profile then return end

	local slot = profile.Data.Slots[profile.Data.SlotSelected]
	if not slot then return end

	local function applyCustomization(char)
		CustomizationUtils.ApplyCustomizationDataToCharacter(char, slot.Customization)
	end

	plr.CharacterAdded:Connect(applyCustomization)

	local char = plr.Character
	if not char then return end

	applyCustomization(char)
end

return module