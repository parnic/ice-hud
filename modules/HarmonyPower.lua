local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local HarmonyPower = IceCore_CreateClass(IceClassPowerCounter)

local SPELL_POWER_CHI = SPELL_POWER_CHI
if Enum and Enum.PowerType then
	SPELL_POWER_CHI = Enum.PowerType.Chi
end

function HarmonyPower.prototype:init()
	HarmonyPower.super.prototype.init(self, "Chi")

	self:SetDefaultColor("ChiNumeric", 218, 231, 31)

	-- pulled from MonkHarmonyBar.xml in Blizzard's UI source
	self.runeCoords =
	{
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
		{0.00390625, 0.08593750, 0.71093750, 0.87500000},
	}
	self.numRunes = 4
	self.numericColor = "ChiNumeric"
	if IceHUD.WowVer >= 50100 then
		self.unitPower = SPELL_POWER_CHI
	else
		self.unitPower = SPELL_POWER_LIGHT_FORCE
	end
	if IceHUD.WowVer >= 70000 then
		self.requiredSpec = SPEC_MONK_WINDWALKER
	end
	self.minLevel = 0
	self.bTreatEmptyAsFull = true
	self.unit = "player"
	self.runeWidth = self.runeHeight
end

function HarmonyPower.prototype:Enable(core)
	HarmonyPower.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_POWER_FREQUENT", "UpdateRunePower")
end

function HarmonyPower.prototype:UpdateRunePower(event, arg1, arg2)
	if event == "UNIT_POWER_FREQUENT" and (arg1 ~= self.unit or (arg2 ~= "CHI" and arg2 ~= "LIGHT_FORCE" and arg2 ~= "DARK_FORCE")) then
		return
	end

	local numRunes = UnitPowerMax(self.unit, self.unitPower)
	-- totally invalid....right?
	if numRunes == 0 then
		return
	end

	if numRunes ~= self.numRunes then
		if numRunes < self.numRunes and #self.frame.graphical >= numRunes then
			for i=numRunes + 1, #self.frame.graphical do
				self.frame.graphical[i]:Hide()
			end
		end
		local oldNumRunes = self.numRunes
		self.numRunes = numRunes

		self:CreateRuneFrame()

		if oldNumRunes < self.numRunes and #self.frame.graphical >= self.numRunes then
			for i=oldNumRunes, self.numRunes do
				self.frame.graphical[i]:Show()
			end
		end

		local width = self.runeHeight
		if self.moduleSettings.runeMode == "Graphical" then
			width = self.runeWidth
		end
		self.frame:SetWidth(width*self.numRunes)
	end
	HarmonyPower.super.prototype.UpdateRunePower(self)
end

function HarmonyPower.prototype:GetOptions()
	local opts = HarmonyPower.super.prototype.GetOptions(self)

	opts.hideBlizz.desc = L["Hides Blizzard Harmony Power frame and disables all events related to it.\n\nNOTE: Blizzard attaches the harmony power UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."]

	return opts
end

function HarmonyPower.prototype:GetRuneTexture(rune)
	if not rune or rune ~= tonumber(rune) then
		return
	end
	return "Interface\\PlayerFrame\\MonkUI"
end

function HarmonyPower.prototype:ShowBlizz()
	local frame = MonkHarmonyBarFrame
	if frame == nil then
		frame = MonkHarmonyBar
	end

	frame:Show()
	frame:GetScript("OnLoad")(frame)
end

function HarmonyPower.prototype:HideBlizz()
	local frame = MonkHarmonyBarFrame
	if frame == nil then
		frame = MonkHarmonyBar
	end

	frame:Hide()
	frame:UnregisterAllEvents()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "MONK" and IceHUD.WowVer >= 50000) then
	IceHUD.HarmonyPower = HarmonyPower:new()
end
