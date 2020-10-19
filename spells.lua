local addon, ns = ...

--[[ checked:
[ ] DEATHKNIGHT
[ ] DEMONHUNTER
[ ] DRUID
[ ] HUNTER
[ ] MAGE
[ ] MONK
[X] PALADIN
    Notes: have to check if the talent is active
[ ] PRIEST
[ ] ROGUE
[ ] SHAMAN
[ ] WARLOCK
[ ] WARRIOR
]]

ns.spells = {
	["DEATHKNIGHT"] = {
		-- Blood
		[250] = {
			-- Mind Freeze
			["kick"] = {
				["spellID"] = 47528,
			},
		},
		-- Frost
		[251] = {
			-- Mind Freeze
			["kick"] = {
				["spellID"] = 47528,
			},
		},
		-- Unholy
		[252] = {
			-- Mind Freeze
			["kick"] = {
				["spellID"] = 47528,
			},
		},
--		["stun"] = "",
--		["cc"] = "",
	},
	["DEMONHUNTER"] = {
		-- Havoc
		[577] = {
			-- Disrupt
			["kick"] = {
				["spellID"] = 183752,
			},
		},
		-- Vengeance
		[581] = {
			-- Disrupt
			["kick"] = {
				["spellID"] = 183752,
			},
		},
--		["stun"] = 179057, --chaos nova
--		["cc"] = 217832, --imprison
	},
	["DRUID"] = {
		-- Balance
		[102] = {
			-- Solar Beam
			["kick"] = {
				["spellID"] = 78675,
			},
		},
		-- Feral
		[103] = {
			-- Skull Bash
			["kick"] = {
				["spellID"] = 106839,
			},
		},
		-- Guardian
		[104] = {
			-- Skull Bash
			["kick"] = {
				["spellID"] = 106839,
			},
		},
		-- Restoration
		[105] = {
			["kick"] = {
				["spellID"] = nil,
			}
		},
--		["stun"] = "",
--		["cc"] = 339, -- entangling roots
	},
	["HUNTER"] = {
		-- Beast Mastery
		[253] = {
			-- Counter Shot
			["kick"] = {
				["spellID"] = 147362,
			}
		},
		-- Marksmanship
		[254] = {
			-- Counter Shot
			["kick"] = {
				["spellID"] = 147362,
			}
		},
		-- Survival
		[255] = {
			-- Muzzle
			["kick"] = {
				["spellID"] = 187707,
			}
		},
--		["stun"] = "",
--		["cc"] = 187650, --freezing trap
	},
	["MAGE"] = {
		-- Arcane
		[62] = {
			-- Counter Spell
			["kick"] = {
				["spellID"] = 2139,
			},
		},
		-- Fire
		[63] = {
			-- Counter Spell
			["kick"] = {
				["spellID"] = 2139,
			},
		},
		-- Frost
		[64] = {
			-- Counter Spell
			["kick"] = {
				["spellID"] = 2139,
			},
		},
--		["stun"] = "",
--		["cc"] = 118, --polymorph
	},
	["MONK"] = {
		-- Brewmaster
		[268] = {
			-- Spear Hand Strinke
			["kick"] = {
				["spellID"] = 116705,
			},
		},
		-- Windwalker
		[269] = {
			-- Spear Hand Strinke
			["kick"] = {
				["spellID"] = 116705,
			},
		},
		-- Mistweaver
		[270] = {
			["kick"] = {
				["spellID"] = nil,
			}
		},
--		["stun"] = 119381, --leg sweep
--		["cc"] = 115078, --paralysis
	},
	["PALADIN"] = {
		-- Holy
		[65] = {
			["kick"] = {
				["spellID"] = nil,
			},
			-- Hammer of Justice
			["stun"] = {
				["SpellID"] = 853,
			},
			-- Repentance
			["cc"] = {
				["spellID"] = 20066,
			},
		},
		-- Protection
		[66] = {
			-- Avenger's Shield
			["kick"] = {
				["spellID"] = 31935,
			},
			-- Hammer of Justice
			["stun"] = {
				["SpellID"] = 853,
			},
			-- Repentance
			["cc"] = {
				["spellID"] = 20066,
			},
		},
		-- Retribution
		[70] = {
			-- Rebuke
			["kick"] = {
				["spellID"] = 96231,
			},
			-- Hammer of Justice
			["stun"] = {
				["SpellID"] = 853,
			},
			-- Repentance
			["cc"] = {
				["spellID"] = 20066,
			},
		},
	},
	["PRIEST"] = {
		-- Discipline
		[256] = {
			["kick"] = {
				["spellID"] = nil,
			}
		},
		-- Holy
		[257] = {
			["kick"] = {
				["spellID"] = nil,
			}
		},
		-- Shadow
		[258] = {
			-- Silence
			["kick"] = {
				["spellID"] = 15487,
			},
		},
--		["stun"] = 88625 or 200199 or 205369 or 64044, -- holy word: chastice / censure [holy], mind bomb / psychic horror [shadow]
--		["cc"] = 9484, --shackle undead
		--204263 shining force (holy)
	},
	["ROGUE"] = {
		-- Assassination
		[259] = {
			-- Kick
			["kick"] = {
				["spellID"] = 1766,
			},
		},
		-- Outlaw
		[260] = {
			-- Kick
			["kick"] = {
				["spellID"] = 1766,
			},
		},
		-- Subtlety
		[261] = {
			-- Kick
			["kick"] = {
				["spellID"] = 1766,
			},
		},
--		["stun"] = 6770, --sap
--		["cc"] = 2094, --blind
	},
	["SHAMAN"] = {
		-- Elemental
		[262] = {
			-- Wind Shear
			["kick"] = {
				["spellID"] = 57994,
			},
		},
		-- Enhancement
		[263] = {
			-- Wind Shear
			["kick"] = {
				["spellID"] = 57994,
			},
		},
		-- Restoration
		[264] = {
			-- Wind Shear
			["kick"] = {
				["spellID"] = 57994,
			},
		},
--		["stun"] = 265046 or 135622, --static charge [elemental] / capacitor totem [restoration]
--		["cc"] = 51514 or 211010 or 210873 or 211015 or 269352 or 277778 or 211004 or 277784, --hex
		-- 51490 thunder storm (elemental)
		-- 2484 earth bind totem (all)
	},
	["WARLOCK"] = {
		-- Affliction
		[265] = {
			["kick"] = {
				["spellID"] = 119914 or 19647,
			}
		},
		-- Demonology
		[266] = {
			["kick"] = {
				["spellID"] = 119914 or 19647,
			}
		},
		-- Destruction
		[267] = {
			["kick"] = {
				["spellID"] = 119914 or 19647,
			}
		},
--		["kick"] = 119914 or 19647, --Axe Toss (pet), Spell Lock (pet)
		--119898,
--		["stun"] = "",
--		["cc"] = 710, --banish
	},
	["WARRIOR"] = {
		-- Arms
		[71] = {
			-- Pummel
			["kick"] = {
				["spellID"] = 6552,
			},
		},
		-- Fury
		[72] = {
			-- Pummel
			["kick"] = {
				["spellID"] = 6552,
			},
		},
		-- Protection
		[73] = {
			-- Pummel
			["kick"] = {
				["spellID"] = 6552,
			},
		},
--		["stun"] = "",
--		["cc"] = "",
	},
}