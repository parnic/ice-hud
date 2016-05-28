local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerAltMana = IceCore_CreateClass(IceUnitBar)

PlayerAltMana.prototype.PlayerAltMana = nil
PlayerAltMana.prototype.PlayerAltManaMax = nil

local _, unitClass = UnitClass("player")

-- Constructor --
function PlayerAltMana.prototype:init()
	PlayerAltMana.super.prototype.init(self, "PlayerAltMana", "player")

	self.side = IceCore.Side.Right
	self.offset = 0

	self:SetDefaultColor("PlayerAltMana", 87, 82, 141)
end

function PlayerAltMana.prototype:GetDefaultSettings()
	local settings = PlayerAltMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	settings["textVisible"] = {upper = true, lower = false}
	settings["upperText"] = "[PercentMana:Round]"
	settings["lowerText"] = "[FractionalMana:Color('3071bf'):Bracket]"

	return settings
end

function GetEventsToRegister()
	return {"UNIT_DISPLAYPOWER"}
--[[	if unitClass == "PRIEST" then
		return {"PLAYER_SPECIALIZATION_CHANGED"}
	elseif unitClass == "SHAMAN" then
		return {"PLAYER_SPECIALIZATION_CHANGED"}
	elseif unitClass == "DRUID" then
		return {"UPDATE_SHAPESHIFT_FORM"}
	end
]]-- probably not necessary, but could use as a fallback
end

function PlayerAltMana.prototype:Enable(core)
	PlayerAltMana.super.prototype.Enable(self, core)

	local eventsToRegister = GetEventsToRegister()
	for i = 1, #eventsToRegister do
		self:RegisterEvent(eventsToRegister[i], "Update")
	end
	self:RegisterEvent("UNIT_POWER_FREQUENT", "Update")
	self:RegisterEvent("UNIT_MAXPOWER", "Update")
end


function PlayerAltMana.prototype:Disable(core)
	PlayerAltMana.super.prototype.Disable(self, core)
end

function ShouldShow(unit)
	if unitClass == "MONK" then
		return GetSpecialization() == SPEC_MONK_MISTWEAVER
	end
	return UnitPowerType(unit) ~= SPELL_POWER_MANA
--[[	if unitClass == "PRIEST" then
		return UnitPowerType(unit) == SPELL_POWER_INSANITY
	elseif unitClass == "SHAMAN" then
		return GetSpecialization() ~= SPEC_SHAMAN_RESTORATION
	elseif unitClass == "DRUID" then
		return UnitPowerType(unit) ~= SPELL_POWER_MANA
	end
]]-- probably not necessary, but could use as a fallback
end

function PlayerAltMana.prototype:Update()
	PlayerAltMana.super.prototype.Update(self)

	self.PlayerAltMana = UnitPower(self.unit, SPELL_POWER_MANA)
	self.PlayerAltManaMax = UnitPowerMax(self.unit, SPELL_POWER_MANA)

	if (not self.alive or not ShouldShow(self.unit) or not self.PlayerAltMana or not self.PlayerAltManaMax or self.PlayerAltManaMax == 0) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.PlayerAltManaMax ~= 0 and self.PlayerAltMana / self.PlayerAltManaMax or 0, "PlayerAltMana")
end

if (unitClass == "PRIEST" and IceHUD.WowVer >= 70000)
	or (unitClass == "DRUID")
	or (unitClass == "SHAMAN" and IceHUD.WowVer >= 70000)
	or (unitClass == "MONK" and IceHUD.WowVer < 70000) then
	IceHUD.PlayerAltMana = PlayerAltMana:new()
end
