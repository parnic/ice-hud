local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local DragonridingVigor = IceCore_CreateClass(IceClassPowerCounter)

-- NOTE (TWW 11.2.7+): Blizzard removed the Vigor bar and moved Skyriding to a shared charge system.
-- This module now supports BOTH:
--   * Old Vigor UIWidget FillUpFrames (Dragonflight/TWW pre-11.2.7)
--   * New Skyriding charges (TWW 11.2.7+)
--
-- If the widget no longer exists, we automatically fall back to charges.

local DragonridingBuffs = {
	360954, -- Highland Drake
	368896, -- Renewed Proto-Drake
	368899, -- Windborn Velocidrake
	368901, -- Cliffside Wylderdrake
	368893, -- Winding Slitherdrake
	412088, -- Grotto Netherwing Drake
}

-- Old Vigor widget (pre-11.2.7)
local vigorWidgetSetID = 283
local vigorWidgetType = 24
local defaultVigorWidgetID = 4460
local vigorWidgetIDs = nil

-- New Skyriding charges (11.2.7+)
-- Verified IDs:
--   Surge Forward (Skyriding mount ability): 372608
--   Skyward Ascent (Skyriding mount ability): 372610
local SKYRIDING_CHARGE_SPELL_IDS = { 372608, 372610 }

local knowsAlternateMountEnum = Enum and Enum.PowerType and Enum.PowerType.AlternateMount
local unitPowerType = Enum and Enum.PowerType and Enum.PowerType.AlternateMount
unitPowerType = unitPowerType or ALTERNATE_POWER_INDEX


local BUILD_NUMBER = select(4, GetBuildInfo())
local FORCE_CHARGES_BUILD = 110207 -- 11.2.7
-- -------------------------
-- Helpers
-- -------------------------
local function SafeGetSpellCharges(spellID)
	-- Prefer modern C_Spell API where available
	if C_Spell and C_Spell.GetSpellCharges then
		local ch = C_Spell.GetSpellCharges(spellID)
		-- C_Spell.GetSpellCharges can return a table (Retail) or nil
		if type(ch) == "table" then
			return ch.currentCharges, ch.maxCharges, ch.cooldownStartTime, ch.cooldownDuration
		end
	end

	-- Fallback to legacy API
	if GetSpellCharges then
		local currentCharges, maxCharges, start, duration = GetSpellCharges(spellID)
		return currentCharges, maxCharges, start, duration
	end

	return nil
end

function DragonridingVigor.prototype:UsingOldVigorWidgets()
	return C_UIWidgetManager
		and C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo
		and C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(defaultVigorWidgetID) ~= nil
end

function DragonridingVigor.prototype:GetChargeSpell()
	-- Find a skyriding spell that exposes charges (shared-charge system will still report properly)
	for i = 1, #SKYRIDING_CHARGE_SPELL_IDS do
		local spellID = SKYRIDING_CHARGE_SPELL_IDS[i]
		local charges, maxCharges = SafeGetSpellCharges(spellID)
		if maxCharges and maxCharges > 0 then
			return spellID
		end
	end
	return nil
end

function DragonridingVigor.prototype:EnsureRuneCount(count)
	count = tonumber(count) or 0
	if count <= 0 then
		return
	end

	if self.numRunes == count and self.runeCoords then
		return
	end

	self.numRunes = count
	self.runeCoords = self.runeCoords or { }
	for i = 1, self.numRunes do
		self:SetupNewRune(i)
	end

	-- Some IceHUD classes redraw automatically; this is a safe poke if it exists
	if self.Redraw then
		self:Redraw()
	end
end

function DragonridingVigor.prototype:ShouldShowCharges()
	-- Show when the player is mounted AND the skyriding charge spell exists.
	-- (Avoid showing in cities/ground when not skyriding.)
	if not IsMounted or not IsMounted() then
		return false
	end

	local spellID = self:GetChargeSpell()
	if not spellID then
		return false
	end

	-- If the client provides gliding info, we can be stricter and only show when it reports skyriding/gliding.
	-- But different builds return different payloads, so we keep it permissive.
	return true
end

-- -------------------------
-- Core
-- -------------------------
function DragonridingVigor.prototype:init()
	DragonridingVigor.super.prototype.init(self, "Vigor")

	self:SetDefaultColor("VigorNumeric", 150, 150, 255)

	self.unit = "player"
	self.numericColor = "VigorNumeric"
	self.unitPower = unitPowerType
	self.minLevel = 0
	self.bTreatEmptyAsFull = false
	self.runeWidth = self.runeHeight
	self.shouldRegisterDisplayPower = false

	self.mode = "widget" -- "widget" (old) or "charges" (new)
	self.chargeSpellID = nil
end

function DragonridingVigor.prototype:Enable(core)
	-- Decide mode:
	-- In 11.2.7+ Blizzard removed Vigor and moved Skyriding to shared charges.
	-- Even if the old Vigor widget still exists, it may stay hidden (shownState=0),
	-- so we prefer charge mode on modern builds.
	local preferCharges = (BUILD_NUMBER and BUILD_NUMBER >= FORCE_CHARGES_BUILD) or (not self:UsingOldVigorWidgets())

	if preferCharges then
		self.mode = "charges"
		self.chargeSpellID = self:GetChargeSpell()
		local _, maxCharges = self.chargeSpellID and SafeGetSpellCharges(self.chargeSpellID) or nil
		self:EnsureRuneCount(maxCharges or 6)
	else
		self.mode = "widget"
		self.numRunes = UnitPowerMax(self.unit, unitPowerType) or 0
		self:EnsureRuneCount(self.numRunes)
	end

	DragonridingVigor.super.prototype.Enable(self, core)
	self:Show(false)

	-- Widget-driven show/hide + recharge (legacy)
	self:RegisterEvent("UNIT_AURA", "CheckShouldShow")
	self:RegisterEvent("UPDATE_UI_WIDGET", "UpdateVigorRecharge")

	-- Charge/power-driven updates (modern)
	self:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED", "CheckShouldShow")
	self:RegisterEvent("SPELL_UPDATE_CHARGES", "UpdateVigorRecharge")
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateVigorRecharge")
	self:RegisterEvent("UNIT_POWER_UPDATE", "UpdateRunePower")
	self:RegisterEvent("UNIT_POWER_FREQUENT", "UpdateRunePower")
end

function DragonridingVigor.prototype:EnteringWorld()
	DragonridingVigor.super.prototype.EnteringWorld(self)

	self:CheckShouldShow("PLAYER_ENTERING_WORLD", "player")
end

function DragonridingVigor.prototype:CheckShouldShow(event, unit, info)
	if unit and unit ~= "player" then
		return
	end

	-- Charges mode (11.2.7+)
	if self.mode == "charges" or not self:UsingOldVigorWidgets() then
		self.mode = "charges"
		self.chargeSpellID = self.chargeSpellID or self:GetChargeSpell()

		local show = self:ShouldShowCharges()
		self:Show(show)

		-- In charges mode we do NOT try to show/hide Blizzard's old widget frame
		self.suppressHideBlizz = true

		if show then
			self:UpdateVigorRecharge("internal")
		end

		return
	end

	-- Widget mode (pre-11.2.7)
	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:PopulateVigorWidgetIDs()
	end

	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:Show(false)
		return
	end

	local shown = false
	for i = 1, #vigorWidgetIDs do
		local wInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetIDs[i])
		if wInfo and wInfo.shownState ~= 0 then
			shown = true
			break
		end
	end

	if not shown then
		self:Show(false)
		self.suppressHideBlizz = true
		if self.moduleSettings.hideBlizz then
			self:ShowBlizz()
		end
		return
	end

	self:Show(true)
end

function DragonridingVigor.prototype:UpdateRunePower(event, arg1, arg2)
	self:UpdateVigorRecharge("internal")

	-- In charge mode, the base class still reads UnitPower/UnitPowerMax.
	-- We temporarily shim those APIs so IceClassPowerCounter renders spell charges as "power".
	if self.mode == "charges" and self.chargeSpellID then
		local charges, maxCharges, start, duration = SafeGetSpellCharges(self.chargeSpellID)
		if maxCharges and maxCharges > 0 then
			local origUnitPower, origUnitPowerMax = UnitPower, UnitPowerMax

			UnitPower = function(unit, powerType, ...)
				if unit == "player" and powerType == unitPowerType then
					return charges or 0
				end
				return origUnitPower(unit, powerType, ...)
			end

			UnitPowerMax = function(unit, powerType, ...)
				if unit == "player" and powerType == unitPowerType then
					return maxCharges or 0
				end
				return origUnitPowerMax(unit, powerType, ...)
			end

			local ok, err = pcall(function()
				DragonridingVigor.super.prototype.UpdateRunePower(self, event, arg1, arg2)
			end)

			UnitPower, UnitPowerMax = origUnitPower, origUnitPowerMax

			if not ok then
				error(err)
			end
			return
		end
	end

	DragonridingVigor.super.prototype.UpdateRunePower(self, event, arg1, arg2)
end

function DragonridingVigor.prototype:PopulateVigorWidgetIDs()
	if not C_UIWidgetManager or not C_UIWidgetManager.GetAllWidgetsBySetID then
		return
	end

	local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(vigorWidgetSetID)
	if not widgets then
		return
	end

	-- reset list each time; IDs can change between sessions
	vigorWidgetIDs = {}

	for i = 1, #widgets do
		if widgets[i].widgetType == vigorWidgetType then
			table.insert(vigorWidgetIDs, widgets[i].widgetID)
		end
	end
end

function DragonridingVigor.prototype:UpdateVigorRecharge(event, widget)
	-- Charges mode (11.2.7+)
	if self.mode == "charges" or not self:UsingOldVigorWidgets() then
		self.mode = "charges"
		self.chargeSpellID = self.chargeSpellID or self:GetChargeSpell()

		if not self.chargeSpellID then
			self:Show(false)
			return
		end

		local charges, maxCharges, start, duration = SafeGetSpellCharges(self.chargeSpellID)
		if not maxCharges or maxCharges == 0 then
			self:Show(false)
			return
		end

		self:EnsureRuneCount(maxCharges)

		-- Clear partial fill
		self.partialReady = nil
		self.partialReadyPercent = nil

		-- If not full, show partial progress for the NEXT charge being generated
		local full = charges or 0
		if duration and duration > 0 and start and start > 0 and full < maxCharges then
			local now = GetTime()
			local pct = (now - start) / duration
			pct = IceHUD:Clamp(pct, 0, 1)

			self.partialReady = IceHUD:Clamp(full + 1, 0, maxCharges)
			self.partialReadyPercent = pct
		end

		-- Update
		if event ~= "internal" then
			self:UpdateRunePower()
		end

		return
	end

	-- Widget mode (pre-11.2.7)
	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:PopulateVigorWidgetIDs()
	end
	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		return
	end

	self.partialReady = nil
	self.partialReadyPercent = nil
	if event ~= "internal" and (not widget or widget.widgetSetID ~= vigorWidgetSetID) then
		return
	end

	local widgetID = defaultVigorWidgetID
	if widget then
		widgetID = widget.widgetID
	end

	local wInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(widgetID)
	if not wInfo then
		return
	end

	self.suppressHideBlizz = not wInfo or wInfo.shownState == 0

	if event ~= "internal" then
		if self.moduleSettings.hideBlizz then
			self:HideBlizz()
		else
			self:ShowBlizz()
		end
	end

	if wInfo.numFullFrames == wInfo.numTotalFrames then
		return
	end
	if wInfo.fillMax == 0 then
		return
	end

	self.partialReady = IceHUD:Clamp(wInfo.numFullFrames + 1, 0, wInfo.numTotalFrames)
	self.partialReadyPercent = wInfo.fillValue / wInfo.fillMax
	if event ~= "internal" then
		self:UpdateRunePower()
	end
end

function DragonridingVigor.prototype:SetupNewRune(rune)
	self.runeCoords[rune] = {0, 1, 0, 1}
end

function DragonridingVigor.prototype:GetDefaultSettings()
	local defaults = DragonridingVigor.super.prototype.GetDefaultSettings(self)

	defaults.pulseWhenFull = false
	defaults.runeGap = 4
	defaults.inactiveDisplayMode = "Shown"
	defaults.hideBlizz = true
	defaults.vpos = -25

	return defaults
end

function DragonridingVigor.prototype:GetOptions()
	local opts = DragonridingVigor.super.prototype.GetOptions(self)

	opts.inactiveDisplayMode.hidden = function() return true end

	return opts
end

function DragonridingVigor.prototype:GetRuneAtlas(rune)
	return "dragonriding_vigor_fillfull"
end

function DragonridingVigor.prototype:GetShineAtlas(rune)
	return "Mage-ArcaneCharge-SmallSpark"
end

function DragonridingVigor.prototype:GetFrameAtlas(rune)
	return "dragonriding_vigor_frame"
end

function DragonridingVigor.prototype:GetBackgroundAtlas(rune)
	return "dragonriding_vigor_background"
end

function DragonridingVigor.prototype:GetPartialRuneAtlas(rune)
	return "dragonriding_vigor_fill"
end

function DragonridingVigor.prototype:ShowBlizz()
	-- Old widget frame only exists pre-11.2.7; guard heavily.
	if self.mode == "charges" then
		return
	end

	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:PopulateVigorWidgetIDs()
	end
	local testIDs = vigorWidgetIDs
	if not testIDs or #testIDs == 0 then
		testIDs = {defaultVigorWidgetID}
	end

	if not UIWidgetPowerBarContainerFrame or not UIWidgetPowerBarContainerFrame.widgetFrames then
		return
	end

	for i = 1, #testIDs do
		local wInfo = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(testIDs[i])
		if wInfo and wInfo.shownState ~= 0 then
			local frame = UIWidgetPowerBarContainerFrame.widgetFrames[testIDs[i]]
			if frame and frame.Show then
				frame:Show()
			end
			return
		end
	end
end

function DragonridingVigor.prototype:HideBlizz(fromConfig)
	if self.mode == "charges" then
		return
	end

	if self.suppressHideBlizz and not fromConfig then
		return
	end

	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:PopulateVigorWidgetIDs()
	end
	local testIDs = vigorWidgetIDs
	if not testIDs or #testIDs == 0 then
		testIDs = {defaultVigorWidgetID}
	end

	if not UIWidgetPowerBarContainerFrame or not UIWidgetPowerBarContainerFrame.widgetFrames then
		return
	end

	for i = 1, #testIDs do
		local frame = UIWidgetPowerBarContainerFrame.widgetFrames[testIDs[i]]
		if frame and frame.Hide then
			frame:Hide()
		end
	end
end

-- Load us up
-- Pre-11.2.7: requires UIWidget FillUpFrames
-- 11.2.7+: works via spell charges (GetSpellCharges / C_Spell.GetSpellCharges)
if unitPowerType then
	IceHUD.DragonridingVigor = DragonridingVigor:new()
end
