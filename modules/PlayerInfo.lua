local AceOO = AceLibrary("AceOO-2.0")
local PlayerInfo = AceOO.Class(IceTargetInfo)

-- Constructor --
function PlayerInfo.prototype:init()
	PlayerInfo.super.prototype.init(self, "PlayerInfo", "player")
end

function PlayerInfo.prototype:GetDefaultSettings()
	local settings = PlayerInfo.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["vpos"] = -100

	return settings
end

function PlayerInfo.prototype:CreateFrame(redraw)
	PlayerInfo.super.prototype.CreateFrame(self, redraw)

	self.frame.menu = function()
		ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor")
	end
end

function PlayerInfo.prototype:CreateIconFrames(parent, direction, buffs, type)
	local buffs = PlayerInfo.super.prototype.CreateIconFrames(self, parent, direction, buffs, type)

	for i = 1, IceCore.BuffLimit do
		if (self.moduleSettings.mouseBuff) then
			buffs[i]:SetScript("OnMouseUp", function( self, button)
				if( button == "RightButton" ) then CancelUnitBuff("player", i) end
			end)
		else
			buffs[i]:SetScript("OnMouseUp", nil)
		end
	end

	return buffs
end

-- Load us up
IceHUD.PlayerInfo = PlayerInfo:new()
