local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXUtils = require(ReplicatedStorage.Modules.Utilities.Media.VFXUtils)
local CameraShaker = require(ReplicatedStorage.Modules.Utilities.Media.CameraShaker)
local Rocks = require(ReplicatedStorage.Modules.Utilities.Media.Rocks)

local module = {}

function module:CameraShake(Pos: Vector3?, Preset: string, parent: Instance)
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

function module:Start(args)
    local parent = args.parent
    local offset = args.offset
    local vfxCFrame = args.vfxCFrame
    local shake = args.shake
    local pos = args.position
    local rocks = args.rocks
    local deletionTime = args.deletionTime or 2
    local shouldWeld = args.shouldWeld
    local dontClone = args.dontClone
    local vfx

    if dontClone then
        vfx = args.vfx
    else
        vfx = args.vfx:Clone()
    end
    

    vfx.Parent = parent
    if vfx:IsA("BasePart") then
        if shouldWeld then
            vfx.CFrame = vfxCFrame or (offset and parent.CFrame * offset) or parent.CFrame

            local weld = Instance.new("Weld", parent)
            weld.Part0 = parent
            weld.Part1 = vfx

            if args.weldC1 then
                weld.C1 = args.weldC1
            end
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

            if args.weldC1 then
                weld.C1 = args.weldC1
            end
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

    VFXUtils.Emit(vfx)

    Debris:AddItem(vfx, deletionTime)
end

return module