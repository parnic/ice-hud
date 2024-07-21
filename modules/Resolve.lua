local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Resolve = IceCore_CreateClass(IceUnitBar)

local RESOLVE_SPELL_ID = 158300
local RESOLVE_MAX = 240

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

Resolve.prototype.current = nil
Resolve.prototype.max = RESOLVE_MAX

-- constructor
function Resolve.prototype:init()
	Resolve.super.prototype.init(self, "Resolve", "player")

	self.current = 0
	self:SetDefaultColor("Resolve", 200, 45, 45)

	self.bTreatEmptyAsFull = true
end

-- default settings
function Resolve.prototype:GetDefaultSettings()
	local defaults = Resolve.super.prototype.GetDefaultSettings(self)
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
function Resolve.prototype:Enable(core)
	Resolve.super.prototype.Enable(self, core)

	-- Avoiding iteration where I can
	self:RegisterEvent("UNIT_AURA", "UpdateCurrent")

	self:Update()
end

-- disable plugin
function Resolve.prototype:Disable(core)
	Resolve.super.prototype.Disable(self, core)

	self:UnregisterAllEvents()
end

-- scan the tooltip and extract the Resolve value
do
	local spellName = GetSpellName(RESOLVE_SPELL_ID)

	function Resolve.prototype:UpdateCurrent(event, unit)
		if (unit and (unit ~= self.unit)) then
			return
		end

		if UnitAura then
			self.current = select(IceHUD.SpellFunctionsReturnRank and 15 or 14, UnitAura(self.unit, spellName)) or 0
		else
			local auraInfo = C_UnitAuras.GetAuraDataBySpellName(self.unit, spellName)
			self.current = auraInfo and auraInfo.timeMod or 0
		end

		self:Update()
	end
end

function Resolve.prototype:Update()
	Resolve.super.prototype.Update(self)

	if self.current == 0 then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.current / self.max, "Resolve")
	self:SetBottomText1(floor((self.current / self.max) * 100) .. "%")
	self:SetBottomText2(tostring(self.current) .."/"..tostring(self.max))
end

-- Load for tanks only
local _, unitClass = UnitClass("player")
if (unitClass == "DEATHKNIGHT" or unitClass == "DRUID" or unitClass == "PALADIN" or unitClass == "WARRIOR" or unitClass == "MONK")
	and GetSpellName(RESOLVE_SPELL_ID) then
  IceHUD.Resolve = Resolve:new()
end
