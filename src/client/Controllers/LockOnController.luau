local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local LockOnUI: BillboardGui = ReplicatedStorage.Assets.UI.BillboardUI.LockOn

local LockOnController = {}

local CONFIG = {
	MAX_DISTANCE = 500,
	INITIAL_CAMERA_DISTANCE = 18,
	LOCK_ON_OFFSET = Vector3.new(15, 0, 0),
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

function LockOnController:_UpdateLockOnCamera(deltaTime: number)
	if not self.target then return end

	local camera = workspace.CurrentCamera
	local targetHrp = self.target:FindFirstChild("HumanoidRootPart")
	if not targetHrp then return end

	local lookAtPosition = targetHrp.CFrame:PointToWorldSpace(CONFIG.LOCK_ON_OFFSET)

	local camPos = camera.CFrame.Position
	camera.CFrame = CFrame.new(camPos, lookAtPosition)

	self.cameraPos = camPos
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