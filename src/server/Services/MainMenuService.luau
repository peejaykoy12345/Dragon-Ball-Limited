local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profiles = require(ServerScriptService.Services.Profiles)

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuPackets = MainMenuNamespace.packets
local MainMenuQueries = MainMenuNamespace.queries

local MainMenuService = {}

function MainMenuService:Init()
    MainMenuQueries.GetCustomizationData.listen(function(data, plr)
        local customizationData = Profiles:GetSlotData(plr, "Customization")
        customizationData.HasCustomized = Profiles:GetSlotData(plr, "Flags").HasCustomized

		return customizationData
	end)

    MainMenuPackets.ConfirmCustomization.listen(function(data, plr)
        local profile = Profiles:GetProfile(plr)
        if not profile then return end

        local CustomizationData = profile.Data.Slots[profile.Data.SlotSelected].Customization

        CustomizationData.Height = data.Height
        CustomizationData.BodyType = data.BodyType
        CustomizationData.Hair = data.Hair
        CustomizationData.Race = data.Race

        print("Edited: ", profile.Data.Slots[profile.Data.SlotSelected].Customization)
        
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
end

return MainMenuService