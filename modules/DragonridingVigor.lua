local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local DragonridingVigor = IceCore_CreateClass(IceClassPowerCounter)

local DragonridingBuffs = {
	360954, -- Highland Drake
	368896, -- Renewed Proto-Drake
	368899, -- Windborn Velocidrake
	368901, -- Cliffside Wylderdrake
}

local vigorWidgetSetID = 283
local vigorWidgetID = 4460

function DragonridingVigor.prototype:init()
	DragonridingVigor.super.prototype.init(self, "Vigor")

	self:SetDefaultColor("VigorNumeric", 150, 150, 255)

	self.unit = "player"
	self.numericColor = "VigorNumeric"
	self.unitPower = ALTERNATE_POWER_INDEX
	self.minLevel = 0
	self.bTreatEmptyAsFull = false
	self.runeWidth = self.runeHeight
	self.shouldRegisterDisplayPower = false
end

function DragonridingVigor.prototype:Enable(core)
	self.numRunes = UnitPowerMax(self.unit, ALTERNATE_POWER_INDEX)
	self.runeCoords = { }
	for i = 1, self.numRunes do
		self:SetupNewRune(i)
	end

	DragonridingVigor.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "CheckShouldShow")
	self:RegisterEvent("UPDATE_UI_WIDGET", "UpdateVigorRecharge")
end

function DragonridingVigor.prototype:EnteringWorld()
	DragonridingVigor.super.prototype.EnteringWorld(self)

	self:CheckShouldShow("player")
end

function DragonridingVigor.prototype:CheckShouldShow(event, unit, info)
	if unit ~= "player" then
		return
	end

	if IceHUD:HasAnyBuff("player", DragonridingBuffs) then
		self:Show(true)
	else
		self:Show(false)
		if self.moduleSettings.hideBlizz then
			self:ShowBlizz()
		end
	end
end

function DragonridingVigor.prototype:UpdateRunePower(event, arg1, arg2)
	self:UpdateVigorRecharge("internal")
	DragonridingVigor.super.prototype.UpdateRunePower(self, event, arg1, arg2)
end

function DragonridingVigor.prototype:UpdateVigorRecharge(event, widget)
	self.partialReady = nil
	self.partialReadyPercent = nil
	if event ~= "internal" and (not widget or widget.widgetSetID ~= vigorWidgetSetID) then
		return
	end

	if event ~= "internal" then
		if self.moduleSettings.hideBlizz then
			self:HideBlizz()
		else
			self:ShowBlizz()
		end
	end

	local info = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetID)
	if not info then
		return
	end

	if info.numFullFrames == info.numTotalFrames then
		return
	end
	if info.fillMax == 0 then
		return
	end

	self.partialReady = IceHUD:Clamp(info.numFullFrames + 1, 0, info.numTotalFrames)
	self.partialReadyPercent = info.fillValue / info.fillMax
	if event ~= "internal" then
		self:UpdateRunePower()
	end
end

function DragonridingVigor.prototype:SetupNewRune(rune)
    self.runeCoords[rune] = {0, 1, 0, 1}
end

function DragonridingVigor.prototype:GetDefaultSettings()
	local defaults =  DragonridingVigor.super.prototype.GetDefaultSettings(self)

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
	UIWidgetPowerBarContainerFrame:Show()
end

function DragonridingVigor.prototype:HideBlizz()
	UIWidgetPowerBarContainerFrame:Hide()
end

-- Load us up
if ALTERNATE_POWER_INDEX and C_UIWidgetManager and C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo then
	IceHUD.DragonridingVigor = DragonridingVigor:new()
end
