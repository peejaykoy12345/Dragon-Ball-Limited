local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets
local MovementAnimations = Assets.Animations.Default.Movement

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local StateManager = require(Utilities.General.StateManager)
local Animation = require(Utilities.Media.Animation)

local FlyController = require(script.Parent.FlyController)

local ASSETS = {
	IDLE = MovementAnimations.Idle,
	WALK = MovementAnimations.Walk,
	RUN = MovementAnimations.Running,
	JUMP = MovementAnimations.Jump,
}

local CONFIG = {
	WALK_SPEED = 16,
	RUN_SPEED = 32,
	JUMP_HEIGHT = 30,

	DEFAULT_FOV = 70,
	RUN_FOV = 80,
	FOV_TWEEN_TIME = 0.3,
}

local MovementController = {}

function MovementController:_IsFlying(): boolean
	return FlyController.isFlying == true
end

function MovementController:_GetHumanoid(): Humanoid?
	local char = self.plr.Character
	return char and char:FindFirstChildWhichIsA("Humanoid")
end

function MovementController:_SetAnim(animName: string?)
	local char = self.plr.Character
	if not char then return end

	if self.currentAnim == animName then return end

	if self.currentAnim and ASSETS[self.currentAnim] then
		Animation:Stop(char, ASSETS[self.currentAnim])
	end

	self.currentAnim = animName

	if animName and ASSETS[animName] then
		Animation:Play(char, ASSETS[animName])
	end
end

function MovementController:_TweenFOV(targetFOV: number)
	if self.fovTween then
		self.fovTween:Cancel()
		self.fovTween = nil
	end

	local camera = workspace.CurrentCamera
	if math.abs(camera.FieldOfView - targetFOV) < 0.5 then return end

	self.fovTween = TweenService:Create(camera, TweenInfo.new(CONFIG.FOV_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = targetFOV,
	})
	self.fovTween:Play()
end

function MovementController:_StartSprint()
	if self.sprinting then return end
	if self:_IsFlying() then return end

	local char = self.plr.Character
	if not char then return end
	if StateManager.isActionBlocked(char) then return end

	local hum = self:_GetHumanoid()
	if not hum then return end

	self.sprinting = true
	hum.WalkSpeed = CONFIG.RUN_SPEED
	self:_TweenFOV(CONFIG.RUN_FOV)
end

function MovementController:_StopSprint()
	if not self.sprinting then return end

	self.sprinting = false

	local hum = self:_GetHumanoid()
	if hum then
		hum.WalkSpeed = CONFIG.WALK_SPEED
	end

	if not self:_IsFlying() then
		self:_TweenFOV(CONFIG.DEFAULT_FOV)
	end
end

function MovementController:_ShutDown()
	self:_StopSprint()
	self:_SetAnim(nil)
	self.active = false
end

function MovementController:_Resume()
	self.active = true

	local hum = self:_GetHumanoid()
	if hum then
		hum.WalkSpeed = CONFIG.WALK_SPEED
	end

	self:_TweenFOV(CONFIG.DEFAULT_FOV)
end

function MovementController:_UpdateMovementState()
	if not self.active then return end
	if self:_IsFlying() then return end

	local char = self.plr.Character
	if not char then return end

	local hum = self:_GetHumanoid()
	if not hum then return end

	if StateManager.isActionBlocked(char) then
		self:_StopSprint()
		self:_SetAnim(nil)
		return
	end

	hum.JumpHeight = CONFIG.JUMP_HEIGHT

	local state = hum:GetState()

	if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
		self:_SetAnim("JUMP")
		return
	end

	local moveDir = hum.MoveDirection
	local isMoving = moveDir.Magnitude > 0.01

	if not isMoving then
		self:_SetAnim("IDLE")
		return
	end

	if self.sprinting then
		self:_SetAnim("RUN")
	else
		self:_SetAnim("WALK")
	end
end

function MovementController:Init()
	self.plr = Players.LocalPlayer
	self.currentAnim = nil
	self.sprinting = false
	self.active = true
	self.fovTween = nil

	local function onCharacterAdded(char)
		self:_SetAnim(nil)
		self.sprinting = false
		self.active = not self:_IsFlying()
		self.currentAnim = nil

		local hum = char:WaitForChild("Humanoid")
		hum.WalkSpeed = CONFIG.WALK_SPEED
		hum.JumpHeight = CONFIG.JUMP_HEIGHT
	end

	if self.plr.Character then
		onCharacterAdded(self.plr.Character)
	end
	self.plr.CharacterAdded:Connect(onCharacterAdded)

	FlyController.IsFlyingChanged.Event:Connect(function()
		if self:_IsFlying() then
			self:_ShutDown()
		else
			self:_Resume()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:_StartSprint()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			self:_StopSprint()
		end
	end)

	RunService.Heartbeat:Connect(function()
		self:_UpdateMovementState()
	end)
end

return MovementController