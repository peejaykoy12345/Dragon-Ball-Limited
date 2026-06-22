local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeVFX = require(ReplicatedStorage.Modules.Packages.ForgeVFX)

local Utils = {}

function Utils.Tween(object, goal, Time, loopstime, reverse)
	Time = Time or 1
	local Ti = TweenInfo.new(
		Time,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.In,
		loopstime or 0,
		reverse or false
	)
	goal = goal or {}
	local t = TweenService:Create(object, Ti, goal)
	t:Play()
	return t
end

function Utils.Emit(part: BasePart | Attachment)
	ForgeVFX.emit(part)
	--[[for _, instance in ipairs(part:GetDescendants()) do
		if not (instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Sound")) then continue end

		task.spawn(function()
			if not instance.Parent then return end

			local delay = instance:GetAttribute("EmitDelay") or 0
			local duration = instance:GetAttribute("EmitDuration")

			if delay > 0 then
				task.wait(delay)
			end

			if not instance.Parent then return end

			if instance:IsA("Sound") then
				instance:Play()

			elseif instance:IsA("ParticleEmitter") then
				local count = instance:GetAttribute("EmitCount")
				if duration and duration > 0 then
					instance.Enabled = true
					task.wait(duration)
					if instance.Parent then instance.Enabled = false end
				elseif count and count > 0 then
					instance:Emit(count)
				else
					instance:Emit(1)
				end

			elseif instance:IsA("Beam") then
				local beamClone = instance:Clone()
				beamClone.Parent = instance.Parent
				beamClone.Enabled = true

				task.wait(if duration and duration > 0 then duration else 0.03)

				if beamClone and beamClone.Parent then beamClone:Destroy() end
			end
		end)
	end]]
end

function Utils.ToggleParticleEmitters(part: BasePart | Attachment, status: boolean)
	if status then
		ForgeVFX.enable(part)
	else
		ForgeVFX.disable(part)
	end
end

return Utils