local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StateManager = require(ReplicatedStorage.Modules.Utilities.General.StateManager)

local Utils = {}
local Multipliers: {[Model]: (number) -> number} = {}

function Utils:ValidateAndDamage(attacker: Model, target: Model, damage: number)
	if attacker == target then return end
	if not target:FindFirstChild("Humanoid") then return end

	if Multipliers[attacker] then
		damage = Multipliers[attacker](damage)
	end

	local humanoid = target:FindFirstChild("Humanoid") :: Humanoid
	humanoid:TakeDamage(damage)

	if StateManager.HasState(target, "Down") or StateManager.HasState(target, "Gripped") then
		humanoid.Health = math.max(humanoid.Health, 1)
	end
end

function Utils:AddDamageMultiplier(char: Model, multiplier: number, duration: number)
	Multipliers[char] = function(damage)
		return damage * multiplier
	end

	local conn: RBXScriptConnection?

	local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		conn = humanoid.Died:Connect(function()
			Multipliers[char] = nil
			if conn then conn:Disconnect() end
		end)
	end

	task.delay(duration, function()
		Multipliers[char] = nil
		if conn then conn:Disconnect() end
	end)
end

return Utils