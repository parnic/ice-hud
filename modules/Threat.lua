local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
--[[
Name: IceThreat
Author: Caryna/Turalyon EU (Alliance) (updated for Threat-2.0 by 'acapela' of WoWI and merged into IceHUD by Parnic)
Description: adds a threat bar to IceHUD
]]

IceThreat = IceCore_CreateClass(IceUnitBar)

local IceHUD = _G.IceHUD

IceThreat.prototype.color = nil
IceThreat.aggroBar = nil
IceThreat.aggroBarMulti = nil
IceThreat.prototype.scheduledEvent = nil

local GetNumPartyMembers, GetNumRaidMembers = GetNumPartyMembers, GetNumRaidMembers
local MAX_NUM_RAID_MEMBERS, MAX_NUM_PARTY_MEMBERS = MAX_NUM_RAID_MEMBERS, MAX_NUM_PARTY_MEMBERS
if IceHUD.WowVer >= 50000 then
	GetNumPartyMembers = GetNumGroupMembers
	GetNumRaidMembers = GetNumGroupMembers
	MAX_NUM_PARTY_MEMBERS = MAX_PARTY_MEMBERS
	MAX_NUM_RAID_MEMBERS = MAX_RAID_MEMBERS
end

local MAX_NUM_RAID_MEMBERS = 40
local MAX_NUM_PARTY_MEMBERS = 5

-- constructor
function IceThreat.prototype:init(name, unit)
	if not name or not unit then
		IceThreat.super.prototype.init(self, "Threat", "target")
	else
		IceThreat.super.prototype.init(self, name, unit)
	end

	self:SetDefaultColor("ThreatLow", 102, 204, 51)
	self:SetDefaultColor("ThreatMedium", 0, 204, 204)
	self:SetDefaultColor("ThreatHigh", 204, 0, 153)
	self:SetDefaultColor("ThreatDanger", 255, 0, 0)
	self:SetDefaultColor("ThreatCustom", 255, 255, 0)
	self:SetDefaultColor("ThreatPullAggro", 255, 0, 0)
	self:SetDefaultColor("ThreatSecondPlace", 255, 255, 0)

	self.bTreatEmptyAsFull = true
end

-- default settings
function IceThreat.prototype:GetDefaultSettings()
	local settings = IceThreat.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 4
	settings["enabled"] = false
	settings["aggroAlpha"] = 0.7
	settings["usesDogTagStrings"] = false
	settings["onlyShowInGroups"] = true
	settings["showScaledThreat"] = false
	settings["displaySecondPlaceThreat"] = true
	settings["secondPlaceThreatAlpha"] = 0.75
	settings["bAllowExpand"] = false
	settings["showTankName"] = true
	return settings
end

-- options stuff
function IceThreat.prototype:GetOptions()
	local opts = IceThreat.super.prototype.GetOptions(self)

	opts["enabled"] = {
		type = "toggle",
		name = L["Enabled"],
		desc = L["Enable/disable module"],
		get = function()
			return self.moduleSettings.enabled
		end,
		set = function(info, value)
			self.moduleSettings.enabled = value
			if (value) then
				self:Enable(true)
			else
				self:Disable()
			end
		end,
		order = 20
	}

	opts["aggroAlpha"] =
	{
		type = 'range',
		name = L["Aggro Indicator alpha"],
		desc = L["Aggro indicator alpha (0 is disabled)"],
		min = 0,
		max = 1,
		step = 0.1,
		get = function()
			return self.moduleSettings.aggroAlpha
		end,
		set = function(info, value)
			self.moduleSettings.aggroAlpha = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.5
	}

	opts["onlyShowInGroups"] = {
		type = 'toggle',
		name = L["Only show in groups"],
		desc = L["Only show the threat bar if you are in a group or you have an active pet"],
		get = function()
			return self.moduleSettings.onlyShowInGroups
		end,
		set = function(info, v)
			self.moduleSettings.onlyShowInGroups = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.6
	}

	opts["showScaledThreat"] = {
		type = 'toggle',
		name = L["Show scaled threat"],
		desc = L["Whether to show threat in scaled values or raw values. Scaled threat means that you will pull aggro when it hits 100%. Raw threat means you will pull aggro at either 110% (melee) or 130% (ranged). Omen uses raw threat which can cause this mod to disagree with Omen if it is in scaled mode."],
		get = function()
			return self.moduleSettings.showScaledThreat
		end,
		set = function(info, v)
			self.moduleSettings.showScaledThreat = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.7
	}

	opts["displaySecondPlaceThreat"] = {
		type = 'toggle',
		name = L["Show second highest threat"],
		desc = L["When tanking, this toggles whether or not the second-highest threat value found in your party or raid is displayed on top of your actual threat value"],
		width = 'double',
		get = function()
			return self.moduleSettings.displaySecondPlaceThreat
		end,
		set = function(info, v)
			self.moduleSettings.displaySecondPlaceThreat = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.8
	}

	opts["secondPlaceThreatAlpha"] = {
		type = 'range',
		name = L["Second place threat alpha"],
		desc = L["The alpha value for the second-place threat bar to be (this is multiplied by the bar's alpha so it's always proportionate)"],
		get = function()
			return self.moduleSettings.secondPlaceThreatAlpha
		end,
		set = function(info, v)
			self.moduleSettings.secondPlaceThreatAlpha = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		min = 0,
		max = 1,
		step = 0.05,
		order = 27.9
	}

	opts["showTankName"] = {
		type = 'toggle',
		name = L["Show tank name"],
		desc = L["Shows the name of the threat holder colorized by his or her role"],
		get = function()
			return self.moduleSettings.showTankName
		end,
		set = function(info, v)
			self.moduleSettings.showTankName = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 29.1,
	}

	return opts
end

-- enable plugin
function IceThreat.prototype:Enable(core)
	IceThreat.super.prototype.Enable(self, core)

	self.scheduledEvent = self:ScheduleRepeatingTimer("Update", 0.2)

	self:SetScale(0, true, true)
	self:Update(self.unit)
end

-- disable plugin
function IceThreat.prototype:Disable(core)
	IceThreat.super.prototype.Disable(self, core)

	self:CancelTimer(self.scheduledEvent, true)
end

-- OVERRIDE
function IceThreat.prototype:CreateFrame()
	IceThreat.super.prototype.CreateFrame(self)

	self:CreateAggroBar()
	self:CreateSecondThreatBar()
end

-- create the aggro range indicator bar
function IceThreat.prototype:CreateAggroBar()
	self.aggroBar = self:BarFactory(self.aggroBar, "BACKGROUND","ARTWORK")

	local r, g, b = self:GetColor("ThreatPullAggro")
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor("CastCasting")
	end
	self.aggroBar.bar:SetVertexColor(r, g, b, self.moduleSettings.aggroAlpha)

	self:SetBarCoord(self.aggroBar, 0 , true)
end

function IceThreat.prototype:CreateSecondThreatBar()
	self.secondThreatBar = self:BarFactory(self.secondThreatBar, "MEDIUM", "OVERLAY")

	self.secondThreatBar.bar:SetVertexColor(self:GetColor("ThreatSecondPlace", self.alpha * self.moduleSettings.secondPlaceThreatAlpha))

	self:SetBarCoord(self.secondThreatBar)
end

-- bar stuff
function IceThreat.prototype:Update(unit)
	IceThreat.super.prototype.Update(self)

	if (unit and (unit ~= self.unit)) then
		return
	end

	if IceHUD.IceCore:IsInConfigMode() then
		return
	end

	if not unit then
		unit = self.unit
	end

	local isInGroup = GetNumPartyMembers() > 0
	if self.moduleSettings.onlyShowInGroups and (not isInGroup and not UnitExists("pet")) then
		self:Show(false)
		return
	end

	if not UnitExists(self.unit) or not UnitCanAttack("player", self.unit) or UnitIsDead(self.unit)
		or UnitIsFriend("player", self.unit) or UnitPlayerControlled(self.unit) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	local isTanking, threatState, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", self.unit)
	local tankThreat = 0
	local secondHighestThreat = 0
	local rangeMulti = 1.1
	local scaledPercentZeroToOne
	local _
--[[
threatState = 1
scaledPercent = 1
rawPercent = 1
scaledPercentZeroToOne = 1
isTanking = 1
tankThreat = 100
threatValue = 100
]]
	if not isTanking then
		_, _, _, _, tankThreat = UnitDetailedThreatSituation("targettarget", self.unit) -- highest threat target of target (i.e. the tank)
	elseif self.moduleSettings.displaySecondPlaceThreat then
		secondHighestThreat = self:GetSecondHighestThreat()
	end
--secondHighestThreat = 75
	if threatValue and threatValue < 0 then
		threatValue = threatValue + 410065408 -- the corrected threat while under MI or Fade
		if isTanking then
			tankThreat = threatValue
		end

		if threatValue and tankThreat then -- Corrects rawPercent and scaledPercent while under MI or Fade
			rawPercent = ((threatValue / tankThreat) * 100)

			if GetItemInfo(37727) then -- 5 yards for melee range (Ruby Acorn - http://www.wowhead.com/?item=37727)
				rangeMulti = tankThreat * (IsItemInRange(37727, "target") == 1 and 1.1 or 1.3)
			else -- 9 yards compromise
				rangeMulti = tankThreat * (CheckInteractDistance("target", 3) and 1.1 or 1.3)
			end
			scaledPercent = ((threatValue / rangeMulti) * 100)
		end
	end

	if not self.combat and (scaledPercent == 0 or rawPercent == 0) then
		self:Show(false)
		return
	end

	if not rawPercent then
		rawPercent = 0
	end

	if rawPercent < 0 then
		rawPercent = 0
	elseif isTanking then
		rawPercent = 100
		scaledPercent = 100
	end

	if not threatState or not scaledPercent or not rawPercent then
		scaledPercentZeroToOne = 0
		scaledPercent = 0

		--IceHUD:Debug( "Threat: nil threat on valid target" )
	else
		if self.moduleSettings.showScaledThreat then
			scaledPercentZeroToOne = scaledPercent / 100
		else
			scaledPercentZeroToOne = rawPercent / 100
		end

		IceHUD:Debug( "isTanking="..(tostring(isTanking) or "nil").." threatState="..(tostring(threatState) or "nil").." scaledPercent="..(tostring(scaledPercent) or "nil").." rawPercent="..(tostring(rawPercent) or "nil").." threatValue="..(tostring(threatValue) or "nil").." secondhighest="..(tostring(secondHighestThreat) or "nil"))
	end

	-- set percentage text
	self:SetBottomText1( IceHUD:MathRound(self.moduleSettings.showScaledThreat and scaledPercent or rawPercent) .. "%" )
	if not self.moduleSettings.showTankName or isTanking then
		-- nothing if we are the target
		self:SetBottomText2()
	else
		-- display the name of the current threat holder
		local name = select(1, UnitName("targettarget"))
		local color
		if UnitGroupRolesAssigned("targettarget") == "TANK" or GetPartyAssignment("MAINTANK", "targettarget") then
			color = "ThreatLow"
		elseif GetPartyAssignment("MAINASSIST", "targettarget") then
			color = "ThreatMedium"
		else
			color = "ThreatHigh"
		end
		self:SetBottomText2(name, color)
	end

	if ( isTanking ) then
		rangeMulti = 1
	end

	-- Parnic: this should probably be switched to use the new api colors for threat...
	-- set bar color
	if( isTanking == 1 ) then
		self.color = "ThreatDanger"
	elseif( scaledPercent < 50 ) then
		self.color = "ThreatLow"
	elseif ( scaledPercent < 80 ) then
		self.color = "ThreatMedium"
	else
		self.color = "ThreatHigh"
	end

	-- set the bar value
	self:UpdateBar( scaledPercentZeroToOne, self.color )

	-- do the aggro indicator bar stuff, but only if it has changed
	if ( self.aggroBarMulti ~= rangeMulti ) then
		self.aggroBarMulti = rangeMulti

		local pos = IceHUD:Clamp(1 - (1 / rangeMulti), 0, 1)
		self:SetBarCoord(self.aggroBar, pos, true)
	end

	self:UpdateAlpha()
	self:UpdateSecondHighestThreatBar(secondHighestThreat, threatValue)
end

function IceThreat.prototype:UpdateSecondHighestThreatBar(secondHighestThreat, threatValue)
	if secondHighestThreat <= 0 or not threatValue or threatValue == 0 then
		self.secondThreatBar:Hide()
	else
		local secondPercent = secondHighestThreat / threatValue
		if not self.lastSecondHighestThreat or self.lastSecondHighestThreat ~= secondPercent then
			self.lastSecondHighestThreat = secondPercent

			self.secondThreatBar.bar:SetVertexColor(self:GetColor("ThreatSecondPlace", self.alpha * self.moduleSettings.secondPlaceThreatAlpha))

			local pos = IceHUD:Clamp(secondPercent, 0, 1)
			if self.moduleSettings.reverse then
				pos = 1-pos
			end

			self:SetBarCoord(self.secondThreatBar, pos)
			self.secondThreatBar:Show()
		end
	end
end

function IceThreat.prototype:GetSecondHighestThreat()
	local secondHighestThreat = 0
	local i = 1
	local numFound = 0
	local numMembers = 0

	if UnitInRaid("player") then
		numMembers = GetNumRaidMembers()

		while numFound < numMembers and i <= MAX_NUM_RAID_MEMBERS do
			if UnitExists("raid"..i) and not UnitIsUnit("player", "raid"..i) then
				numFound = numFound + 1
				local _, _, _, _, temp = UnitDetailedThreatSituation("raid"..i, self.unit)
				if temp ~= nil and temp > secondHighestThreat then
					secondHighestThreat = temp
				end
			end

			i = i + 1
		end
	else
		numMembers = GetNumPartyMembers()

		while numFound < numMembers and i <= MAX_NUM_PARTY_MEMBERS do
			if UnitExists("party"..i) and not UnitIsUnit("player", "party"..i) then
				numFound = numFound + 1
				local _, _, _, _, temp = UnitDetailedThreatSituation("party"..i, self.unit)
				if temp ~= nil and temp > secondHighestThreat then
					secondHighestThreat = temp
				end
			end

			i = i + 1
		end
	end

	if UnitExists("pet") then
		local _, _, _, _, temp = UnitDetailedThreatSituation("pet", self.unit)
		if temp ~= nil and temp > secondHighestThreat then
			secondHighestThreat = temp
		end
	end

	return secondHighestThreat
end

function IceThreat.prototype:Show(bShouldShow)
	IceThreat.super.prototype.Show(self, bShouldShow)
	if not bShouldShow then
		self:SetScale(0, true, true)
	end
end

-- Load us up
IceHUD.IceThreat = IceThreat:new()
