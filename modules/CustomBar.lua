local AceOO = AceLibrary("AceOO-2.0")

IceCustomBar = AceOO.Class(IceUnitBar)

local validUnits = {"player", "target", "focus", "pet", "vehicle", "targettarget", "main hand weapon", "off hand weapon"}
local buffOrDebuff = {"buff", "debuff"}
local validBuffTimers = {"none", "seconds", "minutes:seconds", "minutes"}

IceCustomBar.prototype.auraDuration = 0
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

	self.unit = self.moduleSettings.myUnit

	self:UpdateCustomBar(self.unit)

	if self.moduleSettings.auraIconXOffset == nil then
		self.moduleSettings.auraIconXOffset = 40
	end
	if self.moduleSettings.auraIconYOffset == nil then
		self.moduleSettings.auraIconYOffset = 0
	end
end

function IceCustomBar.prototype:TargetChanged()
	IceCustomBar.super.prototype.TargetChanged(self)

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
	settings["customBarType"] = "Bar"
	settings["buffToTrack"] = ""
	settings["myUnit"] = "player"
	settings["buffOrDebuff"] = "buff"
	settings["barColor"] = {r=1, g=0, b=0, a=1}
	settings["trackOnlyMine"] = true
	settings["displayWhenEmpty"] = false
	settings["hideAnimationSettings"] = true
	settings["buffTimerDisplay"] = "minutes"
	settings["maxDuration"] = 0
	settings["displayAuraIcon"] = false
	settings["auraIconXOffset"] = 40
	settings["auraIconYOffset"] = 0

	return settings
end

function IceCustomBar.prototype:CreateBar()
	IceCustomBar.super.prototype.CreateBar(self)

	if not self.barFrame.icon then
		self.barFrame.icon = self.barFrame:CreateTexture(nil, "LOW")
		-- default texture so that 'config mode' can work without activating the bar first
		self.barFrame.icon:SetTexture("Interface\\Icons\\Spell_Frost_Frost")
		self.barFrame.icon:SetWidth(20)
		self.barFrame.icon:SetHeight(20)
		-- this cuts off the border around the buff icon
		self.barFrame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		self.barFrame.icon:SetDrawLayer("OVERLAY")
	end
	self:PositionIcons()
end

function IceCustomBar.prototype:PositionIcons()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	self.barFrame.icon:ClearAllPoints()
	self.barFrame.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.moduleSettings.auraIconXOffset, self.moduleSettings.auraIconYOffset)
end

function IceCustomBar.prototype:Redraw()
	IceCustomBar.super.prototype.Redraw(self)

	self:UpdateCustomBar(self.unit)
end

-- OVERRIDE
function IceCustomBar.prototype:GetOptions()
	local opts = IceCustomBar.super.prototype.GetOptions(self)

	opts.textSettings.args.upperTextString.hidden = false
	opts.textSettings.args.lowerTextString.hidden = false

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
			AceLibrary("Waterfall-1.0"):Refresh("IceHUD")
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
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
		end,
		order = 20.5,
	}

	opts["buffToTrack"] = {
		type = 'text',
		name = "Aura to track",
		desc = "Which buff/debuff this bar will be tracking.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save.",
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
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
		end,
		usage = "<which buff to track>",
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
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
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
			self.barFrame.bar:SetVertexColor(self:GetBarColor())
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.8,
	}

	opts["displayWhenEmpty"] = {
		type = 'toggle',
		name = 'Display when empty',
		desc = 'Whether or not to display this bar even if the buff/debuff specified is not present.',
		get = function()
			return self.moduleSettings.displayWhenEmpty
		end,
		set = function(v)
			self.moduleSettings.displayWhenEmpty = v
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 20.9
	}

	opts["buffTimerDisplay"] = {
		type = 'text',
		name = 'Buff timer display',
		desc = 'How to display the buff timer next to the name of the buff on the bar',
		get = function()
			return self.moduleSettings.buffTimerDisplay
		end,
		set = function(v)
			self.moduleSettings.buffTimerDisplay = v
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		validate = validBuffTimers,
		order = 21
	}

	opts["maxDuration"] = {
		type = 'text',
		name = "Maximum duration",
		desc = "Maximum Duration for the bar (the bar will remained full if it has longer than maximum remaining).  Leave 0 for spell duration.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save.",
		get = function()
			return self.moduleSettings.maxDuration
		end,
		set = function(v)
			if not v or not tonumber(v) then
				v = 0
			end
			self.moduleSettings.maxDuration = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<the maximum duration for a bar>",
		order = 21.1,
	}
	
	opts["headerIcons"] = {
		type = 'header',
		name = 'Icons',
		order = 40
	}
	
	opts["displayAuraIcon"] = {
		type = 'toggle',
		name = "Display aura icon",
		desc = "Whether or not to display an icon for the aura that this bar is tracking",
		get = function()
			return self.moduleSettings.displayAuraIcon
		end,
		set = function(v)
			self.moduleSettings.displayAuraIcon = v
			if self.barFrame.icon then
				if v then
					self.barFrame.icon:Show()
				else
					self.barFrame.icon:Hide()
				end
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<whether or not to display an icon for this bar's tracked spell>",
		order = 40.1,
	}
	
	opts["auraIconXOffset"] = {
		type = 'range',
		min = -250,
		max = 250,
		step = 1,
		name = "Aura icon horizontal offset",
		desc = "Adjust the horizontal position of the aura icon",
		get = function()
			return self.moduleSettings.auraIconXOffset
		end,
		set = function(v)
			self.moduleSettings.auraIconXOffset = v
			self:PositionIcons()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
		end,
		usage = "<adjusts the spell icon's horizontal position>",
		order = 40.2,
	}

	opts["auraIconYOffset"] = {
		type = 'range',
		min = -250,
		max = 250,
		step = 1,
		name = "Aura icon vertical offset",
		desc = "Adjust the vertical position of the aura icon",
		get = function()
			return self.moduleSettings.auraIconYOffset
		end,
		set = function(v)
			self.moduleSettings.auraIconYOffset = v
			self:PositionIcons()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
		end,
		usage = "<adjusts the spell icon's vertical position>",
		order = 40.3,
	}
	
	return opts
end

function IceCustomBar.prototype:GetBarColor()
	return self.moduleSettings.barColor.r, self.moduleSettings.barColor.g, self.moduleSettings.barColor.b, self.alpha
end

-- 'Protected' methods --------------------------------------------------------

function IceCustomBar.prototype:GetAuraDuration(unitName, buffName)
	if unitName == "main hand weapon" or unitName == "off hand weapon" then
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges
			= GetWeaponEnchantInfo()

		if unitName == "main hand weapon" and hasMainHandEnchant then
			local slotId, mainHandTexture = GetInventorySlotInfo("MainHandSlot")
			return mainHandExpiration/1000, mainHandExpiration/1000, mainHandCharges, GetInventoryItemTexture("player", slotId)
		elseif unitName == "off hand weapon" and hasOffHandEnchant then
			local slotId, offHandTexture = GetInventorySlotInfo("SecondaryHandSlot")
			return offHandExpiration/1000, offHandExpiration/1000, offHandCharges, GetInventoryItemTexture("player", slotId)
		end

		return nil, nil, nil, nil
	end

	local i = 1
	local remaining
	local isBuff = self.moduleSettings.buffOrDebuff == "buff" and true or false
	local buffFilter = (isBuff and "HELPFUL" or "HARMFUL") .. (self.moduleSettings.trackOnlyMine and "|PLAYER" or "")
	local buff, rank, texture, count, type, duration, endTime, unitCaster = UnitAura(unitName, i, buffFilter)
	local isMine = unitCaster == "player"

	while buff do
		if self.moduleSettings.maxDuration and self.moduleSettings.maxDuration ~= 0 then
			duration = self.moduleSettings.maxDuration
		end
		
		if (string.match(buff:upper(), buffName:upper()) and (not self.moduleSettings.trackOnlyMine or isMine)) then
			if endTime and not remaining then
				remaining = endTime - GetTime()
			end
			return duration, remaining, count, texture
		end

		i = i + 1;

		buff, rank, texture, count, type, duration, endTime, unitCaster = UnitAura(unitName, i, buffFilter)
		isMine = unitCaster == "player"
	end

	return nil, nil, nil, nil
end

function IceCustomBar.prototype:UpdateCustomBar(unit, fromUpdate)
	if unit and unit ~= self.unit and not (self.unit == "main hand weapon" or self.unit == "off hand weapon") then
		return
	end

	local now = GetTime()
	local remaining = nil
	local count = 0
	local auraIcon = nil

	if not fromUpdate then
		self.auraDuration, remaining, count, auraIcon =
			self:GetAuraDuration(self.unit, self.moduleSettings.buffToTrack)

		if not remaining then
			self.auraEndTime = 0
		else
			self.auraEndTime = remaining + now
		end

		if auraIcon ~= nil then
			self.barFrame.icon:SetTexture(auraIcon)
		end

		if IceHUD.IceCore:IsInConfigMode() or self.moduleSettings.displayAuraIcon then
			self.barFrame.icon:Show()
		else
			self.barFrame.icon:Hide()
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

		self:UpdateBar(self.auraDuration ~= 0 and remaining / self.auraDuration or 0, "undef")
	else
		self:UpdateBar(0, "undef")
		self:Show(false)
		self.frame:SetScript("OnUpdate", nil)
	end

	if (remaining ~= nil) then
		local buffString = ""
		if self.moduleSettings.buffTimerDisplay == "seconds" then
			buffString = tostring(ceil(remaining or 0)) .. "s"
		else
			local seconds = ceil(remaining)%60
			local minutes = ceil(remaining)/60

			if self.moduleSettings.buffTimerDisplay == "minutes:seconds" then
				buffString = floor(minutes) .. ":" .. string.format("%02d", seconds)
			elseif self.moduleSettings.buffTimerDisplay == "minutes" then
				if minutes > 1 then
					buffString = ceil(minutes) .. "m"
				else
					buffString = ceil(remaining) .. "s"
				end
			end
		end
		self:SetBottomText1(self.moduleSettings.upperText .. " " .. buffString)
	else
		self.auraBuffCount = 0
		self:SetBottomText1(self.moduleSettings.upperText)
	end

	self.barFrame.bar:SetVertexColor(self:GetBarColor())
end

function IceCustomBar.prototype:OutCombat()
	IceCustomBar.super.prototype.OutCombat(self)

	self:UpdateCustomBar(self.unit)
end

function IceCustomBar.prototype:Show(bShouldShow)
	if self.moduleSettings.displayWhenEmpty then
		if not self.bIsVisible then
			IceCustomBar.super.prototype.Show(self, true)
		end
	else
		IceCustomBar.super.prototype.Show(self, bShouldShow)
	end
end
