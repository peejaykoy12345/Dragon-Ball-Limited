local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local WCSFolder = Modules.WCS

local WCS = require(Modules.Packages.WCS)

local Server = WCS.CreateServer()

Server:RegisterDirectory(WCSFolder.Skills)
Server:RegisterDirectory(WCSFolder.StatusEffects)

Server:Start()