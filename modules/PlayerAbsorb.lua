local PlayerAbsorb = IceCore_CreateClass(IceTargetAbsorb)

-- Constructor --
function PlayerAbsorb.prototype:init()
	PlayerAbsorb.super.prototype.init(self, "PlayerAbsorb", "player", "PlayerAbsorb")
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function PlayerAbsorb.prototype:GetDefaultSettings()
	local settings = PlayerAbsorb.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3

	return settings
end

function PlayerAbsorb.prototype:MyRegisterCustomEvents()
end

function PlayerAbsorb.prototype:MyUnregisterCustomEvents()
end

-- Load us up
IceHUD.PlayerAbsorb = PlayerAbsorb:new()
