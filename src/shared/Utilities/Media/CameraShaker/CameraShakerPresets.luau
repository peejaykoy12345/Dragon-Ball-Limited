-- Camera Shake Presets
-- Stephen Leitnick
-- February 26, 2018

--[[
	
	CameraShakePresets.Bump
	CameraShakePresets.Explosion
	CameraShakePresets.Earthquake
	CameraShakePresets.BadTrip
	CameraShakePresets.HandheldCamera
	CameraShakePresets.Vibration
	CameraShakePresets.RoughDriving
	
--]]



local CameraShakeInstance = require(script.Parent.CameraShakerInstance)

local CameraShakePresets = {
	DashHit = function()
		local c = CameraShakeInstance.new(8, 20, 0, 0.3)
		c.PositionInfluence = Vector3.new(0.1,0.1,0.1)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end,
	DownSlam = function()
		local c = CameraShakeInstance.new(30, 15, 0, 0.5)
		c.PositionInfluence = Vector3.new(0.15,0.15,0.15)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end,
	Vibrate = function()
		local c = CameraShakeInstance.new(3, 21, 0.1, 1)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Small = function()
		local c = CameraShakeInstance.new(4, 21, 0.1, 0.5)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	SmallQuick = function()
		local c = CameraShakeInstance.new(4, 21, 0.1, 0.1)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	SmallMedium = function()
		local c = CameraShakeInstance.new(6, 24, 0.1, 0.3)
		c.PositionInfluence = Vector3.new(0.13, 0.13,0.13)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Slam = function()
		local c = CameraShakeInstance.new(2.5, 21, 0.1, 0.2)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Hit = function()
		local c = CameraShakeInstance.new(1.1, 25, 0.1, 0.2)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Tiny = function()
		local c = CameraShakeInstance.new(2, 15, 0.1, 0.3)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	VeryTiny = function()
		local c = CameraShakeInstance.new(1, 10, 0.1, 0.2)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	SuperTiny = function()
		local c = CameraShakeInstance.new(0.5, 10, 0.1, 0.2)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Medium = function()
		local c = CameraShakeInstance.new(8, 21, 0.1, 0.8)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Large = function()
		local c = CameraShakeInstance.new(9, 25, 0.1, 0.8)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end,
	MediumShorter = function()
		local c = CameraShakeInstance.new(7, 17, 0.1, 0.7)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	Bump = function()
		local c = CameraShakeInstance.new(2.5, 4, 0.1, 0.75)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end;
	Explosion = function()
		local c = CameraShakeInstance.new(5, 10, 0, 1.5)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end;
	-- A continuous, rough shake
	-- Sustained.
	Earthquake = function()
		local c = CameraShakeInstance.new(0.6, 3.5, 2, 10)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(1, 1, 4)
		return c
	end;

	-- A bizarre shake with a very high magnitude and low roughness.
	-- Sustained.
	BadTrip = function()
		local c = CameraShakeInstance.new(10, 0.15, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0.15)
		c.RotationInfluence = Vector3.new(2, 1, 4)
		return c
	end;
	-- A subtle, slow shake.
	-- Sustained.
	HandheldCamera = function()
		local c = CameraShakeInstance.new(1, 0.25, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 0.5, 0.5)
		return c
	end;


	-- A very rough, yet low magnitude shake.
	-- Sustained.
	Vibration = function()
		local c = CameraShakeInstance.new(0.4, 20, 2, 2)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end;


	-- A slightly rough, medium magnitude shake.
	-- Sustained.
	RoughDriving = function()
		local c = CameraShakeInstance.new(1, 2, 1, 1)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end;

	SlamHit = function()
		local c = CameraShakeInstance.new(6, 8, 0, 1)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end;

	HeavyHit = function()
		local c = CameraShakeInstance.new(3, 6, 0, 0.9)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(3.5, 1, 1)
		return c
	end;
	
	TinyLoop = function()
		local c = CameraShakeInstance.new(2, 15, 1, 1)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
	
	MediumLoop = function()
		local c = CameraShakeInstance.new(8, 21, 1, 1)
		c.PositionInfluence = Vector3.new(0.8, 0.8,0.8)
		c.RotationInfluence = Vector3.new(0,0,0)
		return c
	end;
}


return setmetatable({}, {
	__index = function(t, i)
		local f = CameraShakePresets[i]
		if (type(f) == "function") then
			return f()
		end
		error("No preset found with index \"" .. i .. "\"")
	end;
})