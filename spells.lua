local addon, ns = ...

ns.spells = {
	["DEATHKNIGHT"] = {
		["kick"] = 47528, --mind freeze
		["stun"] = "",
		["cc"] = "",
	},
	["DEMONHUNTER"] = {
		["kick"] = 183752, --disrupt
		["stun"] = 179057, --chaos nova
		["cc"] = 217832, --imprison
	},
	["DRUID"] = {
		["kick"] = 78675, --solar beam [moonkin]
		["stun"] = "",
		["cc"] = 339, -- entangling roots
	},
	["HUNTER"] = {
		["kick"] = "",
		["stun"] = "",
		["cc"] = 187650, --freezing trap
	},
	["MAGE"] = {
		["kick"] = 2139, --counter spell
		["stun"] = "",
		["cc"] = 118, --polymorph
	},
	["MONK"] = {
		["kick"] = 116705, --spear hand strike [Brewmaster, Windwalker]
		["stun"] = 119381, --leg sweep
		["cc"] = 115078, --paralysis
	},
	["PALADIN"] = {
		["kick"] = 96231 or 31935, --"rebuke / avenger's shield"
		["stun"] = 853, --hammer of justice
		["cc"] = "", --"buße"
	},
	["PRIEST"] = {
		["kick"] = 15487, --silence [shadow]
		["stun"] = 88625 or 200199 or 205369 or 64044, -- holy word: chastice / censure [holy], mind bomb / psychic horror [shadow]
		["cc"] = 9484, --shackle undead
		--204263 shining force (holy)
	},
	["ROGUE"] = {
		["kick"] = 1766, --kick
		["stun"] = 6770, --sap
		["cc"] = 2094, --blind
	},
	["SHAMAN"] = {
		["kick"] = 57994, --wind shear
		["stun"] = 265046 or 135622, --static charge [elemental] / capacitor totem [restoration]
		["cc"] = 51514 or 211010 or 210873 or 211015 or 269352 or 277778 or 211004 or 277784, --hex
		-- 51490 thunder storm (elemental)
		-- 2484 earth bind totem (all)
	},
	["WARLOCK"] = {
		["kick"] = 89766 or 19647, --Axe Toss (pet), Spell Lock (pet)
		
		["stun"] = "",
		["cc"] = 710, --banish
	},
	["WARRIOR"] = {
		["kick"] = 6552, --pummel
		["stun"] = "",
		["cc"] = "",
	},
}