local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local KnockbackAnimations = Assets.Animations.Default.HitReactions.Knockback

local Modules = ReplicatedStorage.Modules
local WCS = require(Modules.Packages.WCS)

local StateManager = require(ReplicatedStorage.Modules.Utilities.General.StateManager)
local Animation = require(ReplicatedStorage.Modules.Utilities.Media.Animation)

local AutoRotateEffect = require(ReplicatedStorage.Modules.WCS.StatusEffects.AutoRotate)

local Velocity = {}

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

function Velocity:ApplyKnockback(attacker: Model, target: Model, knockback: number, duration: number)
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