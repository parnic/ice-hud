local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ArcaneCharges = IceCore_CreateClass(IceClassPowerCounter)

function ArcaneCharges.prototype:init()
	ArcaneCharges.super.prototype.init(self, "ArcaneCharges")

	self:SetDefaultColor("ArcaneChargesNumeric", 150, 150, 255)

	self.unit = "player"
	self.numericColor = "ArcaneChargesNumeric"
	self.unitPower = SPELL_POWER_ARCANE_CHARGES
	self.minLevel = 0
	self.bTreatEmptyAsFull = true
	self.runeWidth = self.runeHeight
	self.requiredSpec = SPEC_MAGE_ARCANE
end

function ArcaneCharges.prototype:Enable(core)
	self.numRunes = UnitPowerMax(self.unit, SPELL_POWER_ARCANE_CHARGES)
	self.runeCoords = { }
	for i = 1, self.numRunes do
		self.runeCoords[#self.runeCoords + 1] = {0, 1, 0, 1}
	end

	ArcaneCharges.super.prototype.Enable(self, core)

end

function ArcaneCharges.prototype:GetOptions()
	local opts = ArcaneCharges.super.prototype.GetOptions(self)

	opts.hideBlizz.desc = L["Hides Blizzard Arcane Charges frame and disables all events related to it.\n\nNOTE: Blizzard attaches the arcane charges UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."]

	return opts
end

function ArcaneCharges.prototype:GetRuneAtlas(rune)
	return "Mage-ArcaneCharge"
end

function ArcaneCharges.prototype:GetShineAtlas(rune)
	return "Mage-ArcaneCharge-SmallSpark"
end

function ArcaneCharges.prototype:ShowBlizz()
	MageArcaneChargesFrame:Show()

	MageArcaneChargesFrame:GetScript("OnLoad")(MageArcaneChargesFrame)
end

function ArcaneCharges.prototype:HideBlizz()
	MageArcaneChargesFrame:Hide()

	MageArcaneChargesFrame:UnregisterAllEvents()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "MAGE" and IceHUD.WowVer >= 70000) then
	IceHUD.ArcaneCharges = ArcaneCharges:new()
end
