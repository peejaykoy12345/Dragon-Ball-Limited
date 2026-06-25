local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFXFolder = ReplicatedStorage.Assets.Sounds

local SoundPlayer = {}

function SoundPlayer:ReturnToCache(soundId: number, sound: Sound)
    sound:Stop()
    sound.Parent = SFXFolder
    sound.Name = tostring(soundId)
end

function SoundPlayer:Play(soundId: number, parent: Instance)
    local sound = self:LoadSound(soundId, parent)

    local returned = false

    local function onSoundFinished()
        if returned then return end  
        returned = true
        self:ReturnToCache(soundId, sound)
    end

    sound.Ended:Once(onSoundFinished)
    sound.Stopped:Once(onSoundFinished)

    sound:Play()
end

function SoundPlayer:LoadSound(soundId: number, parent: Instance)
    local cached = SFXFolder:FindFirstChild(tostring(soundId))
    if cached and not cached.Playing then
        cached.Parent = parent
        return cached
    end

    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Name = tostring(soundId)
    sound.Parent = parent

    return sound
end

return SoundPlayer