local AceOO = AceLibrary("AceOO-2.0")

local MobHealth = nil
IceTargetHealth = AceOO.Class(IceUnitBar)

IceTargetHealth.prototype.color = nil
IceTargetHealth.prototype.determineColor = true
IceTargetHealth.prototype.registerEvents = true

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

	MobHealth = AceLibrary:HasInstance("LibMobHealth-4.0") and AceLibrary("LibMobHealth-4.0") or nil
end


function IceTargetHealth.prototype:GetDefaultSettings()
	local settings = IceTargetHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 2
	settings["mobhealth"] = (MobHealth3 ~= nil)
	settings["classColor"] = false
	settings["hideBlizz"] = true
	settings["upperText"] = "[PercentHP:Round]"
	settings["lowerText"] = "[(HP:Round \"/\" MaxHP:Round):HPColor:Bracket]"
	settings["raidIconOnTop"] = true
	settings["showRaidIcon"] = true
	settings["raidIconXOffset"] = 12
	settings["raidIconYOffset"] = 0
	settings["lockIconAlpha"] = false
	settings["abbreviateHealth"] = true

	return settings
end


-- OVERRIDE
function IceTargetHealth.prototype:GetOptions()
	local opts = IceTargetHealth.super.prototype.GetOptions(self)

	opts["mobhealth"] = {
		type = "toggle",
		name = "MobHealth3 support",
		desc = "Enable/disable MobHealth3 target HP data. If this option is gray, you do not have MobHealth3.",
		get = function()
			return self.moduleSettings.mobhealth
		end,
		set = function(value)
			self.moduleSettings.mobhealth = value
			self:Update(self.unit)
		end,
		disabled = function()
			return (not self.moduleSettings.enabled) and (MobHealth3 == nil)
		end,
		order = 40
	}

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

	opts["showRaidIcon"] = {
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
	}

	opts["lockIconAlpha"] = {
		type = "toggle",
		name = "Lock raid icon to 100% alpha",
		desc = "With this enabled, the raid icon is always 100% alpha, regardless of the bar's alpha. Otherwise, it assumes the bar's alpha level.",
		get = function()
			return self.moduleSettings.lockIconAlpha
		end,
		set = function(value)
			self.moduleSettings.lockIconAlpha = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 51
	}

	opts["raidIconOnTop"] = {
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
	}

	opts["raidIconXOffset"] = {
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
	}

	opts["raidIconYOffset"] = {
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
	}

	opts["shortenHealth"] = {
		type = 'toggle',
		name = 'Abbreviate estimated health',
		desc = 'If this is checked, then a health value of 1100 will display as 1.1k, otherwise it shows the number\n\nNote: this only applies if you are NOT using DogTag',
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

	if not (UnitExists(unit)) then
		self:Show(false)
		return
	else	
		self:Show(true)
	end

	self:UpdateRaidTargetIcon()

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

	if not AceLibrary:HasInstance("LibDogTag-3.0") then
		self:SetBottomText1(math.floor(self.healthPercentage * 100))

		-- first see if we have LibMobHealth that we can piggyback on
		if MobHealth then
			self.health = MobHealth:GetUnitCurrentHP(self.unit)
			self.maxHealth = MobHealth:GetUnitMaxHP(self.unit)
		elseif (self.maxHealth == 100 and self.moduleSettings.mobhealth and MobHealth3) then
			-- assumption that if a unit's max health is 100, it's not actual amount
			-- but rather a percentage - this obviously has one caveat though

			self.health, self.maxHealth, _ = MobHealth3:GetUnitHealth(self.unit, self.health, self.maxHealth)
		end

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

	if not (UnitExists(self.unit)) or not self.moduleSettings.showRaidIcon then
		self.frame.raidIcon:Hide()
		return
	end

	local index = GetRaidTargetIndex(self.unit);

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
		return self:MathRound(health/1000000, 1) .. "M"
	end
	if (health > 1000) then
		return self:MathRound(health/1000, 1) .. "k"
	end
	return health
end


function IceTargetHealth.prototype:MathRound(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num  * mult + 0.5) / mult
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
