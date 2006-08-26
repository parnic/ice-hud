local AceOO = AceLibrary("AceOO-2.0")

local TargetInfo = AceOO.Class(IceElement)


TargetInfo.Width = 260
TargetInfo.prototype.buffSize = nil

-- Constructor --
function TargetInfo.prototype:init()
	TargetInfo.super.prototype.init(self, "TargetInfo")
	
	self.buffSize = math.floor((TargetInfo.Width - 15) / 16)
	
	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------


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

	return opts
end


-- OVERRIDE
function TargetInfo.prototype:GetDefaultSettings()
	local defaults =  TargetInfo.super.prototype.GetDefaultSettings(self)
	defaults["fontSize"] = 13
	defaults["vpos"] = -50
	return defaults
end


-- OVERRIDE
function TargetInfo.prototype:Redraw()
	TargetInfo.super.prototype.Redraw(self)

	self:CreateFrame()
end


function TargetInfo.prototype:Enable(core)
	TargetInfo.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	self:RegisterEvent("UNIT_AURA", "AuraChanged")
	
	self:RegisterEvent("UNIT_FACTION", "InfoTextChanged")
	self:RegisterEvent("UNIT_LEVEL", "InfoTextChanged")
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", "InfoTextChanged")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "InfoTextChanged")
	self:RegisterEvent("UNIT_DYNAMIC_FLAGS", "InfoTextChanged")
	
	self:RegisterEvent("RAID_TARGET_UPDATE", "RaidIconChanged")
end



-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function TargetInfo.prototype:CreateFrame()
	TargetInfo.super.prototype.CreateFrame(self)
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(TargetInfo.Width)
	self.frame:SetHeight(42)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", 0, self.moduleSettings.vpos)
	self.frame:SetScale(self.moduleSettings.scale)
	
	self.frame:Show()
	
	self:CreateTextFrame()
	self:CreateInfoTextFrame()
	self:CreateBuffFrame()
	self:CreateDebuffFrame()
	self:CreateRaidIconFrame()
end


function TargetInfo.prototype:CreateTextFrame()
	self.frame.targetName = self:FontFactory("Bold", self.moduleSettings.fontSize+1, nil, self.frame.targetName)
	
	self.frame.targetName:SetWidth(TargetInfo.Width - 120)
	self.frame.targetName:SetHeight(14)
	self.frame.targetName:SetJustifyH("LEFT")
	self.frame.targetName:SetJustifyV("BOTTOM")
	
	self.frame.targetName:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -2)
	self.frame.targetName:Show()
end


function TargetInfo.prototype:CreateInfoTextFrame()
	self.frame.targetInfo = self:FontFactory(nil, self.moduleSettings.fontSize, nil, self.frame.targetInfo)
	
	self.frame.targetInfo:SetWidth(TargetInfo.Width)
	self.frame.targetInfo:SetHeight(14)
	self.frame.targetInfo:SetJustifyH("LEFT")
	self.frame.targetInfo:SetJustifyV("TOP")
	
	self.frame.targetInfo:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -16)
	self.frame.targetInfo:Show()
end


function TargetInfo.prototype:CreateRaidIconFrame()
	if (self.frame.raidIcon) then
		return
	end

	self.frame.raidIcon = self.frame:CreateTexture(nil, "BACKGROUND")
	
	self.frame.raidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	self.frame.raidIcon:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -5, -5)
	self.frame.raidIcon:SetWidth(16)
	self.frame.raidIcon:SetHeight(16)
	SetRaidTargetIconTexture(self.frame.raidIcon, 0)
	self.frame:Hide()
end


function TargetInfo.prototype:CreateBuffFrame()
	if (self.frame.buffFrame) then
		return
	end

	self.frame.buffFrame = CreateFrame("Frame", nil, self.frame)
	
	self.frame.buffFrame:SetFrameStrata("BACKGROUND")
	self.frame.buffFrame:SetWidth(TargetInfo.Width)
	self.frame.buffFrame:SetHeight(20)
	
	self.frame.buffFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -32)
	self.frame.buffFrame:Show()
		
	self.frame.buffFrame.buffs = self:CreateIconFrames(self.frame.buffFrame)
end


function TargetInfo.prototype:CreateDebuffFrame()
	if (self.frame.debuffFrame) then
		return
	end
	
	self.frame.debuffFrame = CreateFrame("Frame", nil, self.frame)
	
	self.frame.debuffFrame:SetFrameStrata("BACKGROUND")
	self.frame.debuffFrame:SetWidth(TargetInfo.Width)
	self.frame.debuffFrame:SetHeight(20)
	
	self.frame.debuffFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -34 - self.buffSize)
	self.frame.debuffFrame:Show()
		
	self.frame.debuffFrame.buffs = self:CreateIconFrames(self.frame.debuffFrame)
end



function TargetInfo.prototype:CreateIconFrames(parent)
	local buffs = {}
	
	for i = 1, 16 do
		buffs[i] = CreateFrame("Frame", nil, parent)
		buffs[i]:SetFrameStrata("BACKGROUND")
		buffs[i]:SetWidth(self.buffSize)
		buffs[i]:SetHeight(self.buffSize)
		buffs[i]:SetPoint("LEFT", (i-1) * self.buffSize + (i-1), 0)
		buffs[i]:Show()
		
		buffs[i].texture = buffs[i]:CreateTexture()
		buffs[i].texture:SetTexture(nil)
		buffs[i].texture:SetAllPoints(buffs[i])
		
		buffs[i].stack = self:FontFactory("Bold", 15, buffs[i])
		buffs[i].stack:SetPoint("BOTTOMRIGHT" , buffs[i], "BOTTOMRIGHT", 0, -1)
	end
	return buffs
end


function TargetInfo.prototype:UpdateBuffs()
	for i = 1, 16 do
		local buffTexture, buffApplications = UnitBuff("target", i)
		
		self.frame.buffFrame.buffs[i].texture:SetTexture(buffTexture)
		
		if (buffApplications and (buffApplications > 1)) then
			self.frame.buffFrame.buffs[i].stack:SetText(buffApplications)
		else
			self.frame.buffFrame.buffs[i].stack:SetText(nil)
		end
	end
	
	for i = 1, 16 do
		local buffTexture, buffApplications = UnitDebuff("target", i)
		
		self.frame.debuffFrame.buffs[i].texture:SetTexture(buffTexture)
		
		if (buffApplications and (buffApplications > 1)) then
			self.frame.debuffFrame.buffs[i].stack:SetText(buffApplications)
		else
			self.frame.debuffFrame.buffs[i].stack:SetText(nil)
		end
	end
end



function TargetInfo.prototype:InfoTextChanged(unit)
	if (unit == "target") then
		self.frame.targetInfo:SetText(self:GetInfoString())
	end
end


function TargetInfo.prototype:AuraChanged(unit)
	if (unit == "target") then
		self:UpdateBuffs()
	end
end


function TargetInfo.prototype:RaidIconChanged(unit)
	if (unit == "target") then
		self:UpdateRaidTargetIcon()
	end
end


function TargetInfo.prototype:UpdateRaidTargetIcon()
	if not (UnitExists("target")) then
		self.frame.raidIcon:Hide()
		return
	end

	local index = GetRaidTargetIndex("target");
	if (index and (index > 0)) then
		SetRaidTargetIconTexture(self.frame.raidIcon, index)
		self.frame.raidIcon:Show()
	else
		self.frame.raidIcon:Hide()
	end
end


function TargetInfo.prototype:TargetChanged()
	local name = UnitName("target")
	local _, unitClass = UnitClass("target")

	self.frame.targetName:SetTextColor(self:GetColor(unitClass, 1))
	self.frame.targetName:SetText(name)
	self.frame.targetInfo:SetText(self:GetInfoString())
	self:UpdateBuffs()
	self:UpdateRaidTargetIcon()
end


function TargetInfo.prototype:GetInfoString()
	local u = "target"
	
	if not (UnitExists(u)) then
		return ""
	end
	
	local class, unitClass = UnitClass(u)
	local creatureType = UnitCreatureType(u)
	local classification = UnitClassification(u)
	local level = UnitLevel(u)
	
	local isPlayer = UnitIsPlayer(u)
	
	local classColor = self:GetHexColor(unitClass)
	
	local sLevel = "[??] "
	if (level > 0) then
		sLevel = "[L" .. level
		if (UnitIsPlusMob(u)) then
			sLevel = sLevel .. "+"
		end
		sLevel = sLevel .. "] "
	end
	
	local sClass = ""
	if (class and isPlayer) then
		sClass = "|c" .. classColor ..  class .. "|r "
	elseif (creatureType) then
		sClass = creatureType .. " "
	end
	
	local sPVP = ""
	if (isPlayer) then
		if (UnitIsPVP(u)) then
			local color = "ff10ff10" -- friendly
			if (UnitFactionGroup("target") ~= UnitFactionGroup("player")) then
				color = "ffff1010"
			end
			sPVP = "|c" .. color .. "[PvP]|r "
		else
			sPVP = "|cff1010ff[PvE]|r "
		end
	end
	
	local sClassification = ""
	if (classification == "rare" or classification == "rareelite") then
		sClassification = "[Rare] "
	end
	if (classification == "worldboss") then
		sClassification = "[World Boss] "
	end

	local sLeader = ""
	if (UnitIsPartyLeader(u)) then
		sLeader = "[Leader] "
	end
	
	local sCombat = ""
	--if (UnitAffectingCombat(u)) then
	--	sCombat = " +Combat+"
	--end
	
	return string.format("%s%s%s%s%s%s",
		sLevel, sClass, sPVP, sClassification, sLeader, sCombat)
end



-- Load us up
TargetInfo:new()
