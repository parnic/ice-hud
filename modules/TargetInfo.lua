local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceTargetInfo = IceCore_CreateClass(IceElement)

local CooldownFrame_SetTimer = CooldownFrame_SetTimer
if IceHUD.WowVer >= 70000 then
	CooldownFrame_SetTimer = CooldownFrame_Set
end

local DogTag = nil

local internal = "internal"

local ValidAnchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

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
	if not UnitExists(unit) then
		return 1, 1, 1, 1
	elseif UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet") then
		if UnitIsPVP("player") then
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
		local playerPvp = UnitIsPVP("player")
		local unitPvp = UnitIsPVP(unit)
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
	IceTargetInfo.super.prototype.Enable(self, core)

	local _
	_, self.playerClass = UnitClass("player")

	if IceHUD.IceCore:ShouldUseDogTags() then
		DogTag = LibStub("LibDogTag-3.0", true)
		if DogTag then
			LibStub("LibDogTag-Unit-3.0")
		end
	end

	self:RegisterEvent("UNIT_AURA", "AuraChanged")

	self:RegisterEvent("UNIT_NAME_UPDATE", "TargetName")
	self:RegisterEvent("UNIT_FACTION", "TargetFaction")
	self:RegisterEvent("UNIT_LEVEL", "TargetLevel")

	self:RegisterEvent("UNIT_FLAGS", "TargetFlags")
	self:RegisterEvent("UNIT_DYNAMIC_FLAGS", "TargetFlags")

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


-- OVERRIDE
function IceTargetInfo.prototype:GetOptions()
	local opts = IceTargetInfo.super.prototype.GetOptions(self)

	opts["targetInfoHeader"] = {
		type = 'header',
		name = L["Look and Feel"],
		order = 30.9
	}

	opts["vpos"] = {
		type = "range",
		name = L["Vertical Position"],
		desc = L["Vertical Position"],
		get = function()
			return self.moduleSettings.vpos
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
			return self.moduleSettings.hpos
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
			sorted = {
				type = 'toggle',
				name = L["Sort by expiration"],
				desc = L["Toggles whether or not to sort by expiration time (otherwise they're sorted how the game sorts them - by application time)"],
				get = function()
					return self.moduleSettings.auras["buff"].sortByExpiration
				end,
				set = function(info, v)
					self.moduleSettings.auras["buff"].sortByExpiration = v
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 32.2
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
			sorted = {
				type = 'toggle',
				name = L["Sort by expiration"],
				desc = L["Toggles whether or not to sort by expiration time (otherwise they're sorted how the game sorts them - by application time)"],
				get = function()
					return self.moduleSettings.auras["debuff"].sortByExpiration
				end,
				set = function(info, v)
					self.moduleSettings.auras["debuff"].sortByExpiration = v
					self:RedrawBuffs()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 32.2
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

	return opts
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
			DogTag:AddFontString(textFrame, self.frame, tag, "Unit", { unit = self.unit })
		else
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
do 	-- OVERRIDE: IceTargetInfo.prototype:CreateFrame(redraw)
	local function CreateTextFrame(self, textFrame, fontSize, relativePoint, offsetX, offsetY, height, show)
		textFrame = self:FontFactory(fontSize, self.frame, textFrame)
		textFrame:SetJustifyH("CENTER")
		textFrame:SetJustifyV("TOP")
		textFrame:SetPoint("TOP", self.frame, relativePoint, offsetX, offsetY)

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

		-- Parnic - yes, 200 is fairly arbitrary. make a best effort for long names to fit
		self.width = math.max(200, self.settings.gap + 50)

		self.frame:SetScale(self.moduleSettings.scale)

		self.frame:SetFrameStrata("BACKGROUND")
		self.frame:SetWidth(self.width)
		self.frame:SetHeight(32)
		self.frame:ClearAllPoints()
		self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)
		self.frame:SetScale(self.moduleSettings.scale)

		if (self.moduleSettings.mouseTarget) then
			self.frame:EnableMouse(true)
			self.frame:RegisterForClicks("AnyUp")
			self.frame:SetScript("OnEnter", function(frame) self:OnEnter(frame) end)
			self.frame:SetScript("OnLeave", function(frame) self:OnLeave(frame) end)

			self.frame:SetAttribute("type1", "target")
			self.frame:SetAttribute("type2", "menu")

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

		if not self.frame.menu then
			self.frame.menu = function(this, unit)
				IceHUD.DropdownUnit = unit
				ToggleDropDownMenu(1, nil, IceHUD_UnitFrame_DropDown, "cursor")
			end
		end


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
		self.frame.targetName = CreateTextFrame(self, self.frame.targetName, self.moduleSettings.fontSize+1, "TOP", 0, 0, nil, nil)
		self.frame.targetInfo = CreateTextFrame(self, self.frame.targetInfo, self.moduleSettings.fontSize, "TOP", 0, -16, 14, true)
		self.frame.targetGuild = CreateTextFrame(self, self.frame.targetGuild, self.moduleSettings.fontSize, "BOTTOM", 0, 0, 14, true)
		self.frame.targetExtra = CreateTextFrame(self, self.frame.targetExtra, self.moduleSettings.fontSize, "BOTTOM", 0, -16, 14, true)

		self:CreateAuraFrame("buff", redraw)
		self:CreateAuraFrame("debuff", redraw)

		CreateRaidIconFrame(self)
	end
end

function IceTargetInfo.prototype:CreateAuraFrame(aura, redraw)
	local auraFrame, point

	if (aura == "buff") then
		auraFrame = "buffFrame"
		point = "TOPRIGHT"
	elseif (aura == "debuff") then
		auraFrame = "debuffFrame"
		point = "TOPLEFT"
	else
		error("Invalid Auraframe")
	end

	if (not self.frame[auraFrame]) then
		self.frame[auraFrame] = CreateFrame("Frame", nil, self.frame)
		self.frame[auraFrame]:SetFrameStrata("BACKGROUND")
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

do
	local function FrameFactory(frameType, parentFrame, inheritsFrame)
		local frame = CreateFrame(frameType, nil, parentFrame, inheritsFrame)
		frame:SetFrameStrata("BACKGROUND")
		frame:ClearAllPoints()
		return frame
	end

	local function TextureFactory(frame)
		local texture = frame:CreateTexture()
		texture:ClearAllPoints()
		texture:SetAllPoints(frame)
		return texture
	end

	function IceTargetInfo.prototype:CreateIconFrames(parent, direction, iconFrames, type)
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

		for i = 1, IceCore.BuffLimit do
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
			-- Rokiyo: Can't locally buffering these until I'm sure they exist :(
			local frame = iconFrames[i]
			local icon = frame.icon

			frame:ClearAllPoints()
			frame:SetPoint(anchor, offset_x, offset_y)

			-- Frame resizing --
			local size = frame.fromPlayer and self.moduleSettings.auras[type].ownSize or self.moduleSettings.auras[type].size
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
				if frame.isStealable and self.playerClass == "MAGE" then
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
	if a[5] == 0 then
		return false
	elseif b[5] == 0 then
		return true
	end

	return a[5] < b[5]
end

local buffData = {}
buffData["buff"] = {}
buffData["debuff"] = {}

function IceTargetInfo.prototype:UpdateBuffType(aura)
	local auraFrame, reaction
	local filter = false
	local auraFrame = aura.."Frame"

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
		for i = 1, IceCore.BuffLimit do
			local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitAura(self.unit, i, reaction .. (filter and "|PLAYER" or ""))
			local isFromMe = (unitCaster == "player")

			if not icon and IceHUD.IceCore:IsInConfigMode() and UnitExists(self.unit) then
				icon = [[Interface\Icons\Spell_Frost_Frost]]
				duration = 60
				expirationTime = GetTime() + 59
				count = math.random(5)
			end

			if icon then
				if self.moduleSettings.auras[aura].sortByExpiration then
					buffData[aura][i] = {aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, debuffType}
				else
					self:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, debuffType)
				end
			else
				self.frame[auraFrame].iconFrames[i]:Hide()
				buffData[aura][i] = nil
			end
		end
	end

	if self.moduleSettings.auras[aura].sortByExpiration then
		table.sort(buffData[aura], BuffExpirationSort)
		for k,v in pairs(buffData[aura]) do
			if v then
				self:SetupAura(v[1], k, v[3], v[4], v[5], v[6], v[7], v[8], v[9])
				-- pretty hacky, but hey...whaddya gonna do?
				self.frame[aura.."Frame"].iconFrames[k].id = v[2]
			end
		end
	end

	self.frame[auraFrame].iconFrames = self:CreateIconFrames(self.frame[auraFrame], self.moduleSettings.auras[aura].growDirection, self.frame[auraFrame].iconFrames, aura)
end

function IceTargetInfo.prototype:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, auraType)
	local hostile = UnitCanAttack("player", self.unit)
	local zoom = self.moduleSettings.zoom
	local auraFrame = aura.."Frame"

	-- Rokiyo: Locally buffering to reduce table lookups
	local size = isFromMe and self.moduleSettings.auras[aura].ownSize or self.moduleSettings.auras[aura].size
	local frame = self.frame[auraFrame].iconFrames[i]
	local frameTexture = frame.texture
	local frameIcon = frame.icon

	if aura == "buff" then
		frame.isStealable = isStealable
	elseif aura == "debuff" and (not hostile or not filter or (filter and duration)) then
		local alpha = icon and 1 or 0
		frameTexture:SetTexture(1, 1, 1, alpha)

		local color = auraType and DebuffTypeColor[auraType] or DebuffTypeColor["none"]
		frameTexture:SetVertexColor(color.r, color.g, color.b)
	end

	-- cooldown frame
	if (duration and duration > 0 and expirationTime and expirationTime > 0) then
		local start = expirationTime - duration

		CooldownFrame_SetTimer(frame.cd, start, duration, true)
		frame.cd:Show()
	else
		frame.cd:Hide()
	end

	frame.type = ((auraType == "mh" or auraType == "oh") and auraType) or aura
	frame.fromPlayer = isFromMe
	frame.id = i

	frameIcon.texture:SetTexture(icon)
	frameIcon.texture:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)
	frameIcon.stack:SetText((count and (count > 1)) and count or nil)

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

	if (index and (index > 0)) then
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


		if (self.classLocale and self.isPlayer) then
			self.classLocale = "|c" .. self:GetHexColor(self.classEnglish) ..  self.classLocale .. "|r"
		else
			self.classLocale = UnitCreatureType(self.unit)
		end


		if IceHUD.WowVer < 50000 then
			self.leader = UnitIsPartyLeader(self.unit) and " |cffcccc11Leader|r" or ""
		else
			self.leader = UnitIsGroupLeader(self.unit) and " |cffcccc11Leader|r" or ""
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


function IceTargetInfo.prototype:TargetReaction(unit)
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
			if (UnitIsPVP(self.unit)) then
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
		if IceHUD.WowVer < 70000 then
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
	for i = 1, #self.frame["buffFrame"].iconFrames do
		self.frame["buffFrame"].iconFrames[i].cd:SetSwipeColor(0, 0, 0, self.alpha)
		self.frame["buffFrame"].iconFrames[i].cd:SetDrawEdge(false)
	end
	for i = 1, #self.frame["debuffFrame"].iconFrames do
		self.frame["debuffFrame"].iconFrames[i].cd:SetSwipeColor(0, 0, 0, self.alpha)
		self.frame["debuffFrame"].iconFrames[i].cd:SetDrawEdge(false)
	end
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

	if self.alpha == 0 then
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
		GameTooltip:SetInventoryItem("player", this.type == "mh" and GetInventorySlotInfo("MainHandSlot") or GetInventorySlotInfo("SecondaryHandSlot"))
	else
		GameTooltip:SetUnitDebuff(self.unit, this.id)
	end
end


-- Load us up
IceHUD.TargetInfo = IceTargetInfo:new()
