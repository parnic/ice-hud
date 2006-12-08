local AceOO = AceLibrary("AceOO-2.0")

local TargetCast = AceOO.Class(IceCastBar)

-- Constructor --
function TargetCast.prototype:init()
	TargetCast.super.prototype.init(self, "TargetCast")

	self.unit = "target"
end


-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetCast.prototype:GetDefaultSettings()
	local settings = TargetCast.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 3
	settings["flashInstants"] = "Never"
	settings["flashFailures"] = "Never"
	return settings
end


-- OVERRIDE
function TargetCast.prototype:Enable(core)
	TargetCast.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
end


function TargetCast.prototype:TargetChanged(unit)
	if not (UnitExists(self.unit)) then
		self:StopBar()
		return
	end
	
	local spell = UnitCastingInfo(self.unit)
	if (spell) then
		self:StartBar(IceCastBar.Actions.Cast)
		return
	end
	
	local channel = UnitChannelInfo(self.unit)
	if (channel) then
		self:StartBar(IceCastBar.Actions.Channel)
		return
	end
	
	self:StopBar()
end

-------------------------------------------------------------------------------


-- Load us up
TargetCast:new()
