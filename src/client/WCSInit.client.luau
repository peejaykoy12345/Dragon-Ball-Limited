local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)

local Client = WCS.CreateClient()

Client:Start()