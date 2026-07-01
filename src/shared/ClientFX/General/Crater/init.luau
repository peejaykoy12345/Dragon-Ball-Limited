local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RocksModule = require(ReplicatedStorage.Modules.Utilities.Media.Rocks)

local module = {}

function module:Start(args)
    local cframe = args.vfxCFrame

    RocksModule.CraterRows(cframe * CFrame.new(0, 2, 0), 7, 1, 9, 8, 14, true)
end

return module