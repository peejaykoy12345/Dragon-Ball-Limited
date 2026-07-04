local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer

local MainMenuController = {}

function MainMenuController:Init()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.T then
            local char = plr.Character

            -- print("PRESSED")
            require(game.ReplicatedStorage.Modules.Utilities.Misc.CustomizationUtils).PutOnClothing(char, workspace["Customization Stuff"].Clothing["saiyan(Starter Oufit)"])
        end
    end)
end 

return MainMenuController