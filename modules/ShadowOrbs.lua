local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ShadowOrbs = IceCore_CreateClass(IceClassPowerCounter)

function ShadowOrbs.prototype:init()
	ShadowOrbs.super.prototype.init(self, "ShadowOrbs")

	self:SetDefaultColor("ShadowOrbsNumeric", 218, 231, 31)

	-- pulled from PriestBar.xml in Blizzard's UI source
	self.runeCoords =
	{
		{0.45703125, 0.60546875, 0.44531250, 0.73437500},
		{0.45703125, 0.60546875, 0.44531250, 0.73437500},
		{0.45703125, 0.60546875, 0.44531250, 0.73437500},
	}
	self.numericColor = "ShadowOrbsNumeric"
	self.unitPower = SPELL_POWER_SHADOW_ORBS
	self.minLevel = SHADOW_ORBS_SHOW_LEVEL
	self.bTreatEmptyAsFull = true
	self.unit = "player"
	self.numConsideredFull = PRIEST_BAR_NUM_ORBS
	self.runeHeight = 36
	self.runeWidth = 36
	self.requiredSpec = SPEC_PRIEST_SHADOW
end

function ShadowOrbs.prototype:GetOptions()
	local opts = ShadowOrbs.super.prototype.GetOptions(self)

	opts.hideBlizz.desc = L["Hides Blizzard Shadow Orb frame and disables all events related to it.\n\nNOTE: Blizzard attaches the shadow orb UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."]

	return opts
end

function ShadowOrbs.prototype:GetRuneTexture(rune)
	if not rune or rune ~= tonumber(rune) then
		return
	end
	return "Interface\\PlayerFrame\\Priest-ShadowUI"
end

function ShadowOrbs.prototype:ShowBlizz()
	PriestBarFrame:Show()

	PriestBarFrame:GetScript("OnLoad")(PriestBarFrame)
end

function ShadowOrbs.prototype:HideBlizz()
	PriestBarFrame:Hide()

	PriestBarFrame:UnregisterAllEvents()
end

function ShadowOrbs.prototype:UpdateRunePower()
	local numRunes = UnitPowerMax(self.unit, self.unitPower)

	if self.fakeNumRunes ~= nil and self.fakeNumRunes > 0 then
		numRunes = self.fakeNumRunes
	end

	if numRunes ~= self.numRunes then
		if numRunes < self.numRunes and #self.frame.graphical >= numRunes then
			for i=numRunes + 1, #self.frame.graphical do
				self.frame.graphical[i]:Hide()
			end
		end
		self.numRunes = numRunes

		self:CreateRuneFrame()
	end
	ShadowOrbs.super.prototype.UpdateRunePower(self)
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "PRIEST" and IceHUD.WowVer >= 50000) then
	IceHUD.ShadowOrbs = ShadowOrbs:new()
end

