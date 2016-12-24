local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceCustomCDBar = IceCore_CreateClass(IceBarElement)

local IceHUD = _G.IceHUD

local validDisplayModes = {"Always", "When ready", "When cooling down", "When targeting"}
local validBuffTimers = {"none", "seconds", "minutes:seconds", "minutes"}
local AuraIconWidth = 20
local AuraIconHeight = 20
local validInventorySlotNames = {"HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot",
	"HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot", "MainHandSlot",
	"SecondaryHandSlot", "AmmoSlot"}
local cooldownTypes = {STAT_CATEGORY_SPELL, HELPFRAME_ITEM_TITLE}

local COOLDOWN_TYPE_SPELL = 1
local COOLDOWN_TYPE_ITEM = 2

local localizedInventorySlotNames = {}

IceCustomCDBar.prototype.cooldownDuration = 0
IceCustomCDBar.prototype.cooldownEndTime = 0
IceCustomCDBar.prototype.coolingDown = false

-- Constructor --
function IceCustomCDBar.prototype:init()
	IceCustomCDBar.super.prototype.init(self, "MyCustomCDBar")
	self.textColorOverride = true

	for i=1, #validInventorySlotNames do
		if _G[strupper(validInventorySlotNames[i]).."_UNIQUE"] then
			localizedInventorySlotNames[i] = _G[strupper(validInventorySlotNames[i]).."_UNIQUE"]
		else
			localizedInventorySlotNames[i] = _G[strupper(validInventorySlotNames[i])]
		end
	end
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceCustomCDBar.prototype:Enable(core)
	IceCustomCDBar.super.prototype.Enable(self, core)

	self:RegisterEvent("SPELL_UPDATE_COOLDOWN", "UpdateCustomBarEvent")
	self:RegisterEvent("SPELL_UPDATE_USABLE", "UpdateCustomBarEvent")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "UpdateItemInventoryChanged")
	self:RegisterEvent("UNIT_AURA", "UpdateItemUnitInventoryChanged")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED", "UpdateItemUnitInventoryChanged")

	self:Show(true)

	if self.moduleSettings.auraIconScale == nil then
		self.moduleSettings.auraIconScale = 1
	end

	self:EnableUpdates(false)
	self:UpdateCustomBar()
	self:UpdateIcon()

	if self.moduleSettings.auraIconXOffset == nil then
		self.moduleSettings.auraIconXOffset = 40
	end
	if self.moduleSettings.auraIconYOffset == nil then
		self.moduleSettings.auraIconYOffset = 0
	end

	if self.moduleSettings.displayMode == nil then
		if self.moduleSettings.displayWhenEmpty then
			self.moduleSettings.displayMode = "Always"
		else
			self.moduleSettings.displayMode = "When cooling down"
		end
		self.moduleSettings.displayWhenEmpty = nil
	end

	self:FixupTextColors()
	self:SetCustomTextColor(self.frame.bottomUpperText, self.moduleSettings.upperTextColor)
	self:SetCustomTextColor(self.frame.bottomLowerText, self.moduleSettings.lowerTextColor)
end

function IceCustomCDBar.prototype:FixupTextColors()
	if not self.moduleSettings.upperTextColor then
		self.moduleSettings.upperTextColor = {r=1, g=1, b=1}
	end
	if not self.moduleSettings.lowerTextColor then
		self.moduleSettings.lowerTextColor = {r=1, g=1, b=1}
	end
end

function IceCustomCDBar.prototype:Disable(core)
	IceHUD.IceCore:RequestUpdates(self, nil)

	IceCustomCDBar.super.prototype.Disable(self, core)
end

-- OVERRIDE
function IceCustomCDBar.prototype:GetDefaultSettings()
	local settings = IceCustomCDBar.super.prototype.GetDefaultSettings(self)

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
	settings["cooldownToTrack"] = ""
	settings["barColor"] = {r=1, g=0, b=0, a=1}
	settings["displayMode"] = "When cooling down"
	settings["hideAnimationSettings"] = true
	settings["cooldownTimerDisplay"] = "minutes"
	settings["customBarType"] = "CD"
	settings["maxDuration"] = 0
	settings["displayAuraIcon"] = false
	settings["auraIconXOffset"] = 40
	settings["auraIconYOffset"] = 0
	settings["auraIconScale"] = 1
	settings["lowerTextColor"] = {r=1, g=1, b=1}
	settings["upperTextColor"] = {r=1, g=1, b=1}
	settings["cooldownType"] = COOLDOWN_TYPE_SPELL
	settings["itemToTrack"] = 15 -- trinket 0

	return settings
end

function IceCustomCDBar.prototype:CreateBar()
	IceCustomCDBar.super.prototype.CreateBar(self)

	if not self.barFrame.icon then
		self.barFrame.icon = self.masterFrame:CreateTexture(nil, "LOW")
		-- default texture so that 'config mode' can work without activating the bar first
		self.barFrame.icon:SetTexture("Interface\\Icons\\Spell_Frost_Frost")
		-- this cuts off the border around the buff icon
		self.barFrame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		self.barFrame.icon:SetDrawLayer("OVERLAY")
	end
	self:PositionIcons()
end

function IceCustomCDBar.prototype:PositionIcons()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	self.barFrame.icon:ClearAllPoints()
	self.barFrame.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.moduleSettings.auraIconXOffset, self.moduleSettings.auraIconYOffset)
	self.barFrame.icon:SetWidth(AuraIconWidth * (self.moduleSettings.auraIconScale or 1))
	self.barFrame.icon:SetHeight(AuraIconHeight * (self.moduleSettings.auraIconScale or 1))
end

function IceCustomCDBar.prototype:Redraw()
	IceCustomCDBar.super.prototype.Redraw(self)

	self:UpdateCustomBar()
end

function IceCustomCDBar.prototype:GetDisplayText(fromValue)
	local v = fromValue

	if not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL then
		if tonumber(fromValue) ~= nil then
			local spellName = GetSpellInfo(tonumber(fromValue))
			if spellName then
				v = spellName
			end
		end
	else
		if tonumber(v) then
			v = localizedInventorySlotNames[v]
		end
	end

	return v
end

-- OVERRIDE
function IceCustomCDBar.prototype:GetOptions()
	local opts = IceCustomCDBar.super.prototype.GetOptions(self)

	opts.textSettings.args.upperTextString.hidden = false
	opts.textSettings.args.lowerTextString.hidden = false
	opts.lowThresholdColor = nil

	opts["customHeader"] = {
		type = 'header',
		name = L["Custom CD settings"],
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
		name = string.format("%s %s", L["Module type:"], tostring(self:GetBarTypeDescription("CD"))),
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
			if v ~= "" then
				IceHUD.IceCore:RenameDynamicModule(self, v)
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<a name for this bar>",
		order = 30.3,
	}

	opts["cooldownType"] = {
		type = 'select',
		name = L["Cooldown type"],
		desc = L["The type of thing to track the cooldown of"],
		values = cooldownTypes,
		get = function()
			return self.moduleSettings.cooldownType or COOLDOWN_TYPE_SPELL
		end,
		set = function(info, v)
			local updateUpperText = false
			local dispStr = (not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL) and self.moduleSettings.cooldownToTrack or self.moduleSettings.itemToTrack
			if self:GetDisplayText(dispStr)
				== self.moduleSettings.upperText then
					updateUpperText = true
			end

			self.moduleSettings.cooldownType = v

			dispStr = (not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL) and self.moduleSettings.cooldownToTrack or self.moduleSettings.itemToTrack
			if updateUpperText then
				self.moduleSettings.upperText = self:GetDisplayText(dispStr)
			end
			self:UpdateCustomBar()
			self:UpdateIcon()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30.4,
	}

	opts["cooldownToTrack"] = {
		type = 'input',
		name = L["Spell to track"],
		desc = L["Which spell cooldown this bar will be tracking.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.moduleSettings.cooldownToTrack
		end,
		set = function(info, v)
			local orig = v
			if tonumber(v) ~= nil then
				v = GetSpellInfo(tonumber(v))
			end
			if v == nil then
				v = orig
			end
			if self.moduleSettings.cooldownToTrack == self.moduleSettings.upperText then
				self.moduleSettings.upperText = v
			end
			self.moduleSettings.cooldownToTrack = v
			self:Redraw()
			self:UpdateCustomBar()
			self:UpdateIcon()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.cooldownType and self.moduleSettings.cooldownType ~= COOLDOWN_TYPE_SPELL
		end,
		usage = "<which spell to track>",
		order = 30.6,
	}

	opts["cooldownItemToTrack"] = {
		type = 'select',
		name = L["Item to track"],
		desc = L["Which item cooldown this bar will be tracking."],
		values = localizedInventorySlotNames,
		get = function()
			return self.moduleSettings.itemToTrack or 15
		end,
		set = function(info, v)
			if self:GetDisplayText(self.moduleSettings.itemToTrack) == self.moduleSettings.upperText then
				self.moduleSettings.upperText = localizedInventorySlotNames[v]
			end
			self.moduleSettings.itemToTrack = v
			self:Redraw()
			self:UpdateCustomBar()
			self:UpdateIcon()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.cooldownType ~= COOLDOWN_TYPE_ITEM
		end,
		order = 30.6,
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

	opts["displayMode"] = {
		type = 'select',
		name = L["Display mode"],
		desc = L["When to display this bar."],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.displayMode)
		end,
		set = function(info, v)
			self.moduleSettings.displayMode = info.option.values[v]
			self:UpdateCustomBar()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		values = validDisplayModes,
		order = 30.9
	}

	opts["cooldownTimerDisplay"] = {
		type = 'select',
		name = L["Cooldown timer display"],
		desc = L["How to display the buff timer next to the name of the buff on the bar"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.cooldownTimerDisplay)
		end,
		set = function(info, v)
			self.moduleSettings.cooldownTimerDisplay = info.option.values[v]
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

	opts["bIgnoreRange"] = {
		type = 'toggle',
		name = L["Ignore range"],
		desc = L["If the selected ability has a max range or only works on friendly units, this will ignore that check. Meaning you can use a CD bar for buff spells and it will display when you have an enemy targeted."],
		get = function()
			return self.moduleSettings.bIgnoreRange
		end,
		set = function(info, v)
			self.moduleSettings.bIgnoreRange = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.cooldownType and self.moduleSettings.cooldownType ~= COOLDOWN_TYPE_SPELL
		end,
		order = 31.2,
	}

	opts["bUseNormalAlphas"] = {
		type = 'toggle',
		name = L["Use normal alpha"],
		desc = L["Usually CD bars will always display if they're set to 'When Ready' or 'Always' mode regardless of your other transparency settings. If you'd rather this bar show/hide as per normal transparency rules, then check this box."],
		get = function()
			return self.moduleSettings.bUseNormalAlphas
		end,
		set = function(info, v)
			self.moduleSettings.bUseNormalAlphas = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.displayMode ~= "When ready" and self.moduleSettings.displayMode ~= "Always"
		end,
		order = 31.3,
	}

	opts["bOnlyShowWithTarget"] = {
		type = 'toggle',
		name = L["Only show with a target selected"],
		desc = L["Use this for abilities that don't require a target to cast, but you only want to see them when you have a target"],
		width = 'double',
		get = function()
			return self.moduleSettings.bOnlyShowWithTarget
		end,
		set = function(info, v)
			self.moduleSettings.bOnlyShowWithTarget = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.displayMode ~= "When ready"
		end,
		order = 31.4,
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
					self:UpdateIcon()
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
			return self.moduleSettings.upperTextColor.r, self.moduleSettings.upperTextColor.g, self.moduleSettings.upperTextColor.b, self.alpha
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

function IceCustomCDBar.prototype:GetBarColor()
	return self.moduleSettings.barColor.r, self.moduleSettings.barColor.g, self.moduleSettings.barColor.b, self.alpha
end

-- 'Protected' methods --------------------------------------------------------

function IceCustomCDBar.prototype:GetCooldownDuration(buffName)
	buffName = self:GetSpellNameOrId(buffName)

	local now = GetTime()
	local localRemaining = nil
	local localStart, localDuration, hasCooldown = GetSpellCooldown(buffName)

	if (hasCooldown == 1) then
		-- the item has a potential cooldown
		if (localDuration <= 1.5) then
			return nil, nil
		end

		localRemaining = localDuration + (localStart - now)

		if self.moduleSettings.maxDuration and tonumber(self.moduleSettings.maxDuration) ~= 0 then
			localDuration = tonumber(self.moduleSettings.maxDuration)
		end

		return localDuration, localRemaining
	else
		return nil, nil
	end
end


function IceCustomCDBar.prototype:EnableUpdates(enable_update)
	-- If we want to display as soon as the spell is ready, we need to over-ride the parameter if
	-- it is possible the spell might be starting or stopping to be ready at any time. For spells
	-- without range (don't require a target) this is any time. For ranged spells that's when we
	-- have a valid target (IsSpellInRange() returns 0 or 1).
	--
	-- There is a hole in the logic here for spells that can be cast on any friendly target. When
	-- the correct UI option is selected they will cast on self when no target is selected. Deal
	-- with that later if it turns out to be a problem.
	if (not enable_update and (self.moduleSettings.displayMode == "When ready")--[[ and (IsUsableSpell(self.moduleSettings.cooldownToTrack) == 1)]]) then
-- Parnic: there are too many edge cases for "when ready" cooldowns that cause the bar to not appear when it should
--         so, i'm forcing updates to always run for any bar that's set to only show "when ready"
--		if SpellHasRange(self.moduleSettings.cooldownToTrack) then
--			if IsSpellInRange(self.moduleSettings.cooldownToTrack, "target") then
--				enable_update = true
--			end
--		else
			enable_update = true
--	 	end
	end

	self.handlesOwnUpdates = enable_update

	if enable_update then
		if not self.CustomUpdateFunc then
			self.CustomUpdateFunc = function() self:UpdateCustomBar(true) end
		end

		if not IceHUD.IceCore:IsUpdateSubscribed(self, self.CustomUpdateFunc) then
			IceHUD.IceCore:RequestUpdates(self, self.CustomUpdateFunc)
		end
	else
		IceHUD.IceCore:RequestUpdates(self, nil)
	end
end

function IceCustomCDBar.prototype:UpdateIcon()
	if self.barFrame.icon then
		if not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL then
			local name, rank, icon = GetSpellInfo(self.moduleSettings.cooldownToTrack)

			if icon ~= nil then
				self.barFrame.icon:SetTexture(icon)
			end
		elseif self.moduleSettings.itemToTrack then
			local itemId = GetInventoryItemID("player", GetInventorySlotInfo(validInventorySlotNames[self.moduleSettings.itemToTrack]))
			if itemId then
				local name, _, _, _, _, _, _, _, _, texture = GetItemInfo(itemId)
				if name and texture then
					self.barFrame.icon:SetTexture(texture)
				end
			end
		end

		if IceHUD.IceCore:IsInConfigMode() or self.moduleSettings.displayAuraIcon then
			self.barFrame.icon:Show()
		else
			self.barFrame.icon:Hide()
		end
	end
end

function IceCustomCDBar.prototype:UpdateItemInventoryChanged(event)
	if self.moduleSettings.cooldownType == COOLDOWN_TYPE_ITEM then
		self:UpdateCustomBar()
	end
end

function IceCustomCDBar.prototype:UpdateItemUnitInventoryChanged(event, unit)
	if unit == "player" and self.moduleSettings.cooldownType == COOLDOWN_TYPE_ITEM then
		self:UpdateCustomBar()
	end
end

function IceCustomCDBar.prototype:UpdateCustomBarEvent()
	if not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL then
		self:UpdateCustomBar()
	end
end

function IceCustomCDBar.prototype:UpdateCustomBar(fromUpdate)
	local now = GetTime()
	local remaining = nil
	local auraIcon = nil

	if not fromUpdate then
		if not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL then
			self.cooldownDuration, remaining =
				self:GetCooldownDuration(self.moduleSettings.cooldownToTrack)
		elseif self.moduleSettings.itemToTrack then
			local start = nil
			start, self.cooldownDuration = GetInventoryItemCooldown("player", GetInventorySlotInfo(validInventorySlotNames[self.moduleSettings.itemToTrack]))
			if start and start > 0 then
				remaining = self.cooldownDuration - (GetTime() - start)
			end
		end

		if not remaining then
			self.cooldownEndTime = nil
		else
			self.cooldownEndTime = remaining + now
		end
	end

	if self.cooldownEndTime and self.cooldownEndTime >= now then
		if not fromUpdate then
			self:EnableUpdates(true)
		end

		self:Show(true)

		if not remaining then
			remaining = self.cooldownEndTime - now
		end

		self:UpdateBar(self.cooldownDuration ~= 0 and remaining / self.cooldownDuration or 0, "undef")
	else
		self:UpdateBar(0, "undef")
		self:Show(false)
		self:EnableUpdates(false)
	end

	if (remaining ~= nil) then
		local buffString = ""
		if self.moduleSettings.cooldownTimerDisplay == "seconds" then
			buffString = tostring(ceil(remaining or 0)) .. "s"
		else
			local seconds = ceil(remaining)%60
			local minutes = ceil(remaining)/60

			if self.moduleSettings.cooldownTimerDisplay == "minutes:seconds" then
				buffString = floor(minutes) .. ":" .. string.format("%02d", seconds)
			elseif self.moduleSettings.cooldownTimerDisplay == "minutes" then
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

	self:SetBottomText2(self.moduleSettings.lowerText)

	self:UpdateAlpha()

	self.barFrame.bar:SetVertexColor(self:GetBarColor())

	self.coolingDown = remaining ~= nil and remaining > 0
end

function IceCustomCDBar.prototype:OutCombat()
	IceCustomCDBar.super.prototype.OutCombat(self)

	self:UpdateCustomBar()
end

function IceCustomCDBar.prototype:TargetChanged()
	IceCustomCDBar.super.prototype.TargetChanged(self)

	-- Target changing only affects us if we want to show the bar as soon as it is ready.
	if (self.moduleSettings.displayMode == "When ready" or self.moduleSettings.displayMode == "Always") then
		self:UpdateCustomBar()
	end
end

function IceCustomCDBar.prototype:IsReady()
	local is_ready = nil
	if not self.moduleSettings.cooldownType or self.moduleSettings.cooldownType == COOLDOWN_TYPE_SPELL then
		local checkSpell = self:GetSpellNameOrId(self.moduleSettings.cooldownToTrack)

		if (IsUsableSpell(checkSpell)) then
			if (not self.moduleSettings.bIgnoreRange and SpellHasRange(checkSpell)) or (self.moduleSettings.bOnlyShowWithTarget) then
				if (UnitExists("target") and (not SpellHasRange(checkSpell) or IsSpellInRange(checkSpell, "target") == 1))
					or (not UnitExists("target") and not self.moduleSettings.bOnlyShowWithTarget and IsSpellInRange(checkSpell, "player")) then
					is_ready = 1
				end
			else
				is_ready = 1
			end
		end
	else
		local start, duration = GetInventoryItemCooldown("player", GetInventorySlotInfo(validInventorySlotNames[self.moduleSettings.itemToTrack]))
		if (not start or start == 0) and (not duration or duration == 0) then
			is_ready = 1
		end
	end

	return is_ready
end

function IceCustomCDBar.prototype:GetSpellNameOrId(spellName)
	return spellName
end

function IceCustomCDBar.prototype:Show(bShouldShow, bForceHide)
	if self.moduleSettings.enabled and not bForceHide then
		if self.moduleSettings.displayMode == "Always" then
			--if self.target then
				IceCustomCDBar.super.prototype.Show(self, true)
			--else
				--IceCustomCDBar.super.prototype.Show(self, bShouldShow)
			--end
		elseif self.moduleSettings.displayMode == "When ready" then
			if not self.coolingDown and self:IsReady() and (not self.moduleSettings.bOnlyShowWithTarget or UnitExists("target")) then
				IceCustomCDBar.super.prototype.Show(self, true)
			else
				IceCustomCDBar.super.prototype.Show(self, false)
			end
		elseif self.moduleSettings.displayMode == "When targeting" then
		    if UnitExists("target") then
				IceCustomCDBar.super.prototype.Show(self, true)
			else
				IceCustomCDBar.super.prototype.Show(self, false)
			end
		else
			IceCustomCDBar.super.prototype.Show(self, bShouldShow)
		end
	else
		IceCustomCDBar.super.prototype.Show(self, bShouldShow)
	end
end

function IceCustomCDBar.prototype:UseTargetAlpha(scale)
	if self.moduleSettings.bUseNormalAlphas
		and (self.moduleSettings.displayMode == "When ready" or self.moduleSettings.displayMode == "Always") then
		return scale == 0
	elseif (self.moduleSettings.displayMode == "When ready" or self.moduleSettings.displayMode == "Always")
		and scale == 0 then
		return false
	end

	return IceCustomCDBar.super.prototype:UseTargetAlpha(self, scale)
end
