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
	settings["hideBlizz"] = false

	return settings
end

function PlayerInfo.prototype:GetOptions()
	local opts = PlayerInfo.super.prototype.GetOptions(self)

	opts["hideBlizz"] = {
		type = "toggle",
		name = "Hide Blizzard Buff Frame",
		desc = "Hides Blizzard buffs frame and disables all events related to it",
		get = function()
			return self.moduleSettings.hideBlizz
		end,
		set = function(value)
			self.moduleSettings.hideBlizz = value
			if (value) then
				self:HideBlizz()
			else
				self:ShowBlizz()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 41
	}

	return opts
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

function PlayerInfo.prototype:Enable(core)
	PlayerInfo.super.prototype.Enable(self, core)

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function PlayerInfo.prototype:ShowBlizz()
	BuffFrame:Show()

	BuffFrame:RegisterEvent("UNIT_AURA");
end


function PlayerInfo.prototype:HideBlizz()
	BuffFrame:Hide()

	BuffFrame:UnregisterAllEvents()
end

-- Load us up
IceHUD.PlayerInfo = PlayerInfo:new()
