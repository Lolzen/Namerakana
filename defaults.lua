--//defaultcfg//--

local addon, ns = ...

ns.defaults = {
	["kick"] = {
		["show"] = true,
		["XPos"] = 100,
		["YPos"] = 100,
		["width"] = 120,
		["backdropalpha"] = 1,
		["font"] = "Namerakana",
		["fontsize"] = 6,
		["fontflag"] = "THINOUTLINE",
		["barheight"] = 8,
		["bartexture"] = "Namerakana",
	},
	["stun"] = {
		["show"] = false,
		["XPos"] = 100,
		["YPos"] = 100,
		["width"] = 120,
		["backdropalpha"] = 1,
		["font"] = "Namerakana",
		["fontsize"] = 6,
		["fontflag"] = "THINOUTLINE",
		["barheight"] = 8,
		["bartexture"] = "Namerakana",
	},
	["cc"] = {
		["show"] = false,
		["XPos"] = 100,
		["YPos"] = 100,
		["width"] = 120,
		["backdropalpha"] = 1,
		["font"] = "Namerakana",
		["fontsize"] = 6,
		["fontflag"] = "THINOUTLINE",
		["barheight"] = 8,
		["bartexture"] = "Namerakana",
	},
}

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, addon)
	if addon == "Namerakana" then
		-- create new defaults on first login
		if Namerakana == nil then
			Namerakana = ns.defaults
		end
	end
end)
f:RegisterEvent("ADDON_LOADED")

