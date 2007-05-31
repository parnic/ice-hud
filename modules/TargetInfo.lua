local AceOO = AceLibrary("AceOO-2.0")

local TargetInfo = AceOO.Class(IceElement)

local target = "target"
local internal = "internal"

TargetInfo.prototype.buffSize = nil
TargetInfo.prototype.width = nil

TargetInfo.prototype.name = nil
TargetInfo.prototype.guild = nil
TargetInfo.prototype.realm = nil
TargetInfo.prototype.classLocale = nil
TargetInfo.prototype.classEnglish = nil
TargetInfo.prototype.leader = nil

TargetInfo.prototype.combat = nil
TargetInfo.prototype.pvp = nil
TargetInfo.prototype.level = nil
TargetInfo.prototype.classification = nil
TargetInfo.prototype.reaction = nil
TargetInfo.prototype.tapped = nil

TargetInfo.prototype.isPlayer = nil


-- Constructor --
function TargetInfo.prototype:init()
	TargetInfo.super.prototype.init(self, "TargetInfo")
	
	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetInfo.prototype:Enable(core)
	TargetInfo.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	self:RegisterEvent("UNIT_AURA", "AuraChanged")

	self:RegisterEvent("UNIT_FACTION", "TargetFaction")
	self:RegisterEvent("UNIT_LEVEL", "TargetLevel")

	self:RegisterEvent("UNIT_FLAGS", "TargetFlags")
	self:RegisterEvent("UNIT_DYNAMIC_FLAGS", "TargetFlags")

	self:RegisterEvent("RAID_TARGET_UPDATE", "UpdateRaidTargetIcon")
	
	RegisterUnitWatch(self.frame)
end


-- OVERRIDE
function TargetInfo.prototype:Disable(core)
	TargetInfo.super.prototype.Disable(self, core)
	
	UnregisterUnitWatch(self.frame)
end


-- OVERRIDE
function TargetInfo.prototype:GetOptions()
	local opts = TargetInfo.super.prototype.GetOptions(self)

	opts["vpos"] = {
		type = "range",
		name = "Vertical Position",
		desc = "Vertical Position",
		get = function()
			return self.moduleSettings.vpos
		end,
		set = function(v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -300,
		max = 300,
		step = 10,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["fontSize"] = {
		type = 'range',
		name = 'Font Size',
		desc = 'Font Size',
		get = function()
			return self.moduleSettings.fontSize
		end,
		set = function(v)
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
		name = 'Stack Font Size',
		desc = 'Stack Font Size',
		get = function()
			return self.moduleSettings.stackFontSize
		end,
		set = function(v)
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
		name = 'Buff zoom',
		desc = 'Buff/debuff icon zoom',
		get = function()
			return self.moduleSettings.zoom
		end,
		set = function(v)
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
	
	opts["buffSize"] = {
		type = 'range',
		name = 'Buff size',
		desc = 'Buff/debuff icon size',
		get = function()
			return self.moduleSettings.buffSize
		end,
		set = function(v)
			self.moduleSettings.buffSize = v
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
	
	opts["filter"] = {
		type = 'text',
		name = 'Filter buffs/debuffs',
		desc = 'Toggles filtering buffs and debuffs (uses Blizzard default filter code)',
		get = function()
			return self.moduleSettings.filter
		end,
		set = function(v)
			self.moduleSettings.filter = v
			self:RedrawBuffs()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		validate = { "Never", "In Combat", "Always" },
		order = 35
	}
	
	opts["perRow"] = {
		type = 'range',
		name = 'Buffs / row',
		desc = 'How many buffs/debuffs is shown on each row',
		get = function()
			return self.moduleSettings.perRow
		end,
		set = function(v)
			self.moduleSettings.perRow = v
			self:RedrawBuffs()
		end,
		min = 5,
		max = 20,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 36
	}
	
	opts["mouseTarget"] = {
		type = 'toggle',
		name = 'Mouseover for target',
		desc = 'Toggle mouseover on/off for target',
		get = function()
			return self.moduleSettings.mouseTarget
		end,
		set = function(v)
			self.moduleSettings.mouseTarget = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 37
	}
	
	opts["mouseBuff"] = {
		type = 'toggle',
		name = 'Mouseover for buffs',
		desc = 'Toggle mouseover on/off for buffs/debuffs',
		get = function()
			return self.moduleSettings.mouseBuff
		end,
		set = function(v)
			self.moduleSettings.mouseBuff = v
			self:RedrawBuffs()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 38
	}

	return opts
end


-- OVERRIDE
function TargetInfo.prototype:GetDefaultSettings()
	local defaults =  TargetInfo.super.prototype.GetDefaultSettings(self)
	defaults["fontSize"] = 13
	defaults["stackFontSize"] = 11
	defaults["vpos"] = -50
	defaults["zoom"] = 0.08
	defaults["buffSize"] = 20
	defaults["mouseTarget"] = true
	defaults["mouseBuff"] = true
	defaults["filter"] = "Never"
	defaults["perRow"] = 10
	return defaults
end


-- OVERRIDE
function TargetInfo.prototype:Redraw()
	TargetInfo.super.prototype.Redraw(self)

	if (self.moduleSettings.enabled) then
		self:CreateFrame(true)
		self:TargetChanged()
	end
end


function TargetInfo.prototype:RedrawBuffs()
	if (self.moduleSettings.enabled) then
		self:CreateBuffFrame(false)
		self:CreateDebuffFrame(false)
		
		self:TargetChanged()
	end
end



-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function TargetInfo.prototype:CreateFrame(redraw)
	if not (self.frame) then
		self.frame = CreateFrame("Button", "IceHUD_"..self.elementName, self.parent, "SecureUnitButtonTemplate")
	end
	
	self.width = self.settings.gap + 50

	self.frame:SetScale(self.moduleSettings.scale)
	
	-- set showing/hiding the frame depending on current target
	self.frame:SetAttribute("unit", target)

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.width)
	self.frame:SetHeight(32)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", 0, self.moduleSettings.vpos)
	self.frame:SetScale(self.moduleSettings.scale)
	
	if (self.moduleSettings.mouseTarget) then
		self.frame:EnableMouse(true)
		self.frame:RegisterForClicks("AnyUp")
		self.frame:SetScript("OnEnter", function() self:OnEnter() end)
		self.frame:SetScript("OnLeave", function() self:OnLeave() end)
	else
		self.frame:EnableMouse(false)
		self.frame:RegisterForClicks()
		self.frame:SetScript("OnEnter", nil)
		self.frame:SetScript("OnLeave", nil)
	end
	self.frame.unit = target
	
	
	-- set up stuff for clicking
	self.frame:SetAttribute("type1", "target")
	self.frame:SetAttribute("type2", "menu")
	self.frame:SetAttribute("unit", target)

	self.frame.menu = function()
		ToggleDropDownMenu(1, nil, TargetFrameDropDown, "cursor")
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
	self:CreateTextFrame()
	self:CreateInfoTextFrame()
	self:CreateGuildTextFrame()

	self:CreateBuffFrame(redraw)
	self:CreateDebuffFrame(redraw)

	self:CreateRaidIconFrame()
	
	
	-- set up click casting
	ClickCastFrames = ClickCastFrames or {}
	ClickCastFrames[self.frame] = true
end


function TargetInfo.prototype:CreateTextFrame()
	self.frame.targetName = self:FontFactory("Bold", self.moduleSettings.fontSize+1, nil, self.frame.targetName)
	self.frame.targetName:SetJustifyH("CENTER")
	self.frame.targetName:SetJustifyV("TOP")
	self.frame.targetName:SetAllPoints(self.frame)
end


function TargetInfo.prototype:CreateInfoTextFrame()
	self.frame.targetInfo = self:FontFactory(nil, self.moduleSettings.fontSize, nil, self.frame.targetInfo)

	self.frame.targetInfo:SetWidth(self.width)
	self.frame.targetInfo:SetHeight(14)
	self.frame.targetInfo:SetJustifyH("CENTER")
	self.frame.targetInfo:SetJustifyV("TOP")

	self.frame.targetInfo:SetPoint("TOP", self.frame, "TOP", 0, -16)
	self.frame.targetInfo:Show()
end


function TargetInfo.prototype:CreateGuildTextFrame()
	self.frame.targetGuild = self:FontFactory(nil, self.moduleSettings.fontSize, nil, self.frame.targetGuild)

	self.frame.targetInfo:SetWidth(self.width)
	self.frame.targetGuild:SetHeight(14)
	self.frame.targetGuild:SetJustifyH("CENTER")
	self.frame.targetGuild:SetJustifyV("TOP")

	self.frame.targetGuild:SetAlpha(0.6)

	self.frame.targetGuild:SetPoint("TOP", self.frame, "BOTTOM", 0, 0)
	self.frame.targetGuild:Show()
end


function TargetInfo.prototype:CreateRaidIconFrame()
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


function TargetInfo.prototype:CreateBuffFrame(redraw)
	if (not self.frame.buffFrame) then
		self.frame.buffFrame = CreateFrame("Frame", nil, self.frame)

		self.frame.buffFrame:SetFrameStrata("BACKGROUND")
		self.frame.buffFrame:SetWidth(1)
		self.frame.buffFrame:SetHeight(1)
	
		self.frame.buffFrame:ClearAllPoints()
		self.frame.buffFrame:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -10, 0)
		self.frame.buffFrame:Show()

		self.frame.buffFrame.buffs = {}
	end
	
	if (not redraw) then
		self.frame.buffFrame.buffs = self:CreateIconFrames(self.frame.buffFrame, -1, self.frame.buffFrame.buffs, "buff")
	end
end


function TargetInfo.prototype:CreateDebuffFrame(redraw)
	if (not self.frame.debuffFrame) then
		self.frame.debuffFrame = CreateFrame("Frame", nil, self.frame)

		self.frame.debuffFrame:SetFrameStrata("BACKGROUND")
		self.frame.debuffFrame:SetWidth(1)
		self.frame.debuffFrame:SetHeight(1)
	
		self.frame.debuffFrame:ClearAllPoints()
		self.frame.debuffFrame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 10, 0)
		self.frame.debuffFrame:Show()

		self.frame.debuffFrame.buffs = {}
	end
	
	if (not redraw) then
		self.frame.debuffFrame.buffs = self:CreateIconFrames(self.frame.debuffFrame, 1, self.frame.debuffFrame.buffs, "debuff")
	end
end


function TargetInfo.prototype:CreateIconFrames(parent, direction, buffs, type)
	for i = 1, IceCore.BuffLimit do
		if (not buffs[i]) then
			buffs[i] = CreateFrame("Frame", nil, parent)
			buffs[i].icon = CreateFrame("Frame", nil, buffs[i])
			buffs[i].cd = CreateFrame("Cooldown", nil, buffs[i], "CooldownFrameTemplate")
		end

		buffs[i]:SetFrameStrata("BACKGROUND")
		buffs[i]:SetWidth(self.moduleSettings.buffSize)
		buffs[i]:SetHeight(self.moduleSettings.buffSize)
		
		buffs[i].icon:SetFrameStrata("BACKGROUND")
		buffs[i].icon:SetWidth(self.moduleSettings.buffSize-2)
		buffs[i].icon:SetHeight(self.moduleSettings.buffSize-2)
		
		buffs[i].cd:SetFrameStrata("BACKGROUND")
		buffs[i].cd:SetReverse(true)
		buffs[i].cd:ClearAllPoints()
		buffs[i].cd:SetAllPoints(buffs[i])


		local pos = math.fmod(i, self.moduleSettings.perRow)
		if (pos == 0) then
			pos = self.moduleSettings.perRow
		end
		
		local x = (((pos-1) * self.moduleSettings.buffSize) + pos) * direction
		local y = math.floor((i-1) / self.moduleSettings.perRow) * self.moduleSettings.buffSize * -1

		buffs[i]:ClearAllPoints()
		buffs[i]:SetPoint("TOP", x, y)
		
		
		buffs[i].icon:ClearAllPoints()
		buffs[i].icon:SetPoint("CENTER", 0, 0)

		buffs[i]:Show()
		buffs[i].icon:Show()

		if (not buffs[i].texture) then
			buffs[i].texture = buffs[i]:CreateTexture()
			buffs[i].texture:ClearAllPoints()
			buffs[i].texture:SetAllPoints(buffs[i])

			buffs[i].icon.texture = buffs[i].icon:CreateTexture()
			buffs[i].icon.texture:SetTexture(nil)

			buffs[i].icon.texture:ClearAllPoints()
			buffs[i].icon.texture:SetAllPoints(buffs[i].icon)
		end
		
		buffs[i].icon.stack = self:FontFactory("Bold",
			self.moduleSettings.stackFontSize, buffs[i].icon, buffs[i].icon.stack, "OUTLINE")

		buffs[i].icon.stack:ClearAllPoints()
		buffs[i].icon.stack:SetPoint("BOTTOMRIGHT" , buffs[i].icon, "BOTTOMRIGHT", 3, -1)
		
		
		buffs[i].id = i
		if (self.moduleSettings.mouseBuff) then
			buffs[i]:EnableMouse(true)
			buffs[i]:SetScript("OnEnter", function() self:BuffOnEnter(type) end)
			buffs[i]:SetScript("OnLeave", function() GameTooltip:Hide() end)
		else
			buffs[i]:EnableMouse(false)
			buffs[i]:SetScript("OnEnter", nil)
			buffs[i]:SetScript("OnLeave", nil)
		end
	end

	return buffs
end




function TargetInfo.prototype:UpdateBuffs()
	local zoom = self.moduleSettings.zoom
	local filter = false
	
	if (self.moduleSettings.filter == "Always") then
		filter = true
	elseif (self.moduleSettings.filter == "In Combat") then
		if (UnitAffectingCombat("player")) then
			filter = true
		end
	end
	
	local hostile = UnitCanAttack("player", "target")
	

	for i = 1, IceCore.BuffLimit do
		local buffName, buffRank, buffTexture, buffApplications,
			buffDuration, buffTimeLeft = UnitBuff("target", i, filter and not hostile)

		if (buffTexture) then
			self.frame.buffFrame.buffs[i].icon.texture:SetTexture(buffTexture)
			self.frame.buffFrame.buffs[i].icon.texture:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)
			
			local alpha = buffTexture and 0.5 or 0
			self.frame.buffFrame.buffs[i].texture:SetTexture(0, 0, 0, alpha)
			
			-- cooldown frame
			if (buffDuration and buffDuration > 0 and
				buffTimeLeft and buffTimeLeft > 0) then
				local start = GetTime() - buffDuration + buffTimeLeft
				self.frame.buffFrame.buffs[i].cd:SetCooldown(start, buffDuration)
				self.frame.buffFrame.buffs[i].cd:Show()
			else
				self.frame.buffFrame.buffs[i].cd:Hide()
			end

			if (buffApplications and (buffApplications > 1)) then
				self.frame.buffFrame.buffs[i].icon.stack:SetText(buffApplications)
			else
				self.frame.buffFrame.buffs[i].icon.stack:SetText(nil)
			end
		
		
			self.frame.buffFrame.buffs[i]:Show()
		else
			self.frame.buffFrame.buffs[i]:Hide()
		end

	end

	for i = 1, IceCore.BuffLimit do
		local buffName, buffRank, buffTexture, buffApplications, debuffDispelType,
			debuffDuration, debuffTimeLeft = UnitDebuff("target", i, filter and not hostile)

		if (buffTexture and (not hostile or not filter or 
			(filter and debuffDuration and debuffDuration > 0))) then

			local color = debuffDispelType and DebuffTypeColor[debuffDispelType] or DebuffTypeColor["none"]
			local alpha = buffTexture and 1 or 0
			self.frame.debuffFrame.buffs[i].texture:SetTexture(1, 1, 1, alpha)
			self.frame.debuffFrame.buffs[i].texture:SetVertexColor(color.r, color.g, color.b)

			-- cooldown frame
			if (debuffDuration and debuffDuration > 0 and
				debuffTimeLeft and debuffTimeLeft > 0) then
				local start = GetTime() - debuffDuration + debuffTimeLeft
				self.frame.debuffFrame.buffs[i].cd:SetCooldown(start, debuffDuration)
				self.frame.debuffFrame.buffs[i].cd:Show()
			else
				self.frame.debuffFrame.buffs[i].cd:Hide()
			end

			self.frame.debuffFrame.buffs[i].icon.texture:SetTexture(buffTexture)
			self.frame.debuffFrame.buffs[i].icon.texture:SetTexCoord(zoom, 1-zoom, zoom, 1-zoom)

			if (buffApplications and (buffApplications > 1)) then
				self.frame.debuffFrame.buffs[i].icon.stack:SetText(buffApplications)
			else
				self.frame.debuffFrame.buffs[i].icon.stack:SetText(nil)
			end


			self.frame.debuffFrame.buffs[i]:Show()
		else
			self.frame.debuffFrame.buffs[i]:Hide()
		end
	end
end



function TargetInfo.prototype:AuraChanged(unit)
	if (unit == target) then
		self:UpdateBuffs()
	end
end


function TargetInfo.prototype:UpdateRaidTargetIcon()
	if not (UnitExists(target)) then
		self.frame.raidIcon:Hide()
		return
	end

	local index = GetRaidTargetIndex(target);

	if (index and (index > 0)) then
		SetRaidTargetIconTexture(self.frame.raidIcon.icon, index)
		self.frame.raidIcon:Show()
	else
		self.frame.raidIcon:Hide()
	end
end


function TargetInfo.prototype:TargetChanged()
	if (not UnitExists(target)) then
		--self.frame:Hide()
		--self.frame.target:Hide()
		
		self.frame.targetName:SetText()
		self.frame.targetInfo:SetText()
		self.frame.targetGuild:SetText()
		
		self:UpdateBuffs()
		self:UpdateRaidTargetIcon()
		return
	end
	
	--self.frame:Show()
	--self.frame.target:Show()

	self.name, self.realm = UnitName(target)
	self.classLocale, self.classEnglish = UnitClass(target)
	self.isPlayer = UnitIsPlayer(target)
	

	local classification = UnitClassification(target)
	if (string.find(classification, "boss")) then
		self.classification = " |cffcc1111Boss|r"
	elseif(string.find(classification, "rare")) then
		self.classification = " |cffcc11ccRare|r"
	else
		self.classification = ""
	end


	local guildName, guildRankName, guildRankIndex = GetGuildInfo(target);
	self.guild = guildName and "<" .. guildName .. ">" or ""


	if (self.classLocale and self.isPlayer) then
		self.classLocale = "|c" .. self:GetHexColor(self.classEnglish) ..  self.classLocale .. "|r"
	else
		self.classLocale = UnitCreatureType(target)
	end


	self.leader = UnitIsPartyLeader(target) and " |cffcccc11Leader|r" or ""


	-- pass "internal" as a paramater so event handler code doesn't execute
	-- self:Update() unnecassarily
	self:TargetLevel(internal)
	self:TargetReaction(internal)
	self:TargetFaction(internal)
	self:TargetFlags(internal)

	self:UpdateBuffs()
	self:UpdateRaidTargetIcon()

	self:Update(target)
end


function TargetInfo.prototype:TargetLevel(unit)
	if (unit == target or unit == internal) then
		self.level = UnitLevel(target)
		
		local color = GetDifficultyColor((self.level > 0) and self.level or 100)

		if (self.level > 0) then
			if (UnitClassification(target) == "elite") then
				self.level = self.level .. "+"
			end
		else
			self.level = "??"
		end

		self.level = "|c" .. self:ConvertToHex(color) .. self.level .. "|r"

		self:Update(unit)
	end
end


function TargetInfo.prototype:TargetReaction(unit)
	if (unit == target or unit == internal) then
		self.reaction = UnitReaction(target, "player")
		
		-- if we don't get reaction, unit is out of range - has to be friendly
		-- to be targettable (party/raid)
		if (not self.reaction) then
			self.reaction = 5
		end
		self:Update(unit)
	end
end


-- PVP status
function TargetInfo.prototype:TargetFaction(unit)
	if (unit == target or unit == internal) then
		if (self.isPlayer) then
			if (UnitIsPVP(target)) then
				local color = "ff10ff10" -- friendly
				if (UnitFactionGroup(target) ~= UnitFactionGroup("player")) then
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


function TargetInfo.prototype:TargetFlags(unit)
	if (unit == target or unit == internal) then
		self.tapped = UnitIsTapped(target) and (not UnitIsTappedByPlayer(target))
		self.combat = UnitAffectingCombat(target) and " |cffee4030Combat|r" or ""
		self:UpdateBuffs()
		self:Update(unit)
	end
end


function TargetInfo.prototype:Update(unit)
	if (unit ~= target) then
		return
	end

	local reactionColor = self:ConvertToHex(UnitReactionColor[self.reaction])
	if (self.tapped) then
		reactionColor = self:GetHexColor("Tapped")
	end

	local line1 = string.format("|c%s%s|r", reactionColor, self.name or '')
	self.frame.targetName:SetText(line1)

	local line2 = string.format("%s %s%s%s%s%s",
		self.level or '', self.classLocale or '', self.pvp or '', self.leader or '', self.classification or '', self.combat or '')
	self.frame.targetInfo:SetText(line2)

	local realm = self.realm and " " .. self.realm or ""
	local line3 = string.format("%s%s", self.guild or '', realm)
	self.frame.targetGuild:SetText(line3)
end


function TargetInfo.prototype:OnEnter()
	UnitFrame_OnEnter()
	self.frame.highLight:Show()
end


function TargetInfo.prototype:OnLeave()
	UnitFrame_OnLeave()
	self.frame.highLight:Hide()
end


function TargetInfo.prototype:BuffOnEnter(type)
	if (not this:IsVisible()) then
		return
	end

	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	if (type == "buff") then
		GameTooltip:SetUnitBuff(target, this.id)
	else
		GameTooltip:SetUnitDebuff(target, this.id)
	end
end


-- Load us up
IceHUD.TargetInfo = TargetInfo:new()
