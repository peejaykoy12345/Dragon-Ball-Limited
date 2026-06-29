return {
    M1 = {
        Cooldown = 1.5,
        KnockbackPower = 50,
        KnockbackDuration = 2,
        HitboxWeldOffsetCFrame = CFrame.new(0, 0, -3),
        BlockParams = {
            Blockable = true,
            BlockDamage = 20
        },
        ComboTimings = {
            {
                Damage = 4,
                HitboxSize = Vector3.new(6, 5, 8),
                UserStunDuration = 0.25, 
                TargetStunDuration = 0.6
            },
            {
                Damage = 4, 
                TotalDuration = 0.3, 
                HitboxSize = Vector3.new(6.5, 5, 8), 
                UserStunDuration = 0.25, 
                TargetStunDuration = .6
            },
            {
                Damage = 5, 
                TotalDuration = 0.3, 
                HitboxSize = Vector3.new(6.5, 5, 8), 
                UserStunDuration = 0.25, 
                TargetStunDuration = .6
            },
            {
                Damage = 5, 
                TotalDuration = 0.3, 
                HitboxSize = Vector3.new(6.5, 5, 8), 
                UserStunDuration = 0.25, 
                TargetStunDuration = .6
            },
            { 
                Damage = 6, 
                TotalDuration = 0.3, 
                HitboxSize = Vector3.new(6.5, 5, 8), 
                UserStunDuration = 0.25, 
                TargetStunDuration = 1 
            },
            {
                Damage = 8, 
                TotalDuration = 1.0, 
                HitboxDelay = 0.5, 
                HitboxSize = Vector3.new(7, 5, 10), 
                UserStunDuration = .5, 
                TargetStunDuration = 1
            }
        }
    },
    Heavy = {
        Damage = 10,
        KnockbackPower = 80,
        Cooldown = 1.5,
        HitboxWeldOffsetCFrame = CFrame.new(0, 0, -3),
        BlockParams = {
            Blockable = true,
            BlockDamage = 100
        },
    }
}