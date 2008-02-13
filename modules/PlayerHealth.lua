local AceOO = AceLibrary("AceOO-2.0")

local PlayerHealth = AceOO.Class(IceUnitBar)

PlayerHealth.prototype.resting = nil

-- Constructor --
function PlayerHealth.prototype:init()
	PlayerHealth.super.prototype.init(self, "PlayerHealth", "player")
	
	self:SetDefaultColor("PlayerHealth", 37, 164, 30)
end


function PlayerHealth.prototype:GetDefaultSettings()
	local settings = PlayerHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 1
	settings["hideBlizz"] = true
	settings["upperText"] = "[PercentHP:Round]"
	settings["lowerText"] = "[FractionalHP:HPColor:Bracket]"
	settings["allowMouseInteraction"] = true

	return settings
end


function PlayerHealth.prototype:Enable(core)
	PlayerHealth.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")
	
	self:RegisterEvent("PLAYER_UPDATE_RESTING", "Resting")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "Resting")

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end

	self:Resting()
	--self:Update(self.unit)
end


-- OVERRIDE
function PlayerHealth.prototype:GetOptions()
	local opts = PlayerHealth.super.prototype.GetOptions(self)
	
	opts["classColor"] = {
		type = "toggle",
		name = "Class color bar",
		desc = "Use class color as the bar color instead of default color",
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
		order = 40
	}
	
	opts["hideBlizz"] = {
		type = "toggle",
		name = "Hide Blizzard Frame",
		desc = "Hides Blizzard Player frame and disables all events related to it",
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
		order = 41
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
		order = 42
	}

	opts["allowClickTarget"] = {
		type = 'toggle',
		name = 'Allow click-targeting',
		desc = 'Whether or not to allow click targeting/casting and the player drop-down menu for this bar (Note: does not work properly with HiBar, have to click near the base of the bar)',
		get = function()
			return self.moduleSettings.allowMouseInteraction
		end,
		set = function(v)
			self.moduleSettings.allowMouseInteraction = v
			self:CreateBackground(true)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = '',
		order = 43
	}
	
	return opts
end


function PlayerHealth.prototype:CreateBackground(redraw)
	PlayerHealth.super.prototype.CreateBackground(self)

	if not self.frame.button then
		self.frame.button = CreateFrame("Button", nil, self.frame, "SecureUnitButtonTemplate")
	end

	self.frame.button:ClearAllPoints()
	-- Parnic - kinda hacky, but in order to fit this region to multiple types of bars, we need to do this...
	--          would be nice to define this somewhere in data, but for now...here we are
	if self.settings.barTexture == "HiBar" then
		self.frame.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, 0)
		self.frame.button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT", -1 * self.frame:GetWidth(), 0)
	else
		self.frame.button:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -6, 0)
		self.frame.button:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMRIGHT", -1 * self.frame:GetWidth() / 3, 0)
	end

	self.frame.button.menu = function()
		ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor");
	end

	if self.moduleSettings.allowMouseInteraction then
		self.frame.button:EnableMouse(true)
		self.frame.button:RegisterForClicks("AnyUp")
		self.frame.button:SetAttribute("type1", "target")
		self.frame.button:SetAttribute("type2", "menu")
		self.frame.button:SetAttribute("unit", self.unit)

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


function PlayerHealth.prototype:Resting()
	self.resting = IsResting()
	self:Update(self.unit)
end


function PlayerHealth.prototype:Update(unit)
	PlayerHealth.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end

	local color = "PlayerHealth"

	if (self.moduleSettings.classColor) then
		color = self.unitClass
	end

	if (self.moduleSettings.scaleHealthColor) then
		color = "ScaledHealthColor"
	end

	if not (self.alive) then
		color = "Dead"
	end

	local textColor = color
	if (self.resting) then
		textColor = "Text"
	end

	self:UpdateBar(self.health/self.maxHealth, color)

	if not AceLibrary:HasInstance("LibDogTag-2.0") then
		self:SetBottomText1(math.floor(self.healthPercentage * 100))
		self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), textColor)
	end
end




function PlayerHealth.prototype:ShowBlizz()
	PlayerFrame:Show()

	PlayerFrame:RegisterEvent("UNIT_LEVEL");
	PlayerFrame:RegisterEvent("UNIT_COMBAT");
	PlayerFrame:RegisterEvent("UNIT_FACTION");
	PlayerFrame:RegisterEvent("UNIT_MAXMANA");
	PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
	PlayerFrame:RegisterEvent("PLAYER_ENTER_COMBAT");
	PlayerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT");
	PlayerFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	PlayerFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
	PlayerFrame:RegisterEvent("PLAYER_UPDATE_RESTING");
	PlayerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
	PlayerFrame:RegisterEvent("PARTY_LEADER_CHANGED");
	PlayerFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
	PlayerFrame:RegisterEvent("RAID_ROSTER_UPDATE");
	PlayerFrame:RegisterEvent("PLAYTIME_CHANGED");
end


function PlayerHealth.prototype:HideBlizz()
	PlayerFrame:Hide()

	PlayerFrame:UnregisterAllEvents()
end



-- Load us up
IceHUD.PlayerHealth = PlayerHealth:new()
