local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local EssencePower = IceCore_CreateClass(IceClassPowerCounter)

local SPELL_POWER_ESSENCE = SPELL_POWER_ESSENCE
if Enum and Enum.PowerType then
	SPELL_POWER_ESSENCE = Enum.PowerType.Essence
end

function EssencePower.prototype:init()
	EssencePower.super.prototype.init(self, "EssencePower")

	self:SetDefaultColor("EssencePowerNumeric", 150, 150, 255)

	self.unit = "player"
	self.numericColor = "EssencePowerNumeric"
	self.unitPower = SPELL_POWER_ESSENCE
	self.minLevel = 0
	self.bTreatEmptyAsFull = false
	self.runeWidth = self.runeHeight
end

function EssencePower.prototype:Enable(core)
	self.numRunes = UnitPowerMax(self.unit, SPELL_POWER_ESSENCE)
	self.runeCoords = { }
	for i = 1, self.numRunes do
		self:SetupNewRune(i)
	end

	EssencePower.super.prototype.Enable(self, core)
end

function EssencePower.prototype:SetupNewRune(rune)
    self.runeCoords[rune] = {0, 1, 0, 1}
end

function EssencePower.prototype:GetPowerEvent()
	return "UNIT_POWER_FREQUENT"
end

function EssencePower.prototype:GetDefaultSettings()
	local defaults =  EssencePower.super.prototype.GetDefaultSettings(self)

	defaults["pulseWhenFull"] = false

	return defaults
end

function EssencePower.prototype:GetOptions()
	local opts = EssencePower.super.prototype.GetOptions(self)

	opts.hideBlizz.hidden = function() return true end

	return opts
end

function EssencePower.prototype:GetRuneAtlas(rune)
	return "UF-Essence-Icon"
end

function EssencePower.prototype:GetShineAtlas(rune)
	return "Mage-ArcaneCharge-SmallSpark"
end

function EssencePower.prototype:ShowBlizz()
end

function EssencePower.prototype:HideBlizz()
end

-- Load us up
local _, unitClass = UnitClass("player")
if unitClass == "EVOKER" then
	IceHUD.EssencePower = EssencePower:new()
end
