local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local DruidEnergy = IceCore_CreateClass(IceUnitBar)

DruidEnergy.prototype.DruidEnergy = nil
DruidEnergy.prototype.DruidEnergyMax = nil

local _, unitClass = UnitClass("player")

local FORM_NONE = 0
local FORM_BEAR = 1
local FORM_TRAVEL = 3

local SPELL_POWER_ENERGY = SPELL_POWER_ENERGY
if Enum and Enum.PowerType then
	SPELL_POWER_ENERGY = Enum.PowerType.Energy
end

local shapeshiftFormValues = {NONE = L["No form"], BEAR = L["Bear"], TRAVEL = L["Travel"], OTHER = L["Other"]}
local shapeshiftFormIds = {NONE = FORM_NONE, BEAR = FORM_BEAR, TRAVEL = FORM_TRAVEL}

function DruidEnergy.prototype:init()
	DruidEnergy.super.prototype.init(self, "DruidEnergy", "player")

	self.side = IceCore.Side.Left
	self.offset = 5

	self:SetDefaultColor("DruidEnergy", 218, 231, 31)
end

function DruidEnergy.prototype:GetDefaultSettings()
	local settings = DruidEnergy.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 5
	settings["textVisible"] = {upper = true, lower = false}
	settings["upperText"] = "[PercentMP(type='Energy'):Round]"
	settings["lowerText"] = "[FractionalMP(type='Energy'):Color('dae71f'):Bracket]"
	settings.enabled = false
	settings.whileInForm = {["BEAR"] = true}

	return settings
end

function DruidEnergy.prototype:GetOptions()
	local opts = DruidEnergy.super.prototype.GetOptions(self)

	opts["whileInForm"] = {
		type = 'multiselect',
		values = shapeshiftFormValues,
		name = L["Show in form"],
		desc = L["When the player is in one of the chosen shapeshift forms the bar will be shown, otherwise it will be hidden."],
		get = function(info, v)
			for key, value in pairs(self.moduleSettings.whileInForm) do
				if key == v then
					return value
				end
			end

			return false
		end,
		set = function(info, v, state)
			self.moduleSettings.whileInForm[v] = state
			self:Update()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	return opts
end

function DruidEnergy.prototype:Enable(core)
	DruidEnergy.super.prototype.Enable(self, core)

	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
	self:RegisterEvent("UNIT_POWER_FREQUENT", "Update")
	self:RegisterEvent("UNIT_MAXPOWER", "Update")
end

function DruidEnergy.prototype:GetElementDescription()
	return L["Always shows the Druid's Energy level while in non-energy-using forms."]
end


function DruidEnergy.prototype:ShouldShow(unit)
	local currentForm = GetShapeshiftForm()
	for k, v in pairs(self.moduleSettings.whileInForm) do
		if currentForm > FORM_TRAVEL and k == "OTHER" then
			return v
		elseif currentForm == shapeshiftFormIds[k] then
			return v
		end
	end

	return false
end

function DruidEnergy.prototype:Update()
	DruidEnergy.super.prototype.Update(self)

	self.DruidEnergy = UnitPower(self.unit, SPELL_POWER_ENERGY)
	self.DruidEnergyMax = UnitPowerMax(self.unit, SPELL_POWER_ENERGY)
	self.DruidEnergyPercentage = self.DruidEnergyMax ~= 0 and (self.DruidEnergy/self.DruidEnergyMax) or 0

	if (not self.alive or not self:ShouldShow(self.unit) or not self.DruidEnergy or not self.DruidEnergyMax or self.DruidEnergyMax == 0) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	if not IceHUD.IceCore:ShouldUseDogTags() and self.frame:IsVisible() then
		self:SetBottomText1(math.floor(self.DruidEnergyPercentage * 100))
		self:SetBottomText2(self:GetFormattedText(self:Round(self.DruidEnergy), self:Round(self.DruidEnergyMax)), "DruidEnergy")
	end

	self:UpdateBar(self.DruidEnergyMax ~= 0 and self.DruidEnergy / self.DruidEnergyMax or 0, "DruidEnergy")
end

if unitClass == "DRUID" then
	IceHUD.DruidEnergy = DruidEnergy:new()
end
