local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PetInfo = IceCore_CreateClass(IceTargetInfo)

-- Constructor --
function PetInfo.prototype:init()
	PetInfo.super.prototype.init(self, "PetInfo", "pet")
end

function PetInfo.prototype:GetDefaultSettings()
	local settings = PetInfo.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["vpos"] = -150
	settings["line2Tag"] = "[Level:DifficultyColor] [SmartRace:ClassColor] [PvPIcon] [InCombat ? 'Combat':Red]"

	return settings
end

function PetInfo.prototype:Enable(core)
	PetInfo.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_PET", "PetChanged")
end

function PetInfo.prototype:PetChanged(event, unit)
	if unit == "player" then
		self:TargetChanged()
	end
end

-- Load us up
IceHUD.PetInfo = PetInfo:new()
