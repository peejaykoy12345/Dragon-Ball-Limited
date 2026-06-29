local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local InputPackets = Network.Input.packets

local Mouse = require(script.Mouse)
local Keyboard = require(script.Keyboard)

local InputService = {}

local MOUSE_CONTROLS = {"M1"}

function InputService:_IsMouseControl(input: string): boolean
    for _, control in MOUSE_CONTROLS do
        if control == input then
            return true
        end
    end
    return false
end

function InputService:Init()
    Players.PlayerRemoving:Connect(function(plr)
        Mouse.PlayerRemoving(plr)
        Keyboard.PlayerRemoving(plr)
    end)

    InputPackets.InputStarted.listen(function(data, plr)
        local char = plr.Character
        if not char then return end

        local input = data.Input

        if InputService:_IsMouseControl(input) then
            Mouse.HandleInput(plr, input, true)
        else
            Keyboard.HandleInput(plr, input, true)
        end
    end)

    InputPackets.InputEnded.listen(function(data, plr)
        local char = plr.Character
        if not char then return end

        local input = data.Input

        if InputService:_IsMouseControl(input) then
            Mouse.HandleInput(plr, input, false)
        else
            Keyboard.HandleInput(plr, input, false)
        end
    end)
end

return InputService