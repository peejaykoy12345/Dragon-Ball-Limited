local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("MainMenu"):WaitForChild("Main Menu") :: ScreenGui
local PlayButton = ScreenGui:WaitForChild("Play") :: ImageButton
local CustomizeButton = ScreenGui:WaitForChild("Customize") :: ImageButton
local SlotsButton = ScreenGui:WaitForChild("Slots") :: ImageButton

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuPackets = MainMenuNamespace.packets
local MainMenuQueries = MainMenuNamespace.queries

local Customization = require(script.Customization)
local Slots = require(script.Slots)

local MainMenuController = {}
MainMenuController.__index = true

function MainMenuController:Init()
    PlayButton.Activated:Connect(function()
        local data = MainMenuQueries.GetCustomizationData.invoke({})
        if not data or not data.HasCustomized then return end

        MainMenuPackets.Play.send({})

        ScreenGui.Enabled = false
    end)    

    CustomizeButton.Activated:Connect(function()
        Customization:OpenCustomization()
    end)

    SlotsButton.Activated:Connect(function()
        Slots:OpenUI()
    end)

    Customization:Init()
    Slots:Init()
end 

return MainMenuController