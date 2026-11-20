local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local FocusInfo = IceCore_CreateClass(IceTargetInfo)

-- Constructor --
function FocusInfo.prototype:init()
	FocusInfo.super.prototype.init(self, "FocusInfo", "focus")
end

function FocusInfo.prototype:GetDefaultSettings()
	local settings = FocusInfo.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["vpos"] = -200

	return settings
end

function FocusInfo.prototype:Enable(core)
	FocusInfo.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "TargetChanged")
end

-- Load us up
if FocusUnit then
	IceHUD.FocusInfo = FocusInfo:new()
end
