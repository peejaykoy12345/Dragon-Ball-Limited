local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MediaUtilities = ReplicatedStorage.Modules.Utilities.Media

local VFXUtils = require(MediaUtilities.VFXUtils)
local CameraShaker = require(MediaUtilities.CameraShaker)
local Rocks = require(MediaUtilities.Rocks)

local Effect = {}

function Effect:CameraShake(Pos: Vector3?, Preset: string, parent: Instance)
    local MaxDistance = 100
	local Character = game.Players.LocalPlayer.Character
	if typeof(parent) == "Instance" and Pos then
        local distance = (Character.PrimaryPart.Position - Pos).Magnitude
	    if distance > MaxDistance then return end
    end

	local Camera = workspace.CurrentCamera

	local camShake = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCf)
		if shakeCf then
			Camera.CFrame *= shakeCf
		else
			warn("shakeCf is nil")
		end
	end)

	camShake:Start()
	camShake:Shake(CameraShaker.Presets[Preset])
end

function Effect:Construct(args)
    self.parent = args.parent
    self.vfx = args.vfx:Clone()
    self.offset = args.offset
    self.vfxCFrame = args.vfxCFrame
    self.shake = args.shake
    self.pos = args.position
    self.rocks = args.rocks
    self.deletionTime = args.deletionTime or 2
    self.shouldWeld = args.shouldWeld
    self.weldC1 = args.weldC1

	self.DestroyOnEnd = false
	self.DestroyOnLifecycleEnd = false
	self.MaxLifetime = 15
end

function Effect:Start()
    local parent = self.parent
    local vfx = self.vfx
    local offset = self.offset
    local vfxCFrame = self.vfxCFrame
    local shake = self.shake
    local pos = self.pos
    local rocks = self.rocks
    local deletionTime = self.deletionTime
    local shouldWeld = self.shouldWeld

    vfx.Parent = parent
    if vfx:IsA("BasePart") then
        if shouldWeld then
            vfx.CFrame = vfxCFrame or (offset and parent.CFrame * offset) or parent.CFrame

            local weld = Instance.new("Weld", parent)
            weld.Part0 = parent
            weld.Part1 = vfx
            self.weld = weld
        else
            if vfxCFrame then
                vfx.CFrame = vfxCFrame
            elseif offset then
                vfx.CFrame = parent.CFrame * offset
            end
        end
    elseif vfx:IsA("Model") then
        if shouldWeld then
            local primaryPart = vfx.PrimaryPart
            if not primaryPart then
                warn(`VFX {vfx.Name} shouldWeld is true but no primary part is set!`)
                return
            end

            local targetCFrame = vfxCFrame or (offset and parent.CFrame * offset) or parent.CFrame
            vfx:PivotTo(targetCFrame)

            local weld = Instance.new("Weld", vfx)
            weld.Part0 = parent
            weld.Part1 = primaryPart

            if self.weldC1 then
                weld.C1 = self.weldC1
            end
            self.weld = weld
        else
            local targetCFrame
            if vfxCFrame then
                targetCFrame = vfxCFrame
            elseif offset then
                targetCFrame = parent.CFrame * offset
            end

            vfx:PivotTo(targetCFrame)
        end
    end

    if shake then
        self:CameraShake(pos, shake, parent)
    end

    if rocks then
        if vfx:IsA("BasePart") then
            Rocks.Explosion(vfx.CFrame)
        elseif vfx:IsA("Model") then
            if vfx.PrimaryPart then
                Rocks.Explosion(vfx.PrimaryPart.CFrame)
            else
                Rocks.Explosion(vfx:GetPivot())
            end
        else
            warn(`VFX: {vfx.Name} is not a basepart or a model`)
        end
    end

    VFXUtils.ToggleParticleEmitters(vfx, true)

    Debris:AddItem(vfx, deletionTime)
end

function Effect:OnDestroy()
    if self.vfx then
        VFXUtils.ToggleParticleEmitters(self.vfx, false)
        self.vfx:Destroy()
    end

    if self.weld then
        self.weld:Destroy()
        self.weld = nil
    end
end

return Effect