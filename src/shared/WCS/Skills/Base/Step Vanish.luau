local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local VFX = Assets.VFX

local ZVanishVFX = VFX.General.StepVanish

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local GeneralUtilities = Utilities.General
local MediaUtilities = Utilities.Media

local Config = require(script.Parent.Config)[script.Name]

local Network = require(Modules.Network)
local SendCFrame = Network.Skill.packets.SendCFrame

local StateManager = require(GeneralUtilities.StateManager)
local Velocity = require(GeneralUtilities.Velocity)
local Cooldown = require(GeneralUtilities.Cooldown)
local MoveUtils = require(GeneralUtilities.MoveUtils)

local ClientFX = require(MediaUtilities.ClientFX)

local WCS = require(Modules.Packages.WCS)

local Skill = WCS.RegisterSkill("Step Vanish")

function Skill:CanStart(char: Model)
	return not StateManager.HasState(char, "Vanish")
end

function Skill:OnStartClient()
	local plr = self.Character.Player
	local char = plr.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local playerModule = require(plr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	local moveVector = playerModule:GetControls():GetMoveVector()
	local forwardScalar, rightScalar = -moveVector.Z, moveVector.X

	local useLockOn = char:GetAttribute("LockOn") and char:FindFirstChild("LockOnTarget")
		and char:FindFirstChild("LockOnTarget"):IsA("ObjectValue")
		and char:FindFirstChild("LockOnTarget").Value ~= nil

	local isFlying = char:GetAttribute("Flying")
	local useHRP = useLockOn and isFlying

	local dir
	if forwardScalar ~= 0 or rightScalar ~= 0 then
		local look, right

		if useHRP then
			look = hrp.CFrame.LookVector
			right = hrp.CFrame.RightVector
		else
			look = workspace.CurrentCamera.CFrame.LookVector
			right = workspace.CurrentCamera.CFrame.RightVector
		end

		local direction = (look * forwardScalar) + (right * rightScalar)

		if direction.Magnitude > 1 then
			direction = direction.Unit
		end

		dir = direction
	else
		if useHRP then
			dir = hrp.CFrame.LookVector
		else
			dir = workspace.CurrentCamera.CFrame.LookVector
		end
	end

	SendCFrame.send({
		Name = "Step Vanish",
		CFrame = CFrame.new(Vector3.zero, dir),
	})
end

function Skill:OnStartServer(info, buffered)
	self.disconnect = SendCFrame.listen(function(data, plr)
		local char = self.Character.Instance
		if data.Name ~= "Step Vanish" or not char then return end

		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
		if not hrp then return end

		local hitboxPart = char:FindFirstChild("Hitbox") :: BasePart

		self.disconnect()
		self.disconnect = nil

		local dir = data.CFrame.LookVector

		ClientFX:RenderToClient(
			{
				Name = "EmitParticles",
				Type = "General",
			},
			{
				parent = hrp,
				shouldWeld = true,
				vfx = ZVanishVFX,
				vfxCFrame = hrp.CFrame,
				position = hrp.Position,
			}
		)

		MoveUtils:SetPartsProperties(char:GetDescendants(), "Transparency", 1, {hrp, hitboxPart})

		Velocity.ApplyVelocityPhysicsOverride({
			Name = "StepVanish",
			Target = char,
			Type = "LinearVelocity",
			Duration = Config.Duration,
			Velocity = dir * Config.Speed,
			MaxForce = Vector3.new(math.huge, math.huge, math.huge),
            ForceVelocity = true,
		})
        
        StateManager.SetState(char, "Vanish", true)
        StateManager.SetState(char, "IFrames", true)

		task.delay(Config.Duration, function()
            StateManager.RemoveState(char, "Vanish")
            StateManager.RemoveState(char, "IFrames")

            Cooldown:SetCooldown(char, script.Name, Config.Cooldown)
			MoveUtils:SetPartsProperties(char:GetDescendants(), "Transparency", 0, {hrp, hitboxPart})
		end)
	end)

	task.delay(2, function()
		if self.disconnect then
			self.disconnect()
			self.disconnect = nil
		end
	end)
end

return Skill