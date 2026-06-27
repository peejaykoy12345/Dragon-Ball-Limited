local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules

local WCSFolder = Modules.WCS

local WCS = require(Modules.Packages.WCS)

local Client = WCS.CreateClient()

Client:RegisterDirectory(WCSFolder.Skills)
Client:RegisterDirectory(WCSFolder.StatusEffects)

Client:Start()