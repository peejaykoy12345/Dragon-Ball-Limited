local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local SaiyanM1Anims = Assets.Animations.Characters.Saiyan.M1

local Modules = ReplicatedStorage.Modules
local BufferInput = require(Modules.Utilities.General.BufferInput)
local WCS = require(Modules.Packages.WCS)

local M1_BASE = require(ReplicatedStorage.Modules.Templates.Combat.M1)

local M1 = setmetatable({}, M1_BASE)
M1.Anims = SaiyanM1Anims:GetChildren()

local Skill = WCS.RegisterHoldableSkill("Saiyan M1")

function Skill:CanStart(char: Model)
    return M1:CanStart(char)
end

function Skill:OnStartServer(info, buffered)
    self._active = true

    task.spawn(function()
        while self._active do
            if not self._isNotAllowed then
                M1:M1(self.Character, info)
            end
            task.wait(0.1)
        end
    end)
end

function Skill:OnEndServer()
    self._active = false

    if M1.IsRunning then
        local before = os.time()
        M1.Finished.Event:Wait()
        local current = os.time()

        if current - before > 2 then return end

        local plr = self.Character.Player
        if plr then
            BufferInput.TryConsumeBuffer(plr)
        end
    else
        local plr = self.Character.Player
        if plr then
            BufferInput.TryConsumeBuffer(plr)
        end
    end
end

return Skill