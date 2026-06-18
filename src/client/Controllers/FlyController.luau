local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
local GeneralUtilities = Modules.Utilities.General
local StateManager = require(GeneralUtilities.StateManager)

local Network = require(Modules.Network)

local FlyController = {}

local FLY_SPEED = 50
local ALIGN_RESPONSIVENESS = 15 
local SHIFTLOCK_FACE_SPEED = 10 

function FlyController:_GetCameraInputScalars(): (number, number)
	local moveVector = self.controls:GetMoveVector()

	local camCFrame = workspace.CurrentCamera.CFrame
	local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z)
	local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z)

	flatLook = flatLook.Unit
	flatRight = flatRight.Unit

	local forwardScalar = moveVector:Dot(flatLook)
	local rightScalar = moveVector:Dot(flatRight)

	print("[_GetCameraInputScalars] moveVector:", moveVector, "flatLook:", flatLook, "flatRight:", flatRight)
	print("[_GetCameraInputScalars] forwardScalar:", forwardScalar, "rightScalar:", rightScalar)

	return forwardScalar, rightScalar
end

function FlyController:_GetCameraRelativeDirection(forwardScalar: number, rightScalar: number): Vector3
	local camCFrame = workspace.CurrentCamera.CFrame
	local direction = (camCFrame.LookVector * forwardScalar) + (camCFrame.RightVector * rightScalar)

	if direction.Magnitude > 1 then
		direction = direction.Unit
	end

	print("[_GetCameraRelativeDirection] camLook:", camCFrame.LookVector, "camRight:", camCFrame.RightVector)
	print("[_GetCameraRelativeDirection] direction:", direction)

	return direction
end

function FlyController:_UpdateFreeCamFacing(forwardScalar: number, rightScalar: number)
	if not self.alignOrientation then return end
	if forwardScalar == 0 and rightScalar == 0 then return end

	local direction = self:_GetCameraRelativeDirection(forwardScalar, rightScalar)
	if direction.Magnitude < 0.05 then return end

	print("[_UpdateFreeCamFacing] setting alignOrientation target toward:", direction)

	self.alignOrientation.CFrame = CFrame.new(Vector3.zero, direction)
end

function FlyController:_UpdateShiftlockFacing(dt: number)
	local char = self.plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local camLook = workspace.CurrentCamera.CFrame.LookVector
	local targetCFrame = CFrame.new(hrp.Position, hrp.Position + camLook)
	local alpha = math.clamp(dt * SHIFTLOCK_FACE_SPEED, 0, 1)

	print("[_UpdateShiftlockFacing] camLook:", camLook, "alpha:", alpha, "hrp.LookVector before:", hrp.CFrame.LookVector)

	hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, alpha)

	print("[_UpdateShiftlockFacing] hrp.LookVector after:", hrp.CFrame.LookVector)
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
	alignOrientation.Responsiveness = ALIGN_RESPONSIVENESS
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

function FlyController:_StartFly()
	local char = self.plr.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hrp or not hum then return end

	if StateManager.isActionBlocked(char) then return end

	self.isFlying = true
	self.doubleJumpAvailable = false

	--hum:ChangeState(Enum.HumanoidStateType.Physics)

	self:_CreateFlyConstraints(hrp)
end

function FlyController:_StopFly()
	if not self.isFlying then return end

	self.isFlying = false
	self:_DestroyFlyConstraints()
end

function FlyController:Init()
	self.plr = Players.LocalPlayer

	local playerModule = require(self.plr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	self.controls = playerModule:GetControls()

	self.isFlying = false
	self.doubleJumpAvailable = true
	self.attachment = nil
	self.linearVelocity = nil
	self.alignOrientation = nil

	local function onCharacterAdded(char)
		self.doubleJumpAvailable = true
		self:_StopFly()

		local hum = char:WaitForChild("Humanoid")

		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
				self.doubleJumpAvailable = true
			end
		end)

		hum.Died:Connect(function()
			self:_StopFly()
		end)
	end

	if self.plr.Character then
		onCharacterAdded(self.plr.Character)
	end
	self.plr.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.JumpRequest:Connect(function()
		local char = self.plr.Character
		if not char then return end

		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end

		if self.isFlying then
			self:_StopFly()
			return
		end

		local state = hum:GetState()
		local isAirborne = state == Enum.HumanoidStateType.Jumping
			or state == Enum.HumanoidStateType.Freefall

		if isAirborne and self.doubleJumpAvailable then
			self:_StartFly()
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if not self.isFlying then return end
		if not self.linearVelocity then return end

		local char = self.plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local forwardScalar, rightScalar = self:_GetCameraInputScalars()
		local isShiftlocked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

		--print("[Heartbeat] isShiftlocked:", isShiftlocked, "hrp.LookVector:", hrp.CFrame.LookVector)

		if isShiftlocked then
			self:_UpdateShiftlockFacing(dt)

			if forwardScalar == 0 and rightScalar == 0 then
				self.linearVelocity.VectorVelocity = Vector3.zero
				--print("[Heartbeat][shiftlock] no input, VectorVelocity = zero")
			else
				local direction = self:_GetCameraRelativeDirection(forwardScalar, rightScalar)

				--print("[Heartbeat][shiftlock] direction:", direction, "-> VectorVelocity:", direction * FLY_SPEED)

				self.linearVelocity.VectorVelocity = direction * FLY_SPEED
			end
		else
			self:_UpdateFreeCamFacing(forwardScalar, rightScalar)

			if forwardScalar == 0 and rightScalar == 0 then
				self.linearVelocity.VectorVelocity = Vector3.zero
				--print("[Heartbeat][freecam] no input, VectorVelocity = zero")
			else
				local direction = self:_GetCameraRelativeDirection(forwardScalar, rightScalar)

				--print("[Heartbeat][freecam] direction:", direction, "-> VectorVelocity:", direction * FLY_SPEED)

				self.linearVelocity.VectorVelocity = direction * FLY_SPEED
			end
		end
	end)
end

return FlyController