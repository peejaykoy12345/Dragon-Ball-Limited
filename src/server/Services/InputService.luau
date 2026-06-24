local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local InputPackets = Network.Input.packets

local InputService = {}

function InputService:Init()
    InputPackets.InputStarted.listen(function(data, plr)
        local char = plr.Character
        if not char then return end
        
        local input = data.Input
    end)

    InputPackets.InputEnded.listen(function(data, plr)
        local char = plr.Character
        if not char then return end
        
        local input = data.Input
    end)
end

return InputService