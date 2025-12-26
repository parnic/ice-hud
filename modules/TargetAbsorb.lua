local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceTargetAbsorb = IceCore_CreateClass(IceUnitBar)

IceTargetAbsorb.prototype.highestAbsorbSinceLastZero = 0
IceTargetAbsorb.prototype.ColorName = "TargetAbsorb"

local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs

function IceTargetAbsorb.prototype:init(moduleName, unit, colorName)
	if moduleName == nil or unit == nil then
		IceTargetAbsorb.super.prototype.init(self, "TargetAbsorb", "target")
	else
		IceTargetAbsorb.super.prototype.init(self, moduleName, unit)
	end

	if colorName ~= nil then
		self.ColorName = colorName
	end

	self:SetDefaultColor(self.ColorName, 0.99, 0.99, 0.99)
end

function IceTargetAbsorb.prototype:GetDefaultSettings()
	local settings = IceTargetAbsorb.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 3
	settings["upperText"] = "[TotalAbsorb:VeryShort]"

	return settings
end

function IceTargetAbsorb.prototype:GetOptions()
	local opts = IceTargetAbsorb.super.prototype.GetOptions(self)

	opts["scaleToUnitHealth"] = {
		type = 'toggle',
		name = L["Scale to health"],
		desc = L["Whether the bar's maximum value should be set to the unit's maximum health or not. If set, any absorb above that amount will not be shown."],
		get = function()
			return self.moduleSettings.scaleToUnitHealth
		end,
		set = function(info, v)
			self.moduleSettings.scaleToUnitHealth = v
			self:Update()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	return opts
end

function IceTargetAbsorb.prototype:Enable(core)
	IceTargetAbsorb.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", "UpdateAbsorbAmount")
	self:MyRegisterCustomEvents()

	self:UpdateAbsorbAmount()

	self:Show(false)
end

function IceTargetAbsorb.prototype:MyRegisterCustomEvents()
end

function IceTargetAbsorb.prototype:MyUnregisterCustomEvents()
end

function IceTargetAbsorb.prototype:Update()
	IceTargetAbsorb.super.prototype.Update(self)
	self:UpdateAbsorbAmount()
end

function IceTargetAbsorb.prototype:UpdateAbsorbAmount(event, unit)
	if event == "UNIT_ABSORB_AMOUNT_CHANGED" and unit ~= self.unit then
		return
	end

	local absorbAmount = UnitGetTotalAbsorbs(self.unit) or 0

	if absorbAmount <= 0 then
		self.highestAbsorbSinceLastZero = 0
	elseif absorbAmount > self.highestAbsorbSinceLastZero then
		self.highestAbsorbSinceLastZero = absorbAmount
	end

	local maxAbsorb = self.highestAbsorbSinceLastZero
	if self.moduleSettings.scaleToUnitHealth then
		maxAbsorb = self.maxHealth
	end
	self.absorbPercent = maxAbsorb ~= 0 and IceHUD:Clamp(absorbAmount / maxAbsorb, 0, 1) or 0

	if absorbAmount <= 0 or maxAbsorb <= 0 then
		self:Show(false)
	else
		self:Show(true)
		self:UpdateBar(self.absorbPercent, self.ColorName)
	end

	if not IceHUD.IceCore:ShouldUseDogTags() and self.frame:IsVisible() then
		if (self.PlayerAltManaMax ~= 100) then
			self:SetBottomText1(self:GetFormattedText(self:Round(absorbAmount)), self.ColorName)
		else
			self:SetBottomText1()
		end
	end
end

function IceTargetAbsorb.prototype:Disable(core)
	IceTargetAbsorb.super.prototype.Disable(self, core)

	self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	self:MyUnregisterCustomEvents()
end

if UnitGetTotalAbsorbs ~= nil and not IceHUD.IsSecretEnv() then
	IceHUD.TargetAbsorb = IceTargetAbsorb:new()
end
