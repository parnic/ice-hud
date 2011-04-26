local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerAlternatePower = IceCore_CreateClass(IceUnitBar)

-- Constructor --
function PlayerAlternatePower.prototype:init(moduleName, unit)
	PlayerAlternatePower.super.prototype.init(self, "PlayerAlternatePower", "player")

	self.bTreatEmptyAsFull = true
	self.power = 0
	self.maxPower = 0
	self.powerPercent = 0
end

function PlayerAlternatePower.prototype:GetDefaultSettings()
	local settings = PlayerAlternatePower.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = -1
	settings["upperText"] = "[PercentAltP:Round]"
	settings["lowerText"] = "[FractionalAltP]"
	settings["hideBlizz"] = false

	return settings
end

function PlayerAlternatePower.prototype:Enable(core)
	PlayerAlternatePower.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_POWER", "UpdateEvent")
	self:RegisterEvent("UNIT_MAXPOWER", "UpdateEvent")
	self:RegisterEvent("UNIT_POWER_BAR_SHOW", "PowerBarShow")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE", "PowerBarHide")

	self:Update(self.unit)

	if self.maxPower == 0 then
		self:Show(false)
	end
	if self.moduleSettings.hideBlizz then
		self:HideBlizz()
	end
end

function PlayerAlternatePower.prototype:PowerBarShow(event, unit)
	if unit ~= self.unit then
		return
	end

	self:Show(true)
	self:Update(self.unit)
end

function PlayerAlternatePower.prototype:PowerBarHide(event, unit)
	if unit ~= self.unit then
		return
	end

	self:Show(false)
	self:Update(self.unit)
end

function PlayerAlternatePower.prototype:UpdateEvent(event, unit)
	self:Update(unit)
end

function PlayerAlternatePower.prototype:Update(unit)
	PlayerAlternatePower.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end

	self.maxPower = UnitPowerMax(self.unit, ALTERNATE_POWER_INDEX)
	self.power = UnitPower(self.unit, ALTERNATE_POWER_INDEX)
	if self.maxPower > 0 then
		self.powerPercent = self.power / self.maxPower
	else
		self.powerPercent = 0
	end

	self:UpdateBar(self.powerPercent)

	local texture, r, g, b = UnitAlternatePowerTextureInfo(self.unit, ALT_POWER_TEX_FILL)
	self.barFrame.bar:SetVertexColor(r, g, b, self.alpha)

	if not IceHUD.IceCore:ShouldUseDogTags() then
		self:SetBottomText1(math.floor(self.powerPercent * 100))
		self:SetBottomText2(self:GetFormattedText(self.power, self.maxPower), color)
	end
end

function PlayerAlternatePower.prototype:GetOptions()
	local opts = PlayerAlternatePower.super.prototype.GetOptions(self)

	opts["lowThresholdColor"] = nil

	opts["hideBlizz"] = {
		type = "toggle",
		name = L["Hide Blizzard Frame"],
		desc = L["Hides Blizzard Player frame and disables all events related to it"],
		get = function()
			return self.moduleSettings.hideBlizz
		end,
		set = function(info, value)
			self.moduleSettings.hideBlizz = value
			if value then
				self:HideBlizz()
			else
				self:ShowBlizz()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 51
	}

	return opts
end

function PlayerAlternatePower.prototype:ShowBlizz()
	PlayerPowerBarAlt:GetScript("OnLoad")(PlayerPowerBarAlt)
end

function PlayerAlternatePower.prototype:HideBlizz()
	PlayerPowerBarAlt:Hide()

	PlayerPowerBarAlt:UnregisterAllEvents()
end

-- Load us up
IceHUD.PlayerAlternatePower = PlayerAlternatePower:new()
