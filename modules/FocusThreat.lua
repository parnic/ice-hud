local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local FocusThreat = IceCore_CreateClass(IceThreat)

-- constructor
function FocusThreat.prototype:init()
	FocusThreat.super.prototype.init(self, "FocusThreat", "focus")
end

function FocusThreat.prototype:GetDefaultSettings()
	local settings = FocusThreat.super.prototype.GetDefaultSettings(self)

	settings.side = IceCore.Side.Right
	settings.offset = 4
	settings.scale = 0.7
	settings.barVerticalOffset = 35

	return settings
end

-- Load us up
if FocusUnit then
	IceHUD.FocusThreat = FocusThreat:new()
end
