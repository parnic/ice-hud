local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local HolyPower = IceCore_CreateClass(IceClassPowerCounter)

function HolyPower.prototype:init()
	HolyPower.super.prototype.init(self, "HolyPower")

	self:SetDefaultColor("HolyPowerNumeric", 218, 231, 31)

	-- pulled from PaladinPowerBar.xml in Blizzard's UI source
	if IceHUD.WowVer >= 50000 then
		self.runeCoords =
		{
			{0.00390625, 0.14453125, 0.78906250, 0.96093750},
			{0.15234375, 0.27343750, 0.78906250, 0.92187500},
			{0.28125000, 0.38671875, 0.64843750, 0.81250000},
			{0.28125000, 0.38671875, 0.82812500, 0.92187500},
			{0.39453125, 0.49609375, 0.64843750, 0.74218750},
		}
	else
		self.runeCoords =
		{
			{0.00390625, 0.14453125, 0.64843750, 0.82031250},
			{0.00390625, 0.12500000, 0.83593750, 0.96875000},
			{0.15234375, 0.25781250, 0.64843750, 0.81250000},
		}
	end
	self.numericColor = "HolyPowerNumeric"
	self.unitPower = SPELL_POWER_HOLY_POWER
	self.minLevel = PALADINPOWERBAR_SHOW_LEVEL
	if IceHUD.WowVer >= 70000 then
		self.requiredSpec = SPEC_PALADIN_RETRIBUTION
	end
	self.bTreatEmptyAsFull = true
	self.unit = "player"
	self.numRunes = 5
	if IceHUD.WowVer >= 50000 then
		self.numConsideredFull = HOLY_POWER_FULL
	else
		self.numConsideredFull = 3
	end
end

function HolyPower.prototype:SetDisplayMode()
	local updated = false
	if self.moduleSettings.runeMode == "Graphical" then
		if self.runeHeight ~= 22 then
			self.runeHeight = 22
			updated = true
		end
	else
		if self.runeHeight ~= self.runeWidth then
			self.runeHeight = self.runeWidth
			updated = true
		end
	end

	if updated then
		self:CreateRuneFrame()
	end

	HolyPower.super.prototype.SetDisplayMode(self)
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
	local frame = PaladinPowerBarFrame
	if frame == nil then
		frame = PaladinPowerBar
	end

	frame:Show()
	frame:GetScript("OnLoad")(frame)
end

function HolyPower.prototype:HideBlizz()
	local frame = PaladinPowerBarFrame
	if frame == nil then
		frame = PaladinPowerBar
	end

	frame:Hide()
	frame:UnregisterAllEvents()
end

function HolyPower.prototype:UpdateRunePower(event)
	local numRunes = UnitPowerMax(self.unit, self.unitPower)
	if numRunes == 0 then
		return
	end

	if self.fakeNumRunes ~= nil and self.fakeNumRunes > 0 then
		numRunes = self.fakeNumRunes
	end

	if numRunes ~= self.numRunes then
		local oldNumRunes = self.numRunes
		if numRunes < self.numRunes and #self.frame.graphical >= numRunes then
			for i=numRunes + 1, #self.frame.graphical do
				self.frame.graphical[i]:Hide()
			end
		end
		self.numRunes = numRunes

		self:CreateRuneFrame()

		if numRunes > oldNumRunes then
			for i=oldNumRunes + 1, #self.frame.graphical do
				self.frame.graphical[i]:Show()
			end
		end
	end
	HolyPower.super.prototype.UpdateRunePower(self)
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "PALADIN" and IceHUD.WowVer >= 40000) then
	IceHUD.HolyPower = HolyPower:new()
end

