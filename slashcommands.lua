--// slash commands //--

local addon, ns = ...

-- Open up the option panel
SLASH_NAMERAKANA1 = "/namerakana"
SLASH_NAMERAKANA2 = "/nmk"
SlashCmdList["NAMERAKANA"] = function(self)
	-- we have to call it twice; known Blizzard bug
	-- see http://www.wowinterface.com/forums/showthread.php?t=54599
	InterfaceOptionsFrame_OpenToCategory("Namerakana")
	InterfaceOptionsFrame_OpenToCategory("Namerakana")
end