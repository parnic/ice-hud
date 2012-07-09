local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local HolyPower = IceCore_CreateClass(IceClassPowerCounter)

function HolyPower.prototype:init()
	HolyPower.super.prototype.init(self, "HolyPower")

	self:SetDefaultColor("HolyPowerNumeric", 218, 231, 31)

	-- pulled from PaladinPowerBar.xml in Blizzard's UI source
	self.runeCoords =
	{
		{0.00390625, 0.14453125, 0.78906250, 0.96093750},
		{0.15234375, 0.27343750, 0.78906250, 0.92187500},
		{0.28125000, 0.38671875, 0.64843750, 0.81250000},
		{0.28125000, 0.38671875, 0.82812500, 0.92187500},
		{0.39453125, 0.49609375, 0.64843750, 0.74218750},
	}
	self.numericColor = "HolyPowerNumeric"
	self.unitPower = SPELL_POWER_HOLY_POWER
	self.minLevel = PALADINPOWERBAR_SHOW_LEVEL
	self.bTreatEmptyAsFull = true
	self.unit = "player"
	self.numConsideredFull = HOLY_POWER_FULL
end

function HolyPower.prototype:GetOptions()
	local opts = HolyPower.super.prototype.GetOptions(self)

	opts.hideBlizz.desc = L["Hides Blizzard Holy Power frame and disables all events related to it.\n\nNOTE: Blizzard attaches the holy power UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."]

	return opts
end

function HolyPower.prototype:GetRuneTexture(rune)
	if not rune or rune ~= tonumber(rune) then
		return
	end
	--return "Paladin-Rune0"..rune..".png"
	return "Interface\\PlayerFrame\\PaladinPowerTextures"
end

function HolyPower.prototype:ShowBlizz()
	PaladinPowerBar:Show()

	PaladinPowerBar:GetScript("OnLoad")(PaladinPowerBar)
end

function HolyPower.prototype:HideBlizz()
	PaladinPowerBar:Hide()

	PaladinPowerBar:UnregisterAllEvents()
end

function HolyPower.prototype:UpdateRunePower()
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
	HolyPower.super.prototype.UpdateRunePower(self)
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "PALADIN" and IceHUD.WowVer >= 40000) then
	IceHUD.HolyPower = HolyPower:new()
end

