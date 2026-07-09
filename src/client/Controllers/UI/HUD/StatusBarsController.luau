local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Modules = ReplicatedStorage.Modules

local Network = require(Modules.Network)
local ReplicationPackets = Network.Replication.packets
local InitializePacket = ReplicationPackets.Initialize
local UpdatePacket = ReplicationPackets.Update

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("PlayerGui")
local MainFrame = ScreenGui:WaitForChild("Main")
local PlayerBars = MainFrame:WaitForChild("PlayerBars")

local KiFrame = PlayerBars:WaitForChild("Ki")
local KiBar = KiFrame:WaitForChild("KiBar") :: Frame

local StatusBarController = {}

function StatusBarController:Init()
    UpdatePacket.listen(function(data)
        local statName = data.Name
        local value = data.Value.uint32

        if statName == "Ki" then 
            KiBar.Size = UDim2.new(value / 100, 0, 1, 0)
        end
    end)
    
    InitializePacket.send({Name = "Ki"})
    InitializePacket.send({Name = "MaxKi"})
end

return StatusBarController