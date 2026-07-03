local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage.Modules
local StateManager = require(Modules.Utilities.General.StateManager)

local flyNpc = workspace.LivingBeings.FlyRig

local CONFIG = {
	HOVER_HEIGHT_VARIANCE = 0,
	BOB_SPEED = 0,
	ALIGN_RESPONSIVENESS = 30,
}

local hrp = flyNpc:WaitForChild("HumanoidRootPart")
local hum = flyNpc:WaitForChild("Humanoid")

hum.PlatformStand = true

StateManager.InitializeModel(flyNpc)

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

RunService.Heartbeat:Connect(function()
	if not hrp.Parent then return end

	local forceFacing = flyNpc:GetAttribute("ForceFacingPosition")
	if forceFacing then
		local toTarget = forceFacing - hrp.Position
		if toTarget.Magnitude > 0.05 then
			alignOrientation.CFrame = CFrame.new(Vector3.zero, toTarget.Unit)
		end
	end

	local overrideVelocity = flyNpc:GetAttribute("FlyVelocityOverride")
	if overrideVelocity then
		linearVelocity.VectorVelocity = overrideVelocity
		return
	end

	if StateManager.isActionBlocked(flyNpc) then
		linearVelocity.VectorVelocity = Vector3.zero
		return
	end

	linearVelocity.VectorVelocity = Vector3.zero
end)