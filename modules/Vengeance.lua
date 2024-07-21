local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Vengeance = IceCore_CreateClass(IceUnitBar)

local VENGEANCE_SPELL_ID = 93098

local GetSpellInfo = GetSpellInfo
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
	GetSpellInfo = function(spellID)
		if not spellID then
			return nil
		end

		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo then
			return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
		end
	end
end

local GetSpellName = GetSpellInfo
if C_Spell and C_Spell.GetSpellName then
	GetSpellName = C_Spell.GetSpellName
end

Vengeance.prototype.current = nil
Vengeance.prototype.max = nil

-- constructor
function Vengeance.prototype:init()
	Vengeance.super.prototype.init(self, "Vengeance", "player")

	self.current = 0
	self:SetDefaultColor("Vengeance", 200, 45, 45)

	self.bTreatEmptyAsFull = true
end

-- default settings
function Vengeance.prototype:GetDefaultSettings()
	local defaults = Vengeance.super.prototype.GetDefaultSettings(self)
	defaults.enabled = false
	defaults.usesDogTagStrings = false
	defaults.lockUpperTextAlpha = false
	defaults.shouldAnimate = false
	defaults.hideAnimationSettings = true
	defaults.offset = 5
	defaults.side = IceCore.Side.Left
	return defaults
end

-- enable plugin
function Vengeance.prototype:Enable(core)
	Vengeance.super.prototype.Enable(self, core)

	-- Avoiding iteration where I can
	self:RegisterEvent("UNIT_AURA", "UpdateCurrent")
	self:RegisterEvent("UNIT_MAXHEALTH", "UpdateMax")

	self:UpdateMax()
end

-- disable plugin
function Vengeance.prototype:Disable(core)
	Vengeance.super.prototype.Disable(self, core)

	self:UnregisterAllEvents()
end

-- scan the tooltip and extract the vengeance value
do
	-- making these local as they're not used anywhere else
	local spellName = GetSpellName(VENGEANCE_SPELL_ID)

	function Vengeance.prototype:UpdateCurrent(event, unit)
		if (unit and (unit ~= self.unit)) then
			return
		end

		if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
			local data = C_UnitAuras.GetAuraDataBySpellName(self.unit, spellName)
			if data and data.points and #data.points > 0 then
				self.current = (data and data.points and #data.points > 0) and data.points[1] or 0
			end
		else
			local _, idx = IceHUD:GetBuffCount(self.unit, spellName, true, true)
			if idx then
				self.current = select(17, IceHUD.UnitAura(self.unit, idx))
			else
				self.current = 0
			end
		end

		self:Update()
	end
end

function Vengeance.prototype:UpdateMax(event, unit)
	if (unit and (unit ~= self.unit)) then
		return
	end

	local Stam, MaxHealth = UnitStat(self.unit, 3), UnitHealthMax(self.unit)
	self.max = floor(Stam + (MaxHealth - ((Stam - 19) * 14) - 6) / 10)
	self:Update()
end

function Vengeance.prototype:Update()
	Vengeance.super.prototype.Update(self)

	if self.current == 0 then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.current / self.max, "Vengeance")
	self:SetBottomText1(floor((self.current / self.max) * 100) .. "%")
	self:SetBottomText2(tostring(self.current) .."/"..tostring(self.max))
end

-- Load for tanks only
local _, unitClass = UnitClass("player")
if ((unitClass == "DEATHKNIGHT" or unitClass == "DRUID" or unitClass == "PALADIN" or unitClass == "WARRIOR" or unitClass == "MONK")
	and IceHUD.WowVer >= 40000 and IceHUD.WowVer < 60000) then
  IceHUD.Vengeance = Vengeance:new()
end
