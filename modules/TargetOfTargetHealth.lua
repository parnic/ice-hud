local AceOO = AceLibrary("AceOO-2.0")

local TargetTargetHealth = AceOO.Class(IceTargetHealth)


-- Constructor --
function TargetTargetHealth.prototype:init()
	TargetTargetHealth.super.prototype.init(self, "TargetTargetHealth", "targettarget")

	self:SetDefaultColor("TargetTargetHealthHostile", 231, 31, 36)
	self:SetDefaultColor("TargetTargetHealthFriendly", 46, 223, 37)
	self:SetDefaultColor("TargetTargetHealthNeutral", 210, 219, 87)
	self:SetDefaultColor("SelfColor", 255, 255, 255)
end

function TargetTargetHealth.prototype:GetDefaultSettings()
	local settings = TargetTargetHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 12
	settings["mobHealth"] = (MobHealth3 ~= nil)
	settings["classColor"] = false
	settings["selfColor"] = { r = 0, g = 0, b = 1 }
	settings["useSelfColor"] = true
	settings["upperText"] = "[PercentHP:Round]"
	settings["lowerText"] = "[(HP:Round \"/\" MaxHP:Round):HPColor:Bracket]"
	settings["barVerticalOffset"] = 35
	settings["scale"] = 0.7
	settings["enabled"] = false
	settings["hideBlizz"] = false

	return settings
end


-- OVERRIDE
function TargetTargetHealth.prototype:GetOptions()
	local opts = TargetTargetHealth.super.prototype.GetOptions(self)

	opts["hideBlizz"] = nil

	opts["useSelfColor"] = {
		type = "toggle",
		name = "Use Self Color",
		desc = "Whether or not to use the self color.",
		get = function()
			return self.moduleSettings.useSelfColor
		end,
		set = function(value)
			self.moduleSettings.useSelfColor = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 44,
	}

	opts["selfColor"] = {
		type = "color",
		name = "Self Color",
		desc = "Set the color of the TargetTarget bar if you are your target's target.",
		get = function()
			return self.moduleSettings.selfColor.r, self.moduleSettings.selfColor.g, self.moduleSettings.selfColor.b
		end,
		set = function(r, g, b)
			self.moduleSettings.selfColor = { r = r, g = g, b = b }
			IceHUD.IceCore:SetColor("SelfColor", r, g, b)
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.useSelfColor
		end,
		hasAlpha = false,
		order = 45,
	}

	return opts
end


function TargetTargetHealth.prototype:Enable(core)
	self.registerEvents = false
	TargetTargetHealth.super.prototype.Enable(self, core)

	self:ScheduleRepeatingEvent(self.elementName, self.Update, 0.1, self, "targettarget")
end

function TargetTargetHealth.prototype:Disable(core)
	TargetTargetHealth.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

function TargetTargetHealth.prototype:Update(unit)
	self.color = "TargetTargetHealthFriendly" -- friendly > 4

	local reaction = UnitReaction("targettarget", "player")

	if (reaction and (reaction == 4)) then
		self.color = "TargetTargetHealthNeutral"
	elseif (reaction and (reaction < 4)) then
		self.color = "TargetTargetHealthHostile"
	end

	if (self.moduleSettings.classColor) then
		self.color = self.unitClass
	end

	if (self.moduleSettings.scaleHealthColor) then
		self.color = "ScaledHealthColor"
	end

	if (self.tapped) then
		self.color = "Tapped"
	end

	if UnitIsUnit("player", "targettarget") and self.moduleSettings.useSelfColor then
		self.color = "SelfColor"
	end

	self.determineColor = false
	TargetTargetHealth.super.prototype.Update(self, unit)
end

-- Load us up
IceHUD.TargetTargetHealth = TargetTargetHealth:new()
