local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")  

local Modules = ReplicatedStorage.Modules
local GeneralUtils = Modules.Utilities.General
local MediaUtils = Modules.Utilities.Media
local WCS = require(ReplicatedStorage.Modules.Packages.WCS)
local AnimationPlayer = require(MediaUtils.Animation)
local TableUtils = require(GeneralUtils.TableUtils)
local StateManager = require(GeneralUtils.StateManager)
local MoveUtils = require(GeneralUtils.MoveUtils)
local BufferInput = require(GeneralUtils.BufferInput)
local Cooldown = require(GeneralUtils.Cooldown)

local Pooling = require(MediaUtils.Pooling)

local AutoRotateEffect = require(ReplicatedStorage.Modules.WCS.StatusEffects.AutoRotate)
local CastEffect = require(ReplicatedStorage.Modules.WCS.StatusEffects.Cast)

local ActionSession = {}
ActionSession.__index = ActionSession

type cooldownParams = {
    cooldown: number?
}

type statesParams = {
    sharedStates: {string}?,
    attackerStates: {string}?,
    targetStates: {string}?,
}

type properties = {
    ["AutoRotate"]: boolean?,
    ["Anchored"]: boolean?
}

type propertiesParams = {
    attackerProperties: {
        ["AutoRotate"]: boolean?,
        ["Anchored"]: boolean?
    }?,
    sharedProperties: {
        ["AutoRotate"]: boolean?,
        ["Anchored"]: boolean?
    }?,
    targetProperties: {
        ["AutoRotate"]: boolean?,
        ["Anchored"]: boolean?
    }?,
}

export type ActionSessionParams = {
    attacker: Model,
    actionName: string,
    actionType: "Default" | "Overrideable" | "Cooldown" | "Misc",
    cooldown: cooldownParams?,
    states: statesParams?,
    properties: propertiesParams?,
    isProjectile: boolean?,
    skipBuffer: boolean?,
}

local CharacterAttackSessions = {}

function ActionSession.StopSession(char)
    local sessions = CharacterAttackSessions[char]
    if not sessions then return end
    for _, session in ipairs(sessions) do
        session:Stop(true)
    end
    CharacterAttackSessions[char] = nil
end

-- Use only if InitTarget check outlasts the session
function ActionSession.ProcessTarget(char: Model, target: Model)
    ActionSession.StopSession(target)
    MoveUtils:RegisterHit(char, target)
end

function ActionSession.new(params: ActionSessionParams)
    assert(params.attacker, "Attacker is required")
    assert(params.actionName, "actionName is required")
    assert(params.actionType, "ActionType is required")

    if not CharacterAttackSessions[params.attacker] then
        CharacterAttackSessions[params.attacker] = {}
    end

    local sessions = CharacterAttackSessions[params.attacker]
    for _, pastSession in ipairs(sessions) do
        if pastSession.actionType == "Overrideable" then
            pastSession:Stop(true)
        end
    end

    local self = setmetatable({}, ActionSession)

    self.attacker = params.attacker
    self.actionName = params.actionName
    self.actionType = params.actionType
    self.cooldown = params.cooldown
    self.states = params.states
    self.properties = params.properties or {}
    self.properties.extra = {}
    self.animations = {}
    self.targets = {}
    self.skipBuffer = params.skipBuffer or false
    self.options = params

    self.isProjectile = params.isProjectile or false

    self.connections = {}
    self.hitboxes = {}
    self.welds = {}
    self.stuns = {}
    self.statusEffects = {}
    self.pooledObjects = {}
    self.extraStates = {}

    self.stopped = false

    table.insert(CharacterAttackSessions[self.attacker], self)

    local conn

    conn = self.attacker.Humanoid.Died:Connect(function()
        self:Stop(true)
        conn:Disconnect()
    end)

    return self
end

function ActionSession:InitTarget(target: Model)
    ActionSession.StopSession(target)

    if self.states then
        self:SetStatesTo(target, self.states.sharedStates)
        self:SetStatesTo(target, self.states.targetStates)
    end

    if self.properties then
        self:_ApplyPropertiesTo(target, self.properties.sharedProperties)
        self:_ApplyPropertiesTo(target, self.properties.targetProperties)
    end

    MoveUtils:RegisterHit(self.attacker, target)

    if self.targets then
        table.insert(self.targets, target)
    end
end

function ActionSession:WeldParts(primary: BasePart, part: BasePart, weldName: "Weld" | "WeldConstraint" | "Motor6D"): Weld | WeldConstraint | Motor6D
	local weld = MoveUtils:WeldParts(primary, part, weldName)
    
    table.insert(self.welds, weld)

    return weld
end

-------------------
--- ANIMATIONS ----
-------------------

type playOptionsParams = {
    Priority: number
}

function ActionSession:PlayAndAddAnimation(char: Model, AnimationInstanceOrId: number | Animation, playOptions: playOptionsParams?): AnimationTrack
    local anim = AnimationPlayer:Play(char, AnimationInstanceOrId, playOptions)
    self:AddAnimation(anim)

    return anim
end

function ActionSession:AddAnimation(animation: Animation)
    table.insert(self.animations, animation)
end

function ActionSession:StopAnimation(animation: AnimationTrack)
    TableUtils:ArrayRemove(self.animations, animation)
    AnimationPlayer:StopAnimation(animation)
end

function ActionSession:StopAllAnimations()
    if self.animations then
        for _, anim in ipairs(self.animations) do
            AnimationPlayer:StopAnimation(anim)
        end
        self.animations = {}
    end
end

function ActionSession:ApplyExtraStates(target: Model, states: {string})
    if not self.extraStates then
        self.extraStates = {}
    end

    self:SetStatesTo(target, states)

    table.insert(self.extraStates, {
        target = target,
        states = states,
    })
end

function ActionSession:RemoveExtraStates(target: Model, states: {string})
    if not self.extraStates then
        self.extraStates = {}
    end

    local index: number?
    for i, statesData in ipairs(self.extraStates) do
        if statesData.target == target and TableUtils:ArraysEqual(statesData.states, states) then
            index = i
        end
    end

    if index then
        self:RemoveStatesTo(target, states)
        table.remove(self.extraStates, index)
    end
end

function ActionSession:SetStatesTo(target: Model, states)
    if not states then return end

    for _, state in ipairs(states) do 
        StateManager.SetState(target, state, true)
    end
end

function ActionSession:RemoveStatesTo(target: Model, states)
    if not states then return end

    for _, state in ipairs(states) do 
        StateManager.RemoveState(target, state)
    end
end

function ActionSession:ApplyExtraProperties(target: Model, props: properties)
    self:_ApplyPropertiesTo(target, props)

    table.insert(self.properties.extra, {
        target = target,
        props = props,
    })
end

function ActionSession:RemoveExtraProperties(target: Model, props: properties)
    local index: number?
    for i, propsData in ipairs(self.properties.extra) do
        if propsData.target == target and TableUtils:ArraysEqual(propsData.props, props) then
            index = i
        end
    end

    if index then
        self:_RemovePropertiesFrom(target, props)
        table.remove(self.properties.extra, index)
    end
end

function ActionSession:_ApplyPropertiesTo(target: Model, props: {[string]: any}?)
    if not props then return end
    local hrp = target:FindFirstChild("HumanoidRootPart")

    if props.AutoRotate == false then
        local WCS_Character = WCS.Character.GetCharacterFromInstance(target)
        if WCS_Character then
            local AutoRotate = AutoRotateEffect.new(WCS_Character, false)
            AutoRotate:Start(999)
            table.insert(self.statusEffects, { effect = AutoRotate, wcsChar = WCS_Character })
        end
    end

    if props.Anchored == true and hrp then
        hrp.Anchored = true
    end
end

function ActionSession:_RemovePropertiesFrom(target: Model, props: {[string]: any}?)
    if not props then return end

    --local humanoid = target:FindFirstChildOfClass("Humanoid")
    local hrp = target:FindFirstChild("HumanoidRootPart")

    --[[if props.AutoRotate == false and humanoid then
        humanoid.AutoRotate = true
    end]]

    if props.Anchored == true and hrp then
        hrp.Anchored = false
    end
end

function ActionSession:BulkAddConnections(connections: {RBXScriptConnection})
    for _, connection in connections do
        table.insert(self.connections, connection)
    end
end

function ActionSession:AddConnection(connection: RBXScriptConnection)
    table.insert(self.connections, connection)
end

export type StunParamsType = MoveUtils.stunParamsType

function ActionSession:SetStunTo(params: StunParamsType)
    local stun = MoveUtils:ApplyStun(params)

    table.insert(self.statusEffects, stun)

    return stun
end

export type speedParamsType = MoveUtils.speedParamsType

function ActionSession:ApplySpeedEffect(params: speedParamsType)
    local speedEffect = MoveUtils:ApplySpeedEffect({
        Target = params.Target,
        Priority = params.Priority,
        Duration = params.Duration,
        Speed = params.Speed
    })

    table.insert(self.statusEffects, speedEffect)

    return speedEffect
end

export type CastParams = {
    Speed: number?,
    Priority: number?,
}

function ActionSession:ApplyCastEffect(params: CastParams?)
    local WCS_Character = WCS.Character.GetCharacterFromInstance(self.attacker)
    if not WCS_Character then return end

    local castEffect = CastEffect.new(WCS_Character, params)
    castEffect:Start(99999)

    self:AddStatusEffect(castEffect)
end

function ActionSession:AddStatusEffect(statusEffect)
    table.insert(self.statusEffects, statusEffect)
end

function ActionSession:AddPooledObject(object: Instance, template: Instance)
    self.pooledObjects[template] = object
end

function ActionSession:ReturnPooledObject(object: Instance, template: Instance)
    if self.pooledObjects[template] then
        Pooling.Return(object, template)
        self.pooledObjects[template] = nil
    end
end

function ActionSession:ReturnAllPooledObjects()
    if self.pooledObjects then
        for template, pooledObject in pairs(self.pooledObjects) do
            self:ReturnPooledObject(pooledObject, template)
        end
    end
end

function ActionSession:IsStopped(): boolean
    return self.stopped == true
end

function ActionSession:Start()
    local states = self.states
    if states then
        if states.sharedStates then
            self:SetStatesTo(self.attacker, states.sharedStates)
        end
        
        if states.attackerStates then
            self:SetStatesTo(self.attacker, states.attackerStates)
        end
    end

    if self.properties then
        self:_ApplyPropertiesTo(self.attacker, self.properties.attackerProperties)
        self:_ApplyPropertiesTo(self.attacker, self.properties.sharedProperties)
    end
end

function ActionSession:Stop(forcestop: boolean?)
    local sessions = CharacterAttackSessions[self.attacker]
    if sessions then
        TableUtils:ArrayRemove(sessions, self)
    end

    self.stopped = true

    if forcestop then
        self.forceStopped = true
        self:StopAllAnimations()
        self:ReturnAllPooledObjects()
    end

    if self.hitbox then
        self.hitbox:Destroy()
        self.hitbox = nil
    end

    if self.hitboxes then
        for _, hitbox in ipairs(self.hitboxes) do
            hitbox:Destroy()
        end
        self.hitboxes = nil
    end

    if self.states then
        self:RemoveStatesTo(self.attacker, self.states.attackerStates)
        self:RemoveStatesTo(self.attacker, self.states.sharedStates)

        for _, target in ipairs(self.targets) do
            self:RemoveStatesTo(target, self.states.sharedStates)
            self:RemoveStatesTo(target, self.states.targetStates)
        end
    end

    if self.extraStates then
        for _, entry in ipairs(self.extraStates) do
            self:RemoveStatesTo(entry.target, entry.states)
        end
        self.extraStates = nil
    end

    if self.properties then
        self:_RemovePropertiesFrom(self.attacker, self.properties.attackerProperties)
        self:_RemovePropertiesFrom(self.attacker, self.properties.sharedProperties)

        for _, target in ipairs(self.targets or {}) do
            self:_RemovePropertiesFrom(target, self.properties.sharedProperties)
            self:_RemovePropertiesFrom(target, self.properties.targetProperties)
        end

        if self.properties.extra then
            for _, entry in ipairs(self.properties.extra) do
                self:_RemovePropertiesFrom(entry.target, entry.props)
            end
        end
    end

    self.properties = nil
    self.targets = nil
    self.states = nil

    if self.statusEffects and #self.statusEffects > 0 then
        for _, entry in ipairs(self.statusEffects) do
            if typeof(entry) == "table" and entry.effect and entry.wcsChar then
                entry.effect:End()
                entry.effect:Destroy()
            else
                entry:End()
                entry:Destroy()
            end
        end
    end
    self.statusEffects = nil

    if self.connections then
        for _, connection in ipairs(self.connections) do
            if connection then connection:Disconnect() end
        end
    end
    self.connections = nil

    if self.welds then
        for _, weld in ipairs(self.welds) do
            weld:Destroy()
        end
    end
    self.welds = nil

    if self.extraStopFunction then
        self.extraStopFunction(self, forcestop)
        self.extraStopFunction = nil
    end

    if self.cooldown then
        Cooldown:SetCooldown(self.attacker, self.actionName, self.cooldown.cooldown)
    end

    local plr = Players:GetPlayerFromCharacter(self.attacker)
    if plr and not self.skipBuffer then
        BufferInput.TryConsumeBuffer(plr)
    end

    self.attacker = nil
    self.cooldown = nil
    self.options = nil
    self.stuns = nil
    self.animations = nil
    self.pooledObjects = nil
    self.skipBuffer = nil
end

function ActionSession:StopAllSessions()
    ActionSession.StopSession(self.attacker)
end

export type ActionSessionType = typeof(ActionSession)

return ActionSession :: ActionSessionType