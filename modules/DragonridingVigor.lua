local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local DragonridingVigor = IceCore_CreateClass(IceClassPowerCounter)

local DragonridingBuffs = {
	360954, -- Highland Drake
	368896, -- Renewed Proto-Drake
	368899, -- Windborn Velocidrake
	368901, -- Cliffside Wylderdrake
	368893, -- Winding Slitherdrake
	412088, -- Grotto Netherwing Drake
}

local vigorWidgetSetID = 283
local vigorWidgetType = 24
local defaultVigorWidgetID = 4460
local vigorWidgetIDs = nil
local knowsAlternateMountEnum = Enum and Enum.PowerType and Enum.PowerType.AlternateMount
local unitPowerType = Enum and Enum.PowerType and Enum.PowerType.AlternateMount
unitPowerType = unitPowerType or ALTERNATE_POWER_INDEX

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
end

function DragonridingVigor.prototype:Enable(core)
	self.numRunes = UnitPowerMax(self.unit, unitPowerType)
	self.runeCoords = { }
	for i = 1, self.numRunes do
		self:SetupNewRune(i)
	end

	DragonridingVigor.super.prototype.Enable(self, core)
	self:Show(false)

	self:RegisterEvent("UNIT_AURA", "CheckShouldShow")
	self:RegisterEvent("UPDATE_UI_WIDGET", "UpdateVigorRecharge")
end

function DragonridingVigor.prototype:EnteringWorld()
	DragonridingVigor.super.prototype.EnteringWorld(self)

	self:CheckShouldShow("PLAYER_ENTERING_WORLD", "player")
end

function DragonridingVigor.prototype:CheckShouldShow(event, unit, info)
	if not vigorWidgetIDs or #vigorWidgetIDs == 0 then
		self:PopulateVigorWidgetIDs()
	end

	if unit ~= "player" or not vigorWidgetIDs then
		return
	end

	local shown = false
	for i=1,#vigorWidgetIDs do
		local info = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(vigorWidgetIDs[i])
		if info and info.shownState ~= 0 then
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

	-- if knowsAlternateMountEnum and UnitPowerMax(self.unit, unitPowerType) > 0 then
	-- 	self:Show(true)
	-- elseif not knowsAlternateMountEnum and IceHUD:HasAnyBuff("player", DragonridingBuffs) then
	-- 	self:Show(true)
	-- else
	-- 	self:Show(false)
	-- 	if self.moduleSettings.hideBlizz then
	-- 		self:ShowBlizz()
	-- 	end
	-- end
end

function DragonridingVigor.prototype:UpdateRunePower(event, arg1, arg2)
	self:UpdateVigorRecharge("internal")
	DragonridingVigor.super.prototype.UpdateRunePower(self, event, arg1, arg2)
end

function DragonridingVigor.prototype:PopulateVigorWidgetIDs()
	local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(vigorWidgetSetID)
	if not widgets then
		return
	end

	for i=1,#widgets do
		if widgets[i].widgetType == vigorWidgetType then
			if not vigorWidgetIDs then
				vigorWidgetIDs = {}
			end

			table.insert(vigorWidgetIDs, widgets[i].widgetID)
		end
	end
end

function DragonridingVigor.prototype:UpdateVigorRecharge(event, widget)
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

	local info = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(widgetID)
	if not info then
		return
	end

	self.suppressHideBlizz = not info or info.shownState == 0

	if event ~= "internal" then
		if self.moduleSettings.hideBlizz then
			self:HideBlizz()
		else
			self:ShowBlizz()
		end
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
	local info = C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo(defaultVigorWidgetID)
	if not info or info.shownState == 0 then
		return
	end
	UIWidgetPowerBarContainerFrame.widgetFrames[defaultVigorWidgetID]:Show()
end

function DragonridingVigor.prototype:HideBlizz()
	if not UIWidgetPowerBarContainerFrame.widgetFrames or not UIWidgetPowerBarContainerFrame.widgetFrames[defaultVigorWidgetID] then
		return
	end

	if not self.suppressHideBlizz then
		UIWidgetPowerBarContainerFrame.widgetFrames[defaultVigorWidgetID]:Hide()
	end
end

-- Load us up
if unitPowerType and C_UIWidgetManager and C_UIWidgetManager.GetFillUpFramesWidgetVisualizationInfo then
	IceHUD.DragonridingVigor = DragonridingVigor:new()
end
