--[[
	Callbacks:
		LCT_CooldownUsed(unitid, spellid)
		LCT_CooldownsReset(unit)

	Functions:
		lib:RegisterUnit(unitid)
		lib:UnregisterUnit(unitid)
		tpu = lib:GetUnitCooldownInfo(unitid, spellid, used_start, used_end, cooldown_start)
		for spellid, spell_data in lib:IterateCooldowns(class, specID, race) do
		spell_data = lib:GetCooldownData(spellid)
		spells_data = lib:GetCooldownsData()
]]

local version = 10
local lib = LibStub:NewLibrary("LibCooldownTracker-1.0", version)
local LGIST = LibStub:GetLibrary("LibGroupInSpecT-1.1")
local fn = LibStub("LibFunctional-1.0")

local keys, map, filter = fn.keys, fn.map, fn.filter

if not lib then return end

-- upvalues
local pairs, type, next, select, assert, unpack = pairs, type, next, select, assert, unpack
local tinsert, tremove = table.insert, table.remove
local GetTime, UnitGUID, IsInInstance = GetTime, UnitGUID, IsInInstance

lib.frame = lib.frame or CreateFrame("Frame")
lib.callbacks = lib.callbacks or LibStub("CallbackHandler-1.0"):New(lib)

-- init event handler
local events = {}
do
	lib.frame:SetScript("OnEvent",
		function(self, event, ...)
			return events[event](lib, event, ...)
		end)
end

-- lookup tables
local class_spelldata = {}
local race_spelldata = {}
local item_spelldata = {}
local pvp_spelldata = {}

-- generate lookup tables
do
	for spellid, spelldata in pairs(LCT_SpellData) do
		if type(spelldata) == "table" then
			local name, _, icon = GetSpellInfo(spellid)
			if not name then
				DEFAULT_CHAT_FRAME:AddMessage("LibCooldownTracker-1.0: bad spellid for " .. (spelldata.class or spelldata.race or "ITEM") .. ": " .. spellid)
				LCT_SpellData[spellid] = nil
			else
				-- add name and icon
				spelldata.name = name
				spelldata.icon = icon

				-- add required aura name
				if spelldata.requires_aura then
					spelldata.requires_aura_name = GetSpellInfo(spelldata.requires_aura)
					if not spelldata.requires_aura_name then
						DEFAULT_CHAT_FRAME:AddMessage("LibCooldownTracker-1.0: bad aura spellid: " .. spelldata.requires_aura)
					end
				end

				-- convert specID list into lookups table
				if spelldata.specID then
					local specs = {}
					for i = 1, #spelldata.specID do
						specs[spelldata.specID[i]] = true
					end
					spelldata.specID_table = specs
				end

				-- insert into lookup tables
				if spelldata.class then
					class_spelldata[spelldata.class] = class_spelldata[spelldata.class] or {}
					class_spelldata[spelldata.class][spellid] = spelldata
				end
				if spelldata.race then
					race_spelldata[spelldata.race] = race_spelldata[spelldata.race] or {}
					race_spelldata[spelldata.race][spellid] = spelldata
				end
				if spelldata.item then
					item_spelldata[spellid] = spelldata
				end
				if spelldata.pvp_trinket then
					pvp_spelldata[spellid] = spelldata
				end
			end
		end
	end
end

local SpellData = LCT_SpellData
LCT_SpellData = nil

-- state
lib.guid_to_unitid = lib.guid_to_unitid or {} -- [guid] = unitid
lib.tracked_players = lib.tracked_players or {} --[[
	[unitid][spellid] = {
		["cooldown_start"] = time,
		["cooldown_end"] = time,
		["used_start"] = time,
		["used_end"] = time,
		["detected"] = boolean,
		[EVENT] = time
	}
]]
lib.registered_units = lib.registered_units or {} -- [unitid] = count

local function RemoveGUID(unit)
	-- find and delete old references to that unit
	for guid, unitid in pairs(lib.guid_to_unitid) do
		if unitid == unit then
			lib.guid_to_unitid[guid] = nil
		end
	end
end

local function UpdateGUID(unit)
	RemoveGUID(unit)

	local guid = UnitGUID(unit)
	if guid then lib.guid_to_unitid[guid] = unit end

	local pet_guid = UnitGUID(unit .. "pet")
	if pet_guid then lib.guid_to_unitid[pet_guid] = unit end
end

-- simple timer used for updating number of charges
-- timers are stored ordered by their firing time so only the first
-- timer on the list is checked in the OnUpdate
local timers = {}
local timer_frame

local function Timer_OnUpdate()
	local t1 = timers[1]
	if t1 and GetTime() >= t1.time then
		tremove(timers, 1)
		t1.func(unpack(t1.args))
		if #timers == 0 then
			lib.frame:SetScript("OnUpdate", nil)
		end
	end
end

local function SetTimer(time, func, ...)
	local pos = 1
	while pos <= #timers do
		if timers[pos].time >= time then
			break
		end
		pos = pos + 1
	end

	tinsert(timers, pos, { time = time, func = func, args = { ... } })

	if #timers == 1 then
		lib.frame:SetScript("OnUpdate", Timer_OnUpdate)
	end

	return pos
end

local function ClearTimers()
	lib.frame:SetScript("OnUpdate", nil)
	timers = {}
end

local function GetCooldownTime(spellid, unit)
	local spelldata = SpellData[spellid]
	local time = spelldata.cooldown

	-- V: note - this thing ties it to GladiusEx, but no choice :(
	if GladiusEx and GladiusEx.buttons[unit] and spelldata.cooldown_overload then
		local button = GladiusEx.buttons[unit]
		local overloads = spelldata.cooldown_overload
		if button.specID and overloads[button.specID] then
			return overloads[button.specID]
		end
		local class = GladiusEx.buttons[unit].class or select(2, UnitClass(unit))
		if class and overloads[class] then
			return overloads[class]
		end
	end

	local tps = lib.tracked_players[unit][spellid]
	if tps and tps.cooldown then
		time = tps.cooldown
	end
	
	return time
end

local function AddCharge(unit, spellid)
	local tps = lib.tracked_players[unit][spellid]
	if not tps then
		return
	end
	tps.charges = tps.charges + 1
	lib.callbacks:Fire("LCT_CooldownUsed", unit, spellid)

	-- schedule another timer if there are more charges in cooldown
	if tps.max_charges and tps.charges < tps.max_charges then
		local now = GetTime()
		local spelldata = SpellData[spellid]
		tps.cooldown_start = now
		tps.cooldown_end = now + GetCooldownTime(spellid, unit)
		tps.charge_timer = SetTimer(tps.cooldown_end, AddCharge, unit, spellid)
	else
		tps.charge_timer = false
	end
end

local function CooldownEvent(event, unit, spellid)
	local spelldata = SpellData[spellid]
	if not spelldata then return end

	if type(spelldata) == "number" then
		spellid = spelldata
		spelldata = SpellData[spelldata]
	end

	if lib:IsUnitRegistered(unit) then
		local now = GetTime()

		if not lib.tracked_players[unit] then
			lib.tracked_players[unit] = {}
		end

		local tpu = lib.tracked_players[unit]

		if tpu[spellid] then
			-- check if the same spell cast was detected recently
			-- if so, we assume that the first detection time is more accurate and ignore this one
			-- this can happen because we listen to both UNIT_SPELLCAST_SUCCEEDED and SPELL_CAST_SUCCESS from COMBAT_LOG_EVENT_UNFILTERED
			-- and because both SPELL_CAST_SUCCESS and SPELL_AURA_APPLIED are considered events for cooldown uses
			local margin = 1
			if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
				if (event ~= "UNIT_SPELLCAST_SUCCEEDED" and tpu[spellid]["UNIT_SPELLCAST_SUCCEEDED"] and (tpu[spellid]["UNIT_SPELLCAST_SUCCEEDED"] + margin) > now) or
				   (event ~= "SPELL_AURA_APPLIED"       and tpu[spellid]["SPELL_AURA_APPLIED"]       and (tpu[spellid]["SPELL_AURA_APPLIED"]       + margin) > now) or
				   (event ~= "SPELL_CAST_SUCCESS"       and tpu[spellid]["SPELL_CAST_SUCCESS"]       and (tpu[spellid]["SPELL_CAST_SUCCESS"]       + margin) > now) then
					return
				end
			end

			-- register event time
			tpu[spellid][event] = now
		else
			tpu[spellid] = {
				detected = true,
				charges = spelldata.charges or spelldata.opt_charges,
				max_charges = spelldata.charges or spelldata.opt_charges,
				charges_detected = spelldata.charges and true or false,
				[event] = now,
			}
		end
		local tps = tpu[spellid]

		-- find what actions are needed
		local used_start, used_end, cooldown_start

		if spelldata.cooldown_starts_on_dispel then
			if event == "SPELL_DISPEL" then
				used_start = true
				cooldown_start = true
			end
		elseif spelldata.cooldown_starts_on_aura_fade then
			if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
				used_start = true
			elseif event == "SPELL_AURA_REMOVED" then
				cooldown_start = true
			end
		else
			if event == "UNIT_SPELLCAST_SUCCEEDED" or event == "SPELL_CAST_SUCCESS" or event == "SPELL_AURA_APPLIED" then
				used_start = true
				cooldown_start = true
			elseif event == "SPELL_AURA_REMOVED" then
				used_end = true
			end
		end

		-- apply actions
		if used_start then
			tps.used_start = now
			tps.used_end = spelldata.duration and (now + spelldata.duration)

			-- is the cooldown still in progress?
			local on_cd = tps.cooldown_end and (tps.cooldown_end - 2) > now
			local opt_lower_cd = spelldata.opt_lower_cooldown or tps.cooldown or spelldata.cooldown

			-- remove charge
			if tps.charges then
				if tps.charges > 0 then
					tps.charges = tps.charges - 1
					-- if cooldown is still in progress and the spell can optionally have charges (with a talent),
					--  then it must have charges
					if not tps.charges_detected and on_cd then
						tps.charges_detected = true
						if spelldata.opt_charges_linked then
							for i = 1, #spelldata.opt_charges_linked do
								local lspellid = spelldata.opt_charges_linked[i]
								local lspelldata = SpellData[lspellid]
								if not tpu[lspellid] then
									tpu[lspellid] = {
										charges = lspelldata.opt_charges,
										max_charges = lspelldata.opt_charges,
									}
								end
								tpu[lspellid].charges_detected = true
							end
						end
					else
						-- We'd go into negative charges. Instead fix our timer
						tps.cooldown = opt_lower_cd
					end
				end
			end

			if spelldata.restore_charges then
				for i = 1, #spelldata.restore_charges do
					local respellid = spelldata.restore_charges[i]
					local respelldata = SpellData[respellid]
					if not tpu[respellid] then
						-- V: if we have to *add* the cooldown, just use the max number of charges
						--    also, use charges by default, not only optional charges (not sure if the spell only has optional charges)
						tpu[respellid] = {
							charges = respelldata.charges or respelldata.opt_charges,
							max_charges = respelldata.charges or respelldata.opt_charges,
						}
					else
						tpu[respellid].charges = (tpu[respellid].charges or 0) + 1
					end
					tpu[respellid].charges_detected = true
				end
			end

			-- reset other cooldowns (Cold Snap, Preparation)
			if spelldata.resets then
				for i = 1, #spelldata.resets do
					local rspellid = spelldata.resets[i]
					if tpu[rspellid] then
						tpu[rspellid].cooldown_start = 0
						tpu[rspellid].cooldown_end = 0
					end
				end
			end
		end

		if used_end then
			tps.used_end = now
		end

		if cooldown_start then
			-- if the spell has charges and the cooldown is already in progress, it does not need to be reset
			if not tps.charges or not tps.cooldown_end or tps.cooldown_end <= now then
				local cooldown_time = GetCooldownTime(spellid, unit)
				tps.cooldown_start = cooldown_time and now
				tps.cooldown_end = cooldown_time and (now + cooldown_time)

				-- set charge timer
				if tps.charges and not tps.charge_timer then
					tps.charge_timer = SetTimer(tps.cooldown_end, AddCharge, unit, spellid)
				end

				-- V: set other cooldown(s)
				local sets_cooldowns = {}
				if spelldata.sets_cooldown then
					sets_cooldowns = {spelldata.sets_cooldown}
				end
				if spelldata.sets_cooldowns then
					sets_cooldowns = spelldata.sets_cooldowns
				end

				for i = 1, #sets_cooldowns do
					local cd = sets_cooldowns[i]
					local cspellid = cd.spellid
					local cspelldata = SpellData[cspellid]
					if cspelldata and ((tpu[cspellid] and tpu[cspellid].detected) or (not cspelldata.talent and not cspelldata.glyph)) then
						if not tpu[cspellid] then
							tpu[cspellid] = {}
						end
						if not tpu[cspellid].cooldown_end or (tpu[cspellid].cooldown_end < (now + cd.cooldown)) then
							tpu[cspellid].cooldown_start = now
							tpu[cspellid].cooldown_end = now + cd.cooldown
							tpu[cspellid].used_start = tpu[cspellid].used_start or 0
							tpu[cspellid].used_end = tpu[cspellid].used_end or 0
						end
					end
				end
			end
		end

		lib.callbacks:Fire("LCT_CooldownUsed", unit, spellid, used_start, used_end, cooldown_start)
	end
end

local function enable()
	lib.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	lib.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	lib.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	lib.frame:RegisterEvent("UNIT_NAME_UPDATE")
	lib.frame:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
	lib.frame:RegisterEvent("ARENA_COOLDOWNS_UPDATE")

	lib.tracked_players = {}
	lib.guid_to_unitid = {}

	for unitid in pairs(lib.registered_units) do
		UpdateGUID(unitid)
	end

	LGIST.RegisterCallback(lib, "GroupInSpecT_Update")
end

local function disable()
	lib.frame:UnregisterAllEvents()
end

-- Removes all the talent spells from a tracked unit
function lib:ClearTalents(unit)
	local tpu = lib.tracked_players[unit]
	if not tpu then return end

	-- find out which detected spells are talents, and un-detect them
	local remove_spells = filter(keys(tpu), function (k)
		local spell = SpellData[k]
		return tpu[k].detected and type(spell) == "table" and spell.talent
	end)
	for i = 1, #remove_spells do
		tpu[remove_spells[i]] = nil
	end
end

local function GetPartyUnit(unit, guid)
	if unit == "player" then return unit end
	if string.sub(unit, 1, 5) == "party" then return unit end
	if string.sub(unit, 1, 4) == "raid" then
		-- XXX: this is a very ugly for, replace it with *something else*
		for i = 1, GetNumGroupMembers() do
			if UnitGUID("party"..i) == guid then return "party"..i end
		end
	end
end

function lib:GroupInSpecT_Update(event, guid, raw_unit, info)
	local unit = GetPartyUnit(raw_unit, guid)
	if not unit then return end

	local tpu = lib.tracked_players[unit]
	if not tpu then lib.tracked_players[unit] = {} end

	lib:ClearTalents(unit)

	-- we didn't detect any talent. wait for follow-up message.
	if not next(info.talents) then
		return
	end

	for talentId, talent in pairs(info.talents) do
		-- XXX only detect spells if SpellData[talent.spell_id]?
		lib:DetectSpell(unit, talent.spell_id)

		-- TODO have some kind of LCT_TalentData so that we can detect charges and other stuff
	end
end

function lib.callbacks:OnUsed(target, event)
	if event == "LCT_CooldownUsed" then
		enable()
	end
end

function lib.callbacks:OnUnused(target, event)
	if event == "LCT_CooldownUsed" then
		disable()
	end
end

--- Registers an unit to be tracked by the library.
-- @param unitid The unitid to register.
function lib:RegisterUnit(unitid)
	local count = (lib.registered_units[unitid] or 0) + 1
	if count == 1 then
		UpdateGUID(unitid)
	end
	lib.registered_units[unitid] = count
	return count
end

--- Unregisters an unit.
-- While the same unit may be registered more than once, it is important that
-- UnregisterUnit is called exactly once for each call to RegisterUnit.
-- @param unitid The unitid to unregister.
function lib:UnregisterUnit(unitid)
	assert(lib.registered_units[unitid] ~= nil, "Attempting to unregister a unit not registered")

	local count = lib.registered_units[unitid] - 1
	if count == 0 then
		lib.registered_units[unitid] = nil
		RemoveGUID(unitid)
	else
		lib.registered_units[unitid] = count
	end
	return count
end

function lib:IsUnitRegistered(unitid)
	return lib.registered_units[unitid]
end

--- Returns a table with the state of a unit's cooldown, or nil if there is no state stored about it.
-- @param unitid The unit unitid.
-- @param spellid The cooldown spellid.
-- @usage
-- local tracked = lib:GetUnitCooldownInfo(unitid, spellid)
-- if tracked then
--     print(tracked.cooldown_start) -- times are based on GetTime()
--     print(tracked.cooldown_end)
--     print(tracked.used_start)
--     print(tracked.used_end)
--     print(tracked.detected) -- use this to check if the unit has used this spell before (useful for detecting talents/glyphs)
-- end
function lib:GetUnitCooldownInfo(unitid, spellid)
	local tpu = lib.tracked_players[unitid]
	return tpu and tpu[spellid]
end

function lib:SetUnitTrinket(unit, spellid)
	lib:DetectSpell(unit, spellid)
end

function lib:DetectSpell(unit, spellid)
	if not spellid then
		return
	end
	if not lib.tracked_players[unit] then
		lib.tracked_players[unit] = {}
	end
	local spell = lib.tracked_players[unit][spellid]
	if not spell then
		lib.tracked_players[unit][spellid] = {
			detected = true
		}
	elseif not spell.detected then
		spell.detected = true
	end
	lib.callbacks:Fire("LCT_CooldownDetected", unit, spellid)
end

--- Returns the raw data of all the cooldowns. See the cooldowns_*.lua data files for more details about its structure.
function lib:GetCooldownsData()
	return SpellData
end

--- Returns the raw data of a specified cooldown spellid.
-- @param spellid The cooldown spellid.
function lib:GetCooldownData(spellid)
	return SpellData[spellid]
end

local function CooldownIterator(state, spellid)
	while true do
		spellid = next(state.data_source, spellid)
		if spellid == nil then
			return
		end
		local spelldata = state.data_source[spellid]
		-- ignore references to other spells
		if type(spelldata) ~= "number" then
			if state.class and state.class == spelldata.class then
				if state.specID and spelldata.specID_table and spelldata.specID_table[state.specID] then
					-- add spec
					return spellid, spelldata
				elseif not spelldata.specID then
					-- add base
					return spellid, spelldata
				end
			end

			if state.race and state.race == spelldata.race then
				-- return racial
				return spellid, spelldata
			end

			if spelldata.item or spelldata.pvp_trinket then
				-- return item or pvp trinket
				if (spelldata.race and spelldata.race == state.race) or not spelldata.race then
					return spellid, spelldata
				end
			end
		end
	end
end

-- uses lookup tables
local function FastCooldownIterator(state, spellid)
	local spelldata
	-- class
	if state.class then
		if state.data_source then
			spellid, spelldata = CooldownIterator(state, spellid)
		end

		if spellid then
			return spellid, spelldata
		else
			-- do race next
			state.data_source = race_spelldata[state.race]
			state.class = nil
			spellid = nil
		end
	end

	-- race
	if state.race then
		if state.data_source then
			spellid, spelldata = CooldownIterator(state, spellid)
		end

		if spellid then
			return spellid, spelldata
		else
			-- do items next
			state.data_source = item_spelldata
			state.race = nil
			spellid = nil
		end
	end

	-- item
	if state.item then
		if state.data_source then
			spellid, spelldata = CooldownIterator(state, spellid)
		end

		if spellid then
			return spellid, spelldata
		else
			-- do pvp next
			state.data_source = pvp_spelldata
			state.item = nil
			spellid = nil
		end
	end

	-- pvp
	if state.pvp and state.data_source then
		spellid, spelldata = CooldownIterator(state, spellid)
		return spellid, spelldata
	end
end

--- Iterates over the cooldowns that apply to a unit of the specified //class//, //specID// and //race//.
-- @param class The unit class. Can be nil.
-- @param specID The unit talent spec ID. Can be nil.
-- @param race The unit race. Can be nil.
function lib:IterateCooldowns(class, specID, race)
	local state = {}
	state.class = class
	state.specID = specID
	state.race = race or ""
	state.item = true
	state.pvp = true

	if class then
		state.data_source = class_spelldata[state.class]
		return FastCooldownIterator, state
	else
		state.data_source = SpellData
		return CooldownIterator, state
	end
end

function events:PLAYER_ENTERING_WORLD()
	local instanceType = select(2, IsInInstance())

	-- reset cooldowns when joining an arena
	if instanceType == "arena" then
		ClearTimers()
		for unit in pairs(lib.tracked_players) do
			lib.tracked_players[unit] = nil
			lib.callbacks:Fire("LCT_CooldownsReset", unit)
		end
	end
end

function events:UNIT_SPELLCAST_SUCCEEDED(event, unit, lineID, spellId)
	CooldownEvent(event, unit, spellId)
end

function events:CombatLogEvent(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId, spellName, spellSchool, auraType)
	-- check unit
	local unit = lib.guid_to_unitid[sourceGUID]
	if not unit then return end

	-- check spell
	local spelldata = SpellData[spellId]
	if not spelldata then return end

	if event == "SPELL_DISPEL" or
	   event == "SPELL_AURA_REMOVED" or
	   event == "SPELL_AURA_APPLIED" or
	   event == "SPELL_CAST_SUCCESS" then
		CooldownEvent(event, unit, spellId)
	end
end

function events:COMBAT_LOG_EVENT_UNFILTERED(event)
	events:CombatLogEvent(event, CombatLogGetCurrentEventInfo())
end

function events:UNIT_NAME_UPDATE(event, unit)
	UpdateGUID(unit)
end

function events:ARENA_CROWD_CONTROL_SPELL_UPDATE(event, unit, spellID)
	-- V: sometimes we receive such an event for "nameplateX" or "focus"
	if string.sub(unit, 1, 5) ~= "arena" then return end
	
	lib:SetUnitTrinket(unit, spellID)
	lib.callbacks:Fire("LCT_CooldownDetected", unit, spellid)
end

function events:ARENA_COOLDOWNS_UPDATE(event, unit)
	C_PvP.RequestCrowdControlSpell(unit)
	local spellID, startTime, duration = C_PvP.GetArenaCrowdControlInfo(unit)
	-- V: the "duration ~= 30s" hack is because when using WOTF/EMFH, blizzard
	--    also updates the actual trinket... but we discard duration in CooldownEvent so we'd set a 2min cd
	if spellID and duration ~= 30000 then
		CooldownEvent("UNIT_SPELLCAST_SUCCEEDED", unit, spellID)
	end
end
