local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceTargetInfo = IceCore_CreateClass(IceElement)

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
	if not self.moduleSettings.updateAurasIntoTable then
		self.moduleSettings.updateAurasIntoTable = true

		if self.moduleSettings.buffSize then self.moduleSettings.auras["buff"].size = self.moduleSettings.buffSize self.moduleSettings.buffSize = nil end
		if self.moduleSettings.ownBuffSize then self.moduleSettings.auras["buff"].ownSize = self.moduleSettings.ownBuffSize self.moduleSettings.ownBuffSize = nil end
		if self.moduleSettings.showBuffs then self.moduleSettings.auras["buff"].show = self.moduleSettings.showBuffs self.moduleSettings.showBuffs = nil end
		if self.moduleSettings.buffGrowDirection then self.moduleSettings.auras["buff"].growDirection = self.moduleSettings.buffGrowDirection self.moduleSettings.buffGrowDirection = nil end
		if self.moduleSettings.buffAnchorTo then self.moduleSettings.auras["buff"].anchorTo = self.moduleSettings.buffAnchorTo self.moduleSettings.buffAnchorTo = nil end
		if self.moduleSettings.buffOffset then
			if self.moduleSettings.buffOffset['x'] then self.moduleSettings.auras["buff"].offset['x'] = self.moduleSettings.buffOffset['x'] end
			if self.moduleSettings.buffOffset['y'] then self.moduleSettings.auras["buff"].offset['y'] = self.moduleSettings.buffOffset['y'] end
			self.moduleSettings.buffOffset = nil
		end

		if self.moduleSettings.debuffSize then self.moduleSettings.auras["debuff"].size = self.moduleSettings.debuffSize self.moduleSettings.debuffSize = nil end
		if self.moduleSettings.ownDebuffSize then self.moduleSettings.auras["debuff"].ownSize = self.moduleSettings.ownDebuffSize self.moduleSettings.ownDebuffSize = nil end
		if self.moduleSettings.showDebuffs then self.moduleSettings.auras["debuff"].show = self.moduleSettings.showDebuffs self.moduleSettings.showDebuffs = nil end
		if self.moduleSettings.debuffGrowDirection then self.moduleSettings.auras["debuff"].growDirection = self.moduleSettings.debuffGrowDirection self.moduleSettings.debuffGrowDirection = nil end
		if self.moduleSettings.debuffAnchorTo then self.moduleSettings.auras["debuff"].anchorTo = self.moduleSettings.debuffAnchorTo self.moduleSettings.debuffAnchorTo = nil end
		if self.moduleSettings.debuffOffset then
			if self.moduleSettings.debuffOffset['x'] then self.moduleSettings.auras["debuff"].offset['x'] = self.moduleSettings.debuffOffset['x'] end
			if self.moduleSettings.debuffOffset['y'] then self.moduleSettings.auras["debuff"].offset['y'] = self.moduleSettings.debuffOffset['y'] end
			self.moduleSettings.debuffOffset = nil
		end

		if self.moduleSettings.filterBuffs then
			self.moduleSettings.auras["buff"].filter = self.moduleSettings.filterBuffs
		elseif self.moduleSettings.filter then
			self.moduleSettings.auras["buff"].filter = self.moduleSettings.filter
		end
		self.moduleSettings.filterBuffs = nil

		if self.moduleSettings.filterDebuffs then
			self.moduleSettings.auras["debuff"].filter = self.moduleSettings.filterDebuffs
		elseif self.moduleSettings.filter then
			self.moduleSettings.auras["debuff"].filter = self.moduleSettings.filter
		end
		self.moduleSettings.filterDebuffs = nil

		self.moduleSettings.filter = nil
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

	opts["buffHeader"] = {
		type = 'header',
		name = L["Buff/Debuff Settings"],
		order = 33.9
	}

	opts["buffSize"] = {
		type = 'range',
		name = L["Buff size"],
		desc = L["Buff/debuff icon size"],
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
	}

	opts["ownBuffSize"] = {
		type = 'range',
		name = L["Own buff size"],
		desc = L["Buff/debuff size for buffs/debuffs that were applied by you, the player"],
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
	}

	opts["showBuffs"] = {
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
		order = 36
	}

	opts["filterBuffs"] = {
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
		order = 36.1
	}

	opts["showDebuffs"] = {
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
		order = 36.2
	}

	opts["filterDebuffs"] = {
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
		order = 36.3
	}

	opts["perRow"] = {
		type = 'range',
		name = L["Buffs / row"],
		desc = L["How many buffs/debuffs is shown on each row"],
		get = function()
			return self.moduleSettings.perRow
		end,
		set = function(info, v)
			self.moduleSettings.perRow = v
			self:RedrawBuffs()
		end,
		min = 0,
		max = 20,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 37
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

	opts["buffLocHeader"] = {
		type = 'header',
		name = L["Buff placement settings"],
		order = 37.05
	}

	opts["buffGrowDirection"] = {
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
	}

	opts["buffAnchorTo"] = {
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
	}

	opts["buffXOffset"] = {
		type = 'range',
		name = L["Buff horizontal offset"],
		desc = L["How far horizontally the buff frame should be offset from the anchor"],
		min = -500,
		max = 500,
		step = 1,
		get = function()
			return self.moduleSettings.auras["buff"].offset['x']
		end,
		set = function(info, v)
			self.moduleSettings.auras["buff"].offset['x'] = v
			self:CreateAuraFrame("buff")
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
		end,
		order = 37.3
	}

	opts["buffYOffset"] = {
		type = 'range',
		name = L["Buff vertical offset"],
		desc = L["How far vertically the buff frame should be offset from the anchor"],
		min = -500,
		max = 500,
		step = 1,
		get = function()
			return self.moduleSettings.auras["buff"].offset['y']
		end,
		set = function(info, v)
			self.moduleSettings.auras["buff"].offset['y'] = v
			self:CreateAuraFrame("buff")
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.auras["buff"].show
		end,
		order = 37.4
	}

	opts["debuffLocHeader"] = {
		type = 'header',
		name = L["Debuff placement settings"],
		order = 37.801
	}

	opts["debuffGrowDirection"] = {
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
	}

	opts["debuffAnchorTo"] = {
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
	}

	opts["debuffXOffset"] = {
		type = 'range',
		name = L["Debuff horizontal offset"],
		desc = L["How far horizontally the debuff frame should be offset from the anchor"],
		min = -500,
		max = 500,
		step = 1,
		get = function()
			return self.moduleSettings.auras["debuff"].offset['x']
		end,
		set = function(info, v)
			self.moduleSettings.auras["debuff"].offset['x'] = v
			self:CreateAuraFrame("debuff")
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
		end,
		order = 37.83
	}

	opts["debuffYOffset"] = {
		type = 'range',
		name = L["Debuff vertical offset"],
		desc = L["How far vertically the debuff frame should be offset from the anchor"],
		min = -500,
		max = 500,
		step = 1,
		get = function()
			return self.moduleSettings.auras["debuff"].offset['y']
		end,
		set = function(info, v)
			self.moduleSettings.auras["debuff"].offset['y'] = v
			self:CreateAuraFrame("debuff")
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.auras["debuff"].show
		end,
		order = 37.84
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

	opts["textHeader"] = {
		type = 'header',
		name = L["Text Settings"],
		order = 39.01
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
	defaults["perRow"] = 10
	defaults["line1Tag"] = "[Name:HostileColor]"
--	defaults["line2Tag"] = "[Level:DifficultyColor] [[IsPlayer ? Race ! CreatureType]:ClassColor] [[IsPlayer ? Class]:ClassColor] [[~PvP ? \"PvE\" ! \"PvP\"]:HostileColor] [IsLeader ? \"Leader\":Yellow] [InCombat ? \"Combat\":Red] [Classification]"
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
			["offset"] = {x=-10,y=0},
			["anchorTo"] = "TOPLEFT",
			["growDirection"] = "Left",
			["filter"] = "Never",
			["show"] = true,
		},
		["debuff"] = {
			["size"] = 20,
			["ownSize"] = 20,
			["offset"] = {x=10,y=0},
			["anchorTo"] = "TOPRIGHT",
			["growDirection"] = "Right",
			["filter"] = "Never",
			["show"] = true,
		}
	}

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
			self.frame.menu = function()
				IceHUD.DropdownUnit = self.unit
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
	local auraFrame
	local point

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
		self.frame[auraFrame].buffs = {}
	end

	self.frame[auraFrame]:ClearAllPoints()
	self.frame[auraFrame]:SetPoint(point, self.frame, self.moduleSettings.auras[aura].anchorTo, self.moduleSettings.auras[aura].offset['x'], self.moduleSettings.auras[aura].offset['y'])

	if (not redraw) then
		local direction = self.moduleSettings.auras[aura].growDirection == "Left" and -1 or 1
		self.frame[auraFrame].buffs = self:CreateIconFrames(self.frame[auraFrame], direction, self.frame[auraFrame].buffs, "buff")
	end

	if self.moduleSettings.auras[aura].show then
		self.frame[auraFrame]:Show()
	else
		self.frame[auraFrame]:Hide()
	end
end

function IceTargetInfo.prototype:CreateIconFrames(parent, direction, buffs, type, skipSize)
	local lastX = 0
	local lastBuffSize = 0

	if not self.MyOnEnterBuffFunc then
		self.MyOnEnterBuffFunc = function(this) self:BuffOnEnter(this) end
	end
	if not self.MyOnLeaveBuffFunc then
		self.MyOnLeaveBuffFunc = function() GameTooltip:Hide() end
	end

	for i = 1, IceCore.BuffLimit do
		if (not buffs[i]) then
			buffs[i] = CreateFrame("Frame", nil, parent)
			buffs[i].icon = CreateFrame("Frame", nil, buffs[i])
			buffs[i].cd = CreateFrame("Cooldown", nil, buffs[i], "CooldownFrameTemplate")

			buffs[i]:SetFrameStrata("BACKGROUND")
			buffs[i].icon:SetFrameStrata("BACKGROUND")

			buffs[i].cd:SetFrameStrata("BACKGROUND")
			buffs[i].cd:SetFrameLevel(buffs[i].icon:GetFrameLevel()+1)
			buffs[i].cd:SetReverse(true)
			buffs[i].cd:ClearAllPoints()
			buffs[i].cd:SetAllPoints(buffs[i])

			buffs[i].icon:ClearAllPoints()
			buffs[i].icon:SetPoint("CENTER", 0, 0)
		end

		if buffs[i].fromPlayer then
			buffs[i]:SetWidth(self.moduleSettings.auras["buff"].ownSize)
			buffs[i]:SetHeight(self.moduleSettings.auras["buff"].ownSize)
		else
			buffs[i]:SetWidth(self.moduleSettings.auras["buff"].size)
			buffs[i]:SetHeight(self.moduleSettings.auras["buff"].size)
		end

		if not skipSize then
			if buffs[i].fromPlayer then
				buffs[i].icon:SetWidth(self.moduleSettings.auras["buff"].ownSize-2)
				buffs[i].icon:SetHeight(self.moduleSettings.auras["buff"].ownSize-2)
			else
				buffs[i].icon:SetWidth(self.moduleSettings.auras["buff"].size-2)
				buffs[i].icon:SetHeight(self.moduleSettings.auras["buff"].size-2)
			end
		end


		local buffSize = self.moduleSettings.auras["buff"].size
		if buffs[i].fromPlayer then
			buffSize = self.moduleSettings.auras["buff"].ownSize
		end

		local pos = i % self.moduleSettings.perRow
		if pos == 1 or self.moduleSettings.perRow == 1 then
			lastX = 0
			lastBuffSize = 0
		end

		local spaceOffset = ((pos == 1 or self.moduleSettings.perRow == 1) and 0 or self.moduleSettings.spaceBetweenBuffs)
		if direction < 0 then
			spaceOffset = spaceOffset * -1
		end

		local x = lastX + lastBuffSize + spaceOffset
		lastX = x
		lastBuffSize = (buffSize * direction)
		local y = math.floor((i-1) / self.moduleSettings.perRow) * math.max(self.moduleSettings.auras["buff"].size, self.moduleSettings.auras["buff"].ownSize) * -1

		buffs[i]:ClearAllPoints()
		if direction < 0 then
			buffs[i]:SetPoint("TOPRIGHT", x, y)
		else
			buffs[i]:SetPoint("TOPLEFT", x, y)
		end

		if not buffs[i].texture then
			buffs[i].texture = buffs[i]:CreateTexture()
			buffs[i].texture:ClearAllPoints()
			buffs[i].texture:SetAllPoints(buffs[i])

			buffs[i].icon.texture = buffs[i].icon:CreateTexture()
			buffs[i].icon.texture:SetTexture(nil)

			buffs[i].icon.texture:ClearAllPoints()
			buffs[i].icon.texture:SetAllPoints(buffs[i].icon)
		end

		buffs[i].icon.stack = self:FontFactory(self.moduleSettings.stackFontSize, buffs[i].icon, buffs[i].icon.stack,
			"OUTLINE")

		buffs[i].icon.stack:ClearAllPoints()
		buffs[i].icon.stack:SetPoint("BOTTOMRIGHT" , buffs[i].icon, "BOTTOMRIGHT", 3, -1)


		buffs[i].id = i
		if (self.moduleSettings.mouseBuff) then
			buffs[i]:EnableMouse(true)
			buffs[i]:SetScript("OnEnter", self.MyOnEnterBuffFunc)
			buffs[i]:SetScript("OnLeave", self.MyOnLeaveBuffFunc)
		else
			buffs[i]:EnableMouse(false)
			buffs[i]:SetScript("OnEnter", nil)
			buffs[i]:SetScript("OnLeave", nil)
		end
	end

	return buffs
end

function IceTargetInfo.prototype:UpdateBuffType(aura)
	local auraFrame, reaction
	local filter = false

	if (aura == "buff") then
		auraFrame = "buffFrame"
		reaction = "HELPFUL"
	elseif (aura == "debuff") then
		auraFrame = "debuffFrame"
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

			if (icon) then
				self:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable)
			else
				self.frame[auraFrame].buffs[i]:Hide()
			end
		end
	end

	local direction = self.moduleSettings.auras[aura].growDirection == "Left" and -1 or 1
	self.frame[auraFrame].buffs = self:CreateIconFrames(self.frame[auraFrame], direction, self.frame[auraFrame].buffs, aura, true)
end

function IceTargetInfo.prototype:SetupAura(aura, i, icon, duration, expirationTime, isFromMe, count, isStealable, auraType)
	local hostile = UnitCanAttack("player", self.unit)
	local zoom = self.moduleSettings.zoom
	local auraFrame = aura.."Frame"

	if aura == "buff" then
		if isStealable and self.playerClass == "MAGE" then
			self.frame[auraFrame].buffs[i].texture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
			if isFromMe then
				self.frame[auraFrame].buffs[i].icon:SetWidth(self.moduleSettings.auras[aura].ownSize-8)
				self.frame[auraFrame].buffs[i].icon:SetHeight(self.moduleSettings.auras[aura].ownSize-8)
			else
				self.frame[auraFrame].buffs[i].icon:SetWidth(self.moduleSettings.auras[aura].size-8)
				self.frame[auraFrame].buffs[i].icon:SetHeight(self.moduleSettings.auras[aura].size-8)
			end
		else
			local alpha = icon and 0.5 or 0
			self.frame[auraFrame].buffs[i].texture:SetTexture(0, 0, 0, alpha)
			if isFromMe then
				self.frame[auraFrame].buffs[i].icon:SetWidth(self.moduleSettings.auras[aura].ownSize-2)
				self.frame[auraFrame].buffs[i].icon:SetHeight(self.moduleSettings.auras[aura].ownSize-2)
			else
				self.frame[auraFrame].buffs[i].icon:SetWidth(self.moduleSettings.auras[aura].size-2)
				self.frame[auraFrame].buffs[i].icon:SetHeight(self.moduleSettings.auras[aura].size-2)
			end
		end
	elseif aura == "debuff" and (not hostile or not filter or (filter and duration)) then
		local alpha = icon and 1 or 0
		self.frame[auraFrame].buffs[i].texture:SetTexture(1, 1, 1, alpha)

		local color = debuffType and DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
		self.frame[auraFrame].buffs[i].texture:SetVertexColor(color.r, color.g, color.b)
	end

	-- cooldown frame
	if (duration and duration > 0 and expirationTime and expirationTime > 0) then
		local start = expirationTime - duration

		self.frame[auraFrame].buffs[i].cd:SetCooldown(start, duration)
		self.frame[auraFrame].buffs[i].cd:Show()
	else
		self.frame[auraFrame].buffs[i].cd:Hide()
	end

	self.frame[auraFrame].buffs[i].type = auraType or aura
	self.frame[auraFrame].buffs[i].fromPlayer = isFromMe

	self.frame[auraFrame].buffs[i].icon.texture:SetTexture(icon)
	self.frame[auraFrame].buffs[i].icon.texture:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)
	self.frame[auraFrame].buffs[i].icon.stack:SetText((count and (count > 1)) and count or nil)

	self.frame[auraFrame].buffs[i]:Show()
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
	if not (UnitExists(self.unit)) then
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


		self.leader = UnitIsPartyLeader(self.unit) and " |cffcccc11Leader|r" or ""
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
		self.tapped = UnitIsTapped(self.unit) and (not UnitIsTappedByPlayer(self.unit))
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


function IceTargetInfo.prototype:OnEnter(frame)
	UnitFrame_OnEnter(frame)
	self.frame.highLight:Show()
end


function IceTargetInfo.prototype:OnLeave(frame)
	UnitFrame_OnLeave(frame)
	self.frame.highLight:Hide()
end


function IceTargetInfo.prototype:BuffOnEnter(this)
	if (not self:IsVisible()) then
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
