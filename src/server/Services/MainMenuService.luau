local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(ServerScriptService.Services.Profiles)

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuPackets = MainMenuNamespace.packets
local MainMenuQueries = MainMenuNamespace.queries

local RaceData = require(Modules.Configs.RaceData)

local MainMenuService = {}

function MainMenuService:Init()
    MainMenuPackets.ConfirmCustomization.listen(function(data, plr)
        local profile = Profiles:GetProfile(plr)
        if not profile then return end

        local slot = profile.Data.Slots[profile.Data.SlotSelected]
        local CustomizationData = slot.Customization

        CustomizationData.Height = data.Height
        CustomizationData.BodyType = data.BodyType
        CustomizationData.Hair = data.Hair
        CustomizationData.Race = data.Race
        CustomizationData.Eyes = data.Eyes
        CustomizationData.NoseAndMouth = data.NoseAndMouth

        local raceInfo = RaceData[data.Race]
        if raceInfo and raceInfo.StartingStats then
            for stat, value in raceInfo.StartingStats do
                slot.Stats[stat] = value
            end
        end

        -- print("Customization:", data)

        Profiles:GetSlotData(plr, "Flags").HasCustomized = true
    end)

    MainMenuPackets.Play.listen(function(data, plr)
        Profiles:LoadSlotData(plr)
    end)

    MainMenuPackets.ChangeSlot.listen(function(data, plr)
        local profile = Profiles:GetProfile(plr)
        if not profile then return end

        local slot = tostring(data.Slot)

        if not table.find(profile.Data.UnlockedSlots, slot) then return end

        profile.Data.SlotSelected = slot
    end)

    MainMenuQueries.GetCustomizationData.listen(function(data, plr)
        local customizationData = Profiles:GetSlotData(plr, "Customization")
        customizationData.HasCustomized = Profiles:GetSlotData(plr, "Flags").HasCustomized

		return customizationData
	end)

    MainMenuQueries.GetSlotData.listen(function(_, plr)
        local profile = Profiles:GetProfile(plr)

        local sortedKeys = {}

        for key in pairs(profile.Data.Slots) do
            if key == "Template" then continue end
            table.insert(sortedKeys, key)
        end

        table.sort(sortedKeys, function(a, b)
            return tonumber(a) < tonumber(b)
        end)

        local data = {}

        for _, key in ipairs(sortedKeys) do
            local slot = profile.Data.Slots[key]

            table.insert(data, {
                Race = slot.Customization.Race,
                PowerLevel = slot.Stats.PowerLevel,
                Level = slot.Stats.Level,
            })
        end

        return data
    end)
end

return MainMenuService