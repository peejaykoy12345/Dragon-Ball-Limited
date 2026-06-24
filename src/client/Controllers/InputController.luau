local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local InputPackets = Network.Input.packets

local InputToString = require(Modules.Configs.InputToString)

local InputController = {}

function InputController:Init()
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        local inputEnum = if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
            then input.UserInputType
            else input.KeyCode

        local inputString = InputToString[inputEnum]
        if not inputString then return end

        InputPackets.InputStarted.send({Input = inputString})
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        local inputEnum = if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
            then input.UserInputType
            else input.KeyCode

        local inputString = InputToString[inputEnum]
        if not inputString then return end

        InputPackets.InputEnded.send({Input = inputString})
    end)
end

return InputController