local addon, ns = ...

local LSM = LibStub("LibSharedMedia-3.0")
local LGIST = LibStub("LibGroupInSpecT-1.1")
local CT = LibStub("LibCooldownTracker-1.0")

-- stunFrameframe
local stunFrame = CreateFrame("Frame")
local bars = {}

local function initialize()
--	if not Namerakana.stun.show then return end
	stunFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", Namerakana.stun.XPos, Namerakana.stun.YPos)
	stunFrame:SetSize(Namerakana.stun.width, Namerakana.stun.barheight)
	stunFrame:SetMovable(true)
	stunFrame:EnableMouse(true)
	stunFrame:SetUserPlaced(true)
	stunFrame:SetFrameStrata("BACKGROUND")
	stunFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		insets = {left = -1, right = -1, top = -1, bottom = -1},
	})
	stunFrame:SetBackdropColor(0, 0, 0, 1)

	if not stunFrame.title then
		stunFrame.title = stunFrame:CreateFontString(nil, "OVERLAY")
		stunFrame.title:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
		stunFrame.title:SetPoint("TOP", stunFrame, 0, -1)
		stunFrame.title:SetText("STUNS")
	end

	-- Script for moving the frame and resetting data
	local registerClicks = function(self, button)
		if IsAltKeyDown() then
			stunFrame:ClearAllPoints()
			stunFrame:StartMoving()
		end
	end
	stunFrame:SetScript("OnMouseDown", registerClicks)

	stunFrame:SetScript("OnMouseUp", function(self)
		stunFrame:StopMovingOrSizing()
		Namerakana.stun.XPos = self:GetLeft()
		Namerakana.stun.YPos = self:GetBottom()
	end)

	-- statusbars
	for i=1, 5 do
		-- statusbar
		if not bars[i] then
			bars[i] = CreateFrame("StatusBar", "StatusBar"..i, stunFrame)
			bars[i]:SetHeight(Namerakana.stun.barheight)
			bars[i]:SetWidth(stunFrame:GetWidth() - 9)
			bars[i]:SetStatusBarTexture(LSM:Fetch("statusbar", Namerakana.stun.bartexture))
			if i == 1 then
				bars[i]:SetPoint("TOPLEFT", stunFrame, 9, -9)
			else
				bars[i]:SetPoint("TOP", bars[i-1], "BOTTOM", 0, -2)
			end
			bars[i]:SetBackdrop({
				bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
				insets = {left = -10, right = -1, top = -1, bottom = -1},
			})
			bars[i]:SetBackdropColor(0, 0, 0, Namerakana.stun.backdropalpha)
			bars[i]:SetFrameStrata("HIGH")
		end

		-- storing the unit
		if not bars[i].unit then
			bars[i].unit = nil
		end

		-- storing the specID
		if not bars[i].spec then
			bars[i].spec = nil
		end

		-- storing the spec role
		if not bars[i].role then
			bars[i].role = nil
		end

		-- storing start time
		if not bars[i].start then
			bars[i].start = nil
		end

		if not bars[i].duration then
			bars[i].duration = nil
		end

		-- background
		if not bars[i].bg then
			bars[i].bg = bars[i]:CreateTexture(nil, "LOW")
			bars[i].bg:SetAllPoints(bars[i])
			bars[i].bg:SetTexture(LSM:Fetch("statusbar", Namerakana.stun.bartexture))
			bars[i].bg:SetVertexColor(1, 1, 1, 0.2)
		end

		-- icon
		if not bars[i].icon then
			bars[i].icon = bars[i]:CreateTexture(nil, "OVERLAY")
			bars[i].icon:SetTexCoord(.04, .94, .04, .94)
			bars[i].icon:SetSize(Namerakana.stun.barheight, Namerakana.stun.barheight)
			bars[i].icon:SetPoint("RIGHT", bars[i], "LEFT", -1, 0)
			bars[i].icon:SetTexture(GetSpellTexture(212812))
		end

		-- name
		if not bars[i].string1 then
			bars[i].string1 = bars[i]:CreateFontString(nil, "OVERLAY")
			bars[i].string1:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
			bars[i].string1:SetPoint("LEFT", bars[i], 2, 0)
		end

		-- cooldown
		if not bars[i].string2 then
			bars[i].string2 = bars[i]:CreateFontString(nil, "OVERLAY")
			bars[i].string2:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
			bars[i].string2:SetPoint("RIGHT", bars[i], "RIGHT", -2, 0)
			bars[i].string2:SetText("|cff00ff22READY|r")
		end

		-- timer
		if not bars[i].timer then
			bars[i].timer = bars[i]:CreateAnimationGroup()
			bars[i].timerAnim = bars[i].timer:CreateAnimation()
			bars[i].timerAnim:SetDuration(0.1)
				
			--repeat until Stop() is requested
			bars[i].timer:SetScript("OnFinished", function(self, requested)
				if not requested then
					local start, duration = bars[i].start, bars[i].duration
					if start > 0 and start + duration - GetTime() > 0 then
						bars[i]:SetMinMaxValues(0, bars[i].duration)
						bars[i]:SetValue(start + duration - GetTime())
						bars[i].string2:SetFormattedText("%.1f", start + duration - GetTime())
						self:Play()
					else
						bars[i].string2:SetText("|cff00ff22READY|r")
						bars[i]:SetMinMaxValues(0, 1)
						bars[i]:SetValue(1)
						self:Stop()
					end
				end
			end)
		end
	end
	stunFrame:UnregisterEvent("ADDON_LOADED")
end

function stunFrame:LCT_CooldownUsed(event, unit, spellid)
	if not Namerakana.stun.show then return end
	if IsInGroup("player") and not UnitInRaid("player") then
		if UnitInParty(unit) then
			local tracked = CT:GetUnitCooldownInfo(unit, spellid)
			for i=1, #bars do
				if bars[i].string1:GetText() == UnitName(unit) then
					if bars[i].spec ~= nil and ns.spells[select(2, UnitClass(unit))][bars[i].spec]["stun"]["spellID"] == spellid then
						bars[i].start = tracked.cooldown_start
						bars[i].duration = tracked.cooldown_end - tracked.cooldown_start
						bars[i].timer:Play()
					end
				end
			end
		end
	end
end
CT.RegisterCallback(stunFrame, "LCT_CooldownUsed")
CT:RegisterUnit("player")
for i=1, 4 do
	CT:RegisterUnit("party"..i)
end

local function updateBars(self, event, ...)
	if not Namerakana.stun.show then return end
	if IsInGroup("player") and not UnitInRaid("player") then
		LGIST:Rescan()
		stunFrame:Show()
		local unit
		for i=1, #bars do
			if i == 1 then
				unit = "player"
			else
				if UnitExists("party"..i-1) then
					unit = "party"..i-1
				else
					unit = "none"
				end
			end
			-- fill in relevant information, or update it
			if UnitInParty(unit) and unit ~= nil and unit ~= "none" then
				if bars[i].role ~= nil or bars[i].role ~= "healer" then
					bars[i]:Show()
					bars[i].bg:Show()
					bars[i].unit = unit
					bars[i].string1:SetText(UnitName(unit))
					if UnitIsConnected(unit) then
						local color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
						if color then
							bars[i]:SetStatusBarColor(color.r, color.g, color.b)
						end
						bars[i].string2:SetText("|cff00ff22READY|r")
					else
						bars[i]:SetStatusBarColor(0.5, 0.5, 0.5, 1)
						bars[i].string2:SetText("|cffffffffOFFLINE|r")
						bars[i]:Show()
					end
				else
					if i <= 5 then
						bars[i] = bars[i+1]
					else
						bars[i]:Hide()
					end
				end
			else
				bars[i]:Hide()
			end
		end
	else
		stunFrame:Hide()
	end
end

function stunFrame:GroupInSpecT_Update(event, guid, unit, info)
	if not bars then return end
	if info.class and info.global_spec_id then
		for i=1, #bars do
			if bars[i].string1:GetText() == UnitName(unit) and bars[i].spec ~= info.global_spec_id then
				bars[i].spec = info.global_spec_id
				if info.global_spec_id ~= 0 then
					bars[i].role = info.spec_role
					bars[i].icon:SetTexture(GetSpellTexture(ns.spells[info.class][info.global_spec_id]["stun"]["spellID"]))
				end
			end
		end
	end
	--updateBars()
end
LGIST.RegisterCallback(stunFrame, "GroupInSpecT_Update")

function ns.setStunBarHeight()
	stunFrame:SetHeight(Namerakana.stun.barheight)
	for i=1, #bars do
		bars[i]:SetHeight(Namerakana.stun.barheight)
	end
end

function ns.setStunBarWidth()
	stunFrame:SetWidth(Namerakana.stun.width)
	for i=1, #bars do
		bars[i]:SetWidth(stunFrame:GetWidth() - 9)
	end
end

function ns.setStunFont()
	stunFrame.title:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
	for i=1, #bars do
		bars[i].string1:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
		bars[i].string2:SetFont(LSM:Fetch("font", Namerakana.stun.font), Namerakana.stun.fontsize, Namerakana.stun.fontflag)
	end
end

function ns.setStunTexture()
	for i=1, #bars do
		bars[i]:SetStatusBarTexture(LSM:Fetch("statusbar", Namerakana.stun.bartexture))
		bars[i].bg:SetTexture(LSM:Fetch("statusbar", Namerakana.stun.bartexture))
	end
end

function ns.setStunAlpha()
	for i=1, #bars do
		bars[i]:SetBackdropColor(0, 0, 0, Namerakana.stun.backdropalpha)
	end
end

stunFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
stunFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
stunFrame:RegisterEvent("ADDON_LOADED")
stunFrame.GROUP_ROSTER_UPDATE = updateBars
stunFrame.PLAYER_ENTERING_WORLD = updateBars
stunFrame.ADDON_LOADED = initialize

stunFrame:SetScript("OnEvent", function(self, event, ...)  
	if(self[event]) then
		self[event](self, event, ...)
	else
		print("Namerakana debug: "..event)
	end 
end)
