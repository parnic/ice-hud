local AceOO = AceLibrary("AceOO-2.0")

local PlayerHealth = AceOO.Class(IceUnitBar)

PlayerHealth.prototype.resting = nil

local configMode = false
local HealComm
local incomingHealAmt = 0

-- Constructor --
function PlayerHealth.prototype:init()
	PlayerHealth.super.prototype.init(self, "PlayerHealth", "player")
	
	self:SetDefaultColor("PlayerHealth", 37, 164, 30)
	self:SetDefaultColor("PlayerHealthHealAmount", 37, 164, 30)
end


function PlayerHealth.prototype:GetDefaultSettings()
	local settings = PlayerHealth.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 1
	settings["hideBlizz"] = false
	settings["upperText"] = "[PercentHP:Round]"
	settings["lowerText"] = "[FractionalHP:HPColor:Bracket]"
	settings["allowMouseInteraction"] = false
	settings["allowMouseInteractionCombat"] = false
	settings["healAlpha"] = 0.6
	settings["lockIconAlpha"] = false

	settings["showStatusIcon"] = true
	settings["statusIconOffset"] = {x=110, y=0}
	settings["statusIconScale"] = 1
	settings["showStatusCombat"] = true
	settings["showStatusResting"] = true

	settings["showLeaderIcon"] = true
	settings["leaderIconOffset"] = {x=135, y=15}
	settings["leaderIconScale"] = 0.9

	settings["showLootMasterIcon"] = true
	settings["lootMasterIconOffset"] = {x=100, y=-20}
	settings["lootMasterIconScale"] = 0.9

	settings["showPvPIcon"] = true
	settings["PvPIconOffset"] = {x=95, y=-40}
	settings["PvPIconScale"] = 0.9

	return settings
end


function PlayerHealth.prototype:Enable(core)
	PlayerHealth.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")

	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringWorld")

	self:RegisterEvent("PLAYER_UPDATE_RESTING", "Resting")

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckCombat")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckCombat")

	self:RegisterEvent("PARTY_LEADER_CHANGED", "CheckLeader")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "CheckLeader")

	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED", "CheckLootMaster")

	self:RegisterEvent("UPDATE_FACTION", "CheckPvP")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "CheckPvP")
	self:RegisterEvent("UNIT_FACTION", "CheckPvP")

	if AceLibrary:HasInstance("LibHealComm-3.0") then
		HealComm = AceLibrary("LibHealComm-3.0")
		HealComm.RegisterCallback(self, "HealComm_DirectHealStart", function(event, healerName, healSize, endTime, ...) self:HealComm_DirectHealStart(event, healerName, healSize, endTime, ...) end)
		HealComm.RegisterCallback(self, "HealComm_DirectHealStop", function(event, healerName, healSize, succeeded, ...) self:HealComm_DirectHealStop(event, healerName, healSize, succeeded, ...) end)
		HealComm.RegisterCallback(self, "HealComm_HealModifierUpdate", function(event, unit, targetName, healModifier) self:HealComm_HealModifierUpdate(event, unit, targetName, healModifier) end)
	end

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end

	self:Resting()
	--self:Update(self.unit)
end

function PlayerHealth.prototype:HealComm_DirectHealStart(event, healerName, healSize, endTime, ...)
	incomingHealAmt = healSize
	self:Update()
end

function PlayerHealth.prototype:HealComm_DirectHealStop(event, healerName, healSize, succeeded, ...)
	incomingHealAmt = 0
	self:Update()
end

function PlayerHealth.prototype:HealComm_HealModifierUpdate(event, unit, targetName, healModifier)
	incomingHealAmt = incomingHealAmt * healModifier
	self:Update()
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

	opts["allowClickTargetCombat"] = {
		type = 'toggle',
		name = 'Allow click-targeting in combat',
		desc = 'Whether or not to allow click targeting/casting and the player drop-down menu for this bar while the player is in combat (Note: does not work properly with HiBar, have to click near the base of the bar)',
		get = function()
			return self.moduleSettings.allowMouseInteractionCombat
		end,
		set = function(v)
			self.moduleSettings.allowMouseInteractionCombat = v
			self:CreateBackground(true)
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.allowMouseInteraction
		end,
		usage = '',
		order = 43.5
	}

	opts["healAlpha"] =
	{
		type = "range",
		name = "Incoming heal bar alpha",
		desc = "What alpha value to use for the bar that displays how much health you'll have after an incoming heal (This gets multiplied by the bar's current alpha to stay in line with the bar on top of it)",
		min = 0,
		max = 100,
		step = 5,
		get = function()
			return self.moduleSettings.healAlpha * 100
		end,
		set = function(v)
			self.moduleSettings.healAlpha = v / 100.0
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

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
					self:EnteringWorld()
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

			headerStatusIcon = {
				type = 'header',
				name = "Status icon",
				order = 9.9
			},
			statusIcon = {
				type = "toggle",
				name = "Show status icon",
				desc = "Whether or not to show the status icon (resting/combat) above this bar\n\nNote: You can configure resting/combat separately below, but disabling both resting and combat is the same as disabling the icon altogether",
				get = function()
					return self.moduleSettings.showStatusIcon
				end,
				set = function(value)
					self.moduleSettings.showStatusIcon = value
					self:Resting()
					self:CheckCombat()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 10
			},
			showStatusCombat = {
				type = "toggle",
				name = "Show combat status",
				desc = "Whether or not to show the combat status portion of the status icon (for example, if you only care when you're resting, not when you're in combat)",
				get = function()
					return self.moduleSettings.showStatusCombat
				end,
				set = function(value)
					self.moduleSettings.showStatusCombat = value
					self:Resting()
					self:CheckCombat()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showStatusIcon
				end,
				order = 10.1
			},
			showStatusResting = {
				type = "toggle",
				name = "Show resting status",
				desc = "Whether or not to show the resting status portion of the status icon (for example, if you only care when you're in combat, but not when you're resting)",
				get = function()
					return self.moduleSettings.showStatusResting
				end,
				set = function(value)
					self.moduleSettings.showStatusResting = value
					self:Resting()
					self:CheckCombat()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showStatusIcon
				end,
				order = 10.2
			},
			statusIconOffsetX = {
				type = "range",
				name = "Status Icon Horizontal Offset",
				desc = "How much to offset the status icon (resting/combat) from the bar horizontally",
				min = 0,
				max = 250,
				step = 1,
				get = function()
					return self.moduleSettings.statusIconOffset['x']
				end,
				set = function(v)
					self.moduleSettings.statusIconOffset['x'] = v
					self:SetTexLoc(self.frame.statusIcon, self.moduleSettings.statusIconOffset['x'], self.moduleSettings.statusIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showStatusIcon
				end,
				order = 11
			},
			statusIconOffsetY = {
				type = "range",
				name = "Status Icon Vertical Offset",
				desc = "How much to offset the status icon (resting/combat) from the bar vertically",
				min = -300,
				max = 50,
				step = 1,
				get = function()
					return self.moduleSettings.statusIconOffset['y']
				end,
				set = function(v)
					self.moduleSettings.statusIconOffset['y'] = v
					self:SetTexLoc(self.frame.statusIcon, self.moduleSettings.statusIconOffset['x'], self.moduleSettings.statusIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showStatusIcon
				end,
				order = 12
			},
			statusIconScale = {
				type = "range",
				name = "Status Icon Scale",
				desc = "How much to scale the status icon",
				min = 0.05,
				max = 2,
				step = 0.05,
				get = function()
					return self.moduleSettings.statusIconScale
				end,
				set = function(v)
					self.moduleSettings.statusIconScale = v
					self:SetTexScale(self.frame.statusIcon, 20, 20, v)
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showStatusIcon
				end,
				order = 13
			},

			headerLeaderIcon = {
				type = 'header',
				name = "Leader icon",
				order = 19.9
			},
			leaderIcon = {
				type = "toggle",
				name = "Show leader icon",
				desc = "Whether or not to show the party leader icon above this bar",
				get = function()
					return self.moduleSettings.showLeaderIcon
				end,
				set = function(value)
					self.moduleSettings.showLeaderIcon = value
					self:CheckLeader()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 20
			},
			leaderIconOffsetX = {
				type = "range",
				name = "Leader Icon Horizontal Offset",
				desc = "How much to offset the leader icon from the bar horizontally",
				min = 0,
				max = 250,
				step = 1,
				get = function()
					return self.moduleSettings.leaderIconOffset['x']
				end,
				set = function(v)
					self.moduleSettings.leaderIconOffset['x'] = v
					self:SetTexLoc(self.frame.leaderIcon, self.moduleSettings.leaderIconOffset['x'], self.moduleSettings.leaderIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLeaderIcon
				end,
				order = 21
			},
			leaderIconOffsetY = {
				type = "range",
				name = "Leader Icon Vertical Offset",
				desc = "How much to offset the leader icon from the bar vertically",
				min = -300,
				max = 50,
				step = 1,
				get = function()
					return self.moduleSettings.leaderIconOffset['y']
				end,
				set = function(v)
					self.moduleSettings.leaderIconOffset['y'] = v
					self:SetTexLoc(self.frame.leaderIcon, self.moduleSettings.leaderIconOffset['x'], self.moduleSettings.leaderIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLeaderIcon
				end,
				order = 22
			},
			leaderIconScale = {
				type = "range",
				name = "Leader Icon Scale",
				desc = "How much to scale the leader icon",
				min = 0.05,
				max = 2,
				step = 0.05,
				get = function()
					return self.moduleSettings.leaderIconScale
				end,
				set = function(v)
					self.moduleSettings.leaderIconScale = v
					self:SetTexScale(self.frame.leaderIcon, 20, 20, v)
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLeaderIcon
				end,
				order = 23
			},

			headerLootMasterIcon = {
				type = 'header',
				name = "Loot Master icon",
				order = 29.9
			},
			lootMasterIcon = {
				type = "toggle",
				name = "Show loot master icon",
				desc = "Whether or not to show the loot master icon",
				get = function()
					return self.moduleSettings.showLootMasterIcon
				end,
				set = function(value)
					self.moduleSettings.showLootMasterIcon = value
					self:CheckLootMaster()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 30
			},
			lootMasterIconOffsetX = {
				type = "range",
				name = "Loot Master Icon Horizontal Offset",
				desc = "How much to offset the loot master icon from the bar horizontally",
				min = 0,
				max = 250,
				step = 1,
				get = function()
					return self.moduleSettings.lootMasterIconOffset['x']
				end,
				set = function(v)
					self.moduleSettings.lootMasterIconOffset['x'] = v
					self:SetTexLoc(self.frame.lootMasterIcon, self.moduleSettings.lootMasterIconOffset['x'], self.moduleSettings.lootMasterIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLootMasterIcon
				end,
				order = 31
			},
			lootMasterIconOffsetY = {
				type = "range",
				name = "Loot Master Icon Vertical Offset",
				desc = "How much to offset the loot master icon from the bar vertically",
				min = -300,
				max = 50,
				step = 1,
				get = function()
					return self.moduleSettings.lootMasterIconOffset['y']
				end,
				set = function(v)
					self.moduleSettings.lootMasterIconOffset['y'] = v
					self:SetTexLoc(self.frame.lootMasterIcon, self.moduleSettings.lootMasterIconOffset['x'], self.moduleSettings.lootMasterIconOffset['y'])
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLootMasterIcon
				end,
				order = 32
			},
			lootMasterIconScale = {
				type = "range",
				name = "Loot Master Icon Scale",
				desc = "How much to scale the loot master icon",
				min = 0.05,
				max = 2,
				step = 0.05,
				get = function()
					return self.moduleSettings.lootMasterIconScale
				end,
				set = function(v)
					self.moduleSettings.lootMasterIconScale = v
					self:SetTexScale(self.frame.lootMasterIcon, 20, 20, v)
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.showLootMasterIcon
				end,
				order = 33
			},

			headerPvPIcon = {
				type = 'header',
				name = "PvP icon",
				order = 39.9
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
			}
		}
	}
	
	return opts
end


function PlayerHealth.prototype:CreateFrame()
	PlayerHealth.super.prototype.CreateFrame(self)

	self:CreateHealBar()
end


function PlayerHealth.prototype:CreateBackground(redraw)
	PlayerHealth.super.prototype.CreateBackground(self)

	if not self.frame.button then
		self.frame.button = CreateFrame("Button", "IceHUD_PlayerClickFrame", self.frame, "SecureUnitButtonTemplate")
	end

	self.frame.button:ClearAllPoints()
	-- Parnic - kinda hacky, but in order to fit this region to multiple types of bars, we need to do this...
	--          would be nice to define this somewhere in data, but for now...here we are
	if self.settings.barTexture == "HiBar" then
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

	self.frame.button.menu = function()
		ToggleDropDownMenu(1, nil, PlayerFrameDropDown, "cursor");
	end

	self:EnableClickTargeting(self.moduleSettings.allowMouseInteraction)
end

function PlayerHealth.prototype:CreateHealBar()
	if not self.healFrame then
		self.healFrame = CreateFrame("Statusbar", nil, self.frame)
		self.CurrScale = 0
	end

	self.healFrame:SetFrameStrata("LOW")
	self.healFrame:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.healFrame:SetHeight(self.settings.barHeight)

	if not self.healFrame.bar then
		self.healFrame.bar = self.frame:CreateTexture(nil, "BACKGROUND")
	end

	self.healFrame.bar:SetTexture(IceElement.TexturePath .. self.settings.barTexture)
	self.healFrame.bar:SetAllPoints(self.frame)

	self.healFrame:SetStatusBarTexture(self.healFrame.bar)
	self.healFrame:SetStatusBarColor(self:GetColor("PlayerHealthIncomingHeal", self.alpha * self.moduleSettings.healAlpha))

	self:UpdateBar(1, "undef")

	self.healFrame:ClearAllPoints()
	self.healFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
end


function PlayerHealth.prototype:EnableClickTargeting(bEnable)
	if bEnable then
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


function PlayerHealth.prototype:EnteringWorld()
	self:CheckCombat()
	self:CheckLeader()
	self:CheckPvP()
	-- Parnic - moved :Resting to the end because it calls Update which sets alpha on everything
	self:Resting()
end


function PlayerHealth.prototype:Resting()
	self.resting = IsResting()

	-- moved icon logic above :Update so that it will trigger the alpha settings properly
	if (self.resting) then
		if self.moduleSettings.showStatusIcon and self.moduleSettings.showStatusResting and not self.frame.statusIcon then
			self.frame.statusIcon = self:CreateTexCoord(self.frame.statusIcon, "Interface\\CharacterFrame\\UI-StateIcon", 20, 20,
						self.moduleSettings.statusIconScale, 0.0625, 0.4475, 0.0625, 0.4375)
			self:SetTexLoc(self.frame.statusIcon, self.moduleSettings.statusIconOffset['x'], self.moduleSettings.statusIconOffset['y'])
		elseif (not self.moduleSettings.showStatusIcon or not self.moduleSettings.showStatusResting) and self.frame.statusIcon and not self.combat then
			self.frame.statusIcon = self:DestroyTexFrame(self.frame.statusIcon)
		end
	else
		if not self.combat and not configMode and self.frame.statusIcon then
			self.frame.statusIcon = self:DestroyTexFrame(self.frame.statusIcon)
		end
	end

	self:Update(self.unit)
end


function PlayerHealth.prototype:CheckCombat()
	PlayerHealth.super.prototype.CheckCombat(self)

	if self.combat then
		if self.moduleSettings.allowMouseInteraction and not self.moduleSettings.allowMouseInteractionCombat then
			self:EnableClickTargeting(false)
		end
	else
		if self.moduleSettings.allowMouseInteraction and not self.moduleSettings.allowMouseInteractionCombat then
			self:EnableClickTargeting(true)
		end
	end

	if self.combat or configMode then
		if (configMode or (self.moduleSettings.showStatusIcon and self.moduleSettings.showStatusCombat)) and not self.frame.statusIcon then
			self.frame.statusIcon = self:CreateTexCoord(self.frame.statusIcon, "Interface\\CharacterFrame\\UI-StateIcon", 20, 20,
						self.moduleSettings.statusIconScale, 0.5625, 0.9375, 0.0625, 0.4375)
			self:SetTexLoc(self.frame.statusIcon, self.moduleSettings.statusIconOffset['x'], self.moduleSettings.statusIconOffset['y'])
		elseif not configMode and not self.resting and (not self.moduleSettings.showStatusIcon or not self.moduleSettings.showStatusCombat) and self.frame.statusIcon then
			self.frame.statusIcon = self:DestroyTexFrame(self.frame.statusIcon)
		end
	else
		if not self.resting and self.frame.statusIcon then
			self.frame.statusIcon = self:DestroyTexFrame(self.frame.statusIcon)
		end
	end
end


function PlayerHealth.prototype:CheckLeader()
	if configMode or IsPartyLeader() then
		if (configMode or self.moduleSettings.showLeaderIcon) and not self.frame.leaderIcon then
			self.frame.leaderIcon = self:CreateTexCoord(self.frame.leaderIcon, "Interface\\GroupFrame\\UI-Group-LeaderIcon", 20, 20,
						self.moduleSettings.leaderIconScale, 0, 1, 0, 1)
			self:SetTexLoc(self.frame.leaderIcon, self.moduleSettings.leaderIconOffset['x'], self.moduleSettings.leaderIconOffset['y'])
		elseif not configMode and not self.moduleSettings.showLeaderIcon and self.frame.leaderIcon then
			self.frame.leaderIcon = self:DestroyTexFrame(self.frame.leaderIcon)
		end
	else
		if self.frame.leaderIcon then
			self.frame.leaderIcon = self:DestroyTexFrame(self.frame.leaderIcon)
		end
	end

	self:CheckLootMaster()
end


function PlayerHealth.prototype:CheckLootMaster()
	local _, lootmaster = GetLootMethod()
	if configMode or lootmaster == 0 then
		if (configMode or self.moduleSettings.showLootMasterIcon) and not self.frame.lootMasterIcon then
			self.frame.lootMasterIcon = self:CreateTexCoord(self.frame.lootMasterIcon, "Interface\\GroupFrame\\UI-Group-MasterLooter", 20, 20,
						self.moduleSettings.lootMasterIconScale, 0, 1, 0, 1)
			self:SetTexLoc(self.frame.lootMasterIcon, self.moduleSettings.lootMasterIconOffset['x'], self.moduleSettings.lootMasterIconOffset['y'])
		elseif not configMode and not self.moduleSettings.showLootMasterIcon and self.frame.lootMasterIcon then
			self.frame.lootMasterIcon = self:DestroyTexFrame(self.frame.lootMasterIcon)
		end
	else
		if self.frame.lootMasterIcon then
			self.frame.lootMasterIcon = self:DestroyTexFrame(self.frame.lootMasterIcon)
		end
	end
end


function PlayerHealth.prototype:CheckPvP()
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
		if (configMode or self.moduleSettings.showPvPIcon) and not self.frame.PvPIcon then
			self.frame.PvPIcon = self:CreateTexCoord(self.frame.PvPIcon, "Interface\\TargetingFrame\\UI-PVP-"..pvpMode, 20, 20,
						self.moduleSettings.PvPIconScale, minx, maxx, miny, maxy)
			self:SetTexLoc(self.frame.PvPIcon, self.moduleSettings.PvPIconOffset['x'], self.moduleSettings.PvPIconOffset['y'])
		elseif not configMode and not self.moduleSettings.showPvPIcon and self.frame.PvPIcon then
			self.frame.PvPIcon = self:DestroyTexFrame(self.frame.PvPIcon)
		end
	else
		if self.frame.PvPIcon then
			self.frame.PvPIcon = self:DestroyTexFrame(self.frame.PvPIcon)
		end
	end
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

	-- sadly, animation uses bar-local variables so we can't use the animation for 2 bar textures on the same bar element
	if self.healFrame and self.healFrame.bar and incomingHealAmt then
		if (self.moduleSettings.side == IceCore.Side.Left) then
			self.healFrame.bar:SetTexCoord(1, 0, 1-((self.health + incomingHealAmt) / self.maxHealth), 1)
		else
			self.healFrame.bar:SetTexCoord(0, 1, 1-((self.health + incomingHealAmt) / self.maxHealth), 1)
		end
	end

	if not IceHUD.IceCore:ShouldUseDogTags() then
		self:SetBottomText1(math.floor(self.healthPercentage * 100))
		self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), textColor)
	end

	self:SetIconAlpha()
end


function PlayerHealth.prototype:SetIconAlpha()
	if self.frame.statusIcon then
		self.frame.statusIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end

	if self.frame.leaderIcon then
		self.frame.leaderIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end

	if self.frame.lootMasterIcon then
		self.frame.lootMasterIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end

	if self.frame.PvPIcon then
		self.frame.PvPIcon:SetAlpha(self.moduleSettings.lockIconAlpha and 1 or self.alpha)
	end
end


function PlayerHealth.prototype:CreateTexCoord(texframe, icon, width, height, scale, left, right, top, bottom)
	if not texframe then
		texframe = self.frame:CreateTexture(nil, "BACKGROUND")
	end
	texframe:SetTexture(icon)
	texframe:SetTexCoord(left, right, top, bottom)
	self:SetTexScale(texframe, width, height, scale)

	return texframe
end


function PlayerHealth.prototype:SetTexLoc(texframe, xpos, ypos, anchorFrom, anchorTo)
	if not texframe then
		return
	end

	texframe:ClearAllPoints()
	texframe:SetPoint(anchorFrom and anchorFrom or "TOPLEFT", self.frame, anchorTo and anchorTo or "TOPLEFT", xpos, ypos)
end


function PlayerHealth.prototype:SetTexScale(texframe, width, height, scale)
	if not texframe then
		return
	end

	texframe:SetWidth(width * scale)
	texframe:SetHeight(height * scale)
end


function PlayerHealth.prototype:DestroyTexFrame(texframe)
	if not texframe then
		return nil
	end

	texframe:SetTexture(nil)
	texframe:Hide()
	texframe:ClearAllPoints()

	return nil
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
