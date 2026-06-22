local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LockOnUI: BillboardGui = ReplicatedStorage.Assets.UI.BillboardUI.LockOn

local LockOnController = {}

local CONFIG = {
	MAX_DISTANCE = 500,
	TARGET_HEIGHT_OFFSET = 2,
	ALIGN_RESPONSIVENESS = 15,
	CAMERA_DISTANCE = 8,
	CAMERA_HEIGHT = 3,
	CAMERA_LATERAL_OFFSET = 8,
	CAMERA_SIDE = "Right",
}

function LockOnController:_VisualizeRay(origin: Vector3, direction: Vector3)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.new(1, 0, 0)
	part.Size = Vector3.new(0.1, 0.1, direction.Magnitude)
	part.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -direction.Magnitude / 2)
	part.Parent = workspace

	Debris:AddItem(part, 2)
end

function LockOnController:_GetTargetUnderMouse(): Model?
	local camera = workspace.CurrentCamera
	local mouseLocation = UserInputService:GetMouseLocation()
	local unitRay = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { self.plr.Character }

	local rayDirection = unitRay.Direction * CONFIG.MAX_DISTANCE
	self:_VisualizeRay(unitRay.Origin, rayDirection)

	local result = workspace:Raycast(unitRay.Origin, rayDirection, raycastParams)
	if not result then return nil end

	local model = result.Instance:FindFirstAncestorWhichIsA("Model")
	if not model or model == self.plr.Character then return nil end

	local humanoid = model:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return nil end

	return model
end

function LockOnController:_CreateGroundAlign(hrp: BasePart)
	local attachment = Instance.new("Attachment")
	attachment.Name = "LockOnAttachment"
	attachment.Parent = hrp

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "LockOnAlignOrientation"
	alignOrientation.Attachment0 = attachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Responsiveness = CONFIG.ALIGN_RESPONSIVENESS
	alignOrientation.CFrame = hrp.CFrame.Rotation
	alignOrientation.Parent = hrp

	self.groundAttachment = attachment
	self.groundAlignOrientation = alignOrientation

    local hrpParent = hrp.Parent
	local hum = hrpParent:FindFirstChildWhichIsA("Humanoid") 
	if hum then
		hum.AutoRotate = false
	end
end

function LockOnController:_DestroyGroundAlign()
	if self.groundAlignOrientation then
		self.groundAlignOrientation:Destroy()
		self.groundAlignOrientation = nil
	end
	if self.groundAttachment then
		self.groundAttachment:Destroy()
		self.groundAttachment = nil
	end

	local char = self.plr.Character
	local hum = char and char:FindFirstChildWhichIsA("Humanoid")
	if hum then
		hum.AutoRotate = true
	end
end

function LockOnController:_UpdateGroundFacing()
	if not self.target or not self.groundAlignOrientation then return end

	local char = self.plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local targetHrp = self.target:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHrp then return end

	local toTarget = targetHrp.Position - hrp.Position
	local flatDirection = Vector3.new(toTarget.X, 0, toTarget.Z)
	if flatDirection.Magnitude < 0.05 then return end

	self.groundAlignOrientation.CFrame = CFrame.new(Vector3.zero, flatDirection)
end

function LockOnController:_UpdateLockOnCamera()
	if not self.target then return end

	local camera = workspace.CurrentCamera
	local char = self.plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local targetHrp = self.target:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHrp then return end

	local playerPos = hrp.Position
	local targetPos = targetHrp.Position + Vector3.new(0, CONFIG.TARGET_HEIGHT_OFFSET, 0)

	local toTarget = targetPos - playerPos
	local flatToTarget = Vector3.new(toTarget.X, 0, toTarget.Z)
	if flatToTarget.Magnitude < 0.05 then return end
	flatToTarget = flatToTarget.Unit

	local behindOffset = -flatToTarget * CONFIG.CAMERA_DISTANCE
	local rightDir = Vector3.yAxis:Cross(flatToTarget).Unit
	local sideMultiplier = if CONFIG.CAMERA_SIDE == "Left" then 1 else -1
	local lateralOffset = rightDir * CONFIG.CAMERA_LATERAL_OFFSET * sideMultiplier

	local cameraPos = playerPos + behindOffset + lateralOffset + Vector3.new(0, CONFIG.CAMERA_HEIGHT, 0)
	local lookDirection = toTarget.Unit

	camera.CFrame = CFrame.new(cameraPos, cameraPos + lookDirection)
end

function LockOnController:_LockZoom()
	self.savedMinZoom = self.plr.CameraMinZoomDistance
	self.savedMaxZoom = self.plr.CameraMaxZoomDistance
	self.plr.CameraMinZoomDistance = CONFIG.CAMERA_DISTANCE
	self.plr.CameraMaxZoomDistance = CONFIG.CAMERA_DISTANCE
end

function LockOnController:_UnlockZoom()
	if self.savedMinZoom then
		self.plr.CameraMinZoomDistance = self.savedMinZoom
		self.savedMinZoom = nil
	end
	if self.savedMaxZoom then
		self.plr.CameraMaxZoomDistance = self.savedMaxZoom
		self.savedMaxZoom = nil
	end
end

function LockOnController:_LockOnTo(target: Model)
	local hrp = target:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local ui = LockOnUI:Clone()
	ui.Adornee = hrp
	ui.Parent = hrp

	self.lockOnUI = ui
	self.target = target

	local char = self.plr.Character
	char:SetAttribute("LockOn", true)

	local targetValue = Instance.new("ObjectValue")
	targetValue.Name = "LockOnTarget"
	targetValue.Value = target
	targetValue.Parent = char
	self.targetValueInstance = targetValue

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	self:_LockZoom()

	RunService:BindToRenderStep("LockOnCamera", Enum.RenderPriority.Camera.Value + 1, function()
		self:_UpdateLockOnCamera()
	end)

	if not char:GetAttribute("Flying") then
		local charHrp = char:FindFirstChild("HumanoidRootPart")
		if charHrp then
			self:_CreateGroundAlign(charHrp)
		end
	end

	self.flyingChangedConn = char:GetAttributeChangedSignal("Flying"):Connect(function()
		if char:GetAttribute("Flying") then
			self:_DestroyGroundAlign()
		else
			local charHrp = char:FindFirstChild("HumanoidRootPart")
			if charHrp then
				self:_CreateGroundAlign(charHrp)
			end
		end
	end)

	self.groundFacingConn = RunService.Heartbeat:Connect(function()
		self:_UpdateGroundFacing()
	end)

	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	self.targetDiedConn = humanoid.Died:Connect(function()
		self:_Unlock()
	end)
end

function LockOnController:_Unlock()
	RunService:UnbindFromRenderStep("LockOnCamera")

	if self.groundFacingConn then
		self.groundFacingConn:Disconnect()
		self.groundFacingConn = nil
	end

	if self.flyingChangedConn then
		self.flyingChangedConn:Disconnect()
		self.flyingChangedConn = nil
	end

	self:_DestroyGroundAlign()
	self:_UnlockZoom()

	if self.lockOnUI then
		self.lockOnUI:Destroy()
		self.lockOnUI = nil
	end

	if self.targetValueInstance then
		self.targetValueInstance:Destroy()
		self.targetValueInstance = nil
	end

	if self.targetDiedConn then
		self.targetDiedConn:Disconnect()
		self.targetDiedConn = nil
	end

	self.target = nil

	local char = self.plr.Character
	if char then
		char:SetAttribute("LockOn", false)
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

function LockOnController:Init()
	self.plr = Players.LocalPlayer
	self.target = nil
	self.lockOnUI = nil
	self.targetDiedConn = nil
	self.groundAttachment = nil
	self.groundAlignOrientation = nil
	self.groundFacingConn = nil
	self.flyingChangedConn = nil
	self.targetValueInstance = nil
	self.savedMinZoom = nil
	self.savedMaxZoom = nil

	local function onCharacterAdded(char)
		self:_Unlock()
		char:SetAttribute("LockOn", false)

		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(function()
			self:_Unlock()
		end)
	end

	if self.plr.Character then
		onCharacterAdded(self.plr.Character)
	end
	self.plr.CharacterAdded:Connect(onCharacterAdded)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end

		if self.target then
			self:_Unlock()
			return
		end
		local newTarget = self:_GetTargetUnderMouse()
		if newTarget then
			self:_LockOnTo(newTarget)
		end
	end)
end

return LockOnController