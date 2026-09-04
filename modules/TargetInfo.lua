local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceTargetInfo = IceCore_CreateClass(IceElement)

local CooldownFrame_SetTimer = CooldownFrame_SetTimer
if CooldownFrame_Set then
	CooldownFrame_SetTimer = CooldownFrame_Set
end

local DogTag = nil

local internal = "internal"

local ValidAnchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

local CooldownSwipeAlpha = 0.65

---- Fulzamoth - 2019-09-04 : support for cooldowns on target buffs/debuffs (classic)
local LibClassicDurations = LibStub("LibClassicDurations", true)
---- end change by Fulzamoth

IceTargetInfo.prototype.unit = "target"

IceTargetInfo.prototype.buffSize = nil
IceTargetInfo.prototype.ownBuffSize = nil
IceTargetInfo.prototype.width = nil

IceTargetInfo.prototype.name = nil
IceTargetInfo.prototype.guild = nil
IceTargetInfo.prototype.realm = nil
IceTargetInfo.prototype.classLocale = nil
IceTargetInfo.prototype.classEnglish = nil
IceTargetInfo.prototype.leader = nil

IceTargetInfo.prototype.targetCombat = nil
IceTargetInfo.prototype.pvp = nil
IceTargetInfo.prototype.level = nil
IceTargetInfo.prototype.classification = nil
IceTargetInfo.prototype.reaction = nil
IceTargetInfo.prototype.tapped = nil

IceTargetInfo.prototype.isPlayer = nil
IceTargetInfo.prototype.playerClass = nil

local UnitSelectionColor = function(unit)
	local playerPvp = UnitIsPVP("player")
	if not IceHUD.CanAccessValue(playerPvp) then
		playerPvp = false
	end

	if not UnitExists(unit) then
		return 1, 1, 1, 1
	elseif IceHUD:IsSameUnit(unit, "player") or IceHUD:IsSameUnit(unit, "pet") then
		if playerPvp then
			return 0, 1, 0, 1 -- player is in pvp, unit is player or player's pet, return green
		else
			return 0, 0, 1, 1 -- player is not pvp, unit is player or player's pet, return blue
		end
	else
		if UnitIsPVPFreeForAll(unit) then
			return 1, 0, 0, 1 -- FFA PVP, return red
		elseif UnitIsPVPSanctuary(unit) then
			return 0, 0, 1, 1 -- sanctuary PVP, return blue
		end

		local unitPlayer = UnitIsPlayer(unit)
		local unitPvp = UnitIsPVP(unit)
		if not IceHUD.CanAccessValue(unitPvp) then
			unitPvp = false
		end
		local unitFaction = UnitFactionGroup(unit)
		local playerFaction = UnitFactionGroup("player")

		if playerPvp and unitPlayer then
			if unitPvp then
				if unitFaction ~= playerFaction then
					return 1, 0, 0, 1 -- different faction, both pvp, return red
				else
					return 0, 1, 0, 1 -- same faction, both pvp, return green
				end
			else
				return 0, 0, 1, 1 -- unit not pvp, return blue
			end
		else
			if unitPlayer then
				if unitPvp and unitFaction ~= playerFaction then
					return 1, 1, 0, 1 -- unit pvp, player not, return yellow
				else
					return 0, 0, 1, 1 -- player is not pvp and either unit is not pvp or unit is our faction, return blue
				end
			end

			local reaction = UnitReaction(unit, "player")
			if not reaction then
				return 1, 1, 1, 1 -- unknown or bug, return white
			elseif reaction < 4 then
				return 1, 0, 0, 1 -- below neutral, red reaction
			elseif reaction == 4 then
				return 1, 1, 0, 1 -- neutral, yellow reaction
			else
				return 0, 1, 0, 1 -- above neutral, green reaction
			end
		end
	end
end


-- Constructor --
function IceTargetInfo.prototype:init(moduleName, unit)
	self.unit = unit or "target"

	if not moduleName or not unit then
		IceTargetInfo.super.prototype.init(self, "TargetInfo")
	else
		IceTargetInfo.super.prototype.init(self, moduleName)
	end

	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceTargetInfo.prototype:Enable(core)
	local _
	_, self.playerClass = UnitClass("player")

	IceTargetInfo.super.prototype.Enable(self, core)

	if IceHUD.IceCore:ShouldUseDogTags() then
		DogTag = LibStub("LibDogTag-3.0", true)
		if DogTag then
			LibStub("LibDogTag-Unit-3.0")
		end
	end

	self:RegisterEvent("UNIT_AURA", "AuraChanged")

	-- The "In Combat" aura filter otherwise waits for the next aura event to notice
	-- that combat started or ended.
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateBuffs")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateBuffs")

	self:RegisterEvent("UNIT_NAME_UPDATE", "TargetName")
	self:RegisterEvent("UNIT_FACTION", "TargetFaction")
	self:RegisterEvent("UNIT_LEVEL", "TargetLevel")

	self:RegisterEvent("UNIT_FLAGS", "TargetFlags")
	if IceHUD.EventExistsUnitDynamicFlags then
		self:RegisterEvent("UNIT_DYNAMIC_FLAGS", "TargetFlags")
	end

	self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidTargetIcon")

	RegisterUnitWatch(self.frame)

	if self.moduleSettings.myTagVersion < IceHUD.CurrTagVersion then
		local origDefaults = self:GetDefaultSettings()

		self.moduleSettings.line1tag = origDefaults["line1tag"]
		self.moduleSettings.line2tag = origDefaults["line2tag"]
		self.moduleSettings.line3tag = origDefaults["line3tag"]
		self.moduleSettings.myTagVersion = IceHUD.CurrTagVersion
	end

	-- Rokiyo: ye olde backwards compatibility
	local auraSettings = self.moduleSettings.auras
	if not self.moduleSettings.updateAurasIntoTable then
		self.moduleSettings.updateAurasIntoTable = true

		if self.moduleSettings.buffSize then auraSettings["buff"].size = self.moduleSettings.buffSize self.moduleSettings.buffSize = nil end
		if self.moduleSettings.ownBuffSize then auraSettings["buff"].ownSize = self.moduleSettings.ownBuffSize self.moduleSettings.ownBuffSize = nil end
		if self.moduleSettings.showBuffs then auraSettings["buff"].show = self.moduleSettings.showBuffs self.moduleSettings.showBuffs = nil end
		if self.moduleSettings.buffGrowDirection then auraSettings["buff"].growDirection = self.moduleSettings.buffGrowDirection self.moduleSettings.buffGrowDirection = nil end
		if self.moduleSettings.buffAnchorTo then auraSettings["buff"].anchorTo = self.moduleSettings.buffAnchorTo self.moduleSettings.buffAnchorTo = nil end
		if self.moduleSettings.buffOffset then
			if self.moduleSettings.buffOffset['x'] then auraSettings["buff"].offsetX = self.moduleSettings.buffOffset['x'] end
			if self.moduleSettings.buffOffset['y'] then auraSettings["buff"].offsetY = self.moduleSettings.buffOffset['y'] end
			self.moduleSettings.buffOffset = nil
		end

		if self.moduleSettings.debuffSize then auraSettings["debuff"].size = self.moduleSettings.debuffSize self.moduleSettings.debuffSize = nil end
		if self.moduleSettings.ownDebuffSize then auraSettings["debuff"].ownSize = self.moduleSettings.ownDebuffSize self.moduleSettings.ownDebuffSize = nil end
		if self.moduleSettings.showDebuffs then auraSettings["debuff"].show = self.moduleSettings.showDebuffs self.moduleSettings.showDebuffs = nil end
		if self.moduleSettings.debuffGrowDirection then auraSettings["debuff"].growDirection = self.moduleSettings.debuffGrowDirection self.moduleSettings.debuffGrowDirection = nil end
		if self.moduleSettings.debuffAnchorTo then auraSettings["debuff"].anchorTo = self.moduleSettings.debuffAnchorTo self.moduleSettings.debuffAnchorTo = nil end
		if self.moduleSettings.debuffOffset then
			if self.moduleSettings.debuffOffset['x'] then auraSettings["debuff"].offsetX = self.moduleSettings.debuffOffset['x'] end
			if self.moduleSettings.debuffOffset['y'] then auraSettings["debuff"].offsetY = self.moduleSettings.debuffOffset['y'] end
			self.moduleSettings.debuffOffset = nil
		end

		if self.moduleSettings.filterBuffs then
			auraSettings["buff"].filter = self.moduleSettings.filterBuffs
		elseif self.moduleSettings.filter then
			auraSettings["buff"].filter = self.moduleSettings.filter
		end
		self.moduleSettings.filterBuffs = nil

		if self.moduleSettings.filterDebuffs then
			auraSettings["debuff"].filter = self.moduleSettings.filterDebuffs
		elseif self.moduleSettings.filter then
			auraSettings["debuff"].filter = self.moduleSettings.filter
		end
		self.moduleSettings.filterDebuffs = nil

		self.moduleSettings.filter = nil
	end

	if not self.moduleSettings.debuffSizeFixup then
		self.moduleSettings.debuffSizeFixup = true

		auraSettings.debuff.size = auraSettings.buff.size
		auraSettings.debuff.ownSize = auraSettings.buff.ownSize

		-- Rokiyo: Death to tiny tables!
		if auraSettings.buff.offset then
			auraSettings.buff.offsetX = auraSettings.buff.offset['x']
			auraSettings.buff.offsetY = auraSettings.buff.offset['y']
			auraSettings.buff.offset = nil
		end
		if auraSettings.debuff.offset then
			auraSettings.debuff.offsetX = auraSettings.debuff.offset['x']
			auraSettings.debuff.offsetY = auraSettings.debuff.offset['y']
			auraSettings.debuff.offset = nil
		end
	end

	if self.moduleSettings.perRow then
		auraSettings.buff.perRow = self.moduleSettings.perRow
		auraSettings.debuff.perRow = self.moduleSettings.perRow
		self.moduleSettings.perRow = nil
	end

	self:RegisterFontStrings()
end


-- OVERRIDE
function IceTargetInfo.prototype:Disable(core)
	IceTargetInfo.super.prototype.Disable(self, core)

	UnregisterUnitWatch(self.frame)

	self:UnregisterFontStrings()
end

-- Every aura reads as cast by the player where auras are secret, even in the aura
-- container, so the player's own auras can't be told apart to size them differently.
function IceTargetInfo.prototype:CanSizeOwnAuras()
	return not IceHUD.IsSecretEnv()
end

-- Sorting only needs durations compared, which the container does on our behalf.
function IceTargetInfo.prototype:CanSortBuffs()
	return not IceHUD.IsSecretEnv() or IceHUD.CanUseAuraContainer()
end


-- OVERRIDE
function IceTargetInfo.prototype:GetOptions()
	local opts = IceTargetInfo.super.prototype.GetOptions(self)

	opts["targetInfoHeader"] = {
		type = 'header',
		name = L["Look and Feel"],
		order = 30.9
	}

	self:AddDragMoveOption(opts, 30.91)

	opts["vpos"] = {
		type = "range",
		name = L["Vertical Position"],
		desc = L["Vertical Position"],
		get = function()
			return IceHUD:MathRound(self.moduleSettings.vpos)
		end,
		set = function(info, v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -425,
		max = 700,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hpos"] = {
		type = "range",
		name = L["Horizontal Position"],
		desc = L["Horizontal Position"],
		get = function()
			return IceHUD:MathRound(self.moduleSettings.hpos)
		end,
		set = function(info, v)
			self.moduleSettings.hpos = v
			self:Redraw()
		end,
		min = -500,
		max = 500,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["fontSize"] = {
		type = 'range',
		name = L["Font Size"],
		desc = L["Font Size"],
		get = function()
			return self.moduleSettings.fontSize
		end,
		set = function(info, v)
			self.moduleSettings.fontSize = v
			self:Redraw()
		end,
		min = 8,
		max = 20,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["stackFontSize"] = {
		type = 'range',
		name = L["Stack Font Size"],
		desc = L["Stack Font Size"],
		get = function()
			return self.moduleSettings.stackFontSize
		end,
		set = function(info, v)
			self.moduleSettings.stackFontSize = v
			self:RedrawBuffs()
		end,
		min = 8,
		max = 20,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["zoom"] = {
		type = 'range',
		name = L["Buff zoom"],
		desc = L["Buff/debuff icon zoom"],
		get = function()
			return self.moduleSettings.zoom
		end,
		set = function(info, v)
			self.moduleSettings.zoom = v
			self:RedrawBuffs()
		end,
		min = 0,
		max = 0.2,
		step = 0.01,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		isPercent = true,
		order = 33
	}

	opts["spaceBetweenBuffs"] = {
		type = 'range',
		name = L["Space between buffs"],
		desc = L["How much space should be between each buff or debuff icon."],
		get = function()
			return self.moduleSettings.spaceBetweenBuffs
		end,
		set = function(info, v)
			self.moduleSettings.spaceBetweenBuffs = v
			self:RedrawBuffs()
		end,
		min = 0,
		max = 25,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 37.01,
	}

	opts["buff"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Buff Settings"].."|r",
		desc = L["Buff Settings"],
		args = {
			show = {
				type = 'toggle',
				name = L["Show buffs"],
				desc = L["Toggles whether or not buffs are displayed at all"],
				get = function()
					return self.moduleSettings.auras["buff"].show
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].show = v
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 32
			},
			filter = {
				type = 'select',
				name = L["Only show buffs by me"],
				desc = L["Will only show buffs that you cast instead of all buffs active"],
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["buff"].filter)
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].filter = info.option.values[v]
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				values = { "Never", "In Combat", "Always" },
				order = 32.1
			},
			header = {
				type = 'header',
				name = L["Size and Placement"],
				order = 33
			},
			size = {
				type = 'range',
				name = L["Buff size"],
				desc = L["Icon size"],
				get = function()
					return self.moduleSettings.auras["buff"].size
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].size = v
					self:RedrawBuffs()
				end,
				min = 8,
				max = 30,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 34
			},
			ownSize = {
				type = 'range',
				name = L["Own buff size"],
				desc = L["Icon size for auras that were applied by you, the player"],
				get = function()
					return self.moduleSettings.auras["buff"].ownSize
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].ownSize = v
					self:RedrawBuffs()
				end,
				min = 8,
				max = 60,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				hidden = function()
					return not self:CanSizeOwnAuras()
				end,
				order = 35
			},
			growDirection = {
				type = 'select',
				name = L["Buff grow direction"],
				desc = L["Which direction the buffs should grow from the anchor point"],
				values = { "Left", "Right" },
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["buff"].growDirection)
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].growDirection = info.option.values[v]
					self:CreateAuraFrame("buff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				order = 37.1
			},
			anchorTo = {
				type = 'select',
				name = L["Buff anchor to"],
				desc = L["The point on the TargetInfo frame that the buff frame gets connected to"],
				values = ValidAnchors,
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["buff"].anchorTo)
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].anchorTo = info.option.values[v]
					self:CreateAuraFrame("buff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				order = 37.2
			},
			offsetX = {
				type = 'range',
				name = L["Buff horizontal offset"],
				desc = L["How far horizontally the buff frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.auras["buff"].offsetX
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].offsetX = v
					self:CreateAuraFrame("buff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				order = 37.3
			},
			offsetY = {
				type = 'range',
				name = L["Buff vertical offset"],
				desc = L["How far vertically the buff frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.auras["buff"].offsetY
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].offsetY = v
					self:CreateAuraFrame("buff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				order = 37.4
			},
			perRow = {
				type = 'range',
				name = L["Buffs / row"],
				desc = L["How many buffs/debuffs is shown on each row"],
				get = function()
					return self.moduleSettings.auras["buff"].perRow
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].perRow = v
					self:CreateAuraFrame("buff")
				end,
				min = 1,
				max = 20,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
				end,
				order = 37.5
			},
		}
	}

	opts["debuff"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Debuff Settings"].."|r",
		desc = L["Debuff Settings"],
		args = {
			show = {
				type = 'toggle',
				name = L["Show debuffs"],
				desc = L["Toggles whether or not debuffs are displayed at all"],
				get = function()
					return self.moduleSettings.auras["debuff"].show
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].show = v
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 32
			},
			filter = {
				type = 'select',
				name = L["Only show debuffs by me"],
				desc = L["Will only show debuffs that you cast instead of all debuffs active"],
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["debuff"].filter)
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].filter = info.option.values[v]
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				values = { "Never", "In Combat", "Always" },
				order = 32.1
			},
			header = {
				type = 'header',
				name = L["Size and Placement"],
				order = 33
			},
			size = {
				type = 'range',
				name = L["Debuff size"],
				desc = L["Icon size"],
				get = function()
					return self.moduleSettings.auras["debuff"].size
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].size = v
					self:RedrawBuffs()
				end,
				min = 8,
				max = 30,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 34
			},
			ownSize = {
				type = 'range',
				name = L["Own debuff size"],
				desc = L["Icon size for auras that were applied by you, the player"],
				get = function()
					return self.moduleSettings.auras["debuff"].ownSize
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].ownSize = v
					self:RedrawBuffs()
				end,
				min = 8,
				max = 60,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				hidden = function()
					return not self:CanSizeOwnAuras()
				end,
				order = 35
			},
			growDirection = {
				type = 'select',
				name = L["Debuff grow direction"],
				desc = L["Which direction the debuffs should grow from the anchor point"],
				values = { "Left", "Right" },
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["debuff"].growDirection)
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].growDirection = info.option.values[v]
					self:CreateAuraFrame("debuff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				order = 37.81
			},
			anchorTo = {
				type = 'select',
				name = L["Debuff anchor to"],
				desc = L["The point on the TargetInfo frame that the debuff frame gets connected to"],
				values = ValidAnchors,
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.auras["debuff"].anchorTo)
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].anchorTo = info.option.values[v]
					self:CreateAuraFrame("debuff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				order = 37.82
			},
			offsetX = {
				type = 'range',
				name = L["Debuff horizontal offset"],
				desc = L["How far horizontally the debuff frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.auras["debuff"].offsetX
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].offsetX = v
					self:CreateAuraFrame("debuff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				order = 37.83
			},
			offsetY = {
				type = 'range',
				name = L["Debuff vertical offset"],
				desc = L["How far vertically the debuff frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.auras["debuff"].offsetY
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].offsetY = v
					self:CreateAuraFrame("debuff")
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				order = 37.84
			},
			perRow = {
				type = 'range',
				name = L["Buffs / row"],
				desc = L["How many buffs/debuffs is shown on each row"],
				get = function()
					return self.moduleSettings.auras["debuff"].perRow
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].perRow = v
					self:CreateAuraFrame("debuff")
				end,
				min = 1,
				max = 20,
				step = 1,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
				end,
				order = 37.85
			},
		}
	}

	-- unable to sort buffs if we can't inspect their durations due to secret values. this is
	-- checked when the options are shown because the aura container arrives after we load.
	for _, aura in ipairs({"buff", "debuff"}) do
		opts[aura].args.sorted = {
			type = 'toggle',
			name = L["Sort by expiration"],
			desc = L["Toggles whether or not to sort by expiration time (otherwise they're sorted how the game sorts them - by application time)"],
			get = function()
				return self.moduleSettings.auras[aura].sortByExpiration
			end,
			set = function(info, v)
				self.moduleSettings.auras[aura].sortByExpiration = v
				self:RedrawBuffs()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			hidden = function()
				return not self:CanSortBuffs()
			end,
			order = 32.2
		}
	end

	opts["mouseHeader"] = {
		type = 'header',
		name = L["Mouse settings"],
		order = 37.9
	}

	opts["mouseTarget"] = {
		type = 'toggle',
		name = L["Mouseover for target"],
		desc = L["Toggle mouseover on/off for target"],
		get = function()
			return self.moduleSettings.mouseTarget
		end,
		set = function(info, v)
			self.moduleSettings.mouseTarget = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 38
	}

	opts["mouseBuff"] = {
		type = 'toggle',
		name = L["Mouseover for buffs"],
		desc = L["Toggle mouseover on/off for buffs/debuffs"],
		get = function()
			return self.moduleSettings.mouseBuff
		end,
		set = function(info, v)
			self.moduleSettings.mouseBuff = v
			self:RedrawBuffs()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 39
	}

	opts["mouseTooltip"] = {
		type = 'toggle',
		name = L["Show tooltip"],
		desc = L["Show the tooltip for this unit when the mouse is hovering over it."],
		get = function()
			return self.moduleSettings.mouseTooltip
		end,
		set = function(info, v)
			self.moduleSettings.mouseTooltip = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 39.01
	}

	opts["textHeader"] = {
		type = 'header',
		name = L["Text Settings"],
		order = 39.05
	}

	opts["line1Tag"] = {
		type = 'input',
		name = L["Line 1 tag"],
		desc = L["DogTag-formatted string to use for the top text line (leave blank to revert to old behavior)\n\nType /dogtag for a list of available tags.\n\nRemember to press Accept after filling out this box or it will not save."],
		get = function()
			return self.moduleSettings.line1Tag
		end,
		set = function(info, v)
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			v = DogTag:CleanCode(v)
			self.moduleSettings.line1Tag = v
			self:RegisterFontStrings()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag == nil
		end,
		multiline = true,
		order = 39.1
	}

	opts["line2Tag"] = {
		type = 'input',
		name = L["Line 2 tag"],
		desc = L["DogTag-formatted string to use for the second text line (leave blank to revert to old behavior)\n\nType /dogtag for a list of available tags.\n\nRemember to press Accept after filling out this box or it will not save."],
		get = function()
			return self.moduleSettings.line2Tag
		end,
		set = function(info, v)
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			v = DogTag:CleanCode(v)
			self.moduleSettings.line2Tag = v
			self:RegisterFontStrings()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag == nil
		end,
		multiline = true,
		order = 39.2
	}

	opts["line3Tag"] = {
		type = 'input',
		name = L["Line 3 tag"],
		desc = L["DogTag-formatted string to use for the third text line (leave blank to revert to old behavior)\n\nType /dogtag for a list of available tags.\n\nRemember to press Accept after filling out this box or it will not save."],
		get = function()
			return self.moduleSettings.line3Tag
		end,
		set = function(info, v)
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			v = DogTag:CleanCode(v)
			self.moduleSettings.line3Tag = v
			self:RegisterFontStrings()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag == nil
		end,
		multiline = true,
		order = 39.3
	}

	opts["line4Tag"] = {
		type = 'input',
		name = L["Line 4 tag"],
		desc = L["DogTag-formatted string to use for the bottom text line (leave blank to revert to old behavior)\n\nType /dogtag for a list of available tags.\n\nRemember to press Accept after filling out this box or it will not save."],
		get = function()
			return self.moduleSettings.line4Tag
		end,
		set = function(info, v)
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			v = DogTag:CleanCode(v)
			self.moduleSettings.line4Tag = v
			self:RegisterFontStrings()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag == nil
		end,
		multiline = true,
		order = 39.4
	}

	opts["displayTargetName"] = {
		type = 'toggle',
		name = L["Display target name"],
		desc = L["Whether or not to display the first line of text on this module which is the target's name."],
		get = function()
			return self.moduleSettings.displayTargetName
		end,
		set = function(info, v)
			self.moduleSettings.displayTargetName = v
			self.frame.targetName:SetText()
			self:Update(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag ~= nil
		end,
		order = 39.1,
	}

	opts["displayTargetDetails"] = {
		type = 'toggle',
		name = L["Display target details"],
		desc = L["Whether or not to display the second line of text on this module which is the target's details (level, class, PvP status, etc.)."],
		get = function()
			return self.moduleSettings.displayTargetDetails
		end,
		set = function(info, v)
			self.moduleSettings.displayTargetDetails = v
			self.frame.targetInfo:SetText()
			self:Update(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag ~= nil
		end,
		order = 39.2,
	}

	opts["displayTargetGuild"] = {
		type = 'toggle',
		name = L["Display target guild"],
		desc = L["Whether or not to display the third line of text on this module which is the target's guild and realm (if they are from another realm)."],
		get = function()
			return self.moduleSettings.displayTargetGuild
		end,
		set = function(info, v)
			self.moduleSettings.displayTargetGuild = v
			self.frame.targetGuild:SetText()
			self:Update(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return DogTag ~= nil
		end,
		order = 39.3,
	}

	opts.line1Alignment = {
		type = 'select',
		name = L["Line 1 justification"],
		desc = L["This sets the alignment for the text on line 1"],
		get = function()
			return self.moduleSettings.line1Alignment or "CENTER"
		end,
		set = function(_, value)
			self.moduleSettings.line1Alignment = value
			self.frame.targetName:SetText()
			self:Redraw()
		end,
		values = { CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"] },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40.1
	}

	opts.line2Alignment = {
		type = 'select',
		name = L["Line 2 justification"],
		desc = L["This sets the alignment for the text on line 2"],
		get = function()
			return self.moduleSettings.line2Alignment or "CENTER"
		end,
		set = function(_, value)
			self.moduleSettings.line2Alignment = value
			self.frame.targetInfo:SetText()
			self:Redraw()
		end,
		values = { CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"] },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40.2
	}

	opts.line3Alignment = {
		type = 'select',
		name = L["Line 3 justification"],
		desc = L["This sets the alignment for the text on line 3"],
		get = function()
			return self.moduleSettings.line3Alignment or "CENTER"
		end,
		set = function(_, value)
			self.moduleSettings.line3Alignment = value
			self.frame.targetGuild:SetText()
			self:Redraw()
		end,
		values = { CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"] },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40.3
	}

	opts.line4Alignment = {
		type = 'select',
		name = L["Line 4 justification"],
		desc = L["This sets the alignment for the text on line 4"],
		get = function()
			return self.moduleSettings.line4Alignment or "CENTER"
		end,
		set = function(_, value)
			self.moduleSettings.line4Alignment = value
			self.frame.targetExtra:SetText()
			self:Redraw()
		end,
		values = { CENTER = L["Center"], LEFT = L["Left"], RIGHT = L["Right"] },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40.4
	}

	opts["showRaidIcon"] = {
		type = 'toggle',
		name = L['Show raid icon'],
		desc = L['Whether or not to show the raid icon for this unit.'],
		get = function()
			return self.moduleSettings.showRaidIcon
		end,
		set = function(info, v)
			self.moduleSettings.showRaidIcon = v
			self:UpdateRaidTargetIcon()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 37.02,
	}

	opts["forceHideCooldownNumbers"] = {
		type = 'toggle',
		name = L['Force hide cooldown numbers'],
		desc = L['Whether to force buff and debuff frames to hide their cooldown numbers even if enabled in the game settings or not.'],
		get = function()
			return self.moduleSettings.forceHideCooldownNumbers
		end,
		set = function(info, v)
			self.moduleSettings.forceHideCooldownNumbers = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		width = 'double',
		order = 37.03,
	}

	return opts
end

function IceTargetInfo.prototype:ToggleMoveHint()
	if IceTargetInfo.super.prototype.ToggleMoveHint(self) then
		self.origUnit = self.unit
		self.unit = "player"
	else
		self.unit = self.origUnit
		self:TargetChanged()
	end

	self:Redraw()
end

-- OVERRIDE
function IceTargetInfo.prototype:GetDefaultSettings()
	local defaults =  IceTargetInfo.super.prototype.GetDefaultSettings(self)

	defaults["fontSize"] = 13
	defaults["stackFontSize"] = 11
	defaults["vpos"] = -50
	defaults["hpos"] = 0
	defaults["zoom"] = 0.08
	defaults["mouseTarget"] = true
	defaults["mouseBuff"] = true
	defaults["mouseTooltip"] = true
	defaults["line1Tag"] = "[Name:HostileColor]"
--  defaults["line2Tag"] = "[Level:DifficultyColor] [[IsPlayer ? Race ! CreatureType]:ClassColor] [[IsPlayer ? Class]:ClassColor] [[~PvP ? \"PvE\" ! \"PvP\"]:HostileColor] [IsLeader ? \"Leader\":Yellow] [InCombat ? \"Combat\":Red] [Classification]"
	defaults["line2Tag"] = "[Level:DifficultyColor] [SmartRace:ClassColor] [SmartClass:ClassColor] [PvPIcon] [IsLeader ? 'Leader':Yellow] [InCombat ? 'Combat':Red] [Classification]"
	defaults["line3Tag"] = "[Guild:Angle]"
	defaults["line4Tag"] = ""
	defaults["myTagVersion"] = 2
	defaults["alwaysFullAlpha"] = true
	defaults["spaceBetweenBuffs"] = 0
	defaults["displayTargetName"] = true
	defaults["displayTargetDetails"] = true
	defaults["displayTargetGuild"] = true
	defaults["forceHideCooldownNumbers"] = false
	defaults["auras"] = {
		["buff"] = {
			["size"] = 20,
			["ownSize"] = 20,
			["offsetX"] = -10,
			["offsetY"] = 0,
			["anchorTo"] = "TOPLEFT",
			["growDirection"] = "Left",
			["filter"] = "Never",
			["show"] = true,
			["perRow"] = 10,
			["sortByExpiration"] = true,
		},
		["debuff"] = {
			["size"] = 20,
			["ownSize"] = 20,
			["offsetX"] = 10,
			["offsetY"] = 0,
			["anchorTo"] = "TOPRIGHT",
			["growDirection"] = "Right",
			["filter"] = "Never",
			["show"] = true,
			["perRow"] = 10,
			["sortByExpiration"] = true,
		}
	}
	defaults["showRaidIcon"] = true

	return defaults
end


do
	local function SetFontString(self, textFrame, tag)
		if textFrame and tag ~= '' then
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			DogTag:AddFontString(textFrame, self.frame, self:GetDogTagOutline() .. tag, "Unit", { unit = self.unit })
		else
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			DogTag:RemoveFontString(textFrame)
		end
	end

	function IceTargetInfo.prototype:RegisterFontStrings()
		if DogTag ~= nil then
			SetFontString(self, self.frame.targetName, self.moduleSettings.line1Tag)
			SetFontString(self, self.frame.targetInfo, self.moduleSettings.line2Tag)
			SetFontString(self, self.frame.targetGuild, self.moduleSettings.line3Tag)
			SetFontString(self, self.frame.targetExtra, self.moduleSettings.line4Tag)

			self:TargetChanged()
			DogTag:UpdateAllForFrame(self.frame)
		end
	end
end


function IceTargetInfo.prototype:UnregisterFontStrings()
	if DogTag ~= nil then
		DogTag:RemoveFontString(self.frame.targetName)
		DogTag:RemoveFontString(self.frame.targetInfo)
		DogTag:RemoveFontString(self.frame.targetGuild)
		DogTag:RemoveFontString(self.frame.targetExtra)
	end
end


-- OVERRIDE
function IceTargetInfo.prototype:Redraw()
	IceTargetInfo.super.prototype.Redraw(self)

	if (self.moduleSettings.enabled) then
		self:CreateFrame(true)
		self:TargetChanged()
	end
end


function IceTargetInfo.prototype:RedrawBuffs()
	if (self.moduleSettings.enabled) then
		self:CreateAuraFrame("buff", false)
		self:CreateAuraFrame("debuff", false)

		self:TargetChanged()
	end
end

-- 'Protected' methods --------------------------------------------------------
do
	local function CreateTextFrame(self, textFrame, fontSize, relativePoint, offsetX, offsetY, height, show, align)
		if not align then align = "CENTER" end
		textFrame = self:FontFactory(fontSize, self.frame, textFrame)
		textFrame:SetJustifyH(align)
		textFrame:SetJustifyV("TOP")
		textFrame:SetPoint("TOP", self.frame, relativePoint, offsetX, offsetY)
		textFrame:SetPoint("LEFT", self.frame, "LEFT")
		textFrame:SetPoint("RIGHT", self.frame, "RIGHT")

		if height then textFrame:SetHeight(height) end
		if show then textFrame:Show() end

		return textFrame
	end

	local function CreateRaidIconFrame(self)
		if (not self.frame.raidIcon) then
			self.frame.raidIcon = CreateFrame("Frame", nil, self.frame)
		end

		if (not self.frame.raidIcon.icon) then
			self.frame.raidIcon.icon = self.frame.raidIcon:CreateTexture(nil, "BACKGROUND")
			self.frame.raidIcon.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
		end

		self.frame.raidIcon:SetPoint("BOTTOM", self.frame, "TOP", 0, 1)
		self.frame.raidIcon:SetWidth(16)
		self.frame.raidIcon:SetHeight(16)

		self.frame.raidIcon.icon:SetAllPoints(self.frame.raidIcon)
		SetRaidTargetIconTexture(self.frame.raidIcon.icon, 0)
		self.frame.raidIcon:Hide()
	end

	function IceTargetInfo.prototype:CreateFrame(redraw)
		if not (self.frame) then
			self.frame = CreateFrame("Button", "IceHUD_"..self.elementName, self.parent, "SecureUnitButtonTemplate")
		end
		self:CreateMoveHintFrame()

		-- Parnic - yes, 200 is fairly arbitrary. make a best effort for long names to fit
		self.width = math.max(200, self.settings.gap + 50)

		self.frame:SetScale(self.moduleSettings.scale)

		self.frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
		self.frame:SetWidth(self.width)
		self.frame:SetHeight(32)
		self.frame:ClearAllPoints()
		self:SetFramePosition()
		self.frame:SetScale(self.moduleSettings.scale)

		if (self.moduleSettings.mouseTarget) then
			self.frame:EnableMouse(true)
			self.frame:RegisterForClicks("AnyUp")
			self.frame:SetScript("OnEnter", function(frame) self:OnEnter(frame) end)
			self.frame:SetScript("OnLeave", function(frame) self:OnLeave(frame) end)

			self.frame:SetAttribute("type1", "target")
			self.frame:SetAttribute("type2", "togglemenu")

			-- set up click casting
			ClickCastFrames = ClickCastFrames or {}
			ClickCastFrames[self.frame] = true
		else
			self.frame:EnableMouse(false)
			self.frame:RegisterForClicks()
			self.frame:SetScript("OnEnter", nil)
			self.frame:SetScript("OnLeave", nil)

			self.frame:SetAttribute("type1")
			self.frame:SetAttribute("type2")

		-- set up click casting
		--ClickCastFrames = ClickCastFrames or {}
		--ClickCastFrames[self.frame] = false
		end

		self.frame.unit = self.unit

		self.frame:SetAttribute("unit", self.unit)


		-- create a fancy highlight frame for mouse over
		if (not self.frame.highLight) then
			self.frame.highLight = self.frame:CreateTexture(nil, "OVERLAY")
			self.frame.highLight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
			self.frame.highLight:SetBlendMode("ADD")
			self.frame.highLight:SetAllPoints(self.frame)
			self.frame.highLight:SetVertexColor(1, 1, 1, 0.25)
			self.frame.highLight:Hide()
		end


		-- create rest of the frames
		self.frame.targetName = CreateTextFrame(self, self.frame.targetName, self.moduleSettings.fontSize+1, "TOP", 0, 0, nil, nil, self.moduleSettings.line1Alignment)
		self.frame.targetInfo = CreateTextFrame(self, self.frame.targetInfo, self.moduleSettings.fontSize, "TOP", 0, -16, 14, true, self.moduleSettings.line2Alignment)
		self.frame.targetGuild = CreateTextFrame(self, self.frame.targetGuild, self.moduleSettings.fontSize, "BOTTOM", 0, 0, 14, true, self.moduleSettings.line3Alignment)
		self.frame.targetExtra = CreateTextFrame(self, self.frame.targetExtra, self.moduleSettings.fontSize, "BOTTOM", 0, -16, 14, true, self.moduleSettings.line4Alignment)

		self:CreateAuraFrame("buff", redraw)
		self:CreateAuraFrame("debuff", redraw)

		CreateRaidIconFrame(self)
	end
end

-- The corner an aura strip hangs from has to be the one it grows away from, or the strip
-- walks its own first icon around as auras come and go: an aura container sizes itself to
-- its contents, so pinning the edge the icons grow *toward* leaves the other edge - the one
-- icon 1 sits on - moving. The old icon frames were 1x1 holders whose corners all landed on
-- the same pixel, so they never cared which one we named.
function IceTargetInfo.prototype:GetAuraFramePoint(aura)
	return self.moduleSettings.auras[aura].growDirection == "Left" and "TOPRIGHT" or "TOPLEFT"
end

function IceTargetInfo.prototype:CreateAuraFrame(aura, redraw)
	local auraFrame, point

	if (aura == "buff") then
		auraFrame = "buffFrame"
	elseif (aura == "debuff") then
		auraFrame = "debuffFrame"
	else
		error("Invalid Auraframe")
	end

	point = self:GetAuraFramePoint(aura)

	if IceHUD.CanUseAuraContainer() then
		self:CreateAuraContainer(aura, auraFrame, point)
		self:CreateConfigAuraFrame(aura, point, redraw)
		return
	end

	if (not self.frame[auraFrame]) then
		self.frame[auraFrame] = CreateFrame("Frame", nil, self.frame)
		self.frame[auraFrame]:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
		self.frame[auraFrame]:SetWidth(1)
		self.frame[auraFrame]:SetHeight(1)
		self.frame[auraFrame]:Show()
		self.frame[auraFrame].iconFrames = {}
	end

	self.frame[auraFrame]:ClearAllPoints()
	self.frame[auraFrame]:SetPoint(point, self.frame, self.moduleSettings.auras[aura].anchorTo, self.moduleSettings.auras[aura].offsetX, self.moduleSettings.auras[aura].offsetY)

	if (not redraw) then
		self.frame[auraFrame].iconFrames = self:CreateIconFrames(self.frame[auraFrame], self.moduleSettings.auras[aura].growDirection, self.frame[auraFrame].iconFrames, aura)
	end

	if self.moduleSettings.auras[aura].show then
		self.frame[auraFrame]:Show()
	else
		self.frame[auraFrame]:Hide()
	end
end

-- An aura container only ever draws real auras, so config mode gets a parallel strip of
-- our own icon frames standing in for them - the placeholders UpdateBuffType fabricates
-- inline have no icon frames to live in on this path. Like the weapon enchant strip, it's
-- anchored to our own frame rather than to the restricted container.
function IceTargetInfo.prototype:CreateConfigAuraFrame(aura, point, redraw)
	if not IceHUD.CanUseAuraContainer() then
		return
	end

	local settings = self.moduleSettings.auras[aura]
	local frame = self.frame[self:GetConfigAuraFrameKey(aura)]

	-- A full grid of icon frames per aura type isn't free, so don't build the strip until
	-- config mode asks for it. Once it exists, keep it in step with the settings.
	if not frame and not self:IsInConfigMode() then
		return
	end

	if not frame then
		frame = CreateFrame("Frame", nil, self.frame)
		frame:SetWidth(1)
		frame:SetHeight(1)
		frame.iconFrames = {}
		self.frame[self:GetConfigAuraFrameKey(aura)] = frame
	end

	frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
	frame:ClearAllPoints()
	frame:SetPoint(point, self.frame, settings.anchorTo, settings.offsetX, settings.offsetY)

	if not redraw or #frame.iconFrames == 0 then
		frame.iconFrames = self:CreateIconFrames(frame, settings.growDirection, frame.iconFrames, aura)

		-- These stand in for auras that aren't there, so there's nothing to hand a tooltip.
		for i = 1, #frame.iconFrames do
			frame.iconFrames[i]:EnableMouse(false)
			frame.iconFrames[i]:SetScript("OnEnter", nil)
			frame.iconFrames[i]:SetScript("OnLeave", nil)
		end
	end

	frame:Hide()
end

function IceTargetInfo.prototype:GetConfigAuraFrameKey(aura)
	return aura .. "ConfigFrame"
end

-- Matches what the pre-container path fabricates in UpdateBuffType: every slot filled, so
-- the whole grid can be sized and positioned.
function IceTargetInfo.prototype:UpdateConfigAuras(aura)
	local frameKey = self:GetConfigAuraFrameKey(aura)

	-- The container globals can show up after our frames were built, so make the strip on
	-- first use rather than only at creation time.
	if not self.frame[frameKey] then
		self:CreateConfigAuraFrame(aura, self:GetAuraFramePoint(aura), false)
	end

	local frame = self.frame[frameKey]

	if not frame or not frame.iconFrames then
		return
	end

	if not self.moduleSettings.auras[aura].show or not UnitExists(self.unit) then
		frame:Hide()
		return
	end

	frame:Show()

	for i = 1, #frame.iconFrames do
		self:SetupAura(aura, i, [[Interface\Icons\Spell_Frost_Frost]], 60, GetTime() + 59, false,
			math.random(5), nil, aura, nil, true, frameKey)
	end
end

function IceTargetInfo.prototype:HideConfigAuras(aura)
	local frame = self.frame[self:GetConfigAuraFrameKey(aura)]

	if frame then
		frame:Hide()
	end
end

-- Stealable buffs get their own group so mages keep the border that marks them. Splitting
-- by caster isn't possible: every aura reads as the player's while auras are secret.
function IceTargetInfo.prototype:GetAuraGroupDescriptions(aura)
	local settings = self.moduleSettings.auras[aura]
	local splitByStealable = aura == "buff" and self.playerClass == "MAGE"
	local descriptions = {}

	for stealIndex = 1, splitByStealable and 2 or 1 do
		local isStealable

		if splitByStealable then
			isStealable = stealIndex == 1
		end

		tinsert(descriptions, {
			key = "group" .. stealIndex,
			candidateFilters = isStealable ~= nil and {isStealable = isStealable} or nil,
			size = settings.size,
			stealable = isStealable == true,
		})
	end

	return descriptions
end

-- The container invokes this through securecallfunction, which discards errors, so a
-- broken button would otherwise just render nothing with no way to tell why.
function IceTargetInfo.prototype:SafeInitializeAuraButton(aura, container, key, button)
	local ok, err = pcall(self.InitializeAuraButton, self, aura, container, key, button)

	if not ok and not container.iceReportedError then
		container.iceReportedError = true
		IceHUD:Debug("failed to set up " .. aura .. " display: " .. tostring(err))
	end
end

-- Buttons are created on demand as auras appear, so the group's description has to be
-- read now rather than captured when the group was added, or later buttons keep the
-- sizes the settings had back then.
function IceTargetInfo.prototype:InitializeAuraButton(aura, container, key, button)
	local group = container.iceGroups[key]
	local description = group.description
	local inset = description.stealable and 4 or 1
	local border = button:CreateTexture(nil, "BACKGROUND")
	border:SetAllPoints(button)

	if description.stealable then
		border:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
	elseif aura == "debuff" then
		border:SetColorTexture(1, 1, 1, 1)
		button:AddDispelTypeTexture(border)
	else
		border:SetColorTexture(0, 0, 0, 0.5)
	end

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
	icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)

	local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cooldown:SetAllPoints(button)
	cooldown:SetReverse(true)
	cooldown:SetDrawEdge(false)

	local stack = button:CreateFontString()
	stack:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 3, -1)

	local record = {button = button, icon = icon, cooldown = cooldown, stack = stack}

	-- The container starts drawing a region the moment it's handed one, and an unconfigured
	-- region raises rather than drawing nothing, so everything is set up before handover.
	self:ApplyAuraButtonSettings(record, description)

	button:SetIcon(icon)
	button:SetDurationCooldown(cooldown)
	button:SetApplicationCount(stack)
	button:SetTooltipAnchorPoint("ANCHOR_BOTTOMLEFT")

	tinsert(group.buttons, record)
end

-- The container's layout only anchors buttons, so their size is ours to set. Buttons only
-- deny tainted access while auras are secret, so settings changes reach them out of combat.
function IceTargetInfo.prototype:ApplyAuraButtonSettings(record, description)
	local zoom = self.moduleSettings.zoom

	record.button:SetSize(description.size, description.size)
	record.button:EnableMouse(self.moduleSettings.mouseBuff)
	record.icon:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)
	record.cooldown:SetHideCountdownNumbers(self.moduleSettings.forceHideCooldownNumbers)
	self:FontFactory(self.moduleSettings.stackFontSize, record.button, record.stack, "OUTLINE")
	self:ApplyAuraCooldownAlpha(record)
end

function IceTargetInfo.prototype:CreateAuraContainer(aura, auraFrame, point)
	local settings = self.moduleSettings.auras[aura]
	local descriptions = self:GetAuraGroupDescriptions(aura)
	local container = self.frame[auraFrame]

	-- Each group preallocates a batch of buttons, so don't build one until it's wanted.
	if not container and not settings.show then
		return
	end

	if not container then
		container = CreateFrame("AuraContainer", nil, self.frame, "CustomAuraContainerTemplate")
		container:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
		container:SetUnit(self.unit)
		container.iceGroupKeys = {}
		container.iceGroups = {}
		self.frame[auraFrame] = container
	end

	-- Groups are added on first sight rather than only at creation so a description that
	-- shows up later still gets a group instead of failing every layout pass from then on.
	for i = 1, #descriptions do
		if not container.iceGroups[descriptions[i].key] then
			self:AddAuraGroupSafely(aura, container, descriptions[i])
		end
	end

	container:ClearAllPoints()
	container:SetPoint(point, self.frame, settings.anchorTo, settings.offsetX, settings.offsetY)

	local ok, err = pcall(self.ApplyAuraContainerSettings, self, aura, container, descriptions)
	if not ok and not container.iceReportedLayoutError then
		container.iceReportedLayoutError = true
		IceHUD:Debug("aura container layout failed for " .. aura .. ": " .. tostring(err))
	end

	IceHUD:Debug(aura, "container show", tostring(settings.show))

	for _, key in ipairs(container.iceGroupKeys) do
		local group = container.iceGroups[key]
		local filters = group.description.candidateFilters or {}

		IceHUD:Debug(" ", key, "size", group.description.size, "buttons", #group.buttons,
			"stealable", tostring(filters.isStealable))
	end
end

-- One rejected group must not take down the rest of the module's frame creation.
function IceTargetInfo.prototype:AddAuraGroupSafely(aura, container, description)
	local key = description.key

	container.iceGroups[key] = {buttons = {}, description = description}

	local ok, err = pcall(container.AddAuraGroup, container, key, self:GetAuraFilterString(aura), {
		initializeFrame = function(button) self:SafeInitializeAuraButton(aura, container, key, button) end,
		candidateFilters = description.candidateFilters,
		maxFrameCount = IceCore.BuffLimit,
	})

	-- A rejected group keeps its entry, marked, so it isn't retried on every layout pass.
	if not ok then
		container.iceGroups[key].rejected = true
		IceHUD:Debug("aura group " .. key .. " rejected: " .. tostring(err))
		return
	end

	tinsert(container.iceGroupKeys, key)
end

function IceTargetInfo.prototype:ApplyAuraContainerSettings(aura, container, descriptions)
	local settings = self.moduleSettings.auras[aura]
	local left = settings.growDirection == "Left"
	local spacing = self.moduleSettings.spaceBetweenBuffs
	local sortMethod = settings.sortByExpiration and AuraContainerSortMethod.Expiration or AuraContainerSortMethod.Default

	container:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis.Horizontal)
	container:SetFlowLayoutAnchorPoint(left and "TOPRIGHT" or "TOPLEFT")
	container:SetFlowLayoutGrowthDirection(left and AnchorUtil.FlowDirection.Left or AnchorUtil.FlowDirection.Right,
		AnchorUtil.FlowDirection.Down)
	container:SetFlowLayoutMaximumLineSize(settings.perRow * settings.size + (settings.perRow - 1) * spacing)

	for i = 1, #descriptions do
		local description = descriptions[i]

		self:ApplyAuraGroupSettings(container, description, sortMethod, {
			elementSpacing = spacing,
			lineSpacing = spacing,
			elementWidth = description.size,
			elementHeight = description.size,
			layoutIndex = i,
		})
	end

	container:SetEnabled(settings.show)
	container:SetShown(settings.show)
end

-- Restrictions apply to buttons while auras are secret, so a settings change made in
-- combat only reaches the ones it can. The next non-combat pass catches the rest.
function IceTargetInfo.prototype:ApplyAuraGroupSettings(container, description, sortMethod, layout)
	local group = container.iceGroups[description.key]

	if not group or group.rejected then
		return
	end

	group.description = description
	container:SetAuraGroupSortMethod(description.key, sortMethod, AuraContainerSortDirection.Normal)
	container:SetAuraGroupLayout(description.key, layout)

	for _, record in ipairs(group.buttons) do
		pcall(self.ApplyAuraButtonSettings, self, record, description)
	end
end

-- The "In Combat" setting narrows to the player's own auras, which the filter string
-- already expresses, so the container applies it instead of us inspecting casters.
function IceTargetInfo.prototype:GetAuraFilterString(aura)
	local reaction = aura == "buff" and "HELPFUL" or "HARMFUL"
	local onlyMine = self.moduleSettings.auras[aura].filter == "Always"
		or (self.moduleSettings.auras[aura].filter == "In Combat" and UnitAffectingCombat("player"))

	return reaction .. (onlyMine and "|PLAYER" or "")
end

function IceTargetInfo.prototype:UpdateAuraContainer(aura)
	local container = self.frame[aura .. "Frame"]

	-- The container has no way to show anything but the unit's real auras, so config mode
	-- puts it away and shows the placeholder strip in its place.
	if self:IsInConfigMode() then
		if container then
			pcall(container.SetEnabled, container, false)
			pcall(container.SetShown, container, false)
		end

		self:UpdateConfigAuras(aura)
		return
	end

	self:HideConfigAuras(aura)

	if not container or not container.iceGroupKeys then
		return
	end

	for i = 1, #container.iceGroupKeys do
		container:SetAuraGroupFilterString(container.iceGroupKeys[i], self:GetAuraFilterString(aura))
	end

	container:SetEnabled(self.moduleSettings.auras[aura].show)
	pcall(container.SetShown, container, self.moduleSettings.auras[aura].show)
	container:SetUnit(self.unit)
	container:UpdateAllAuras()
end

do
	local function FrameFactory(frameType, parentFrame, inheritsFrame)
		local frame = CreateFrame(frameType, nil, parentFrame, inheritsFrame)
		frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
		frame:ClearAllPoints()
		return frame
	end

	local function TextureFactory(frame)
		local texture = frame:CreateTexture()
		texture:ClearAllPoints()
		texture:SetAllPoints(frame)
		return texture
	end

	-- count defaults to a full aura display; callers that only ever show a couple of icons
	-- (weapon enchants) pass their own so we don't build 40 frames they'll never use.
	function IceTargetInfo.prototype:CreateIconFrames(parent, direction, iconFrames, type, count)
		local numFrames = count or IceCore.BuffLimit
		local lastX = 0
		local lastAuraSize = 0
		local lastY = 0
		local largestHeightThisRow = 0
		local left = direction == "Left"
		local max = math.max

		if not self.MyOnEnterBuffFunc then
			self.MyOnEnterBuffFunc = function(this) self:BuffOnEnter(this) end
		end
		if not self.MyOnLeaveBuffFunc then
			self.MyOnLeaveBuffFunc = function() GameTooltip:Hide() end
		end

		for i = 1, numFrames do
			-- Setup --
			local anchor, spaceOffset
			local perRow = self.moduleSettings.auras.buff.perRow
			if type == "debuff" then
				perRow = self.moduleSettings.auras.debuff.perRow
			end
			local newRow = ((i % perRow) == 1 or perRow == 1)

			if newRow then
				lastX = 0
				lastY = lastY + largestHeightThisRow
				largestHeightThisRow = 0
				lastAuraSize = 0
				spaceOffset = 0
			else
				spaceOffset = self.moduleSettings.spaceBetweenBuffs
			end

			if left then
				spaceOffset = spaceOffset * -1
				anchor = "TOPRIGHT"
			else
				anchor = "TOPLEFT"
			end

			local offset_x = lastX + lastAuraSize + spaceOffset
			local offset_y = lastY * -1

			lastX = offset_x

			-- Frame creation --
			if (not iconFrames[i]) then
				iconFrames[i] = FrameFactory("Frame", parent)

				iconFrames[i].icon = FrameFactory("Frame",iconFrames[i])
				iconFrames[i].icon:SetPoint("CENTER", 0, 0)

				local cooldown = FrameFactory("Cooldown", iconFrames[i], "CooldownFrameTemplate")
				cooldown:SetAllPoints(iconFrames[i])
				cooldown:SetFrameLevel(iconFrames[i].icon:GetFrameLevel()+1)
				cooldown:SetReverse(true)
				iconFrames[i].cd = cooldown
			end

			if iconFrames[i].cd.SetHideCountdownNumbers then
				iconFrames[i].cd:SetHideCountdownNumbers(self.moduleSettings.forceHideCooldownNumbers)
			end

			-- Rokiyo: Can't locally buffering these until I'm sure they exist :(
			local frame = iconFrames[i]
			local icon = frame.icon

			frame:ClearAllPoints()
			frame:SetPoint(anchor, offset_x, offset_y)

			-- Frame resizing --
			local size = (frame.fromPlayer and not IceHUD.IsSecretEnv()) and self.moduleSettings.auras[type].ownSize or self.moduleSettings.auras[type].size
			lastAuraSize = size * (left and -1 or 1)
			largestHeightThisRow = max(size, largestHeightThisRow)

			frame:SetWidth(size)
			frame:SetHeight(size)

			-- Texture creation --
			if not frame.texture then
				frame.texture = TextureFactory(frame)
				icon.texture = TextureFactory(frame.icon)
				icon.texture:SetTexture(nil)
			end

			if type == "buff" then
				if IceHUD.CanAccessValue(frame.isStealable) and frame.isStealable and self.playerClass == "MAGE" then
					frame.texture:SetVertexColor(1, 1, 1)
					frame.texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
					icon:SetWidth(size-8)
					icon:SetHeight(size-8)
				else
					frame.texture:SetTexture(0, 0, 0, 0.5)
					icon:SetWidth(size-2)
					icon:SetHeight(size-2)
				end
			else
				frame.texture:SetTexture(0, 0, 0, 0.5)
				icon:SetWidth(size-2)
				icon:SetHeight(size-2)
			end

			-- Text creation --
			local stack = self:FontFactory(self.moduleSettings.stackFontSize, icon, icon.stack, "OUTLINE")
			stack:ClearAllPoints()
			stack:SetPoint("BOTTOMRIGHT" , frame.icon, "BOTTOMRIGHT", 3, -1)
			icon.stack = stack

			-- Misc --
			if (self.moduleSettings.mouseBuff) then
				frame:EnableMouse(true)
				frame:SetScript("OnEnter", self.MyOnEnterBuffFunc)
				frame:SetScript("OnLeave", self.MyOnLeaveBuffFunc)
			else
				frame:EnableMouse(false)
				frame:SetScript("OnEnter", nil)
				frame:SetScript("OnLeave", nil)
			end
		end

		return iconFrames
	end
end

local function BuffExpirationSort(a, b)
	if not a[5] or a[5] == 0 then
		return false
	elseif not b[5] or b[5] == 0 then
		return true
	end

	return a[5] < b[5]
end

function IceTargetInfo.prototype:UpdateBuffType(aura)
	if IceHUD.CanUseAuraContainer() then
		return self:UpdateAuraContainer(aura)
	end

	if not self.buffData then
		self.buffData = {
			buff = {},
			debuff = {},
		}
	end

	local filter = false
	local auraFrame = aura.."Frame"

	local reaction
	if (aura == "buff") then
		reaction = "HELPFUL"
	elseif (aura == "debuff") then
		reaction = "HARMFUL"
	else
		error("Invalid buff frame")
	end

	if (self.moduleSettings.auras[aura].filter == "Always") then
		filter = true
	elseif (self.moduleSettings.auras[aura].filter == "In Combat") then
		if (UnitAffectingCombat("player")) then
			filter = true
		end
	end

	if self.moduleSettings.auras[aura].show then
		-- Showing every aura on a unit means iterating them, which addons can't do while
		-- auras are secret. The loop still runs so the icons clear instead of going stale.
		local auraFilter = reaction .. (filter and "|PLAYER" or "")
		local canIterate = IceHUD:CanIterateAuras()

		for i = 1, IceCore.BuffLimit do
			local _, icon, count, duration, expirationTime, unitCaster, isStealable, auraInstanceID

			---- Fulzamoth - 2019-09-04 : support for cooldowns on target buffs/debuffs (classic)
			local spellID
			---- end change by Fulzamoth

			if not canIterate then
				-- nothing to read; leave every field nil so the icon hides
			elseif IceHUD.SpellFunctionsReturnRank then
				_, _, icon, count, _, duration, expirationTime, unitCaster, isStealable = IceHUD.UnitAura(self.unit, i, auraFilter)
			else
				---- Fulzamoth - 2019-09-04 : support for cooldowns on target buffs/debuffs (classic)
				-- 1. in addition to other info, get the spellID for for the (de)buff
				_, icon, count, _, duration, expirationTime, unitCaster, isStealable, _, spellID, _, _, _, _, _, auraInstanceID = IceHUD.UnitAura(self.unit, i, auraFilter)
				if IceHUD.CanAccessValue(duration) and duration == 0 and LibClassicDurations then
					-- 2. if no duration defined for the (de)buff, look up the spell in LibClassicDurations
					local classicDuration, classicExpirationTime = LibClassicDurations:GetAuraDurationByUnit(self.unit, spellID, unitCaster)
					-- 3. set the duration if we found one.
					if classicDuration then
						duration = classicDuration
						expirationTime = classicExpirationTime
					end
				end
				---- end change by Fulzamoth
			end
			local isFromMe = IceHUD.CanAccessValue(unitCaster) and (unitCaster == "player")

			if not icon and self:IsInConfigMode() and UnitExists(self.unit) then
				icon = [[Interface\Icons\Spell_Frost_Frost]]
				duration = 60
				expirationTime = GetTime() + 59
				count = math.random(5)
			end

			if self:CanSortBuffs() and self.moduleSettings.auras[aura].sortByExpiration then
				if not self.buffData[aura][i] then
					self.buffData[aura][i] = {}
				end

				-- not sure how i feel about this, but it avoids creating more tables
				self.buffData[aura][i][1] = aura
				self.buffData[aura][i][2] = i
				self.buffData[aura][i][3] = icon
				self.buffData[aura][i][4] = duration
				self.buffData[aura][i][5] = expirationTime
				self.buffData[aura][i][6] = isFromMe
				self.buffData[aura][i][7] = count
				self.buffData[aura][i][8] = isStealable
				self.buffData[aura][i][9] = aura
				self.buffData[aura][i][10] = auraInstanceID
				self.buffData[aura][i][11] = icon ~= nil
			else
				self:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, aura, auraInstanceID, icon ~= nil)
			end
		end
	end

	if self:CanSortBuffs() and self.moduleSettings.auras[aura].sortByExpiration and #self.buffData[aura] > 0 then
		table.sort(self.buffData[aura], BuffExpirationSort)
		for i = 1, IceCore.BuffLimit do
			local v = self.buffData[aura][i]
			self:SetupAura(v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8], v[9], v[10], v[11])
		end
	end

	self.frame[auraFrame].iconFrames = self:CreateIconFrames(self.frame[auraFrame], self.moduleSettings.auras[aura].growDirection, self.frame[auraFrame].iconFrames, aura)
end

function IceTargetInfo.prototype:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, auraType, auraInstanceID, isActive, frameKey)
	local zoom = self.moduleSettings.zoom
	local auraFrame = frameKey or aura.."Frame"

	local frame = self.frame[auraFrame].iconFrames[i]
	frame.id = i
	local frameTexture = frame.texture
	local frameIcon = frame.icon

	if not isActive then
		frame:Hide()
		return
	end

	if aura == "buff" then
		frame.isStealable = isStealable
	elseif aura == "debuff" then
		local alpha = icon and 1 or 0
		frameTexture:SetTexture(1, 1, 1, alpha)

		if DebuffTypeColor then
			local color = auraType and DebuffTypeColor[auraType] or DebuffTypeColor["none"]
			frameTexture:SetVertexColor(color.r, color.g, color.b)
		end
	end

	-- cooldown frame
	if IceHUD.CanAccessValue(duration) then
		if (duration and duration > 0 and expirationTime and expirationTime > 0) then
			local start = expirationTime - duration

			CooldownFrame_SetTimer(frame.cd, start, duration, true)
			frame.cd:Show()
		else
			frame.cd:Hide()
		end
	elseif auraInstanceID then
		duration = C_UnitAuras.GetAuraDuration(self.unit, auraInstanceID)
		if duration then
			frame.cd:SetCooldownFromDurationObject(duration)
		end
	end

	frame.type = auraType
	frame.fromPlayer = isFromMe

	frameIcon.texture:SetTexture(icon)
	frameIcon.texture:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)
	if not IceHUD.CanAccessValue(count) then
		if auraInstanceID then
			count = C_UnitAuras.GetAuraApplicationDisplayCount(self.unit, auraInstanceID)
			frameIcon.stack:SetText(count)
		else
			frameIcon.stack:SetText()
		end
	else
		frameIcon.stack:SetText((count and (count > 1)) and count or nil)
	end

	frame:Show()
end

function IceTargetInfo.prototype:UpdateBuffs()
	self:UpdateBuffType("buff")
	self:UpdateBuffType("debuff")
end

function IceTargetInfo.prototype:AuraChanged(event, unit)
	if (unit == self.unit) then
		self:UpdateBuffs()
	end
end

function IceTargetInfo.prototype:UpdateRaidTargetIcon()
	if not (UnitExists(self.unit)) or not self.moduleSettings.showRaidIcon then
		self.frame.raidIcon:Hide()
		return
	end

	local index = GetRaidTargetIndex(self.unit);

	if index then
		SetRaidTargetIconTexture(self.frame.raidIcon.icon, index)
		self.frame.raidIcon:Show()
	else
		self.frame.raidIcon:Hide()
	end
end


function IceTargetInfo.prototype:TargetChanged()
	IceTargetInfo.super.prototype.TargetChanged(self)

	if (not UnitExists(self.unit)) then
		--self.frame:Hide()
		--self.frame.target:Hide()

		self.frame.targetName:SetText()
		self.frame.targetInfo:SetText()
		self.frame.targetGuild:SetText()
		self.frame.targetExtra:SetText()

		self:UpdateBuffs()
		self:UpdateRaidTargetIcon()
		return
	end


	-- pass "internal" as a paramater so event handler code doesn't execute
	-- Update() unnecassarily

	self:TargetName(nil, internal)

	self:TargetLevel(nil, internal)
	self:TargetReaction(nil, internal)
	self:TargetFaction(nil, internal)
	self:TargetFlags(nil, internal)

	self:UpdateBuffs()
	self:UpdateRaidTargetIcon()

	self:Update(self.unit)
end


function IceTargetInfo.prototype:TargetName(event, unit)
	if (unit == self.unit or unit == internal) then
		self.name, self.realm = UnitName(self.unit)
		self.classLocale, self.classEnglish = UnitClass(self.unit)
		self.isPlayer = UnitIsPlayer(self.unit)


		local classification = UnitClassification(self.unit) or ""
		if (string.find(classification, "boss")) then
			self.classification = " |cffcc1111Boss|r"
		elseif(string.find(classification, "rare")) then
			self.classification = " |cffcc11ccRare|r"
		else
			self.classification = ""
		end


		local guildName, guildRankName, guildRankIndex = GetGuildInfo(self.unit);
		self.guild = guildName and "<" .. guildName .. ">" or ""


		if not (self.classLocale and self.isPlayer) then
			self.classLocale = UnitCreatureType(self.unit)
		elseif IceHUD.CanAccessValue(self.classEnglish) then
			-- a secret class can't be used to look up its color, so the name stays uncolored
			self.classLocale = "|c" .. self:GetHexColor(self.classEnglish) ..  self.classLocale .. "|r"
		end


		if UnitIsPartyLeader then
			self.leader = UnitIsPartyLeader(self.unit) and " |cffcccc11Leader|r" or ""
		else
			local leader = UnitIsGroupLeader(self.unit)
			if not IceHUD.CanAccessValue(leader) then
				leader = false
			end
			self.leader = leader and " |cffcccc11Leader|r" or ""
		end
		self:Update(unit)
	end
end


function IceTargetInfo.prototype:TargetLevel(event, unit)
	if (unit == self.unit or unit == internal) then
		self.level = UnitLevel(self.unit)

		local colorFunc = GetQuestDifficultyColor or GetDifficultyColor
		local color = colorFunc((self.level > 0) and self.level or 100)

		if (self.level > 0) then
			if (UnitClassification(self.unit) == "elite") then
				self.level = self.level .. "+"
			end
		else
			self.level = "??"
		end

		self.level = "|c" .. self:ConvertToHex(color) .. self.level .. "|r"

		self:Update(unit)
	end
end


function IceTargetInfo.prototype:TargetReaction(event, unit)
	if (unit == self.unit or unit == internal) then
		self.reaction = UnitReaction(self.unit, "player")

		-- if we don't get reaction, unit is out of range - has to be friendly
		-- to be targettable (party/raid)
		if (not self.reaction) then
			self.reaction = 5
		end
		self:Update(unit)
	end
end


-- PVP status
function IceTargetInfo.prototype:TargetFaction(event, unit)
	if (unit == self.unit or unit == internal) then
		if (self.isPlayer) then
			local pvp = UnitIsPVP(self.unit)
			if not IceHUD.CanAccessValue(pvp) then
				pvp = false
			end
			if pvp then
				local color = "ff10ff10" -- friendly
				if (UnitFactionGroup(self.unit) ~= UnitFactionGroup("player")) then
					color = "ffff1010" -- hostile
				end
				self.pvp = " |c" .. color .. "PvP|r"
			else
				self.pvp = " |cff1010ffPvE|r"
			end
		else
			self.pvp = ""
		end

		self:TargetReaction(unit)
		self:Update(unit)
	end
end


function IceTargetInfo.prototype:TargetFlags(event, unit)
	if (unit == self.unit or unit == internal) then
		if UnitIsTapped then
			self.tapped = UnitIsTapped(self.unit) and (not UnitIsTappedByPlayer(self.unit))
		else
			self.tapped = UnitIsTapDenied(self.unit)
		end
		self.targetCombat = UnitAffectingCombat(self.unit) and " |cffee4030Combat|r" or ""
		self:UpdateBuffs()
		self:Update(unit)
	end
end


function IceTargetInfo.prototype:Update(unit)
	if (unit ~= self.unit) then
		return
	end

	if DogTag == nil then
		if self.moduleSettings.displayTargetName then
			self.frame.targetName:SetText(self.name or '')
			self.frame.targetName:SetVertexColor(UnitSelectionColor(self.unit))
		end

		if self.moduleSettings.displayTargetDetails then
			local line2 = string.format("%s %s%s%s%s%s",
				self.level or '', self.classLocale or '', self.pvp or '', self.leader or '', self.classification or '', self.targetCombat or '')
			self.frame.targetInfo:SetText(line2)
		end

		if self.moduleSettings.displayTargetGuild then
			local realm = self.realm and " " .. self.realm or ""
			local line3 = string.format("%s%s", self.guild or '', realm)
			self.frame.targetGuild:SetText(line3)
		end
	end

	-- Parnic - i have no idea why i have to force UpdateFontString here...but
	--          if i just do AllForFrame or AllForUnit, then selecting a unit after
	--          having nothing selected refuses to update the frames...*sigh*
	if DogTag ~= nil then
		DogTag:UpdateFontString(self.frame.targetName)
		DogTag:UpdateFontString(self.frame.targetInfo)
		DogTag:UpdateFontString(self.frame.targetGuild)
		DogTag:UpdateFontString(self.frame.targetExtra)
	end

	self:UpdateAlpha()
end

function IceTargetInfo.prototype:UpdateAlpha()
	IceTargetInfo.super.prototype.UpdateAlpha(self)

	-- Temp until Blizzard fixes their cooldown wipes. http://www.wowinterface.com/forums/showthread.php?t=49950
	self:UpdateAuraCooldownAlpha("buffFrame")
	self:UpdateAuraCooldownAlpha("debuffFrame")
	self:UpdateAuraCooldownAlpha(self:GetConfigAuraFrameKey("buff"))
	self:UpdateAuraCooldownAlpha(self:GetConfigAuraFrameKey("debuff"))
end

function IceTargetInfo.prototype:UpdateAuraCooldownAlpha(auraFrame)
	local frame = self.frame[auraFrame]

	if not frame or not IceHUD.CanAccessValue(self.alpha) then
		return
	end

	if not frame.iceGroups then
		for i = 1, #frame.iconFrames do
			self:SetAuraCooldownAlpha(frame.iconFrames[i].cd)
		end
		return
	end

	-- These cooldowns belong to buttons that refuse tainted access while auras are secret,
	-- so tinting them is best-effort.
	for _, group in pairs(frame.iceGroups) do
		for _, record in ipairs(group.buttons) do
			self:ApplyAuraCooldownAlpha(record)
		end
	end
end

-- Buttons hand their cooldown out to secret aura data, after which tinting it can be
-- refused, so the applied value is remembered: a button that missed an alpha change is
-- retried on later passes, and one that's current isn't poked at all.
function IceTargetInfo.prototype:ApplyAuraCooldownAlpha(record)
	if not IceHUD.CanAccessValue(self.alpha) or record.cooldownAlpha == self.alpha then
		return
	end

	if pcall(self.SetAuraCooldownAlpha, self, record.cooldown) then
		record.cooldownAlpha = self.alpha
	end
end

function IceTargetInfo.prototype:SetAuraCooldownAlpha(cooldown)
	cooldown:SetSwipeColor(0, 0, 0, CooldownSwipeAlpha)
	cooldown:SetDrawEdge(false)
end

function IceTargetInfo.prototype:OnEnter(frame)
	if self.moduleSettings.mouseTooltip then
		UnitFrame_OnEnter(frame)
	end
	self.frame.highLight:Show()
end


function IceTargetInfo.prototype:OnLeave(frame)
	if self.moduleSettings.mouseTooltip then
		UnitFrame_OnLeave(frame)
	end
	self.frame.highLight:Hide()
end

function IceTargetInfo.prototype:AllowMouseBuffInteraction(id)
	if (not self:IsVisible()) then
		return false
	end

	if not self.unit or not id then
		return false
	end

	if IceHUD.CanAccessValue(self.alpha) and self.alpha == 0 then
		return false
	end

	return true
end

function IceTargetInfo.prototype:BuffOnEnter(this)
	if not self:AllowMouseBuffInteraction(this.id) then
		return
	end

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	if this.type == "buff" then
		GameTooltip:SetUnitBuff(self.unit, this.id)
	elseif this.type == "mh" or this.type == "oh" then
		GameTooltip:SetInventoryItem("player", this.type == "mh" and GetInventorySlotInfo("MAINHANDSLOT") or GetInventorySlotInfo("SECONDARYHANDSLOT"))
	else
		GameTooltip:SetUnitDebuff(self.unit, this.id)
	end
end


-- Load us up
IceHUD.TargetInfo = IceTargetInfo:new()
