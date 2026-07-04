local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local CustomizationUtils = require(game.ReplicatedStorage.Modules.Utilities.Misc.CustomizationUtils)

local MainMenuController = {}

function MainMenuController:Init()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.T then
            local char = plr.Character

            CustomizationUtils.SetCharacterWidth(char, 1.60)
            CustomizationUtils.SetCharacterHeight(char, 1.20)
            CustomizationUtils.PutOnHair(char, workspace["Customization Stuff"].Hairs["saiyan hair"]["M1"])
            CustomizationUtils.PutOnClothing(char, workspace["Customization Stuff"].Clothing["saiyan(Starter Oufit)"])
        end
    end)
end 

return MainMenuController