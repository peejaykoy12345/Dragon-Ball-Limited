local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local _Assets = ReplicatedStorage.Assets


local Modules = ReplicatedStorage.Modules
local GeneralUtils = Modules.Utilities.General
local ActionSession = require(ReplicatedStorage.Modules.Utilities.General.ActionSession)
local TableUtils = require(ReplicatedStorage.Modules.Utilities.General.TableUtils)
local Velocity = require(ReplicatedStorage.Modules.Utilities.General.Velocity)
local MoveUtils = require(GeneralUtils.MoveUtils)
local DamageUtils = require(GeneralUtils.DamageUtils)
local Cooldown = require(GeneralUtils.Cooldown)

local ClientFX = require(Modules.Utilities.Media.ClientFX)

local M1 = {}
M1.__index = M1
M1.Anims = {
    
}
M1.HitSFX = {
    
}
M1.MissSFX = {
    
}
M1.VFX = {
    
}
M1.SwingVFX = {
    
}
M1.ValidateHitParams = {
    BlockParams = {
        Blockable = true,
        PerfectBlockable = true,
    }
}
M1.KnockVelocity = {
    ZAxis = 25,
    YAxis = 15,
}
M1.RagdollDuration = 1.5
M1.Finished = Instance.new("BindableEvent")
M1.IsRunning = false

M1.lastTrack = {}

function M1:ShowVFX(char: Model, m1Count: number)
    
end

function M1:ShowSwingVFX(char: Model, m1Count: number)
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
    if not hrp then return end

    if self.SwingVFX[m1Count] then
        ClientFX:RenderToClient(
            {
                Name = "EmitParticles",
                Type = "Combat",
            },
            {
                parent = hrp,
                vfx = self.SwingVFX[m1Count],
                position = hrp.Position,
            }
        )
    else
        warn(`No m1 swing vfx found for {char.Name} at {m1Count} m1 count`)
    end
end

function M1:PlaySFX(parent: Instance, m1Count: number, sfxType: "Hit" | "Miss")
    if #self[sfxType .. "SFX"] <= 0 then return end
    ClientFX:PlaySFX(parent, self[sfxType .. "SFX"][m1Count])
end

function M1:CanStart(char: Model)
    return MoveUtils:CanPerformAction(char, script.Name, {statesToSkip = {M1CantUse = true}})
end

function M1:CreateHitbox(char: Model, session, moveInfo, onTouched)
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
            local params = TableUtils:CopyDictionary(self.ValidateHitParams)
            params.session = session
            if not MoveUtils:ValidateHit(char, hitChar, params) then continue end
            session:InitTarget(hitChar)

            onTouched(hitChar)
        end
    end)

    return hitbox
end

function M1:CreateSession(char: Model)
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

function M1:HandleM1Count(char: Model): number
    local Now_Clock = os.clock()
	char:SetAttribute("LastM1", Now_Clock)

	task.delay(1, function()
    if char and char:GetAttribute("LastM1") == Now_Clock then
            char:SetAttribute("Combo", 0) 
        end
    end)

    local maxM1Count = #self.Anims

	local currentCombo = char:GetAttribute("Combo") or 0
    char:SetAttribute("Combo", currentCombo + 1 > maxM1Count and 1 or currentCombo + 1)

    local m1Count = char:GetAttribute("Combo")

    return m1Count
end

function M1:OnLastM1Hit(char: Model, target: Model)
    MoveUtils:RagdollCharacter(target, self.RagdollDuration, true)
    self:ApplyKnockback(char, target)
end

function M1:ApplyKnockback(char: Model, target: Model)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ehrp = target:FindFirstChild("HumanoidRootPart")
    if not ehrp then return end

    local bv = Velocity.CreateBV(ehrp, Vector3.new(math.huge, math.huge, math.huge))
    bv.Velocity = (hrp.CFrame.LookVector * self.KnockVelocity.ZAxis) + (hrp.CFrame.UpVector * self.KnockVelocity.YAxis)
    Debris:AddItem(bv, 0.2)
end

function M1:M1(WCS_Character, info)
    local char, hrp = MoveUtils:GetPlayerContext(WCS_Character.Player)
    if not char or not hrp then return end

    if not self:CanStart(char) then return end

    local session = self:CreateSession(char)
    if not session then return end

    if self.lastTrack[char] then
        self.lastTrack[char]:Stop()
    end

    session:Start()
    self.IsRunning = true 

    session.extraStopFunction = function()
        self.IsRunning = false
        self.Finished:Fire()
    end

    local m1Count = self:HandleM1Count(char)

    local track = session:PlayAndAddAnimation(char, self.Anims[m1Count])
    local trackLength = MoveUtils:GetTrackLengthOrDefault(track, 0.3, 0.2)

    self:PlaySFX(char, m1Count, "Miss")
    self:ShowSwingVFX(char, m1Count)

    local lastM1 = m1Count >= #self.Anims

    if lastM1 then
        Cooldown:SetCooldown(char, script.Name, info.Cooldown)
        print(info.Cooldown)
    end

    local hitbox

    local markers = {
        HitStart = function()
            local hbInfo = {
                HitboxWeldOffsetCFrame = info.HitboxWeldOffsetCFrame,
                hitboxSize = info.ComboTimings[m1Count].HitboxSize,
            }

            hitbox = self:CreateHitbox(char, session, hbInfo, function(hitChar)
                self:PlaySFX(hitChar, m1Count, "Hit")
                DamageUtils:ValidateAndDamage(char, hitChar, info.ComboTimings[m1Count].Damage)

                MoveUtils:ApplyStun({
                    Target = hitChar,
                    Duration = 2,
                })

                if lastM1 then
                    self:OnLastM1Hit(char, hitChar)
                else
                    --MoveUtils:PlayHitReactionAnimation(hitChar)
                end
            end)
        end,
        HitEnd = function()
            if hitbox then
                hitbox:Destroy()
            end
        end,
        Stop = function()
            session:Stop()
        end
    }
    session:BulkAddConnections(MoveUtils:ConnectAnimationMarkers(track, markers))

    session:ApplyCastEffect()

    self.lastTrack[char] = track
    task.delay(trackLength + 1, function()
        if self.lastTrack[char] == track then
            self.lastTrack[char] = nil
        end
    end)
end

return M1