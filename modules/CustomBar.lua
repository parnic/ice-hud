local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceCustomBar = IceCore_CreateClass(IceUnitBar)

local DogTag = nil

local IceHUD = _G.IceHUD

local validUnits = {"player", "target", "focus", "focustarget", "pet", "pettarget", "vehicle", "targettarget", "main hand weapon", "off hand weapon", "other"}
local buffOrDebuff = {"buff", "debuff"}
local validBuffTimers = {"none", "seconds", "minutes:seconds", "minutes"}
local AuraIconWidth = 20
local AuraIconHeight = 20

IceCustomBar.prototype.auraDuration = -1
IceCustomBar.prototype.auraEndTime = -1
IceCustomBar.prototype.bIsAura = false

-- Constructor --
function IceCustomBar.prototype:init()
	IceCustomBar.super.prototype.init(self, "MyCustomBar", "player")
	self.textColorOverride = true
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceCustomBar.prototype:Enable(core)
	IceCustomBar.super.prototype.Enable(self, core)

	if IceHUD.IceCore:ShouldUseDogTags() then
		DogTag = LibStub("LibDogTag-3.0", true)
		if DogTag then
			LibStub("LibDogTag-Unit-3.0", true)
		end
	end

	self:RegisterEvent("UNIT_AURA", "UpdateCustomBarEvent")
	self:RegisterEvent("UNIT_PET", "UpdateCustomBarEvent")
	self:RegisterEvent("PLAYER_PET_CHANGED", "UpdateCustomBarEvent")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED", "UpdateCustomBarEvent")
	if self.unitClass == "SHAMAN" then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE", "UpdateTotems")
	end

	if self.moduleSettings.auraIconScale == nil then
		self.moduleSettings.auraIconScale = 1
	end

	self:Show(true)

	self.unit = self:GetUnitToTrack()
	self:ConditionalSubscribe()

	if not self.moduleSettings.usesDogTagStrings then
		self.moduleSettings.usesDogTagStrings = true
	end

	self:UpdateCustomBar(self.unit)

	if self.moduleSettings.auraIconXOffset == nil then
		self.moduleSettings.auraIconXOffset = 40
	end
	if self.moduleSettings.auraIconYOffset == nil then
		self.moduleSettings.auraIconYOffset = 0
	end

	self:FixupTextColors()
	self:SetCustomTextColor(self.frame.bottomUpperText, self.moduleSettings.upperTextColor)
	self:SetCustomTextColor(self.frame.bottomLowerText, self.moduleSettings.lowerTextColor)
end

function IceCustomBar.prototype:Disable(core)
	self.handlesOwnUpdates = false
	IceHUD.IceCore:RequestUpdates(self, nil)

	IceCustomBar.super.prototype.Disable(self, core)
end

function IceCustomBar.prototype:GetUnitToTrack()
	if self.moduleSettings.myUnit == "other" then
		if self.moduleSettings.customUnit ~= nil and self.moduleSettings.customUnit ~= "" then
			return self.moduleSettings.customUnit
		else
			return validUnits[1]
		end
	else
		return self.moduleSettings.myUnit
	end
end

function IceCustomBar.prototype:FixupTextColors()
	if not self.moduleSettings.upperTextColor then
		self.moduleSettings.upperTextColor = {r=1, g=1, b=1}
	end
	if not self.moduleSettings.lowerTextColor then
		self.moduleSettings.lowerTextColor = {r=1, g=1, b=1}
	end
end

function IceCustomBar.prototype:ConditionalSubscribe()
	if self:ShouldAlwaysSubscribe() then
		if not IceHUD.IceCore:IsUpdateSubscribed(self) then
			if not self.CustomBarUpdateFunc then
				self.CustomBarUpdateFunc = function() self:UpdateCustomBar() end
			end

			self.handlesOwnUpdates = true
			IceHUD.IceCore:RequestUpdates(self, self.CustomBarUpdateFunc)
		end
	else
		self.handlesOwnUpdates = false
		IceHUD.IceCore:RequestUpdates(self, nil)
	end
end

function IceCustomBar.prototype:ShouldAlwaysSubscribe()
	return self.unit == "focustarget" or self.unit == "pettarget"
end

function IceCustomBar.prototype:TargetChanged()
	IceCustomBar.super.prototype.TargetChanged(self)

	self:UpdateCustomBar(self.unit)
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
	--settings["usesDogTagStrings"] = false
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
	settings["displayWhenTargeting"] = false
	settings["hideAnimationSettings"] = true
	settings["buffTimerDisplay"] = "minutes"
	settings["maxDuration"] = 0
	settings["displayAuraIcon"] = false
	settings["auraIconXOffset"] = 40
	settings["auraIconYOffset"] = 0
	settings["auraIconScale"] = 1
	settings["exactMatch"] = false
	settings["lowerTextColor"] = {r=1, g=1, b=1}
	settings["upperTextColor"] = {r=1, g=1, b=1}
	settings["customUnit"] = "player"
	settings["minCount"] = 0

	return settings
end

function IceCustomBar.prototype:CreateBar()
	IceCustomBar.super.prototype.CreateBar(self)

	if not self.barFrame.icon then
		self.barFrame.icon = self.masterFrame:CreateTexture(nil, "LOW")
		-- default texture so that 'config mode' can work without activating the bar first
		self.barFrame.icon:SetTexture("Interface\\Icons\\Spell_Frost_Frost")
		-- this cuts off the border around the buff icon
		self.barFrame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		self.barFrame.icon:SetDrawLayer("OVERLAY")
		self.barFrame.icon:Hide()
	end
	self:PositionIcons()
end

function IceCustomBar.prototype:PositionIcons()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	self.barFrame.icon:ClearAllPoints()
	self.barFrame.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.moduleSettings.auraIconXOffset, self.moduleSettings.auraIconYOffset)
	self.barFrame.icon:SetWidth(AuraIconWidth * (self.moduleSettings.auraIconScale or 1))
	self.barFrame.icon:SetHeight(AuraIconHeight * (self.moduleSettings.auraIconScale or 1))
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
	opts.lowThresholdColor = nil

	opts["customHeader"] = {
		type = 'header',
		name = L["Custom bar settings"],
		order = 30.1,
	}

	opts["deleteme"] = {
		type = 'execute',
		name = L["Delete me"],
		desc = L["Deletes this custom module and all associated settings. Cannot be undone!"],
		func = function()
			local dialog = StaticPopup_Show("ICEHUD_DELETE_CUSTOM_MODULE")
			if dialog then
				dialog.data = self
			end
		end,
		order = 20.1,
	}

	opts["duplicateme"] = {
		type = 'execute',
		name = L["Duplicate me"],
		desc = L["Creates a new module of this same type and with all the same settings."],
		func = function()
			IceHUD:CreateCustomModuleAndNotify(self.moduleSettings.customBarType, self.moduleSettings)
		end,
		order = 20.2,
	}

	opts["type"] = {
		type = "description",
		name = string.format("%s %s", L["Module type:"], tostring(self:GetBarTypeDescription("Bar"))),
		order = 21,
	}

	opts["name"] = {
		type = 'input',
		name = L["Bar name"],
		desc = L["The name of this bar (must be unique!).\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.elementName
		end,
		set = function(info, v)
			if v~= "" then
				IceHUD.IceCore:RenameDynamicModule(self, v)
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<a name for this bar>",
		order = 30.3,
	}

	opts["unitToTrack"] = {
		type = 'select',
		values = validUnits,
		name = L["Unit to track"],
		desc = L["Select which unit that this bar should be looking for buffs/debuffs on"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.myUnit)
		end,
		set = function(info, v)
			self.moduleSettings.myUnit = info.option.values[v]
			self.unit = self:GetUnitToTrack()
			self:RegisterFontStrings()
			self:ConditionalSubscribe()
			self:Redraw()
			self:UpdateCustomBar(self.unit)
			IceHUD:NotifyOptionsChange()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.4,
	}

	opts["customUnitToTrack"] = {
		type = 'input',
		name = L["Custom unit"],
		desc = L["Any valid unit id such as: party1, raid14, targettarget, etc. Not guaranteed to work with all unit ids.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.moduleSettings.customUnit
		end,
		set = function(info, v)
			self.moduleSettings.customUnit = v
			self.unit = self:GetUnitToTrack()
			self:RegisterFontStrings()
			self:ConditionalSubscribe()
			self:Redraw()
			self:UpdateCustomBar(self.unit)
			IceHUD:NotifyOptionsChange()
		end,
		hidden = function()
			return self.moduleSettings.myUnit ~= "other"
		end,
		usage = "<what custom unit to track when unitToTrack is set to 'other'>",
		order = 30.45,
	}

	opts["buffOrDebuff"] = {
		type = 'select',
		values = buffOrDebuff,
		name = L["Buff or debuff?"],
		desc = L["Whether we are tracking a buff or debuff"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.buffOrDebuff)
		end,
		set = function(info, v)
			self.moduleSettings.buffOrDebuff = info.option.values[v]
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
		end,
		order = 30.5,
	}

	opts["buffToTrack"] = {
		type = 'input',
		name = L["Aura to track"],
		desc = L["Which buff/debuff this bar will be tracking.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.moduleSettings.buffToTrack
		end,
		set = function(info, v)
			local orig = v
			--Parnic: we now allow spell IDs to be used directly
			--if tonumber(v) ~= nil then
			--	v = GetSpellInfo(tonumber(v))
			--end
			if v == nil then
				v = orig
			end
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
		order = 30.6,
	}

	opts["exactMatch"] = {
		type = 'toggle',
		name = L["Exact match only"],
		desc = L["If this is checked, then the buff name must be entered exactly as the full buff name. Otherwise, you can use only a portion of the name such as 'Sting' to track all stings."],
		get = function()
			return self.moduleSettings.exactMatch
		end,
		set = function(info, v)
			self.moduleSettings.exactMatch = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
		end,
		order = 30.65,
	}

	opts["trackOnlyMine"] = {
		type = 'toggle',
		name = L["Only track auras by me"],
		desc = L["Checking this means that only buffs or debuffs that the player applied will trigger this bar"],
		get = function()
			return self.moduleSettings.trackOnlyMine
		end,
		set = function(info, v)
			self.moduleSettings.trackOnlyMine = v
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled or self.unit == "main hand weapon" or self.unit == "off hand weapon"
		end,
		order = 30.7,
	}

	opts["minCount"] = {
		type = 'input',
		name = L["Minimum stacks to show"],
		desc = L["Only show the bar when the number of applications of this buff or debuff exceeds this number"],
		get = function()
			return self.moduleSettings.minCount and tostring(self.moduleSettings.minCount) or "0"
		end,
		set = function(info, v)
			self.moduleSettings.minCount = tonumber(v)
			self:Redraw()
			self:UpdateCustomBar(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.71,
	}

	opts["barColor"] = {
		type = 'color',
		name = L["Bar color"],
		desc = L["The color for this bar"],
		get = function()
			return self:GetBarColor()
		end,
		set = function(info, r,g,b)
			self.moduleSettings.barColor.r = r
			self.moduleSettings.barColor.g = g
			self.moduleSettings.barColor.b = b
			self.barFrame.bar:SetVertexColor(self:GetBarColor())
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.8,
	}

	opts["displayWhenEmpty"] = {
		type = 'toggle',
		name = L["Display when empty"],
		desc = L["Whether or not to display this bar even if the buff/debuff specified is not present."],
		get = function()
			return self.moduleSettings.displayWhenEmpty
		end,
		set = function(info, v)
			self.moduleSettings.displayWhenEmpty = v
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.9
	}

	opts["displayWhenTargeting"] = {
		type = 'toggle',
		name = L["Display when targeting"],
		desc = L["Whether to display this bar when you target a unit, even if the buff/debuff specified is not present."],
		get = function()
			return self.moduleSettings.displayWhenTargeting
		end,
		set = function(info, v)
			self.moduleSettings.displayWhenTargeting = v
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.91
	}

	opts["buffTimerDisplay"] = {
		type = 'select',
		name = L["Buff timer display"],
		desc = L["How to display the buff timer next to the name of the buff on the bar"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.buffTimerDisplay)
		end,
		set = function(info, v)
			self.moduleSettings.buffTimerDisplay = info.option.values[v]
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		values = validBuffTimers,
		order = 31
	}

	opts["maxDuration"] = {
		type = 'input',
		name = L["Maximum duration"],
		desc = L["Maximum Duration for the bar (the bar will remained full if it has longer than maximum remaining).  Leave 0 for spell duration.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.moduleSettings.maxDuration
		end,
		set = function(info, v)
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
		order = 31.1,
	}

	opts["iconSettings"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Icon Settings"].."|r",
		args = {
			displayAuraIcon = {
				type = 'toggle',
				name = L["Display aura icon"],
				desc = L["Whether or not to display an icon for the aura that this bar is tracking"],
				get = function()
					return self.moduleSettings.displayAuraIcon
				end,
				set = function(info, v)
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
				order = 40.1,
			},

			auraIconXOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon horizontal offset"],
				desc = L["Adjust the horizontal position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconXOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconXOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.2,
			},

			auraIconYOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon vertical offset"],
				desc = L["Adjust the vertical position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconYOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconYOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.3,
			},

			auraIconScale = {
				type = 'range',
				min = 0.1,
				max = 3.0,
				step = 0.05,
				name = L["Aura icon scale"],
				desc = L["Adjusts the size of the aura icon for this bar"],
				get = function()
					return self.moduleSettings.auraIconScale
				end,
				set = function(info, v)
					self.moduleSettings.auraIconScale = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.4,
			},
		},
	}

	opts.textSettings.args.upperTextColor = {
		type = "color",
		name = L["Upper Text Color"],
		get = function()
			self:FixupTextColors()
			return self.moduleSettings.upperTextColor.r, self.moduleSettings.upperTextColor.g, self.moduleSettings.upperTextColor.b, 1
		end,
		set = function(info, r,g,b)
			self.moduleSettings.upperTextColor.r = r
			self.moduleSettings.upperTextColor.g = g
			self.moduleSettings.upperTextColor.b = b
			self:SetCustomTextColor(self.frame.bottomUpperText, self.moduleSettings.upperTextColor)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 13.9,
	}

	opts.textSettings.args.lowerTextColor = {
		type = "color",
		name = L["Lower Text Color"],
		get = function()
			return self.moduleSettings.lowerTextColor.r, self.moduleSettings.lowerTextColor.g, self.moduleSettings.lowerTextColor.b, 1
		end,
		set = function(info, r,g,b)
			self.moduleSettings.lowerTextColor.r = r
			self.moduleSettings.lowerTextColor.g = g
			self.moduleSettings.lowerTextColor.b = b
			self:SetCustomTextColor(self.frame.bottomLowerText, self.moduleSettings.lowerTextColor)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 14.9,
	}

	return opts
end

function IceCustomBar.prototype:GetBarColor()
	return self.moduleSettings.barColor.r, self.moduleSettings.barColor.g, self.moduleSettings.barColor.b, self.alpha
end

-- 'Protected' methods --------------------------------------------------------

function IceCustomBar.prototype:GetAuraDuration(unitName, buffName)
	if not unitName or not buffName then
		return nil
	end

	if unitName == "main hand weapon" or unitName == "off hand weapon" then
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
			= GetWeaponEnchantInfo()

		if unitName == "main hand weapon" and hasMainHandEnchant then
			local duration =
				(self.auraDuration == nil or (mainHandExpiration/1000) > self.auraDuration) and (mainHandExpiration/1000)
				or self.auraDuration

			local slotId, mainHandTexture = GetInventorySlotInfo("MainHandSlot")
			return duration, mainHandExpiration/1000, mainHandCharges, GetInventoryItemTexture("player", slotId)
		elseif unitName == "off hand weapon" and hasOffHandEnchant then
			local duration =
				(self.auraDuration == nil or (offHandExpiration/1000) > self.auraDuration) and (offHandExpiration/1000)
				or self.auraDuration

			local slotId, offHandTexture = GetInventorySlotInfo("SecondaryHandSlot")
			return duration, offHandExpiration/1000, offHandCharges, GetInventoryItemTexture("player", slotId)
		end

		return nil
	end

	local i = 1
	local remaining
	local isBuff = self.moduleSettings.buffOrDebuff == "buff" and true or false
	local buffFilter = (isBuff and "HELPFUL" or "HARMFUL") .. (self.moduleSettings.trackOnlyMine and "|PLAYER" or "")
	local buff, rank, texture, count, type, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, buffFilter)
	local isMine = unitCaster == "player"
	local mySpellId = tonumber(self.moduleSettings.buffToTrack)
	local checkId = mySpellId ~= nil
	local validId = true

	while buff do
		if self.moduleSettings.maxDuration and self.moduleSettings.maxDuration ~= 0 then
			duration = self.moduleSettings.maxDuration
		end

		if checkId and self.moduleSettings.exactMatch then
			validId = spellId == mySpellId
		end

		if (((self.moduleSettings.exactMatch and buff:upper() == buffName:upper())
				or (not self.moduleSettings.exactMatch and string.match(buff:upper(), buffName:upper())))
				and (not self.moduleSettings.trackOnlyMine or isMine) and validId) then
			if endTime and not remaining then
				remaining = endTime - GetTime()
			end
			return duration, remaining, count, texture, endTime
		end

		i = i + 1;

		buff, rank, texture, count, type, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, buffFilter)
		isMine = unitCaster == "player"
	end

	if self.unitClass == "SHAMAN" then
		for i=1,MAX_TOTEMS do
			local haveTotem, totemName, startTime, realDuration, icon = GetTotemInfo(i)

			if haveTotem and totemName then
				if self.moduleSettings.maxDuration and self.moduleSettings.maxDuration ~= 0 then
					duration = self.moduleSettings.maxDuration
				else
					duration = realDuration
				end

				if ((self.moduleSettings.exactMatch and totemName:upper() == buffName:upper())
					or (not self.moduleSettings.exactMatch and string.match(totemName:upper(), buffName:upper()))) then
					endTime = startTime + realDuration
					remaining = endTime - GetTime()
					return duration, remaining, 1, icon, endTime
				end
			end
		end
	end

	return nil
end

function IceCustomBar.prototype:UpdateCustomBarEvent(event, unit)
	self:UpdateCustomBar(unit)
end

function IceCustomBar.prototype:UpdateTotems(event, totem)
	self:UpdateCustomBar(self.unit)
end

function IceCustomBar.prototype:UpdateCustomBar(unit, fromUpdate)
	if unit and unit ~= self.unit and not (self.unit == "main hand weapon" or self.unit == "off hand weapon") then
		return
	end

	self:ConditionalUpdateFlash()

	local now = GetTime()
	local remaining = nil
	local auraIcon = nil
	local endTime = 0

	if not fromUpdate then
		if tonumber(self.moduleSettings.buffToTrack) == nil then
			self.auraDuration, remaining, self.auraBuffCount, auraIcon, endTime =
				self:GetAuraDuration(self.unit, self.moduleSettings.buffToTrack)
		else
			self.auraDuration, remaining, self.auraBuffCount, auraIcon, endTime =
				self:GetAuraDuration(self.unit, GetSpellInfo(self.moduleSettings.buffToTrack))
		end

		if endTime == 0 then
			self.bIsAura = true
			self.auraDuration = 1
			self.auraEndTime = 0
			remaining = 1
		elseif not remaining then
			self.bIsAura = false
			self.auraEndTime = -1
		else
			self.bIsAura = false
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

	self.auraBuffCount = self.auraBuffCount or 0

	if self.auraEndTime ~= nil and (self.auraEndTime == 0 or self.auraEndTime >= now) and (not self.moduleSettings.minCount or self.auraBuffCount >= self.moduleSettings.minCount) then
		if not self:ShouldAlwaysSubscribe() and not fromUpdate and not IceHUD.IceCore:IsUpdateSubscribed(self) then
			if not self.UpdateCustomBarFunc then
				self.UpdateCustomBarFunc = function() self:UpdateCustomBar(self.unit, true) end
			end

			self.handlesOwnUpdates = true
			IceHUD.IceCore:RequestUpdates(self, self.UpdateCustomBarFunc)
		end

		self:Show(true)

		if not remaining then
			if self.auraEndTime == 0 then
				remaining = self.auraDuration
			else
				remaining = self.auraEndTime - now
			end
		end

		self:UpdateBar(self.auraDuration ~= 0 and remaining / self.auraDuration or 0, "undef")
	else
		self:UpdateBar(0, "undef")
		self:Show(false)
		if not self:ShouldAlwaysSubscribe() then
			self.handlesOwnUpdates = false
			IceHUD.IceCore:RequestUpdates(self, nil)
		end
	end

	local fullString = self.moduleSettings.upperText
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
		fullString = self.moduleSettings.upperText .. (not self.bIsAura and (" " .. buffString) or "")
	end

	if DogTag ~= nil then
		DogTag:AddFontString(self.frame.bottomUpperText, self.frame, fullString, "Unit", { unit = self.unit })
	else
		self:SetBottomText1(fullString)
		self:SetBottomText2(self.moduleSettings.lowerText)
	end

	self.barFrame.bar:SetVertexColor(self:GetBarColor())
	if self.flashFrame and self.flashFrame.flash then
		self.flashFrame.flash:SetVertexColor(self:GetBarColor())
	end
end

function IceCustomBar.prototype:OutCombat()
	IceCustomBar.super.prototype.OutCombat(self)

	self:UpdateCustomBar(self.unit)
end

function IceCustomBar.prototype:Show(bShouldShow, bForceHide)
	if bForceHide then
		IceCustomBar.super.prototype.Show(self, bShouldShow, bForceHide)
		return
	end

	if self.moduleSettings.displayWhenTargeting and self.target then
		IceCustomBar.super.prototype.Show(self, true)
	elseif self.moduleSettings.displayWhenEmpty then
		if not self.bIsVisible then
			IceCustomBar.super.prototype.Show(self, true)
		end
	else
		IceCustomBar.super.prototype.Show(self, bShouldShow)
	end
end
