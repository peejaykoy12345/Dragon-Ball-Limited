local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WCS = require(ReplicatedStorage.Modules.Packages.WCS)
local Character = WCS.Character

local SaiyanSetup = require(script.Setup.Saiyan)

local CharacterService = {}

function CharacterService:Init()
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            char.Parent = workspace.LivingBeings
            
            local WCS_Character = Character.new(char)

            SaiyanSetup.Setup(WCS_Character)
        end)
    end)

    local function RegisterHitbox(char: Model)
        local hitbox = char:FindFirstChild("Hitbox") :: BasePart
        if hitbox then
            hitbox:AddTag("Hitbox")
        end
    end

    for _, livingBeing in ipairs(workspace.LivingBeings:GetChildren()) do
        RegisterHitbox(livingBeing)
    end

    workspace.LivingBeings.ChildAdded:Connect(RegisterHitbox)
end

return CharacterService