local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Assets = ReplicatedStorage.Assets
local FlyVFX = Assets.VFX.General.Flight :: BasePart

local Modules = ReplicatedStorage.Modules
local StateManager = require(Modules.Utilities.General.StateManager)
local ClientFX = require(Modules.Utilities.Media.ClientFX)

local Network = require(Modules.Network)
local RequestToggleFastFly = Network.Fly.queries.RequestToggleFastFly

local BLOCKED_SKIP_FAST_FLIGHT = {
    ["M1CantUse"] = true,
}

local FlyService = {}
FlyService.PlayerVFXHandleIds = {}

function FlyService:Init()
    Players.PlayerRemoving:Connect(function(plr)
        self.PlayerVFXHandleIds[plr] = nil
    end)

    RequestToggleFastFly.listen(function(data, plr)
        local char = plr.Character
        if not char then return false end

        local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
        if not hrp then return false end

        local status = data.Status

        if status then
            if StateManager.isActionBlocked(char, BLOCKED_SKIP_FAST_FLIGHT) then return false end

            StateManager.SetState(char, "FastFlight", true)

            local handleId = ClientFX:Construct(
                {
                    Name = "ToggleParticles",
                    Type = "General"
                },
                {
                    parent = hrp,
                    vfx = FlyVFX,
                    shouldWeld = true,
                    deletionTime = 9999,
                    position = hrp.Position
                }
            )
            ClientFX:Start(handleId, {position = hrp.Position})
            self.PlayerVFXHandleIds[plr] = handleId
        else
            StateManager.RemoveState(char, "FastFlight")

            local handleId = self.PlayerVFXHandleIds[plr]
            if handleId then
                ClientFX:Destroy(handleId)
            end
        end

        return true
    end)
end

return FlyService