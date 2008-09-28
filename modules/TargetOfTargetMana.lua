local AceOO = AceLibrary("AceOO-2.0")

local TargetTargetMana = AceOO.Class(IceTargetMana)

-- Constructor --
function TargetTargetMana.prototype:init()
	TargetTargetMana.super.prototype.init(self, "TargetTargetMana", "targettarget")

	self:SetDefaultColor("TargetTargetMana", 52, 64, 221)
	self:SetDefaultColor("TargetTargetRage", 235, 44, 26)
	self:SetDefaultColor("TargetTargetEnergy", 228, 242, 31)
	self:SetDefaultColor("TargetTargetFocus", 242, 149, 98)
end

function TargetTargetMana.prototype:GetDefaultSettings()
	local settings = TargetTargetMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 11
	settings["upperText"] = "[PercentMP:Round]"
	settings["lowerText"] = "[FractionalMP:PowerColor]"
	settings["barVerticalOffset"] = 35
	settings["scale"] = 0.7
	settings["enabled"] = false

	return settings
end

function TargetTargetMana.prototype:Enable(core)
	self.registerEvents = false
	TargetTargetMana.super.prototype.Enable(self, core)

	self:ScheduleRepeatingEvent(self.elementName, self.Update, 0.1, self, "targettarget")
end

function TargetTargetMana.prototype:Disable(core)
	TargetTargetMana.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- Load us up
IceHUD.TargetTargetMana = TargetTargetMana:new()
