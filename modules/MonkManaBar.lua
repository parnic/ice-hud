local MonkManaBar = IceCore_CreateClass(IceHUDPlayerAlternatePower)

function MonkManaBar.prototype:init(moduleName, unit)
	MonkManaBar.super.prototype.init(self, "MonkMana", unit)

	self.bTreatEmptyAsFull = false
end

function MonkManaBar.prototype:GetDefaultSettings()
	local settings = MonkManaBar.super.prototype.GetDefaultSettings(self)

	settings["upperText"] = "[PercentMonkMP:Round]"
	settings["lowerText"] = "[Concatenate(MonkMP:Short, \"/\", MaxMonkMP:Short):Bracket]"

	return settings
end

function MonkManaBar.prototype:GetOptions()
	local opts = MonkManaBar.super.prototype.GetOptions(self)

	opts.showBlizz = nil
	opts.hideBlizz = nil

	return opts
end

function MonkManaBar.prototype:Enable(core)
	self.specRestriction = SPEC_MONK_MISTWEAVER
	self.powerIndex = SPELL_POWER_MANA
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "CheckShouldShowOnSpecChange")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "CheckShouldShowOnSpecChange")

	MonkManaBar.super.prototype.Enable(self, core)

	self:CheckShouldShowOnSpecChange(nil, self.unit)
end

function MonkManaBar.prototype:CheckShouldShowOnSpecChange(event, unit)
	if unit ~= self.unit and event ~= "PLAYER_SPECIALIZATION_CHANGED" then
		return
	end

	if GetSpecialization() == self.specRestriction then
		self:PowerBarShow(event, self.unit)
	else
		self:PowerBarHide(event, self.unit)
	end
end

-- Load us up
if select(2, UnitClass("player")) == "MONK" then
	IceHUD.MonkManaBar = MonkManaBar:new()
end
