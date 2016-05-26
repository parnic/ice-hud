local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ShadowPriestMana = IceCore_CreateClass(IceUnitBar)

ShadowPriestMana.prototype.shadowPriestMana = nil
ShadowPriestMana.prototype.shadowPriestManaMax = nil

local MANA_POWER_INDEX = SPELL_POWER_MANA

-- Constructor --
function ShadowPriestMana.prototype:init()
	ShadowPriestMana.super.prototype.init(self, "ShadowPriestMana", "player")

	self.side = IceCore.Side.Right
	self.offset = 0

	self:SetDefaultColor("ShadowPriestMana", 87, 82, 141)
end


function ShadowPriestMana.prototype:GetDefaultSettings()
	local settings = ShadowPriestMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	settings["textVisible"] = {upper = true, lower = false}
	settings["upperText"] = "[PercentShadowPriestMP:Round]"
	settings["lowerText"] = "[FractionalShadowPriestMP:Color('3071bf'):Bracket]"

	return settings
end


function ShadowPriestMana.prototype:Enable(core)
	ShadowPriestMana.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_TALENT_UPDATE", "Update")
	self:RegisterEvent("UNIT_POWER", "Update")
	self:RegisterEvent("UNIT_MAXPOWER", "Update")
end


function ShadowPriestMana.prototype:Disable(core)
	ShadowPriestMana.super.prototype.Disable(self, core)
end


function ShadowPriestMana.prototype:Update()
	ShadowPriestMana.super.prototype.Update(self)

	local shadow = (UnitPowerType(self.unit) == SPELL_POWER_INSANITY)

	self.shadowPriestMana = UnitPower(self.unit, MANA_POWER_INDEX)
	self.shadowPriestManaMax = UnitPowerMax(self.unit, MANA_POWER_INDEX)

	if (not self.alive or not shadow or not self.shadowPriestMana or not self.shadowPriestManaMax or self.shadowPriestManaMax == 0) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.shadowPriestManaMax ~= 0 and self.shadowPriestMana / self.shadowPriestManaMax or 0, "ShadowPriestMana")
end

-- Load us up (if we are a priest in 7.0+)
local _, unitClass = UnitClass("player")
if (unitClass == "PRIEST" and IceHUD.WowVer >= 70000) then
	IceHUD.ShadowPriestMana = ShadowPriestMana:new()
end
