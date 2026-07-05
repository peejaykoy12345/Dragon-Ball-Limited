local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("MainMenu"):WaitForChild("Main Menu")
local PlayButton = ScreenGui:WaitForChild("Play") :: ImageButton
local CustomizeButton = ScreenGui:WaitForChild("Customize") :: ImageButton

local Network = require(ReplicatedStorage.Modules.Network)
local GetCustomizationData = Network["Main Menu"].queries.GetCustomizationData

local Customization = require(script.Customization)

local MainMenuController = {}
MainMenuController.__index = true

function MainMenuController:Init()
    PlayButton.Activated:Connect(function()
        local data = GetCustomizationData.invoke({})
        if not data or not data.HasCustomized then return end

    end)    

    CustomizeButton.Activated:Connect(function()
        Customization:OpenCustomization()
    end)

    Customization:Init()
end 

return MainMenuController