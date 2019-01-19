local addon, ns = ...

--[[ todo
saved variables
kicks/stuns windows etc ein/ausschaltbar
größe (höhe. breite), svhrift, schriftgröße, positionen einstellbar
farben einstellbar (schrift, bars(?))

--spec check (heal etc)
complete spelllist
]]


-- kickFrameframe
local kickFrame = CreateFrame("Frame")
kickFrame:SetPoint("CENTER", UIParent, "CENTER")
kickFrame:SetMovable(true)
kickFrame:EnableMouse(true)
kickFrame:SetUserPlaced(true)
kickFrame:SetSize(120, 8)
kickFrame:SetBackdrop({
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	insets = {left = -1, right = -1, top = -1, bottom = -1},
})
kickFrame:SetBackdropColor(0, 0, 0)

local kickFrame1text = kickFrame:CreateFontString(nil, "OVERLAY")
kickFrame1text:SetFont("Interface\\AddOns\\Namerakana\\fonts\\SEMPRG.ttf", 6, "THINOUTLINE")
kickFrame1text:SetPoint("TOP", kickFrame, 0, -1)
kickFrame1text:SetText("KICKS")

-- Script for moving the frame and resetting data
local registerClicks = function(self, button)
	if IsAltKeyDown() then
		kickFrame:ClearAllPoints()
		kickFrame:StartMoving()
	end
end
kickFrame:SetScript("OnMouseDown", registerClicks)

kickFrame:SetScript("OnMouseUp", function()
	kickFrame:StopMovingOrSizing()
end)

-- Statusbars
local bars = {}
local function updateBars()
	if IsInGroup("player") then
		kickFrame:Show()
		if not bars[1] then
			bars[1] = CreateFrame("StatusBar", "StatusBar".."1", kickFrame)
			bars[1]:SetHeight(8)
			bars[1]:SetWidth(kickFrame:GetWidth() - 9)
			bars[1]:SetStatusBarTexture("Interface\\AddOns\\Namerakana\\media\\statusbar")
			bars[1]:SetPoint("TOPLEFT", kickFrame, 9, -9)
			bars[1]:SetStatusBarColor(RAID_CLASS_COLORS[select(2, UnitClass("player"))].r, RAID_CLASS_COLORS[select(2, UnitClass("player"))].g, RAID_CLASS_COLORS[select(2, UnitClass("player"))].b)
			bars[1]:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				insets = {left = -10, right = -1, top = -0.5, bottom = -1},
			})
			bars[1]:SetBackdropColor(0, 0, 0)
		end

		if not bars[1].bg then
			bars[1].bg = bars[1]:CreateTexture(nil, "BACKGROUND")
			bars[1].bg:SetAllPoints(bars[1])
			bars[1].bg:SetTexture("Interface\\AddOns\\Namerakana\\media\\statusbar")
			bars[1].bg:SetVertexColor(1, 1, 1, 0.2)
		end

		if not bars[1].icon then
			bars[1].icon = bars[1]:CreateTexture(nil, "OVERLAY")
			bars[1].icon:SetTexCoord(.04, .94, .04, .94)
			bars[1].icon:SetSize(8, 8)
			bars[1].icon:SetTexture(GetSpellTexture(ns.spells[select(2, UnitClass("player"))]["kick"]))
			bars[1].icon:SetPoint("RIGHT", bars[1], "LEFT", -1, 0)
		end

		-- Create the FontStrings
		if not bars[1].string1 then
			-- #. Name
			bars[1].string1 = bars[1]:CreateFontString(nil, "OVERLAY")
			bars[1].string1:SetFont("Interface\\AddOns\\Namerakana\\fonts\\SEMPRG.ttf", 6, "THINOUTLINE")
			bars[1].string1:SetPoint("LEFT", bars[1], 2, 0)
			bars[1].string1:SetText(UnitName("player"))
		end

		if not bars[1].string2 then
			-- cooldown
			bars[1].string2 = bars[1]:CreateFontString(nil, "OVERLAY")
			bars[1].string2:SetFont("Interface\\AddOns\\Namerakana\\fonts\\SEMPRG.ttf", 6, "THINOUTLINE")
			bars[1].string2:SetPoint("RIGHT", bars[1], "RIGHT", -2, 0)
			bars[1].string2:SetText("|cff00ff22READY|r")
		end

		-- timer
		if not bars[1].timer then
			bars[1].timer = bars[1]:CreateAnimationGroup()
			bars[1].timerAnim = bars[1].timer:CreateAnimation()
			bars[1].timerAnim:SetDuration(0.1)
			
			--repeat until Stop() is requested
			bars[1].timer:SetScript("OnFinished", function(self, requested)
				if not requested then
					local start, duration, enabled, modRate = GetSpellCooldown(ns.spells[select(2, UnitClass("player"))]["kick"])
					if start > 0 and duration > 0 then
						bars[1]:SetMinMaxValues(0, duration)
						bars[1]:SetValue(start + duration - GetTime())
						bars[1].string2:SetFormattedText("%.1f", start + duration - GetTime())
						self:Play()
					else
						bars[1].string2:SetText("|cff00ff22READY|r")
						bars[1]:SetMinMaxValues(0, 1)
						bars[1]:SetValue(1)
						self:Stop()
					end
				end
			end)
		end
		
		-- party members
		for i=2, GetNumSubgroupMembers()+1 do
			if UnitInParty("party"..i-1) then
				if not bars[i] then
					bars[i] = CreateFrame("StatusBar", "StatusBar"..i, kickFrame)
					bars[i]:SetHeight(8)
					bars[i]:SetWidth(kickFrame:GetWidth() - 9)
					bars[i]:SetStatusBarTexture("Interface\\AddOns\\Namerakana\\media\\statusbar")
					bars[i]:SetPoint("TOP", bars[i-1], "BOTTOM", 0, -2) --test
					if UnitIsConnected("party"..i-1) then
						bars[i]:SetStatusBarColor(RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].r, RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].g, RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].b)
					else
						bars[i]:SetStatusBarColor(0.5, 0.5, 0.5, 1)
					end
					bars[i]:SetBackdrop({
						bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
						insets = {left = -10, right = -1, top = -1, bottom = -1},
					})
					bars[i]:SetBackdropColor(0, 0, 0)
				else
					if UnitIsConnected("party"..i-1) then
						bars[i]:SetStatusBarColor(RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].r, RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].g, RAID_CLASS_COLORS[select(2, UnitClass("party"..i-1))].b)
					else
						bars[i]:SetStatusBarColor(0.5, 0.5, 0.5, 1)
					end
				end

				if not bars[i].bg then
					bars[i].bg = bars[1]:CreateTexture(nil, "BACKGROUND")
					bars[i].bg:SetAllPoints(bars[i])
					bars[i].bg:SetTexture("Interface\\AddOns\\Namerakana\\media\\statusbar")
					bars[i].bg:SetVertexColor(1, 1, 1, 0.2)
				end

				if not bars[i].icon then
					bars[i].icon = bars[i]:CreateTexture(nil, "OVERLAY")
					bars[i].icon:SetTexCoord(.04, .94, .04, .94)
					bars[i].icon:SetSize(8, 8)
					bars[i].icon:SetTexture(GetSpellTexture(ns.spells[select(2, UnitClass("party"..i-1))]["kick"]))
					bars[i].icon:SetPoint("RIGHT", bars[i], "LEFT", -1, 0)
				else
					bars[i].icon:SetTexture(GetSpellTexture(ns.spells[select(2, UnitClass("party"..i-1))]["kick"]))
				end

				-- Create the FontStrings
				if not bars[i].string1 then
					-- #. Name
					bars[i].string1 = bars[i]:CreateFontString(nil, "OVERLAY")
					bars[i].string1:SetFont("Interface\\AddOns\\Namerakana\\fonts\\SEMPRG.ttf", 6, "THINOUTLINE")
					bars[i].string1:SetPoint("LEFT", bars[i], 2, 0)
					bars[i].string1:SetText(UnitName("party"..i-1))
				else
					bars[i].string1:SetText(UnitName("party"..i-1))
				end

				if not bars[i].string2 then
					-- cooldown
					bars[i].string2 = bars[i]:CreateFontString(nil, "OVERLAY")
					bars[i].string2:SetFont("Interface\\AddOns\\Namerakana\\fonts\\SEMPRG.ttf", 6, "THINOUTLINE")
					bars[i].string2:SetPoint("RIGHT", bars[i], "RIGHT", -2, 0)
					if UnitIsConnected("party"..i-1) then
						bars[i].string2:SetText("|cff00ff22READY|r")
					else
						bars[i].string2:SetText("|cffffffffOFFLINE|r")
					end
				else
					if UnitIsConnected("party"..i-1) then
						bars[i].string2:SetText("|cff00ff22READY|r")
					else
						bars[i].string2:SetText("|cffffffffOFFLINE|r")
					end
				end

				-- timer
				if not bars[i].timer then
					bars[i].timer = bars[i]:CreateAnimationGroup()
					bars[i].timerAnim = bars[i].timer:CreateAnimation()
					bars[i].timerAnim:SetDuration(0.1)

					--repeat until Stop() is requested
					bars[i].timer:SetScript("OnFinished", function(self, requested)
						if not requested then
							local start, duration, enabled, modRate = GetSpellCooldown(ns.spells[select(2, UnitClass("party"..i-1))]["kick"])
							if start > 0 and duration > 0 then
								bars[i].string2:SetFormattedText("%.1f", start + duration - GetTime())
								bars[i]:SetMinMaxValues(0, duration)
								bars[i]:SetValue(start + duration - GetTime())
								self:Play()
							else
								if UnitIsConnected("party"..i-1) then
									bars[i].string2:SetText("|cff00ff22READY|r")
								else
									bars[i].string2:SetText("|cffffffffOFFLINE|r")
								end
								bars[i]:SetMinMaxValues(0, 1)
								bars[i]:SetValue(1)
								self:Stop()
							end
						end
					end)
				end
			end
			if bars[i] then
				if not UnitInParty(bars[i].string1:GetText()) then
					bars[i]:SetStatusBarColor(0.5, 0.5, 0.5, 0)
					bars[i].bg:SetVertexColor(1, 1, 1, 0)
					bars[i].icon:SetTexture(nil)
					bars[i].string1:SetText(nil)
					bars[i].string2:SetText(nil)
				end
			end
		end
	else
		kickFrame:Hide()
	end
end

function kickFrame.COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, ...)
	local _, eventType, _, _, sourceName, _, _, _, destName, _, _, sourceSpellId = CombatLogGetCurrentEventInfo()
	if IsInGroup("player") then
		if UnitInParty(sourceName) then
			if ns.spells[select(2, UnitClass(sourceName))]["kick"] == sourceSpellId then
				for i=1, #bars do
					if bars[i].string1:GetText() == sourceName then
						bars[i].timer:Play()
						bars[i].icon:SetTexture(GetSpellTexture(ns.spells[select(2, UnitClass(sourceName))]["kick"]))
					end
				end
			end
		end
	end
end

kickFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
kickFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
kickFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
kickFrame.GROUP_ROSTER_UPDATE = updateBars
kickFrame.PLAYER_ENTERING_WORLD = updateBars

kickFrame:SetScript("OnEvent", function(self, event, ...)  
	if(self[event]) then
		self[event](self, event, ...)
	else
		print("Namerakana debug: "..event)
	end 
end)
