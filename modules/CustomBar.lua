local AceOO = AceLibrary("AceOO-2.0")

IceCustomBar = AceOO.Class(IceUnitBar)

local validUnits = {"player", "target", "focus", "pet", "vehicle", "targettarget"}
local buffOrDebuff = {"buff", "debuff"}

IceCustomBar.prototype.auraDuration = 0
IceCustomBar.prototype.auraCount = 0
IceCustomBar.prototype.auraEndTime = 0

-- Constructor --
function IceCustomBar.prototype:init()
	IceCustomBar.super.prototype.init(self, "MyCustomBar", "player")
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceCustomBar.prototype:Enable(core)
	IceCustomBar.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "UpdateCustomBar")
	self:RegisterEvent("UNIT_PET", "UpdateCustomBar")
	self:RegisterEvent("PLAYER_PET_CHANGED", "UpdateCustomBar")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "UpdateCustomBar")

	self:Show(true)

	self:SetBottomText1("")
	self:SetBottomText2("")

	self.unit = self.moduleSettings.myUnit

	self:UpdateCustomBar(self.unit)
end

function IceCustomBar.prototype:TargetChanged()
	self:UpdateCustomBar(self.unit)
end

function IceCustomBar.prototype:Disable(core)
	IceCustomBar.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function IceCustomBar.prototype:GetDefaultSettings()
	local settings = IceCustomBar.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = true
	settings["shouldAnimate"] = false
	settings["desiredLerpTime"] = 0
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 8
	settings["upperText"]=""
	settings["usesDogTagStrings"] = false
	settings["lockLowerFontAlpha"] = false
	settings["lowerText"] = ""
	settings["lowerTextVisible"] = false
	settings["isCustomBar"] = true
	settings["buffToTrack"] = ""
	settings["myUnit"] = "player"
	settings["buffOrDebuff"] = "buff"
	settings["barColor"] = {r=1, g=0, b=0, a=1}
	settings["trackOnlyMine"] = true

	return settings
end

-- OVERRIDE
function IceCustomBar.prototype:GetOptions()
	local opts = IceCustomBar.super.prototype.GetOptions(self)

	opts.textSettings.args.upperTextString.hidden = false
	opts.textSettings.args.lowerTextString.hidden = false

	opts.headerAnimation.hidden = true
	opts.shouldAnimate.hidden = true
	opts.desiredLerpTime.hidden = true

	opts["customHeader"] = {
		type = 'header',
		name = "Custom bar settings",
		order = 20.1,
	}

	opts["deleteme"] = {
		type = 'execute',
		name = 'Delete me',
		desc = 'Deletes this custom module and all associated settings. Cannot be undone!',
		func = function()
			local dialog = StaticPopup_Show("ICEHUD_DELETE_CUSTOM_MODULE")
			if dialog then
				dialog.data = self
			end
		end,
		order = 20.2,
	}

	opts["name"] = {
		type = 'text',
		name = 'Bar name',
		desc = 'The name of this bar (must be unique!)',
		get = function()
			return self.elementName
		end,
		set = function(v)
			IceHUD.IceCore:RenameDynamicModule(self, v)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.3,
	}

	opts["unitToTrack"] = {
		type = 'text',
		validate = validUnits,
		name = 'Unit to track',
		desc = 'Select which unit that this bar should be looking for buffs/debuffs on',
		get = function()
			return self.moduleSettings.myUnit
		end,
		set = function(v)
			self.moduleSettings.myUnit = v
			self.unit = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.4,
	}

	opts["buffOrDebuff"] = {
		type = 'text',
		validate = buffOrDebuff,
		name = 'Buff or debuff?',
		desc = 'Whether we are tracking a buff or debuff',
		get = function()
			return self.moduleSettings.buffOrDebuff
		end,
		set = function(v)
			self.moduleSettings.buffOrDebuff = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.5,
	}

	opts["buffToTrack"] = {
		type = 'text',
		name = "Aura to track",
		desc = "Which buff/debuff this bar will be tracking",
		get = function()
			return self.moduleSettings.buffToTrack
		end,
		set = function(v)
			if self.moduleSettings.buffToTrack == self.moduleSettings.upperText then
				self.moduleSettings.upperText = v
			end
			self.moduleSettings.buffToTrack = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.6,
	}

	opts["trackOnlyMine"] = {
		type = 'toggle',
		name = 'Only track auras by me',
		desc = 'Checking this means that only buffs or debuffs that the player applied will trigger this bar',
		get = function()
			return self.moduleSettings.trackOnlyMine
		end,
		set = function(v)
			self.moduleSettings.trackOnlyMine = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.7,
	}

	opts["barColor"] = {
		type = 'color',
		name = 'Bar color',
		desc = 'The color for this bar',
		get = function()
			return self:GetBarColor()
		end,
		set = function(r,g,b)
			self.moduleSettings.barColor.r = r
			self.moduleSettings.barColor.g = g
			self.moduleSettings.barColor.b = b
			self.barFrame:SetStatusBarColor(self:GetBarColor())
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.8,
	}

	return opts
end

function IceCustomBar.prototype:GetBarColor()
	return self.moduleSettings.barColor.r, self.moduleSettings.barColor.g, self.moduleSettings.barColor.b, self.alpha
end

-- 'Protected' methods --------------------------------------------------------

function IceCustomBar.prototype:GetAuraDuration(unitName, buffName)
	local i = 1
	local remaining
	local isBuff = self.moduleSettings.buffOrDebuff == "buff" and true or false
	local buffFilter = (isBuff and "HELPFUL" or "HARMFUL") .. (unitName == "player" and "|PLAYER" or "")
	local buff, rank, texture, count, type, duration, endTime, unitCaster = UnitAura(unitName, i, buffFilter)
	local isMine = unitCaster == "player"

	while buff do
		if (buff == buffName and (not self.moduleSettings.trackOnlyMine or isMine)) then
			if endTime and not remaining then
				remaining = endTime - GetTime()
			end
			return duration, remaining, count
		end

		i = i + 1;

		buff, rank, texture, count, type, duration, endTime, unitCaster = UnitAura(unitName, i, buffFilter)
		isMine = unitCaster == "player"
	end

	return nil, nil, nil
end

function IceCustomBar.prototype:UpdateCustomBar(unit, fromUpdate)
	if unit and unit ~= self.unit then
		return
	end

	local now = GetTime()
	local remaining = nil

	if not fromUpdate then
		self.auraDuration, remaining, self.auraCount =
			self:GetAuraDuration(self.unit, self.moduleSettings.buffToTrack)

		if not remaining then
			self.auraEndTime = 0
			self.auraCount = 0
		else
			self.auraEndTime = remaining + now
		end
	end

	if self.auraEndTime and self.auraEndTime >= now then
		if not fromUpdate then
			self.frame:SetScript("OnUpdate", function() self:UpdateCustomBar(self.unit, true) end)
		end

		self:Show(true)

		if not remaining then
			remaining = self.auraEndTime - now
		end

		self:UpdateBar(remaining / self.auraDuration, "undef")
	else
		self:UpdateBar(0, "undef")
		self:Show(false)
	end

	if (remaining ~= nil) then
		self:SetBottomText1(self.moduleSettings.upperText .. " " .. tostring(ceil(remaining or 0)) .. "s")
	else
		self.auraBuffCount = 0
		self:SetBottomText1("")
		self:SetBottomText2("")
	end

	self.barFrame:SetStatusBarColor(self:GetBarColor())
end

function IceCustomBar.prototype:OutCombat()
	IceCustomBar.super.prototype.OutCombat(self)

	self:UpdateCustomBar(self.unit)
end
