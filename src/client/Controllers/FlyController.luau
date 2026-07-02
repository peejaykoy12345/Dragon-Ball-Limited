local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = ReplicatedStorage.Assets.Animations
local FlyAnimations = Animations.Default.Flight

local Modules = ReplicatedStorage.Modules
local GeneralUtilities = Modules.Utilities.General
local StateManager = require(GeneralUtilities.StateManager)
local AnimationPlayer = require(Modules.Utilities.Media.Animation)

local Network = require(ReplicatedStorage.Modules.Network)
local RequestToggleFastFly = Network.Fly.queries.RequestToggleFastFly
local FlyVelocityOverride = Network.Fly.packets.FlyVelocityOverride
local StopFlyVelocityOverride = Network.Fly.packets.StopFlyVelocityOverride

local FlyController = {}

local CONFIG = {
	FLY_SPEED = 50,
	BOOST_MULTIPLIER = 2,
	ALIGN_RESPONSIVENESS = 30,
	HOLD_DURATION = 0.5,
	GROUND_CHECK_DISTANCE = 5,
	BASE_WALK_SPEED = 16,
}

local BLOCKED_SKIP = {
	["M1CantUse"] = true,
	["FastFlight"] = true,
}

function FlyController:_IsNearGround(hrp: BasePart): boolean
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.plr.Character}

	local result = workspace:Raycast(hrp.Position, Vector3.new(0, -CONFIG.GROUND_CHECK_DISTANCE, 0), raycastParams)
	return result ~= nil
end

function FlyController:_GetCameraInputScalars(): (number, number)
	local moveVector = self.controls:GetMoveVector()
	return -moveVector.Z, moveVector.X
end

function FlyController:_GetCameraRelativeDirection(forwardScalar: number, rightScalar: number): Vector3
	local camCFrame = workspace.CurrentCamera.CFrame
	local direction = (camCFrame.LookVector * forwardScalar) + (camCFrame.RightVector * rightScalar)

	if direction.Magnitude > 1 then
		direction = direction.Unit
	end

	return direction
end

function FlyController:_GetLockOnTarget(char: Model): Model?
	if not char:GetAttribute("LockOn") then return nil end

	local targetValue = char:FindFirstChild("LockOnTarget")
	if not targetValue or not targetValue:IsA("ObjectValue") then return nil end

	return targetValue.Value
end

function FlyController:_UpdateLockOnFacing(hrp: BasePart, targetHrp: BasePart)
	if not self.alignOrientation then return end

	local toTarget = targetHrp.Position - hrp.Position
	if toTarget.Magnitude < 0.05 then return end

	self.alignOrientation.CFrame = CFrame.new(Vector3.zero, toTarget.Unit)
end

function FlyController:_UpdateFreeCamFacing(forwardScalar: number, rightScalar: number)
	if not self.alignOrientation then return end
	if forwardScalar == 0 and rightScalar == 0 then return end

	local direction = self:_GetCameraRelativeDirection(forwardScalar, rightScalar)
	if direction.Magnitude < 0.05 then return end

	self.alignOrientation.CFrame = CFrame.new(Vector3.zero, direction)
end

function FlyController:_UpdateShiftlockFacing()
	if not self.alignOrientation then return end

	local camLook = workspace.CurrentCamera.CFrame.LookVector
	self.alignOrientation.CFrame = CFrame.new(Vector3.zero, camLook)
end

function FlyController:_CreateFlyConstraints(hrp: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "FlyAttachment"
	attachment.Parent = hrp

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "FlyLinearVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = hrp

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "FlyAlignOrientation"
	alignOrientation.Attachment0 = attachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = CONFIG.ALIGN_RESPONSIVENESS
	alignOrientation.CFrame = hrp.CFrame.Rotation
	alignOrientation.Parent = hrp

	self.attachment = attachment
	self.linearVelocity = linearVelocity
	self.alignOrientation = alignOrientation
end

function FlyController:_DestroyFlyConstraints()
	if self.linearVelocity then
		self.linearVelocity:Destroy()
		self.linearVelocity = nil
	end
	if self.alignOrientation then
		self.alignOrientation:Destroy()
		self.alignOrientation = nil
	end
	if self.attachment then
		self.attachment:Destroy()
		self.attachment = nil
	end
end

function FlyController:_SetAnimation(animName: string?)
	local char = self.plr.Character
	if not char then return end

	if self.currentFlyAnim == animName then return end

	if self.currentFlyAnim then
		local oldAnim = FlyAnimations:FindFirstChild(self.currentFlyAnim)
		if oldAnim then
			AnimationPlayer:Stop(char, oldAnim)
		end
	end

	self.currentFlyAnim = animName

	if animName then
		local newAnim = FlyAnimations:FindFirstChild(animName)
		if newAnim then
			AnimationPlayer:Play(char, newAnim)
		end
	end
end

function FlyController:_GetAnimationName(forwardScalar: number, rightScalar: number, isShiftlocked: boolean): string
	if self.upHeld then return "Up" end
	if self.downHeld then return "Down" end
	if forwardScalar == 0 and rightScalar == 0 then return "Idle" end

	if not isShiftlocked then
		if self.boostHeld then return "FastFlight" end
		return "Forward"
	end

	if forwardScalar > 0 then
		return if self.boostHeld then "FastFlight" else "Forward"
	end
	if forwardScalar < 0 then return "Backward" end
	if rightScalar > 0 then return "Right" end
	if rightScalar < 0 then return "Left" end

	return "Idle"
end

function FlyController:_GetSpeedScale(hum: Humanoid): number
	return hum.WalkSpeed / CONFIG.BASE_WALK_SPEED
end

function FlyController:_ApplyVelocityOverride(velocity: Vector3, duration: number, velType: string, maxForce: Vector3?, name: string?)
	self.velocityOverride = {
		Velocity = velocity,
		Type = velType,
		MaxForce = maxForce,
		Name = name,
	}

	task.delay(duration, function()
		if self.velocityOverride and self.velocityOverride.Velocity == velocity then
			self.velocityOverride = nil
		end
	end)
end

function FlyController:_StartFly()
	local char = self.plr.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hrp or not hum then return end

	if StateManager.isActionBlocked(char, BLOCKED_SKIP) then return end

	self.isFlying = true
	self:_CreateFlyConstraints(hrp)
	self:_SetAnimation("Idle")
	char:SetAttribute("Flying", true)
end

function FlyController:_StopFly()
	if not self.isFlying then return end

	self.isFlying = false
	self.velocityOverride = nil
	self:_SetAnimation(nil)
	self:_DestroyFlyConstraints()

	local char = self.plr.Character
	if char then
		char:SetAttribute("Flying", false)
	end

	RequestToggleFastFly.invoke({Status = false})
	self.boostHeld = false
end

function FlyController:Init()
	self.plr = Players.LocalPlayer

	local playerModule = require(self.plr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	self.controls = playerModule:GetControls()

	self.isFlying = false
	self.attachment = nil
	self.linearVelocity = nil
	self.alignOrientation = nil
	self.currentFlyAnim = nil
	self.spaceHeldStart = nil
	self.upHeld = false
	self.downHeld = false
	self.boostHeld = false
	self.velocityOverride = nil

	local function onCharacterAdded(char)
		self:_StopFly()
		char:SetAttribute("Flying", false)

		local hum = char:WaitForChild("Humanoid")

		hum.Died:Connect(function()
			self:_StopFly()
		end)
	end

	if self.plr.Character then
		onCharacterAdded(self.plr.Character)
	end
	self.plr.CharacterAdded:Connect(onCharacterAdded)

	FlyVelocityOverride.listen(function(data)
		if not self.isFlying then return end
		self:_ApplyVelocityOverride(data.Velocity, data.Duration, data.Type, data.MaxForce, data.Name)
	end)

	StopFlyVelocityOverride.listen(function(data)
		if self.velocityOverride and self.velocityOverride.Name == data.Name then
			self.velocityOverride = nil
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.Space then
			if self.isFlying then
				self.upHeld = true
			else
				self.spaceHeldStart = tick()
			end
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			if self.isFlying then
				self.downHeld = true
			end
		elseif input.KeyCode == Enum.KeyCode.LeftShift and self.isFlying and RequestToggleFastFly.invoke({Status = true}) then
			self.boostHeld = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			self.spaceHeldStart = nil
			self.upHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftControl then
			self.downHeld = false
		elseif input.KeyCode == Enum.KeyCode.LeftShift and RequestToggleFastFly.invoke({Status = false}) then
			self.boostHeld = false
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if self.spaceHeldStart and not self.isFlying then
			if (tick() - self.spaceHeldStart) >= CONFIG.HOLD_DURATION then
				self.spaceHeldStart = nil
				self:_StartFly()
			end
		end

		if not self.isFlying then return end
		if not self.linearVelocity then return end

		local char = self.plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildWhichIsA("Humanoid")
		if not hrp or not hum then return end

		if self.velocityOverride then
			if self.velocityOverride.MaxForce then
				self.linearVelocity.MaxForce = self.velocityOverride.MaxForce.Magnitude
			end
			self.linearVelocity.VectorVelocity = self.velocityOverride.Velocity
			return
		end

		self.linearVelocity.MaxForce = math.huge

		if StateManager.isActionBlocked(char, BLOCKED_SKIP) then
			self.linearVelocity.VectorVelocity = Vector3.zero

			local forceFacing = char:GetAttribute("ForceFacingPosition")
			if forceFacing and self.alignOrientation then
				local toTarget = forceFacing - hrp.Position
				if toTarget.Magnitude > 0.05 then
					self.alignOrientation.CFrame = CFrame.new(Vector3.zero, toTarget.Unit)
				end
			end

			return
		end

		if self.downHeld and self:_IsNearGround(hrp) then
			self:_StopFly()
			return
		end

		local speedScale = self:_GetSpeedScale(hum)
		local forwardScalar, rightScalar = self:_GetCameraInputScalars()
		local isShiftlocked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
		local speed = if self.boostHeld then CONFIG.FLY_SPEED * CONFIG.BOOST_MULTIPLIER * speedScale else CONFIG.FLY_SPEED * speedScale

		local velocity = Vector3.zero

		if forwardScalar ~= 0 or rightScalar ~= 0 then
			velocity = self:_GetCameraRelativeDirection(forwardScalar, rightScalar) * speed
		end

		if self.upHeld or self.downHeld then
			local vertical = 0
			if self.upHeld then vertical += 1 end
			if self.downHeld then vertical -= 1 end
			velocity = velocity + workspace.CurrentCamera.CFrame.UpVector * vertical * speed
		end

		if velocity.Magnitude > speed then
			velocity = velocity.Unit * speed
		end

		self.linearVelocity.VectorVelocity = velocity

		local lockOnTarget = self:_GetLockOnTarget(char)
		local lockOnTargetHrp = lockOnTarget and lockOnTarget:FindFirstChild("HumanoidRootPart")

		local forceFacing = char:GetAttribute("ForceFacingPosition")
		if forceFacing then
			if self.alignOrientation then
				local toTarget = forceFacing - hrp.Position
				if toTarget.Magnitude > 0.05 then
					self.alignOrientation.CFrame = CFrame.new(Vector3.zero, toTarget.Unit)
				end
			end
		elseif lockOnTargetHrp then
			self:_UpdateLockOnFacing(hrp, lockOnTargetHrp)
		elseif isShiftlocked then
			self:_UpdateShiftlockFacing()
		else
			self:_UpdateFreeCamFacing(forwardScalar, rightScalar)
		end

		self:_SetAnimation(self:_GetAnimationName(forwardScalar, rightScalar, isShiftlocked))
	end)
end

return FlyController