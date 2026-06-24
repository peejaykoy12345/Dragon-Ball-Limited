local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

local Server = WCS.CreateServer()

Server:Start()