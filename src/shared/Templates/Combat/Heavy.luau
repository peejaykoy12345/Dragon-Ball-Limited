local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
Heavy.__index = Heavy

Heavy.VFX = {
    HIT = Assets.VFX.General.Hit.M1,
}

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
    })

    return session
end

function Heavy:PlayHitVFX(hitChar: Model)
    local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
    if not ehrp then return end

    ClientFX:RenderToClient(
        {
            Name = "EmitParticles",
            Type = "General"
        },
        {
            parent = ehrp,
            vfx = self.VFX.HIT,
            shouldWeld = true,
            position = ehrp.Position,
        }
    )
end

function Heavy:Start(WCS_Character, info)
    local char, hrp = MoveUtils:GetWCSCharacterContext(WCS_Character)
    print("PASSD")
    if not self:CanStart(char) then return end

    print("Ran")

    local session = self:CreateSession(char)
    if not session then return end

    local heavyAnim = self.Anim
    if not heavyAnim then
        warn(`No heavy animation set for: {char.Name}`)
        return
    end

    char:SetAttribute("Combo", 0)

    local track = session:PlayAndAddAnimation(char, heavyAnim)
    local markers = {
        HitStart = function()
            session.hitbox = self:CreateHitbox(char, session, info, function(hitChar)
                local ehrp = hitChar:FindFirstChild("HumanoidRootPart")
                if not ehrp then return end
                
                DamageUtils:ValidateAndDamage(char, hitChar, info.Damage)

                MoveUtils:FacePlayer(ehrp, hrp)

                MoveUtils:ApplyStun({
                    Target = hitChar,
                    Duration = info.StunDuration,
                })

                self:PlayHitVFX(hitChar)

                Velocity.ApplySlamdown(char, hitChar, {
                    Knockback = info.KnockbackPower,
                    Duration = info.KnockbackDuration,
                    OnLand = function()
                        DamageUtils:ValidateAndDamage(char, hitChar, info.SlamDamage)
                    end
                })
            end)
        end,
        HitEnd = function()
            if session.hitbox then
                session.hitbox:Destroy()
            end
        end,
        Stop = function()
            session:Stop()
        end
    }

    session:BulkAddConnections(MoveUtils:ConnectAnimationMarkers(track, markers))
end

return Heavy