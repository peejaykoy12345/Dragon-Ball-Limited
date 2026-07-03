local ByteNetMax = require(script.ByteNetMax)

return {
	General = ByteNetMax.defineNamespace("General", function()
		return {
			packets = {
				Notification = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Message = ByteNetMax.string,
					})
				}),
			},
			queries = {},
		}
	end),
	Input = ByteNetMax.defineNamespace("Input", function()
		return {
			packets = {
				InputStarted = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Input = ByteNetMax.string,
					})
				}),
				InputEnded = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Input = ByteNetMax.string,
					})
				}),
			},
			queries = {},
		}
	end),
	Skill = ByteNetMax.defineNamespace("Skill", function()
		return {
			packets = {
				SendTarget = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.string,
						Target = ByteNetMax.inst,
					})
				}),
				SendCFrame = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.string,
						CFrame = ByteNetMax.cframe,
					})
				})
			},
			queries = {},
		}
	end),
	Fly = ByteNetMax.defineNamespace("Fly", function()
		return {
			packets = {
				FlyVelocityOverride = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.optional(ByteNetMax.string),
						Velocity = ByteNetMax.vec3,
						Duration = ByteNetMax.float32,
						Type = ByteNetMax.string,
						MaxForce = ByteNetMax.optional(ByteNetMax.vec3),
					})
				}),
				StopFlyVelocityOverride = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.optional(ByteNetMax.string),
					})
				})
			},
			queries = {
				RequestToggleFastFly = ByteNetMax.defineQuery({
					request = ByteNetMax.struct({
						Status = ByteNetMax.bool,	
					}),
					response = ByteNetMax.bool,
				})
			},
		}
	end),
	Replication = ByteNetMax.defineNamespace("Replication", function()
		return {
			packets = {
				Initialize = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.string,
					})
				}),
				Update = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						Name = ByteNetMax.string,
						Args = ByteNetMax.optional(ByteNetMax.struct({
							Type = ByteNetMax.optional(ByteNetMax.string),
							Action = ByteNetMax.optional(ByteNetMax.string),
						})),
						Value = ByteNetMax.struct({
							string = ByteNetMax.optional(ByteNetMax.string),
							uint8 = ByteNetMax.optional(ByteNetMax.uint8),
							uint16 = ByteNetMax.optional(ByteNetMax.uint16),
							uint32 = ByteNetMax.optional(ByteNetMax.uint32),
							arrayofstrings = ByteNetMax.optional(ByteNetMax.array(ByteNetMax.string)),
							custom = ByteNetMax.optional(ByteNetMax.unknown),
						}),
					})
				}),
				UnreliableUpdate = ByteNetMax.definePacket({
					reliabilityType = "unreliable",
					value = ByteNetMax.struct({
						Name = ByteNetMax.string,
						Args = ByteNetMax.optional(ByteNetMax.struct({
							Type = ByteNetMax.optional(ByteNetMax.string),
							Action = ByteNetMax.optional(ByteNetMax.string),
						})),
						Value = ByteNetMax.struct({
							string = ByteNetMax.optional(ByteNetMax.string),
							uint8 = ByteNetMax.optional(ByteNetMax.uint8),
							uint16 = ByteNetMax.optional(ByteNetMax.uint16),
							uint32 = ByteNetMax.optional(ByteNetMax.uint32),
							custom = ByteNetMax.optional(ByteNetMax.unknown),
						}),
					})
				}),
			},
			queries = {},
		}
	end),
	SFX = ByteNetMax.defineNamespace("SFX", function()
		return {
			packets = {
				PlaySFX = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						handleId = ByteNetMax.string,
						Parent = ByteNetMax.inst,
						SoundId = ByteNetMax.optional(ByteNetMax.float64),
						SoundInstance = ByteNetMax.optional(ByteNetMax.inst),
					})
				}),
				StopSFX = ByteNetMax.definePacket({
					value = ByteNetMax.struct({
						handleId = ByteNetMax.string,
					})
				}),
			},
			queries = {},
		}
	end),
	VFX = ByteNetMax.defineNamespace("VFX", function()
		return {
			packets = {
				ClientFXPacket = ByteNetMax.definePacket({
					reliabilityType = "unreliable",
					value = ByteNetMax.struct({
						action = ByteNetMax.string,
						handleId = ByteNetMax.optional(ByteNetMax.string),
						fxData = ByteNetMax.optional(ByteNetMax.struct({
							Name = ByteNetMax.string,
							Type = ByteNetMax.string,
						})),
						args = ByteNetMax.struct({
							parent = ByteNetMax.optional(ByteNetMax.inst), -- Who to set to
                            weldPart = ByteNetMax.optional(ByteNetMax.inst),
                            vfx = ByteNetMax.optional(ByteNetMax.inst), -- Use for instances (particles, etc)
                            vfxName = ByteNetMax.optional(ByteNetMax.string), -- Use for highlight
                            vfxCFrame = ByteNetMax.optional(ByteNetMax.cframe),
                            deletionTime = ByteNetMax.optional(ByteNetMax.uint8), 
                            offset = ByteNetMax.optional(ByteNetMax.cframe),
                            position = ByteNetMax.optional(ByteNetMax.vec3),
                            isBeam = ByteNetMax.optional(ByteNetMax.bool),
                            shouldWeld = ByteNetMax.optional(ByteNetMax.bool),
                            weldC1 = ByteNetMax.optional(ByteNetMax.cframe),
                            caster = ByteNetMax.optional(ByteNetMax.inst),
                            target = ByteNetMax.optional(ByteNetMax.inst),
                            timeBetweenAfterimage = ByteNetMax.optional(ByteNetMax.float32),
                            afterimageDuration = ByteNetMax.optional(ByteNetMax.float32),
                            tween = ByteNetMax.optional(ByteNetMax.struct({
                                target = ByteNetMax.struct({
                                    CFrame = ByteNetMax.optional(ByteNetMax.cframe),
                                }),
                                duration = ByteNetMax.uint16,
                            }))
						})
					}),
				}),
			},
			queries = {},
		}
	end),
}