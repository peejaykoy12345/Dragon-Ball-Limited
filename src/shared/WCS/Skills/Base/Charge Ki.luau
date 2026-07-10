local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations
local VFX = Assets.VFX

local ChargeAnimations = Animations.Default.Charge
local ChargeVFX = VFX.General.Charge

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities
local GeneralUtilities = Utilities.General
local MediaUtilities = Utilities.Media

local MoveUtils = require(GeneralUtilities.MoveUtils)
local ActionSession = require(GeneralUtilities.ActionSession)

local Animation = require(MediaUtilities.Animation)
local ClientFX = require(MediaUtilities.ClientFX)

local Config = require(script.Parent.Config)

local WCS = require(Modules.Packages.WCS)

local ASSETS = {
	ANIMATIONS = {
		START = ChargeAnimations.Start,
		LOOP = ChargeAnimations.Loop,
		END = ChargeAnimations.End,
	},
	VFX = {
		LOOP = ChargeVFX.ChargeLoop,
		END = ChargeVFX.ChargeEnd,
	}
}

local Skill = WCS.RegisterHoldableSkill("Charge Ki")

function Skill:CanStart(char: Model)
	return MoveUtils:CanPerformAction(char, script.Name)
end

function Skill:OnStartServer(_, buffered)
	local char = self.Character.Instance
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return end

	local session = ActionSession.new({
		attacker = char,
		actionName = "Charge Ki",
		actionType = "Default",
		states = {
			attackerStates = { "ChargingKi" },
		},
	})
	session:Start()

	self._session = session

	local startTrack = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.START)
	self._currentTrack = startTrack
	startTrack.Stopped:Once(function()
		if not self.charge then return end
		local loopTrack = session:PlayAndAddAnimation(char, ASSETS.ANIMATIONS.LOOP)
		self._currentTrack = loopTrack
	end)

	self._loopHandleId = ClientFX:Construct(
		{
			Name = "ToggleParticles",
			Type = "General",
		},
		{
			parent = hrp,
			vfx = ASSETS.VFX.LOOP,
			vfxCFrame = hrp.CFrame,
			shouldWeld = true,
			deletionTime = 999,
			position = hrp.Position,
		}
	)
	ClientFX:Start(self._loopHandleId)

	self.charge = true

	task.spawn(function()
		while self.charge do
			local PlayerStatsService = require(ServerScriptService.Services.PlayerStatsService)
			local maxValue = PlayerStatsService:GetMaxValue(self.Character.Player, "Ki")
			PlayerStatsService:IncrementStat(self.Character.Player, "Ki", maxValue * Config["Charge Ki"].ChargeRate)

			print("Maxvalue: ", maxValue)
			print(PlayerStatsService:GetStat(self.Character.Player, "Ki"))
			task.wait(Config["Charge Ki"].ChargeInterval)
		end
	end)

    session:ApplyCastEffect({Speed = 0})

    session.extraStopFunction = function(_, forceStopped)
        if forceStopped then
            self.charge = nil

            if self._loopHandleId then
                ClientFX:Destroy(self._loopHandleId)
                self._loopHandleId = nil
            end

            self._currentTrack = nil
            self._session = nil

            self.forceStopped = true

            self:End()
        end
    end
end

function Skill:OnEndServer()
	local char = self.Character.Instance

	self.charge = nil

	if self._session then
		if self._currentTrack then
			self._session:StopAnimation(self._currentTrack)
			self._currentTrack = nil
		end
		self._session:Stop()
		self._session = nil
	end

	if self._loopHandleId then
		ClientFX:Destroy(self._loopHandleId)
	end

    if not self.forceStopped then
        Animation:Play(char, ASSETS.ANIMATIONS.END)
    end

	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not hrp then return end

	ClientFX:RenderToClient(
		{
			Name = "EmitParticles",
			Type = "General",
		},
		{
			parent = hrp,
			vfx = ASSETS.VFX.END,
			vfxCFrame = hrp.CFrame,
			position = hrp.Position
		}
	)
end

return Skill