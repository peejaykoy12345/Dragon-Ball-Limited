local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local Assets = ReplicatedStorage.Assets
local KnockbackAnimations = Assets.Animations.Default.HitReactions.Knockback

local Modules = ReplicatedStorage.Modules
local WCS = require(Modules.Packages.WCS)

local StateManager = require(ReplicatedStorage.Modules.Utilities.General.StateManager)
local Animation = require(ReplicatedStorage.Modules.Utilities.Media.Animation)

local Network = require(ReplicatedStorage.Modules.Network)
local FlyVelocityOverride = Network.Fly.packets.FlyVelocityOverride

local AutoRotateEffect = require(ReplicatedStorage.Modules.WCS.StatusEffects.AutoRotate)

local Velocity = {}

type PhysicsOverrideParams = {
	Target: Model,
	Type: string,
	Duration: number,
	Velocity: Vector3,
	MaxForce: Vector3,
}


function Velocity.ApplyVelocityPhysicsOverride(params: PhysicsOverrideParams)
    local target = params.Target
    local hrp = target:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local player = Players:GetPlayerFromCharacter(target)

    if player then
        FlyVelocityOverride.sendTo({
            Velocity = params.Velocity,
            Duration = params.Duration,
            Type = params.Type,
            MaxForce = params.MaxForce,
        }, player)
        return
    end

    if params.Type == "LinearVelocity" then
		if target.Name == "FlyRig" then
			target:SetAttribute("FlyVelocityOverride", params.Velocity)
			task.delay(params.Duration, function()
				if target:GetAttribute("FlyVelocityOverride") == params.Velocity then
					target:SetAttribute("FlyVelocityOverride", nil)
				end
			end)
			return
		end
        Velocity.CreateLV(hrp, {
            Velocity = params.Velocity,
            MaxForce = if params.MaxForce then params.MaxForce.Magnitude else nil,
            Lifetime = params.Duration,
        })
    elseif params.Type == "BodyVelocity" then
        Velocity.CreateBodyVelocity(hrp, {
            Velocity = params.Velocity,
            MaxForce = params.MaxForce,
            Lifetime = params.Duration,
        })
    end
end

function Velocity.CreateBV(parent: Instance, MaxForce: Vector3)
    local bv = Instance.new("BodyVelocity")
	bv.MaxForce = MaxForce or bv.MaxForce
	bv.Parent = parent
	return bv
end

type BodyVelocityParams = {
	Velocity: Vector3,
	Attachment: Attachment?,
	MaxForce: Vector3?,
	Lifetime: number?,
}

function Velocity.CreateBodyVelocity(parent: Instance, params: BodyVelocityParams): BodyVelocity
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = params.MaxForce or Vector3.new(9999999, 9999999, 99999999)
	bv.Velocity = params.Velocity or Vector3.new(0, 0, 0)
	bv.Parent = parent

	local lifetime = params.Lifetime
	if lifetime then
		task.delay(lifetime, function()
			bv:Destroy()
		end)
	end

	return bv
end

type LinearVelocityParams = {
	Velocity: Vector3,
	Attachment: Attachment?,
	MaxForce: number?,
	Lifetime: number?,
	Name: string?,
	RelativeTo: "World" | "Attachment"?,
}

function Velocity.ParentAndCreateAttachment(parent: Instance)
	local att = Instance.new("Attachment", parent)
	return att
end

function Velocity.CreateLV(parent: Instance, params: LinearVelocityParams)
	local att = Velocity.ParentAndCreateAttachment(parent)

	local lv = Instance.new("LinearVelocity")
	lv.MaxForce = params.MaxForce or math.huge
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.RelativeTo = if params.RelativeTo == "World" then Enum.ActuatorRelativeTo.World elseif params.RelativeTo == "Attachment" then Enum.ActuatorRelativeTo.Attachment0 else Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = params.Velocity
	lv.Attachment0 = params.Attachment or att
	lv.Name = params.Name or "LinearVelocity"
	lv.Parent = parent

	local lifetime = params.Lifetime
	if lifetime then
		task.delay(lifetime, function()
			lv:Destroy()
			att:Destroy()
		end)
	end

	return lv, att
end

function Velocity:ApplyKnockback(attacker: Model, target: Model, knockback: number | Vector3, duration: number)
	local ehrp = target:FindFirstChild("HumanoidRootPart") :: BasePart
	local hrp = attacker:FindFirstChild("HumanoidRootPart") :: BasePart

	local WCS_Target = WCS.Character.GetCharacterFromInstance(target)
	if not ehrp or not hrp then
		warn("Missing HumanoidRootPart on Caster or Target")
		return
	end

	local AutoRotate = AutoRotateEffect.new(WCS_Target, false)
	AutoRotate:Start(duration)

	local direction = hrp.CFrame.LookVector
	local lookAtPosition = hrp.Position
	local targetPosition = ehrp.Position
	local lookDirection = (lookAtPosition - targetPosition).Unit
	local newCFrame = CFrame.new(targetPosition, targetPosition + Vector3.new(lookDirection.X, 0, lookDirection.Z))
	ehrp.CFrame = newCFrame

	local linearVelocity = Velocity.CreateLV(ehrp, {Velocity = direction * knockback})

	local anim = Animation:Play(target, KnockbackAnimations.Start, {Priority = 1})
	task.delay(anim.Length, function()
		anim = Animation:Play(target, KnockbackAnimations.Loop, {Priority = 1})
	end)

	StateManager.SetState(target, "Knockback", true)

	task.delay(duration, function()
		if anim then
			anim:Stop()
		end

		StateManager.RemoveState(target, "Knockback")

		Animation:Play(target, KnockbackAnimations.End, {Priority = 1})
		
		if linearVelocity then
			linearVelocity:Destroy()
		end
	end)
end

function Velocity.ApplySlamdown(attacker: Model, target: Model, params: {
	Knockback: number?,
	Duration: number?,
	OnLand: (() -> ())?,
})
	local ehrp = target:FindFirstChild("HumanoidRootPart") :: BasePart
	local hrp = attacker:FindFirstChild("HumanoidRootPart") :: BasePart

	local WCS_Target = WCS.Character.GetCharacterFromInstance(target)
	if not ehrp or not hrp then
		warn("Missing HumanoidRootPart on Caster or Target")
		return
	end

	local knockback = params.Knockback or 80
	local duration = params.Duration or 0.6

	local direction = (hrp.Position - ehrp.Position)
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	local slamVector = (direction * knockback) + (Vector3.new(0, -1, 0) * knockback * 1.5)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {target, attacker}

	local rayDirection = slamVector.Unit * slamVector.Magnitude

	local initialResult = workspace:Raycast(ehrp.Position + Vector3.new(0, -2.5, 0), rayDirection * (1 / 60), rayParams)
	if initialResult then
		print("LANDED")
		if params.OnLand then
			params.OnLand()
		end
		return
	end

	local AutoRotate = AutoRotateEffect.new(WCS_Target, false)
	AutoRotate:Start(duration)

	local lookDirection = (hrp.Position - ehrp.Position)
	lookDirection = Vector3.new(lookDirection.X, 0, lookDirection.Z).Unit
	ehrp.CFrame = CFrame.new(ehrp.Position, ehrp.Position + lookDirection)

	local linearVelocity = Velocity.CreateLV(ehrp, {
		Velocity = slamVector,
		Lifetime = duration,
	})

	local anim = Animation:Play(target, KnockbackAnimations.Start, {Priority = 1})
	task.delay(anim.Length, function()
		anim = Animation:Play(target, KnockbackAnimations.Loop, {Priority = 1})
	end)

	StateManager.SetState(target, "Knockback", true)

	local cleanedUp = false
	local heartbeatConnection

	local function cleanup()
		if cleanedUp then
			return
		end
		cleanedUp = true

		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end

		if linearVelocity then
			linearVelocity:Destroy()
		end

		if anim then
			anim:Stop()
		end

		StateManager.RemoveState(target, "Knockback")
		Animation:Play(target, KnockbackAnimations.End, {Priority = 1})

		if params.OnLand then
			params.OnLand()
		end
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if not ehrp or not ehrp.Parent then
			cleanup()
			return
		end

		local origin = ehrp.Position
		local result = workspace:Raycast(origin, rayDirection * dt, rayParams)

		if not result then
			result = workspace:Raycast(origin, Vector3.new(0, -3, 0), rayParams)
		end

		if result then
			cleanup()
		end
	end)
	
	task.delay(duration + 2, function()
		cleanup()
	end)
end

function Velocity:KnockbackToDirection(Target: Model | BasePart, Direction: Vector3, Knockback: number, Duration: number)
	local rootpart = Target:IsA("Model") and Target:FindFirstChild("HumanoidRootPart") or Target
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Velocity = Direction * Knockback
	bodyVelocity.P = 1250
	bodyVelocity.Parent = rootpart
	Debris:AddItem(bodyVelocity, Duration)
end

return Velocity