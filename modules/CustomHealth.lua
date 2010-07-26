local AceOO = AceLibrary("AceOO-2.0")

IceCustomHealth = AceOO.Class(IceTargetHealth)

-- Constructor --
function IceCustomHealth.prototype:init()
	IceCustomHealth.super.prototype.init(self, "IceCustomHealth", "focustarget")

-- these aren't working...don't know why
--[[	self:SetDefaultColor("CustomHealthHostile", 231, 31, 36)
	self:SetDefaultColor("CustomHealthFriendly", 46, 223, 37)
	self:SetDefaultColor("CustomHealthNeutral", 210, 219, 87)
]]--
end

function IceCustomHealth.prototype:GetDefaultSettings()
	local settings = IceCustomHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = -3
	settings["classColor"] = false
	settings["barVerticalOffset"] = 0
	settings["scale"] = 1
	settings["allowMouseInteraction"] = false
	settings["customBarType"] = "Health"
	settings["unitToTrack"] = "focustarget"

	return settings
end


-- OVERRIDE
function IceCustomHealth.prototype:GetOptions()
	local opts = IceCustomHealth.super.prototype.GetOptions(self)

	opts["hideBlizz"] = nil

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
		desc = 'The name of this bar (must be unique!).\n\nRemember to press ENTER after filling out this box with the name you want or it will not save.',
		get = function()
			return self.elementName
		end,
		set = function(v)
			if v~= "" then
				IceHUD.IceCore:RenameDynamicModule(self, v)
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<a name for this bar>",
		order = 20.3,
	}

	opts["unitToTrack"] = {
		type = 'text',
		name = 'Unit to track',
		desc = 'Enter which unit that this bar should be monitoring the health of (e.g.: focustarget, pettarget, etc.)\n\nRemember to press ENTER after filling out this box with the name you want or it will not save.',
		get = function()
			return self.moduleSettings.unitToTrack
		end,
		set = function(v)
			v = string.lower(v)
			self.moduleSettings.unitToTrack = v
			self:SetUnit(v)
			self:Redraw()
			self:CheckCombat()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.4,
	}

	opts["allowClickTarget"] = {
		type = 'toggle',
		name = 'Allow click-targeting',
		desc = 'Whether or not to allow click targeting/casting for this bar (Note: does not work properly with HiBar, have to click near the base of the bar)',
		get = function()
			return self.moduleSettings.allowMouseInteraction
		end,
		set = function(v)
			self.moduleSettings.allowMouseInteraction = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = '',
		order = 41,
	}

	return opts
end


function IceCustomHealth.prototype:Enable(core)
	self.registerEvents = false
	IceCustomHealth.super.prototype.Enable(self, core)

	self:SetUnit(self.moduleSettings.unitToTrack)
	self:CreateFrame()

	self:ScheduleRepeatingEvent(self.elementName, self.Update, IceHUD.IceCore:UpdatePeriod(), self)
end

function IceCustomHealth.prototype:Disable(core)
	IceCustomHealth.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

function IceCustomHealth.prototype:Update(unit)
	self.color = "CustomHealthFriendly" -- friendly > 4

	local reaction = UnitReaction(self.unit, "player")

	if (reaction and (reaction == 4)) then
		self.color = "CustomHealthNeutral"
	elseif (reaction and (reaction < 4)) then
		self.color = "CustomHealthHostile"
	end

	if (self.moduleSettings.classColor) and (not self.moduleSettings.npcHostilityColor or UnitPlayerControlled("target")) then
		self.color = self.unitClass
	end

	if (self.moduleSettings.scaleHealthColor) then
		self.color = "ScaledHealthColor"
	end

	if (self.tapped) then
		self.color = "Tapped"
	end

	if not self:IsVisible() then
		RegisterUnitWatch(self.frame)
	end

	self:Show(true)

	--self.determineColor = false
	IceCustomHealth.super.prototype.Update(self, unit)
end

function IceCustomHealth.prototype:CreateBackground()
	IceCustomHealth.super.prototype.CreateBackground(self)

	if not self.frame.button then
		self.frame.button = CreateFrame("Button", nil, self.frame, "SecureUnitButtonTemplate")
	end

	self.frame.button:ClearAllPoints()
	-- Parnic - kinda hacky, but in order to fit this region to multiple types of bars, we need to do this...
	--          would be nice to define this somewhere in data, but for now...here we are
	if self:GetMyBarTexture() == "HiBar" then
		self.frame.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
		self.frame.button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT", -1 * self.frame:GetWidth(), 0)
	else
		if self.moduleSettings.side == IceCore.Side.Left then
			self.frame.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -6, 0)
			self.frame.button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT", -1 * self.frame:GetWidth() / 3, 0)
		else
			self.frame.button:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 6, 0)
			self.frame.button:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -1 * self.frame:GetWidth() / 1.5, 0)
		end
	end

	self:EnableClickTargeting(self.moduleSettings.allowMouseInteraction)
end

function IceCustomHealth.prototype:EnableClickTargeting(bEnable)
	if bEnable then
		self.frame.button:EnableMouse(true)
		self.frame.button:RegisterForClicks("LeftButtonUp")
		self.frame.button:SetAttribute("type1", "target")

		-- set up click casting
		ClickCastFrames = ClickCastFrames or {}
		ClickCastFrames[self.frame.button] = true

-- Parnic - debug code for showing the clickable region on this bar
--		self.frame.button:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
--						edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
--						tile = false,
--						insets = { left = 0, right = 0, top = 0, bottom = 0 }});
--		self.frame.button:SetBackdropColor(0,0,0,1);
	else
		self.frame.button:EnableMouse(false)
		self.frame.button:RegisterForClicks()
	end
end

function IceCustomHealth.prototype:SetUnit(unit)
	IceCustomHealth.super.prototype.SetUnit(self, unit)
	if self.frame ~= nil and self.frame.button ~= nil then
		self.frame.button:SetAttribute("unit", self.unit)
	end
	self:RegisterFontStrings()
end
