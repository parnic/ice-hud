local FocusAbsorb = IceCore_CreateClass(IceTargetAbsorb)

-- Constructor --
function FocusAbsorb.prototype:init()
	FocusAbsorb.super.prototype.init(self, "FocusAbsorb", "focus", "FocusAbsorb")
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function FocusAbsorb.prototype:GetDefaultSettings()
	local settings = FocusAbsorb.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 6

	return settings
end

function FocusAbsorb.prototype:MyRegisterCustomEvents()
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "UpdateAbsorbAmount")
end

function FocusAbsorb.prototype:MyUnregisterCustomEvents()
	self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
end

-- Load us up
IceHUD.FocusAbsorb = FocusAbsorb:new()
