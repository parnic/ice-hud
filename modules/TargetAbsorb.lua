IceTargetAbsorb = IceCore_CreateClass(IceUnitBar)

IceTargetAbsorb.prototype.highestAbsorbSinceLastZero = 0
IceTargetAbsorb.prototype.ColorName = "TargetAbsorb"

local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
if IceHUD.WowVer < 50200 then
	UnitGetTotalAbsorbs = nil
end

-- Constructor --
function IceTargetAbsorb.prototype:init(moduleName, unit, colorName)
	-- not sure if this is necessary...i think it is...this way, we can instantiate this bar on its own or as a parent class
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
	settings["upperText"] = "[TotalAbsorb]"

	return settings
end

-- OVERRIDE
function IceTargetAbsorb.prototype:Enable(core)
	IceTargetAbsorb.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", "UpdateAbsorbAmount")
	self:MyRegisterCustomEvents()

	self:UpdateAbsorbAmount("UNIT_ABSORB_AMOUNT_CHANGED", self.unit)

	self:Show(false)
end

function IceTargetAbsorb.prototype:MyRegisterCustomEvents()
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateAbsorbAmount")
end

function IceTargetAbsorb.prototype:MyUnregisterCustomEvents()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
end

function IceTargetAbsorb.prototype:UpdateAbsorbAmount(event, unit)
	if UnitGetTotalAbsorbs == nil or (event == "UNIT_ABSORB_AMOUNT_CHANGED" and unit ~= self.unit) then
		return
	end

	local absorbAmount = UnitGetTotalAbsorbs(self.unit)

	if absorbAmount == nil or absorbAmount <= 0 then
		self.highestAbsorbSinceLastZero = 0
	elseif absorbAmount > self.highestAbsorbSinceLastZero then
		self.highestAbsorbSinceLastZero = absorbAmount
	end

	if absorbAmount == nil or absorbAmount <= 0 or self.highestAbsorbSinceLastZero <= 0 then
		self:Show(false)
	else
		self:Show(true)
		self:UpdateBar(absorbAmount / self.highestAbsorbSinceLastZero, self.ColorName)
	end
end

function IceTargetAbsorb.prototype:Disable(core)
	IceTargetAbsorb.super.prototype.Disable(self, core)

	self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED")
	self:MyUnregisterCustomEvents()
end

IceHUD.TargetAbsorb = IceTargetAbsorb:new()
