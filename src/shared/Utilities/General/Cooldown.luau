local Cooldown = {}
Cooldown.Cooldowns = {}

function Cooldown:InitializeCharacter(char: Model)
    self.Cooldowns[char] = {}

    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    hum.Died:Connect(function()
        self.Cooldowns[char] = nil
    end)
end

function Cooldown:SetCooldown(char: Model, action: string, cooldown: number)
    if not self.Cooldowns[char] then
        self:InitializeCharacter(char)
    end

    if self.Cooldowns[char][action] then
        task.cancel(self.Cooldowns[char][action])
    end

    local thread = task.delay(cooldown, function()
        if not self.Cooldowns[char] then return end
        self.Cooldowns[char][action] = nil
    end)

    self.Cooldowns[char][action] = thread

    --[[local plr = Players:GetPlayerFromCharacter(char)
    if plr then
        Network.Character.packets.OnMoveCooldown.sendTo({
            MoveName = action,
            CooldownTime = cooldown,
            TimeOfSent = os.time(),
        }, plr)
    end]]
end

function Cooldown:CancelCooldown(char: Model, action: string)
    if not self.Cooldowns[char] then return end

    local thread = self.Cooldowns[char][action]
    if not thread then return end

    task.cancel(thread)
    self.Cooldowns[char][action] = nil
end

function Cooldown:IsOnCooldown(char: Model, action: string): boolean
    if not self.Cooldowns then
        return false
    end

    if not self.Cooldowns[char] then
        return false
    end

    return self.Cooldowns[char][action] ~= nil
end

return Cooldown