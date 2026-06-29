--[[local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets

local Modules = ReplicatedStorage.Modules
local GeneralUtils = Modules.Utilities.General
local ActionSession = require(ReplicatedStorage.Modules.Utilities.General.ActionSession)
local TableUtils = require(ReplicatedStorage.Modules.Utilities.General.TableUtils)
local Velocity = require(ReplicatedStorage.Modules.Utilities.General.Velocity)
local MoveUtils = require(GeneralUtils.MoveUtils)
local DamageUtils = require(GeneralUtils.DamageUtils)
local Cooldown = require(GeneralUtils.Cooldown)

local Animation = require(Modules.Utilities.Media.Animation)
local ClientFX = require(Modules.Utilities.Media.ClientFX)

local Heavy = {}

function Heavy:CanStart(char: Model)
    return MoveUtils:CanPerformAction(char, script.Name)
end

function Heavy:CreateHitbox(char: Model, session, moveInfo, onTouched)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if session.stopped then return end

    local hitbox = MoveUtils:CreateHitbox({
        SizeOrPart = moveInfo.HitboxSize,
        WeldOffsetCFrame = moveInfo.HitboxWeldOffsetCFrame,
        WeldedPart = hrp
    })

    session.hitbox = hitbox
    hitbox:Start()

    hitbox.HitSomeone:Connect(function(hitChars)
        for _, hitChar in ipairs(hitChars) do
            local params = TableUtils:CopyDictionary(self.ValidateHitParams or {})
            params.session = session
            if not MoveUtils:ValidateHit(char, hitChar, params) then continue end
            session:InitTarget(hitChar)

            onTouched(hitChar)
        end
    end)

    return hitbox
end

function Heavy:CreateSession(char: Model)
    local session = ActionSession.new({
        attacker = char,
        actionName = script.Name,
        actionType = "Default",
        states = {
            attackerStates = {"CantUse"},
        },
        skipBuffer = true,
    })

    return session
end

function Heavy:Start()
    if not self:CanStart(char) then return end
end

return Heavy]]