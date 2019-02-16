--//optionpanel//--

local LSM = LibStub("LibSharedMedia-3.0")

local addon, ns = ...
local L = ns.L

ns.panel = CreateFrame("Frame", addon.."Panel")
ns.panel.name = addon
InterfaceOptions_AddCategory(ns.panel)

local title = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("|cff5599ff"..addon.."|r")

local about = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
about:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
about:SetText(L["Shows bars for kicks/stuns/cc with times"])

local version = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
version:SetPoint("TOPLEFT", about, "BOTTOMLEFT", 5, -20)
version:SetText("|cff5599ffVersion:|r "..GetAddOnMetadata("Namerakana", "Version"))

local author = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
author:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -8)
author:SetText("|cff5599ffAuthor:|r Lolzen")

local github = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
github:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -8)
github:SetText("|cff5599ffGithub:|r https://github.com/Lolzen/Namerakana")

local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, addon)
	if addon == "Namerakana" then
		-- // kickframe related // --
		local header1 = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		header1:SetText("|cff5599ffKicks|r")
		header1:SetPoint("TOPLEFT", github, "BOTTOMLEFT", 0, -30)
		
		local cb1 = CreateFrame("CheckButton", "show_kickframe", ns.panel, "ChatConfigCheckButtonTemplate")
		show_kickframeText:SetText(L["Show kickwindow"])
		cb1:SetChecked(Namerakana.kick.show)
		cb1:SetPoint("TOPLEFT", header1, "BOTTOMLEFT", 0, -5)
		
		local smallheader1 = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		smallheader1:SetText(L["Bars"])
		smallheader1:SetPoint("TOPLEFT", cb1, "BOTTOMLEFT", 0, -10)
		
		local slider1 = CreateFrame("Slider", "kick_bar_height_slider", ns.panel, "OptionsSliderTemplate")
		slider1:SetPoint("TOPLEFT", smallheader1, "BOTTOMLEFT", 0, -20)
		kick_bar_height_sliderLow:SetText("1")
		kick_bar_height_sliderHigh:SetText("20")
		kick_bar_height_sliderText:SetText(L["Bar Height"].." ("..Namerakana.kick.barheight..")")
		slider1:SetMinMaxValues(1, 20)
		slider1:SetValue(Namerakana.kick.barheight)
		slider1:SetValueStep(1)
		slider1:SetScript("OnValueChanged", function(self, event, arg1)
			Namerakana.kick.barheight = math.floor(slider1:GetValue() + 0.5)
			kick_bar_height_sliderText:SetText(L["Bar Height"].." ("..Namerakana.kick.barheight..")")
			ns.setBarHeight()
		end)
		
		local slider2 = CreateFrame("Slider", "kick_bar_width_slider", ns.panel, "OptionsSliderTemplate")
		slider2:SetPoint("LEFT", slider1, "RIGHT", 30, 0)
		kick_bar_width_sliderLow:SetText("50")
		kick_bar_width_sliderHigh:SetText("200")
		kick_bar_width_sliderText:SetText(L["Bar Width"].." ("..Namerakana.kick.width..")")
		slider2:SetMinMaxValues(50, 200)
		slider2:SetValue(Namerakana.kick.width)
		slider2:SetValueStep(1)
		slider2:SetScript("OnValueChanged", function(self, event, arg1)
			Namerakana.kick.width = math.floor(slider2:GetValue() + 0.5)
			kick_bar_width_sliderText:SetText(L["Bar Width"].." ("..Namerakana.kick.width..")")
			ns.setBarWidth()
		end)
		
		local smallheader2 = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		smallheader2:SetText(L["Texture"])
		smallheader2:SetPoint("LEFT", smallheader1, "RIGHT", 330, 0)
		
		local selectedBarTexture_kick
		local picker1 = CreateFrame("Button", "kickbartexture", ns.panel, "UIDropDownMenuTemplate")
		picker1:SetPoint("TOPLEFT", smallheader2, "BOTTOMLEFT", -20, -20)
		picker1:Show()
		
		local function OnClick(kickbartexture)
			Namerakana.kick.bartexture = kickbartexture.value
			UIDropDownMenu_SetSelectedName(picker1, kickbartexture.value)
			ns.setTexture()
		end

		local function initialize(picker1, level)
			local info = UIDropDownMenu_CreateInfo()
			for k, v in pairs(LSM:List(LSM.MediaType.STATUSBAR)) do
				if v == Namerakana.kick.bartexture then
					selectedBarTexture_kick = v
				end
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				info.icon = LSM:Fetch("statusbar", v)
				info.tCoord = 0, 1, 1, 1
				UIDropDownMenu_AddButton(info, level)
			end
		end
		UIDropDownMenu_Initialize(picker1, initialize)
		UIDropDownMenu_SetWidth(picker1, 200)
		UIDropDownMenu_SetButtonWidth(picker1, 215)
		UIDropDownMenu_SetSelectedName(picker1, selectedBarTexture_kick)
		UIDropDownMenu_JustifyText(picker1, "LEFT")
		
		local smallheader3  = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		smallheader3:SetText(L["Font"])
		smallheader3:SetPoint("TOPLEFT", slider1, "BOTTOMLEFT", 0, -30)
		
		local fontobjects_kick = {}
		local selectedFont_kick
		local picker2 = CreateFrame("Button", "kickfont", ns.panel, "UIDropDownMenuTemplate")
		picker2:SetPoint("TOPLEFT", smallheader3, "BOTTOMLEFT", -20, -10)
		picker2:Show()
		
		local function OnClick(kickfont)
			Namerakana.kick.font = kickfont.value
			UIDropDownMenu_SetSelectedName(picker2, kickfont.value)
			ns.setFont()
		end

		local function initialize(picker2, level)
			local info = UIDropDownMenu_CreateInfo()
			for k, v in pairs(LSM:List(LSM.MediaType.FONT)) do
				if v == Namerakana.kick.font then
					selectedFont_kick = v
				end
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				if not fontobjects_kick[v] then
					fontobjects_kick[v] = CreateFont(v)
					fontobjects_kick[v]:SetTextColor(1, 1, 1)
					fontobjects_kick[v]:SetFont(LSM:Fetch("font", v), 12, "")
				end
				--now use created fontObjects to distinguish the fonts in the picker
				info.fontObject = v
				UIDropDownMenu_AddButton(info, level)
			end
		end
		UIDropDownMenu_Initialize(picker2, initialize)
		UIDropDownMenu_SetWidth(picker2, 100)
		UIDropDownMenu_SetButtonWidth(picker2, 115)
		UIDropDownMenu_SetSelectedName(picker2, selectedFont_kick)
		UIDropDownMenu_JustifyText(picker2, "LEFT")
	
		local smallheader4  = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		smallheader4:SetText(L["Font Flag"])
		smallheader4:SetPoint("LEFT", smallheader3, "RIGHT", 120, 0)

		local fontflags = {
			"OUTLINE",
			"THINOUTLINE",
			"MONOCHROME",
			"",
		}
		
		local selectedFlag_kick
		local picker3 = CreateFrame("Button", "kickfontflag", ns.panel, "UIDropDownMenuTemplate")
		picker3:SetPoint("TOPLEFT", smallheader4, "BOTTOMLEFT", -20, -10)
		picker3:Show()
		
		local function OnClick(kickfontflag)
			Namerakana.kick.fontflag = kickfontflag.value
			UIDropDownMenu_SetSelectedName(picker3, kickfontflag.value)
			ns.setFont()
		end

		local function initialize(picker3, level)
			local info = UIDropDownMenu_CreateInfo()
			for k, v in pairs(fontflags) do
				if v == Namerakana.kick.fontflag then
					selectedFlag_kick = k
				end
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				UIDropDownMenu_AddButton(info, level)
			end
		end
		UIDropDownMenu_Initialize(picker3, initialize)
		UIDropDownMenu_SetWidth(picker3, 100)
		UIDropDownMenu_SetButtonWidth(picker3, 115)
		UIDropDownMenu_SetSelectedID(picker3, selectedFlag_kick)
		UIDropDownMenu_JustifyText(picker3, "LEFT")
	
		local slider3 = CreateFrame("Slider", "kick_font_size_slider", ns.panel, "OptionsSliderTemplate")
		slider3:SetPoint("LEFT", picker3, "RIGHT", 10, 3)
		kick_font_size_sliderLow:SetText("1")
		kick_font_size_sliderHigh:SetText("30")
		kick_font_size_sliderText:SetText(L["Font Size"].." ("..Namerakana.kick.fontsize..")")
		slider3:SetMinMaxValues(1, 30)
		slider3:SetValue(Namerakana.kick.fontsize)
		slider3:SetValueStep(1)
		slider3:SetScript("OnValueChanged", function(self, event, arg1)
			Namerakana.kick.fontsize = math.floor(slider3:GetValue() + 0.5)
			kick_font_size_sliderText:SetText(L["Font Size"].." ("..Namerakana.kick.fontsize..")")
			ns.setFont()
		end)
		
		local smallheader5  = ns.panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
		smallheader5:SetText(L["Background Alpha"])
		smallheader5:SetPoint("LEFT", smallheader4, "RIGHT", 260, 0)

		local alphavalues = {
			1,
			0.9,
			0.8,
			0.7,
			0.6,
			0.5,
			0.4,
			0.3,
			0.2,
			0.1,
		}
		
		local selectedAlpha_kick
		local picker4 = CreateFrame("Button", "kickbgalpha", ns.panel, "UIDropDownMenuTemplate")
		picker4:SetPoint("TOPLEFT", smallheader5, "BOTTOMLEFT", -20, -10)
		picker4:Show()
		
		local function OnClick(kickbgalpha)
			Namerakana.kick.backdropalpha = kickbgalpha.value
			UIDropDownMenu_SetSelectedName(picker4, kickbgalpha.value)
			ns.setAlpha()
		end

		local function initialize(picker4, level)
			local info = UIDropDownMenu_CreateInfo()
			for k, v in pairs(alphavalues) do
				if v == tonumber(Namerakana.kick.backdropalpha) then
					selectedAlpha_kick = k
				end
				info = UIDropDownMenu_CreateInfo()
				info.text = v
				info.value = v
				info.func = OnClick
				UIDropDownMenu_AddButton(info, level)
			end
		end
		UIDropDownMenu_Initialize(picker4, initialize)
		UIDropDownMenu_SetWidth(picker4, 100)
		UIDropDownMenu_SetButtonWidth(picker4, 115)
		UIDropDownMenu_SetSelectedID(picker4, selectedAlpha_kick)
		UIDropDownMenu_JustifyText(picker4, "LEFT")
	end
end)
f:RegisterEvent("ADDON_LOADED")

ns.panel.default = function(self)
	Namerakana = ns.defaults
	ns.setBarHeight()
	ns.setBarWidth()
	ns.setFont()
	ns.setTexture()
	ns.setAlpha()
end