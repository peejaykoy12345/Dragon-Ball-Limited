local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local GeneralUtils = Modules.Utilities.General
local StateManager = require(GeneralUtils.StateManager)
local HitboxClass = require(GeneralUtils.HitboxClass)
local Cooldown = require(GeneralUtils.Cooldown)
local Block

local WCS = require(Modules.Packages.WCS)
local Character = WCS.Character

local WCSFolder = ReplicatedStorage.Modules.WCS
local StatusEffects = WCSFolder.StatusEffects
local StunEffect = require(StatusEffects.Stun)
local SpeedEffect = require(StatusEffects.Speed)

local MoveUtils = {}
MoveUtils.ragdollTasks = {}
MoveUtils.activeCounters = {}
MoveUtils.stunInstances = {}

export type CreateHitboxConfig = {
	SizeOrPart: Vector3 | BasePart?,
	CFrame: CFrame?,
	Debug: boolean?,
	UseClient: Player?,
	WeldedPart: Part?,
	WeldOffsetCFrame: CFrame?, 
	DebounceTime: number?,
	VelocityPredictionFactor: number?,
	VelocityPrediction: boolean?,
}

function MoveUtils:CreateHitbox(custom_config: CreateHitboxConfig)
	local config = {
		SizeOrPart = custom_config.SizeOrPart or Vector3.new(4, 4, 4),
		UseClient = custom_config.UseClient,
		DebounceTime = custom_config.DebounceTime,
		Debug = custom_config.Debug ~= false,
		VelocityPredictionFactor = custom_config.VelocityPredictionFactor,
		VelocityPrediction = custom_config.VelocityPrediction,
	}

	local hitbox = HitboxClass.new(config)
	if custom_config.CFrame then 
		hitbox:SetPosition(custom_config.CFrame)
	end

	if custom_config.WeldedPart then
		hitbox:WeldTo(custom_config.WeldedPart, custom_config.WeldOffsetCFrame or CFrame.new(0, 0, 0))
	end

	return hitbox
end

local RecentHits = {} -- [attacker][target] = true
function MoveUtils:RegisterHit(attacker: Model, target: Model, delay: number?)
    RecentHits[attacker] = RecentHits[attacker] or {}
    RecentHits[attacker][target] = true
    task.delay(delay or 0.1, function()
        if RecentHits[attacker] then
            RecentHits[attacker][target] = nil
        end
    end)
end

function MoveUtils:AddCounter(attacker: Model, callback: (Model) -> ())
	self.activeCounters[attacker] = callback
end

function MoveUtils:RemoveCounter(attacker: Model)
	self.activeCounters[attacker] = nil
end

function MoveUtils:HasCounter(target: Model): boolean
	return self.activeCounters[target] ~= nil
end

export type CanPerformActionParams = {
    statesToSkip: {[string]: boolean}?,
}

function MoveUtils:CanPerformAction(char: Model, actionName: string, raw_params: CanPerformActionParams?): boolean
	local params = raw_params or {} 

	if StateManager.isActionBlocked(char, params.statesToSkip ) then
		return false
	end

	if Cooldown:IsOnCooldown(char, actionName) then
		return false
	end

	return true
end

export type ValidateHitParams = {
	session: any?,
	projectilePositon: Vector3?,
	BlockParams: {
		Blockable: boolean,
		BlockDamage: number,
	}?,
}

local _Block

function MoveUtils:ValidateHit(attacker: Model, target: Model, params: ValidateHitParams?): (boolean, string?)
    if attacker == target then return false end
    if StateManager.isCharacterInvincible(target) then return false end
    if RecentHits[target] and RecentHits[target][attacker] then return false end

    local hrp = attacker:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    if params then
        local session = params.session

        local BlockParams = params.BlockParams
        if BlockParams then
            if BlockParams.Blockable then
                if not Block then
                    Block = require(GeneralUtils.Block)
                end

                local attackerPosition = params.projectilePositon or hrp.Position
                local BlockState = Block:CheckBlockState(attacker, target)
                local IsBlocking = BlockState == "Blocking"
                if IsBlocking and Block:CheckBlock(attackerPosition, target) then Block:HitBlock(target, BlockParams.BlockDamage); return false, "Blocked" end
            end
        end

        if session then
            if self.activeCounters[target] then
                local callback = self.activeCounters[target]
                self.activeCounters[target] = nil
                session:StopAllSessions()
                callback(attacker)
                return false
            end
        end
    end

    return true
end

function MoveUtils:GetModelMass(model: Model)
	local Mass = 0
	for _, Part in pairs(model:GetDescendants()) do
		if Part:IsA("BasePart") then
			Mass += Part:GetMass()		
		end
	end
	return Mass
end

function MoveUtils:RagdollCharacter(target: Model, duration: number, ragdollStatus: boolean?)
	ragdollStatus = ragdollStatus or true

	local RagdollTrigger = target:FindFirstChild("RagdollTrigger")
	if not RagdollTrigger then
		warn(`RagdollTrigger not found in {target.Name}`)
		return
	end

	StateManager.SetState(target, "Ragdoll", true)

	RagdollTrigger.Value = ragdollStatus
	self.ragdollTasks[target] = task.delay(duration, function()
		RagdollTrigger.Value = not ragdollStatus
		self.ragdollTasks[target] = nil

		StateManager.RemoveState(target, "Ragdoll")
	end)
end

function MoveUtils:ConnectAnimationMarkers(track: AnimationTrack, markers: {[string]: () -> ()})
	local connections = {}
	for markerName, markerCallback in pairs(markers) do
		local connection = track:GetMarkerReachedSignal(markerName):Connect(markerCallback)
		table.insert(connections, connection)
	end

	return connections
end

function MoveUtils:WeldParts(primary: BasePart, part: BasePart, weldName: "Weld" | "WeldConstraint" | "Motor6D"): Weld | WeldConstraint | Motor6D
	local weld = Instance.new(weldName, primary)
	weld.Part0 = primary
	weld.Part1 = part

	weld.Parent = part

	return weld
end

function MoveUtils:GetWCSCharacterContext(WCS_Character): (Model?, BasePart?, Humanoid?)
	local char = WCS_Character.Instance
	if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
    local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid
	
    return char, hrp, humanoid
end

function MoveUtils:GetTrackLengthOrDefault(track: AnimationTrack, default: number, minNumber: number?): number
	local trackLength = track.Length
	if trackLength < (minNumber or 0) then
		trackLength = default
	end

	return trackLength
end

export type stunParamsType = {
	Target: Model,
	Duration: number,
	Priority: number?,
}

function MoveUtils:ApplyStun(stunParams: stunParamsType)
	local target = stunParams.Target
	local duration = stunParams.Duration
	local priority = stunParams.Priority

	assert(target, "Target is needed")
	assert(duration, "Stun duration is needed")

	local WCS_Character = Character.GetCharacterFromInstance(target)
	if not WCS_Character then 
		warn(`{target.Name} does not have a WCS Character`)
		return 
	end

	local stun = StunEffect.new(WCS_Character, {Priority = priority})
	stun:Start(duration)

	self.stunInstances[WCS_Character] = self.stunInstances[WCS_Character] or {}
	table.insert(self.stunInstances[WCS_Character], stun)

	task.delay(duration, function()
		self:StopStun(WCS_Character, stun)
	end)

	return stun
end

function MoveUtils:StopStun(char: Model)
	if not self.stunInstances then return end

	local WCS_Character = Character.GetCharacterFromInstance(char)
	if not WCS_Character then return end

	local stuns = self.stunInstances[WCS_Character]
	if not stuns then return end

	for _, stun in ipairs(stuns) do
		stun:Stop()
	end

	self.stunInstances[WCS_Character] = nil
end

export type speedParamsType = {
	Target: Model,
    Speed: number,
	Duration: number,
    Priority: number?,
}

function MoveUtils:ApplySpeedEffect(speedParams: speedParamsType)
	local target = speedParams.Target
    local speed = speedParams.Speed
	local duration = speedParams.Duration
    assert(speed, "Speed is required for speed status effect")
    assert(target, "Target is required")
	assert(duration, "Duration is required")

	local WCS_Character = Character.GetCharacterFromInstance(target)
	if not WCS_Character then return end

	local info = {
		Speed = speedParams.Speed,
		Priority = speedParams.Priority,
	}

	local speedEffect = SpeedEffect.new(WCS_Character, info)
	speedEffect:Start(duration)

	return speedEffect
end

function MoveUtils:SetPartsProperties(parts: {Instance}, propertyName: string, value: number | boolean | string, ignoreList: {Instance}?)
    for _, part in ipairs(parts) do
        if not part:IsA("BasePart") then continue end
        if ignoreList and table.find(ignoreList, part) then continue end

        part[propertyName] = value
    end
end

function MoveUtils:GetNearestEntity(position: Vector3, maxRange: number, ignoreList: {Model}?)
	local nearestEntity = nil
	local nearestDistance = math.huge
	
	for _, entity in pairs(workspace.LivingBeings:GetChildren()) do
		if entity:IsA("Model") and not table.find(ignoreList or {}, entity) then
			local distance = (entity.PrimaryPart.Position - position).Magnitude
			if distance < nearestDistance and distance <= maxRange then
				nearestEntity = entity
				nearestDistance = distance
			end
		end
	end
	
	return nearestEntity
end

export type PullParams = {
	Character: Model,
	AnchorPart: BasePart,
	Offset: CFrame,
	Duration: number,
}

export type TaskType = {
	Stop: () -> ()
}

function MoveUtils:PullCharacterToPart(params: PullParams): TaskType
	local character = params.Character
	local anchorPart = params.AnchorPart
	local offset = params.Offset
	local duration = params.Duration

	local rootPart = character:FindFirstChild("HumanoidRootPart")

	local cancelled = false
	local elapsed = 0

	local taskType = {}

	function taskType:Stop()
		cancelled = true
	end

	if not rootPart then
		return taskType
	end

	local startCFrame = rootPart.CFrame

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if cancelled then
			connection:Disconnect()
			return
		end

		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)

		local goalPosition = (anchorPart.CFrame * offset).Position
		local lookDirection = (anchorPart.Position - rootPart.Position)
		local goalCFrame = CFrame.new(goalPosition, goalPosition + lookDirection)

		rootPart.CFrame = startCFrame:Lerp(goalCFrame, alpha)

		if alpha >= 1 then
			connection:Disconnect()
		end
	end)

	return taskType
end

export type RepositionCharactersConfig = {
	ATTACKER_OFFSET: CFrame?,
	TARGET_OFFSET: CFrame?,
	ROTATION_OFFSET: CFrame?
}

function MoveUtils:RepositionCharacters(attacker: Model, target: Model, rawConfig: RepositionCharactersConfig?)
	local config = rawConfig or {}

	local attackerHrp = attacker:FindFirstChild("HumanoidRootPart")
	local targetHrp = target:FindFirstChild("HumanoidRootPart")
	
	if not attackerHrp or not targetHrp then return end

	local targetOffset = config.TARGET_OFFSET or CFrame.new(0, 0, -4)
	local attackerOffset = config.ATTACKER_OFFSET or CFrame.new(0, 0, 0)
	local rotationOffset = config.ROTATION_OFFSET or math.rad(0)

	local startCF = attackerHrp.CFrame

	local targetCF = startCF * targetOffset * CFrame.Angles(0, rotationOffset, 0)
	local attackerCF = startCF * attackerOffset 

	targetHrp.CFrame = targetCF
	attackerHrp.CFrame = attackerCF
end

function MoveUtils:FacePlayer(enemyRoot: BasePart, attackerRoot: BasePart)
	if not enemyRoot or not attackerRoot then return end

	local char = enemyRoot.Parent

	if char then
		char:SetAttribute("ForceFacingPosition", attackerRoot.Position)
	end

	local BodyGyro = Instance.new("BodyGyro")
	BodyGyro.MaxTorque = Vector3.new(0, 40000, 0)
	BodyGyro.P = 10000
	BodyGyro.CFrame = CFrame.lookAt(enemyRoot.Position, attackerRoot.Position * Vector3.new(1, 0, 1) + enemyRoot.Position * Vector3.new(0, 1, 0))
	BodyGyro.Parent = enemyRoot

	task.delay(0.35, function()
		BodyGyro:Destroy()
		if char then
			char:SetAttribute("ForceFacingPosition", nil)
		end
	end)
end	

--[[function MoveUtils:PlayHitReactionAnimation(hitChar: Model)
	local humanoid = hitChar:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local lastIndex = hitChar:GetAttribute("LastHitReaction") or 0

	local newIndex
	repeat
		newIndex = math.random(1, 6)
	until newIndex ~= lastIndex

	hitChar:SetAttribute("LastHitReaction", newIndex)

	local animationInstance = HitReactions:FindFirstChild(tostring(newIndex))
	if not animationInstance then
		warn(`HitReaction {newIndex} not found in HitReactions folder`)
		return
	end

	local track = animator:LoadAnimation(animationInstance)
	track:Play()
end]]

return MoveUtils