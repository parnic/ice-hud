local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ComboPointsBar = IceCore_CreateClass(IceBarElement)

local SPELL_POWER_COMBO_POINTS = SPELL_POWER_COMBO_POINTS
if Enum and Enum.PowerType then
	SPELL_POWER_COMBO_POINTS = Enum.PowerType.ComboPoints
end

function ComboPointsBar.prototype:init()
	ComboPointsBar.super.prototype.init(self, "ComboPointsBar")

	self:SetDefaultColor("ComboPointsBarMin", 1, 1, 0)
	self:SetDefaultColor("ComboPointsBarMax", 0, 1, 0)

	self.bTreatEmptyAsFull = true
end

function ComboPointsBar.prototype:GetOptions()
	local opts = ComboPointsBar.super.prototype.GetOptions(self)

	opts["alwaysDisplay"] = {
		type = "toggle",
		name = L["Always display bar"],
		desc = L["Whether this bar should hide when the player has 0 combo points or stay visible"],
		get = function()
			return self.moduleSettings.alwaysDisplay
		end,
		set = function(info, v)
			self.moduleSettings.alwaysDisplay = v
			self:UpdateComboPoints()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["bShowWithNoTarget"] =
	{
		type = 'toggle',
		name = L["Show with no target"],
		desc = L["Whether or not to display when you have no target selected but have combo points available"],
		get = function()
			return self.moduleSettings.bShowWithNoTarget
		end,
		set = function(info, v)
			self.moduleSettings.bShowWithNoTarget = v
			self:UpdateComboPoints()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	return opts
end

function ComboPointsBar.prototype:GetDefaultSettings()
	local defaults =  ComboPointsBar.super.prototype.GetDefaultSettings(self)
	defaults.offset = 8
	defaults.enabled = false
	defaults.alwaysDisplay = false
	defaults.desiredLerpTime = 0.05
	defaults.bShowWithNoTarget = true
	return defaults
end

function ComboPointsBar.prototype:Enable(core)
	ComboPointsBar.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateComboPoints")
	if not IceHUD.EventExistsPlayerComboPoints then
		if IceHUD.EventExistsUnitComboPoints then
			self:RegisterEvent("UNIT_COMBO_POINTS", "UpdateComboPoints")
		else
			self:RegisterEvent(IceHUD.UnitPowerEvent, "UpdateComboPoints")
		end
		if UnitHasVehicleUI then
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", "UpdateComboPoints")
			self:RegisterEvent("UNIT_EXITED_VEHICLE", "UpdateComboPoints")
		end
	else
		self:RegisterEvent("PLAYER_COMBO_POINTS", "UpdateComboPoints")
	end

	if GetUnitChargedPowerPoints then
		self:RegisterEvent("UNIT_POWER_POINT_CHARGE", "UpdateChargedComboPoints")
	end

	self:UpdateChargedComboPoints()
end

function ComboPointsBar.prototype:UpdateChargedComboPoints()
	if GetUnitChargedPowerPoints then
		local chargedPowerPoints = GetUnitChargedPowerPoints("player")
		self.chargedPowerPointIndex = chargedPowerPoints and chargedPowerPoints[1]
		self:UpdateComboPoints()
	end
end

function ComboPointsBar.prototype:CreateFrame()
	ComboPointsBar.super.prototype.CreateFrame(self)

	self:UpdateComboPoints()
end

local color = {}

function ComboPointsBar.prototype:UpdateComboPoints(...)
	if select('#', ...) >= 3 and select(1, ...) == IceHUD.UnitPowerEvent and select(3, ...) ~= "COMBO_POINTS" then
		return
	end

	local points
	if IceHUD.IceCore:IsInConfigMode() then
		points = UnitPowerMax("player", SPELL_POWER_COMBO_POINTS)
	elseif UnitHasVehicleUI then
		-- Parnic: apparently some fights have combo points while the player is in a vehicle?
		local isInVehicle = UnitHasVehicleUI and UnitHasVehicleUI("player")
		local checkUnit = isInVehicle and "vehicle" or "player"
		if IceHUD.PerTargetComboPoints then
			points = GetComboPoints(checkUnit, "target")
		else
			points = UnitPower(checkUnit, SPELL_POWER_COMBO_POINTS)
		end
	else
		points = GetComboPoints("target")
	end

	if (points == 0) then
		points = nil
	end

	if points == nil or points == 0 or (not UnitExists("target") and not self.moduleSettings.bShowWithNoTarget) then
		self:Show(self.moduleSettings.alwaysDisplay)
		self:UpdateBar(0, "undef")
	else
		self:Show(true)
		self:SetScaledColor(color, (points - 1) / 4.0, self.settings.colors["ComboPointsBarMax"], self.settings.colors["ComboPointsBarMin"])
		self:UpdateBar(points / UnitPowerMax("player", SPELL_POWER_COMBO_POINTS), "undef")
		self.barFrame.bar:SetVertexColor(color.r, color.g, color.b, self.alpha)
	end

	self:SetBottomText1(points or "0")
	self:SetBottomText2(self.chargedPowerPointIndex)
end

function ComboPointsBar.prototype:Update()
	self:UpdateComboPoints()
end

local _, class = UnitClass("player")
if (not IceHUD.WowClassic and not IceHUD.WowClassicBC) or class == "ROGUE" or class == "DRUID" then
	IceHUD.ComboPointsBar = ComboPointsBar:new()
end
