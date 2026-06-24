local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LockOnUI: BillboardGui = ReplicatedStorage.Assets.UI.BillboardUI.LockOn

local LockOnController = {}

local CONFIG = {
	MAX_DISTANCE = 500,
	TARGET_HEIGHT_OFFSET = 6,

	BOX_HALF_WIDTH = 6,
	BOX_HALF_HEIGHT = 4,
	BOX_MIN_DEPTH = 10,
	BOX_MAX_DEPTH = 25,

	INITIAL_CAMERA_DISTANCE = 18,

	DEBUG_SHOW_BOX = true,
	DEBUG_BOX_COLOR = Color3.fromRGB(0, 255, 255),
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

function LockOnController:_CreateDebugBox()
	if not CONFIG.DEBUG_SHOW_BOX then return end

	local box = Instance.new("Part")
	box.Name = "LockOnDebugBox"
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.Transparency = 1
	box.Size = Vector3.new(1, 1, 1)
	box.Parent = workspace

	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Adornee = box
	selectionBox.Color3 = CONFIG.DEBUG_BOX_COLOR
	selectionBox.LineThickness = 0.05
	selectionBox.Transparency = 0
	selectionBox.SurfaceTransparency = 1
	selectionBox.Parent = box

	self.debugBox = box
end

function LockOnController:_DestroyDebugBox()
	if self.debugBox then
		self.debugBox:Destroy()
		self.debugBox = nil
	end
end

function LockOnController:_InitCameraPos(playerPos: Vector3, targetPos: Vector3)
	local flat = Vector3.new(playerPos.X - targetPos.X, 0, playerPos.Z - targetPos.Z)
	local awayDir
	if flat.Magnitude < 0.05 then
		awayDir = Vector3.new(0, 0, 1)
	else
		awayDir = flat.Unit
	end
	self.cameraPos = playerPos + awayDir * (CONFIG.INITIAL_CAMERA_DISTANCE - (playerPos - targetPos).Magnitude)
	if (self.cameraPos - playerPos).Magnitude < 5 then
		self.cameraPos = playerPos + awayDir * 5
	end
end

function LockOnController:_UpdateLockOnCamera(deltaTime: number)
	if not self.target then return end

	local camera = workspace.CurrentCamera
	local char = self.plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local targetHrp = self.target:FindFirstChild("HumanoidRootPart")
	if not hrp or not targetHrp then return end

	local playerPos = hrp.Position
	local targetPos = targetHrp.Position + Vector3.new(0, CONFIG.TARGET_HEIGHT_OFFSET, 0)

	if not self.cameraPos then
		self:_InitCameraPos(playerPos, targetPos)
	end

	local forwardDir = targetPos - self.cameraPos
	if forwardDir.Magnitude < 0.05 then return end
	forwardDir = forwardDir.Unit

	local rightCross = forwardDir:Cross(Vector3.yAxis)
	local rightDir
	if rightCross.Magnitude < 0.05 then
		rightDir = Vector3.xAxis
	else
		rightDir = rightCross.Unit
	end
	local upDir = rightDir:Cross(forwardDir).Unit

	local playerOffset = playerPos - self.cameraPos
	local localRight = playerOffset:Dot(rightDir)
	local localUp = playerOffset:Dot(upDir)
	local localForward = playerOffset:Dot(forwardDir)

	local shift = Vector3.zero

	if localRight > CONFIG.BOX_HALF_WIDTH then
		shift += rightDir * (localRight - CONFIG.BOX_HALF_WIDTH)
	elseif localRight < -CONFIG.BOX_HALF_WIDTH then
		shift += rightDir * (localRight + CONFIG.BOX_HALF_WIDTH)
	end

	if localUp > CONFIG.BOX_HALF_HEIGHT then
		shift += upDir * (localUp - CONFIG.BOX_HALF_HEIGHT)
	elseif localUp < -CONFIG.BOX_HALF_HEIGHT then
		shift += upDir * (localUp + CONFIG.BOX_HALF_HEIGHT)
	end

	if localForward > CONFIG.BOX_MAX_DEPTH then
		shift += forwardDir * (localForward - CONFIG.BOX_MAX_DEPTH)
	elseif localForward < CONFIG.BOX_MIN_DEPTH then
		shift += forwardDir * (localForward - CONFIG.BOX_MIN_DEPTH)
	end

	self.cameraPos += shift

	if self.debugBox then
		local boxCenterForward = (CONFIG.BOX_MIN_DEPTH + CONFIG.BOX_MAX_DEPTH) * 0.5
		local boxDepth = CONFIG.BOX_MAX_DEPTH - CONFIG.BOX_MIN_DEPTH
		local boxCenter = self.cameraPos + forwardDir * boxCenterForward
		self.debugBox.Size = Vector3.new(
			CONFIG.BOX_HALF_WIDTH * 2,
			CONFIG.BOX_HALF_HEIGHT * 2,
			boxDepth
		)
		self.debugBox.CFrame = CFrame.lookAt(boxCenter, boxCenter + forwardDir, upDir)
	end

	camera.CFrame = CFrame.lookAt(self.cameraPos, targetPos)
end

function LockOnController:_LockZoom()
	self.savedMinZoom = self.plr.CameraMinZoomDistance
	self.savedMaxZoom = self.plr.CameraMaxZoomDistance
	self.plr.CameraMinZoomDistance = CONFIG.INITIAL_CAMERA_DISTANCE
	self.plr.CameraMaxZoomDistance = CONFIG.INITIAL_CAMERA_DISTANCE
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
	self.cameraPos = nil

	local char = self.plr.Character
	char:SetAttribute("LockOn", true)

	local targetValue = Instance.new("ObjectValue")
	targetValue.Name = "LockOnTarget"
	targetValue.Value = target
	targetValue.Parent = char
	self.targetValueInstance = targetValue

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	self:_LockZoom()
	self:_CreateDebugBox()

	RunService:BindToRenderStep("LockOnCamera", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		self:_UpdateLockOnCamera(deltaTime)
	end)

	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	self.targetDiedConn = humanoid.Died:Connect(function()
		self:_Unlock()
	end)
end

function LockOnController:_Unlock()
	RunService:UnbindFromRenderStep("LockOnCamera")

	self:_UnlockZoom()
	self:_DestroyDebugBox()
	self.cameraPos = nil

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
	self.targetValueInstance = nil
	self.savedMinZoom = nil
	self.savedMaxZoom = nil
	self.cameraPos = nil
	self.debugBox = nil

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