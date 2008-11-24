local AceOO = AceLibrary("AceOO-2.0")

IceTargetHealth = AceOO.Class(IceUnitBar)

IceTargetHealth.prototype.color = nil
IceTargetHealth.prototype.determineColor = true
IceTargetHealth.prototype.registerEvents = true
IceTargetHealth.prototype.texWidth = 128
IceTargetHealth.prototype.texHeight = 128
IceTargetHealth.prototype.classLeft = 0
IceTargetHealth.prototype.classRight = 0.9375
IceTargetHealth.prototype.classTop = 0
IceTargetHealth.prototype.classBottom = 0.78125
IceTargetHealth.prototype.EliteTexture = IceElement.TexturePath .. "Elite"
IceTargetHealth.prototype.RareEliteTexture = IceElement.TexturePath .. "RareElite"
IceTargetHealth.prototype.RareTexture = IceElement.TexturePath .. "Rare"

local configMode = false

-- Constructor --
function IceTargetHealth.prototype:init(moduleName, unit)
	if not moduleName or not unit then
		IceTargetHealth.super.prototype.init(self, "TargetHealth", "target")
	else
		IceTargetHealth.super.prototype.init(self, moduleName, unit)
	end

	self:SetDefaultColor("TargetHealthHostile", 231, 31, 36)
	self:SetDefaultColor("TargetHealthFriendly", 46, 223, 37)
	self:SetDefaultColor("TargetHealthNeutral", 210, 219, 87)
end


function IceTargetHealth.prototype:GetDefaultSettings()
	local settings = IceTargetHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 2
	settings["classColor"] = false
	settings["hideBlizz"] = false
	settings["upperText"] = "[PercentHP:Round]"
	settings["lowerText"] = "[(HP:Round \"/\" MaxHP:Round):HPColor:Bracket]"
	settings["raidIconOnTop"] = true
	settings["showRaidIcon"] = true
	settings["raidIconXOffset"] = 12
	settings["raidIconYOffset"] = 0
	settings["lockIconAlpha"] = false
	settings["abbreviateHealth"] = true
	settings["classIconOffset"] = {x=0, y=0}
	settings["showClassificationIcon"] = false
	settings["showPvPIcon"] = true
	settings["PvPIconOffset"] = {x=23, y=11}
	settings["PvPIconScale"] = 1.0

	return settings
end


-- OVERRIDE
function IceTargetHealth.prototype:GetOptions()
	local opts = IceTargetHealth.super.prototype.GetOptions(self)

	opts["classColor"] = {
		type = "toggle",
		name = "Class color bar",
		desc = "Use class color as the bar color instead of reaction color",
		get = function()
			return self.moduleSettings.classColor
		end,
		set = function(value)
			self.moduleSettings.classColor = value
			self:Update(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 41
	}

	opts["hideBlizz"] = {
		type = "toggle",
		name = "Hide Blizzard Frame",
		desc = "Hides Blizzard Target frame and disables all events related to it",
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
		order = 42
	}

	opts["scaleHealthColor"] = {
		type = "toggle",
		name = "Color bar by health %",
		desc = "Colors the health bar from MaxHealthColor to MinHealthColor based on current health %",
		get = function()
			return self.moduleSettings.scaleHealthColor
		end,
		set = function(value)
			self.moduleSettings.scaleHealthColor = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 43
	}

if not IceHUD.IceCore:ShouldUseDogTags() then
	opts["shortenHealth"] = {
		type = 'toggle',
		name = 'Abbreviate estimated health',
		desc = 'If this is checked, then a health value of 1100 will display as 1.1k, otherwise it shows the number',
		get = function()
			return self.moduleSettings.abbreviateHealth
		end,
		set = function(v)
			self.moduleSettings.abbreviateHealth = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40.1
	}
end

	opts["iconSettings"] =
	{
		type = 'group',
		name = '|c' .. self.configColor .. 'Icon Settings|r',
		desc = 'Settings related to icons',
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		args = {
			iconConfigMode = {
				type = "toggle",
				name = "Icon config mode",
				desc = "With this enabled, all icons draw so you can configure their placement\n\nNote: the combat and status icons are actually the same texture so you'll only see combat in config mode (unless you're already resting)",
				get = function()
					return configMode
				end,
				set = function(v)
					configMode = v
					self:CheckPvP()
					self:UpdateRaidTargetIcon()
					self:Redraw()
				end,
				order = 5
			},

			lockIconAlpha = {
				type = "toggle",
				name = "Lock all icons to 100% alpha",
				desc = "With this enabled, all icons will be 100% visible regardless of the alpha settings for this bar.",
				get = function()
					return self.moduleSettings.lockIconAlpha
				end,
				set = function(v)
					self.moduleSettings.lockIconAlpha = v
					self:Redraw()
				end,
				order = 6
			},

			PvPIcon = {
				type = "toggle",
				name = "Show PvP icon",
				desc = "Whether or not to show the PvP icon",
				get = function()
					return self.moduleSettings.showPvPIcon
				end,
				set = function(value)
					self.moduleSettings.showPvPIcon = value
					self:CheckPvP()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 40
			},
			PvPIconOffsetX = {
				type = "range",
				name = "PvP Icon Horizontal Offset",
				desc = "How much to offset the PvP icon from the bar horizontally",
				min = 0,
				max = 250,
				step = 1,
				get = function()
					return self.moduleSettings.PvPIconOffset['x']
				end,
				set = function(v)
					self.moduleSettings.PvPIconOffset['x'] = v
					self:SetTexLoc(self.frame.PvPIcon, self.moduleSettings.PvPIconOffset['x'], self.moduleSettings.PvPIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showPvPIcon
				end,
				order = 41
			},
			PvPIconOffsetY = {
				type = "range",
				name = "PvP Icon Vertical Offset",
				desc = "How much to offset the PvP icon from the bar vertically",
				min = -300,
				max = 50,
				step = 1,
				get = function()
					return self.moduleSettings.PvPIconOffset['y']
				end,
				set = function(v)
					self.moduleSettings.PvPIconOffset['y'] = v
					self:SetTexLoc(self.frame.PvPIcon, self.moduleSettings.PvPIconOffset['x'], self.moduleSettings.PvPIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showPvPIcon
				end,
				order = 42
			},
			PvPIconScale = {
				type = "range",
				name = "PvP Icon Scale",
				desc = "How much to scale the PvP icon",
				min = 0.05,
				max = 2,
				step = 0.05,
				get = function()
					return self.moduleSettings.PvPIconScale
				end,
				set = function(v)
					self.moduleSettings.PvPIconScale = v
					self:SetTexScale(self.frame.PvPIcon, 20, 20, v)
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showPvPIcon
				end,
				order = 43
			},

			showRaidIcon = {
				type = "toggle",
				name = "Show Raid Icon",
				desc = "Whether or not to show the raid icon above this bar",
				get = function()
					return self.moduleSettings.showRaidIcon
				end,
				set = function(value)
					self.moduleSettings.showRaidIcon = value
					self:UpdateRaidTargetIcon()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 50
			},

			raidIconOnTop = {
				type = "toggle",
				name = "Draw Raid Icon On Top",
				desc = "Whether to draw the raid icon in front of or behind this bar",
				get = function()
					return self.moduleSettings.raidIconOnTop
				end,
				set = function(value)
					self.moduleSettings.raidIconOnTop = value
					self:UpdateRaidTargetIcon()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showRaidIcon
				end,
				order = 52
			},

			raidIconXOffset = {
				type = "range",
				name = "Raid Icon X Offset",
				desc = "How far to push the raid icon right or left",
				min = -300,
				max = 300,
				step = 1,
				get = function()
					return self.moduleSettings.raidIconXOffset
				end,
				set = function(value)
					self.moduleSettings.raidIconXOffset = value
					self:SetRaidIconPlacement()
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 53
			},

			raidIconYOffset = {
				type = "range",
				name = "Raid Icon Y Offset",
				desc = "How far to push the raid icon up or down",
				min = -300,
				max = 300,
				step = 1,
				get = function()
					return self.moduleSettings.raidIconYOffset
				end,
				set = function(value)
					self.moduleSettings.raidIconYOffset = value
					self:SetRaidIconPlacement()
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 54
			},

			showClassificationIcon = {
				type = "toggle",
				name = "Show Elite Icon",
				desc = "Whether or not to show the rare/elite icon above this bar",
				get = function()
					return self.moduleSettings.showClassificationIcon
				end,
				set = function(value)
					self.moduleSettings.showClassificationIcon = value
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 60
			},

			classIconXOffset = {
				type = "range",
				name = "Elite Icon X Offset",
				desc = "How far to push the elite icon right or left",
				min = -300,
				max = 300,
				step = 1,
				get = function()
					return self.moduleSettings.classIconOffset['x']
				end,
				set = function(value)
					self.moduleSettings.classIconOffset['x'] = value
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 61
			},

			classIconYOffset = {
				type = "range",
				name = "Elite Icon Y Offset",
				desc = "How far to push the elite icon up or down",
				min = -300,
				max = 300,
				step = 1,
				get = function()
					return self.moduleSettings.classIconOffset['y']
				end,
				set = function(value)
					self.moduleSettings.classIconOffset['y'] = value
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 62
			}
		}
	}

	return opts
end


function IceTargetHealth.prototype:Enable(core)
	IceTargetHealth.super.prototype.Enable(self, core)

	if self.registerEvents then
		self:RegisterEvent("UNIT_HEALTH", "Update")
		self:RegisterEvent("UNIT_MAXHEALTH", "Update")
		self:RegisterEvent("UNIT_FLAGS", "Update")
		self:RegisterEvent("UNIT_FACTION", "Update")
		self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidTargetIcon")
		self:RegisterEvent("UPDATE_FACTION", "CheckPvP")
		self:RegisterEvent("PLAYER_FLAGS_CHANGED", "CheckPvP")
		self:RegisterEvent("UNIT_FACTION", "CheckPvP")
	end

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end

	self:CreateRaidIconFrame()

	self:Update(self.unit)
end


function IceTargetHealth.prototype:Disable(core)
	IceTargetHealth.super.prototype.Disable(self, core)
end



function IceTargetHealth.prototype:Update(unit)
	IceTargetHealth.super.prototype.Update(self)

	if (unit and (unit ~= self.unit)) then
		return
	end

	if unit and not (UnitExists(unit)) then
		self:Show(false)
		return
	else	
		self:Show(true)
	end

	self:UpdateRaidTargetIcon()

	local classification = UnitClassification(self.unit);
	if not self.moduleSettings.showClassificationIcon then
		self:DestroyTexFrame(self.frame.classIcon)
	else
		if not self.frame.classIcon then
			self.frame.classIcon = self:CreateTexCoord(self.frame.classIcon, self.EliteTexture, self.texWidth, self.texHeight,
						self.moduleSettings.scale / 3.0, self.classLeft, self.classRight, self.classTop, self.classBottom)
		end

		self:SetTexLoc(self.frame.classIcon, self.moduleSettings.classIconOffset['x'], self.moduleSettings.classIconOffset['y'])
		self.frame.classIcon:Show()
		self.frame.classIcon:SetAlpha(self.alpha == 0 and 0 or math.min(1, self.alpha + 0.2))

		if configMode or IceHUD.IceCore:IsInConfigMode() or classification == "worldboss" or classification == "elite" then
			self.frame.classIcon:SetTexture(self.EliteTexture)
		elseif classification == "rareelite" then
			self.frame.classIcon:SetTexture(self.RareEliteTexture)
		elseif classification == "rare" then
			self.frame.classIcon:SetTexture(self.RareTexture)
		else
			self:DestroyTexFrame(self.frame.classIcon)
			self.frame.classIcon:Hide()
		end
	end

	if self.determineColor then
		self.color = "TargetHealthFriendly" -- friendly > 4

		local reaction = UnitReaction("target", "player")
		if (reaction and (reaction == 4)) then
			self.color = "TargetHealthNeutral"
		elseif (reaction and (reaction < 4)) then
			self.color = "TargetHealthHostile"
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
	end

	self:UpdateBar(self.health/self.maxHealth, self.color)

	if not IceHUD.IceCore:ShouldUseDogTags() then
		self:SetBottomText1(math.floor(self.healthPercentage * 100))

		if self.moduleSettings.abbreviateHealth then
			self.health = self:Round(self.health)
			self.maxHealth = self:Round(self.maxHealth)
		end

		if (self.maxHealth ~= 100) then
			self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), self.color)
		else
			self:SetBottomText2()
		end
	end

	self:CheckPvP()
	self:SetIconAlpha()
end


function IceTargetHealth.prototype:CreateTexCoord(texframe, icon, width, height, scale, left, right, top, bottom)
	if not texframe then
		texframe = self.frame:CreateTexture(nil, "BACKGROUND")
	end

	texframe:SetTexture(icon)
	if left and right and top and bottom then
		texframe:SetTexCoord(left, right, top, bottom)
	end
	self:SetTexScale(texframe, width, height, scale or 1)

	return texframe
end


function IceTargetHealth.prototype:SetTexLoc(texframe, xpos, ypos, anchorFrom, anchorTo)
	texframe:Show()
	texframe:ClearAllPoints()
	texframe:SetPoint(anchorFrom or "TOPLEFT", self.frame, anchorTo or "TOPLEFT", xpos or 0, ypos or 0)
end


function IceTargetHealth.prototype:SetTexScale(texframe, width, height, scale)
	texframe:SetWidth(width * scale)
	texframe:SetHeight(height * scale)
end


function IceTargetHealth.prototype:DestroyTexFrame(texframe)
	if not texframe then
		return nil
	end

	texframe:SetTexture(nil)
	texframe:Hide()
	texframe:ClearAllPoints()

	return texframe
end



function IceTargetHealth.prototype:CreateRaidIconFrame()
	if (not self.frame.raidIcon) then
		self.frame.raidIcon = CreateFrame("Frame", nil, self.frame)
	end

	if (not self.frame.raidIcon.icon) then
		self.frame.raidIcon.icon = self.frame.raidIcon:CreateTexture(nil, "BACKGROUND")
		self.frame.raidIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	end

	self:SetRaidIconPlacement()
	self.frame.raidIcon:SetWidth(16)
	self.frame.raidIcon:SetHeight(16)

	self.frame.raidIcon.icon:SetAllPoints(self.frame.raidIcon)
	SetRaidTargetIconTexture(self.frame.raidIcon.icon, 0)
	self.frame.raidIcon:Hide()
end

function IceTargetHealth.prototype:SetRaidIconPlacement()
	self.frame.raidIcon:ClearAllPoints()
	self.frame.raidIcon:SetPoint("BOTTOM", self.frame, "TOPLEFT", self.moduleSettings.raidIconXOffset, self.moduleSettings.raidIconYOffset)
end


function IceTargetHealth.prototype:UpdateRaidTargetIcon()
	if self.moduleSettings.raidIconOnTop then
		self.frame.raidIcon:SetFrameStrata("MEDIUM")
	else
		self.frame.raidIcon:SetFrameStrata("LOW")
	end

	if not self.moduleSettings.showRaidIcon or (not UnitExists(self.unit) and (not configMode and not IceHUD.IceCore:IsInConfigMode())) then
		self.frame.raidIcon:Hide()
		return
	end

	local index = (IceHUD.IceCore:IsInConfigMode() or configMode) and 1 or GetRaidTargetIndex(self.unit);

	if (index and (index > 0)) then
		SetRaidTargetIconTexture(self.frame.raidIcon.icon, index)
		self.frame.raidIcon:Show()
	else
		self.frame.raidIcon:Hide()
	end

	if self.frame.raidIcon then
		self.frame.raidIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end
end


function IceTargetHealth.prototype:Round(health)
	if (health > 1000000) then
		return IceHUD:MathRound(health/1000000, 1) .. "M"
	end
	if (health > 1000) then
		return IceHUD:MathRound(health/1000, 1) .. "k"
	end
	return health
end


function IceTargetHealth.prototype:CheckPvP()
	local pvpMode = nil
	local minx, maxx, miny, maxy

	if configMode or UnitIsPVPFreeForAll(self.unit) then
		pvpMode = "FFA"

		minx, maxx, miny, maxy = 0.05, 0.605, 0.015, 0.57
	elseif UnitIsPVP(self.unit) then
		pvpMode = UnitFactionGroup(self.unit)

		if pvpMode == "Alliance" then
			minx, maxx, miny, maxy = 0.07, 0.58, 0.06, 0.57
		else
			minx, maxx, miny, maxy = 0.08, 0.58, 0.045, 0.545
		end
	end

	if pvpMode then
		if configMode or self.moduleSettings.showPvPIcon then
			self.frame.PvPIcon = self:CreateTexCoord(self.frame.PvPIcon, "Interface\\TargetingFrame\\UI-PVP-"..pvpMode, 20, 20,
						self.moduleSettings.PvPIconScale, minx, maxx, miny, maxy)
			self:SetTexLoc(self.frame.PvPIcon, self.moduleSettings.PvPIconOffset['x'], self.moduleSettings.PvPIconOffset['y'])
		elseif self.frame.PvPIcon and self.frame.PvPIcon:IsVisible() then
			self.frame.PvPIcon = self:DestroyTexFrame(self.frame.PvPIcon)
		end
	else
		if self.frame.PvPIcon and self.frame.PvPIcon:IsVisible() then
			self.frame.PvPIcon = self:DestroyTexFrame(self.frame.PvPIcon)
		end
	end
end

function IceTargetHealth.prototype:SetIconAlpha()
	if self.frame.PvPIcon then
		self.frame.PvPIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end
end



function IceTargetHealth.prototype:ShowBlizz()
	TargetFrame:Show()
	TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	TargetFrame:RegisterEvent("UNIT_HEALTH")
	TargetFrame:RegisterEvent("UNIT_LEVEL")
	TargetFrame:RegisterEvent("UNIT_FACTION")
	TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
	TargetFrame:RegisterEvent("UNIT_AURA")
	TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
	TargetFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	TargetFrame:RegisterEvent("RAID_TARGET_UPDATE")
	
	ComboFrame:Show()
	ComboFrame:RegisterEvent("PLAYER_TARGET_CHANGED");
	ComboFrame:RegisterEvent("PLAYER_COMBO_POINTS");
end


function IceTargetHealth.prototype:HideBlizz()
	TargetFrame:Hide()
	TargetFrame:UnregisterAllEvents()
	
	ComboFrame:Hide()
	ComboFrame:UnregisterAllEvents()
end



-- Load us up
IceHUD.TargetHealth = IceTargetHealth:new()
