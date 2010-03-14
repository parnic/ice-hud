--[[
Name: IceThreat
Version: 1.2
Author: Caryna/Turalyon EU (Alliance) (updated for Threat-2.0 by 'acapela' of WoWI and merged into IceHUD by Parnic)
Description: adds a threat bar to IceHUD
]]

local AceOO = AceLibrary("AceOO-2.0")

IceThreat = AceOO.Class(IceUnitBar)

IceThreat.prototype.color = nil
IceThreat.aggroBar = nil
IceThreat.aggroBarMulti = nil

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

	self:OnCoreLoad()
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
	return settings
end

-- options stuff
function IceThreat.prototype:GetOptions()
	local opts = IceThreat.super.prototype.GetOptions(self)

	opts["enabled"] = {
		type = "toggle",
		name = "|c" .. self.configColor .. "Enabled|r",
		desc = "Enable/disable module (requires Threat-2.0 library)",
		get = function()
			return self.moduleSettings.enabled
		end,
		set = function(value)
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
		name = 'Aggro Indicator alpha',
		desc = 'Aggro indicator alpha (0 is disabled)',
		min = 0,
		max = 1,
		step = 0.1,
		get = function()
			return self.moduleSettings.aggroAlpha
		end,
		set = function(value)
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
		name = 'Only show in groups',
		desc = 'Only show the threat bar if you are in a group or you have an active pet',
		get = function()
			return self.moduleSettings.onlyShowInGroups
		end,
		set = function(v)
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
		name = 'Show scaled threat',
		desc = 'Whether to show threat in scaled values or raw values. Scaled threat means that you will pull aggro when it hits 100%. Raw threat means you will pull aggro at either 110% (melee) or 130% (ranged). Omen uses raw threat which can cause this mod to disagree with Omen if it is in scaled mode.',
		get = function()
			return self.moduleSettings.showScaledThreat
		end,
		set = function(v)
			self.moduleSettings.showScaledThreat = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.7
	}

	return opts
end

-- enable plugin
function IceThreat.prototype:Enable(core)
	IceThreat.super.prototype.Enable(self, core)

	self:ScheduleRepeatingEvent(self.elementName, self.Update, 0.2, self)

	self:Update(self.unit)
end

-- disable plugin
function IceThreat.prototype:Disable(core)
	IceThreat.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function IceThreat.prototype:CreateFrame()
	IceThreat.super.prototype.CreateFrame(self)
	
	self:CreateAggroBar()
end

-- needs to be inverted for threat bar
function IceThreat.prototype:UseTargetAlpha(scale)
	return (scale and (scale > 0))
end

-- create the aggro range indicator bar
function IceThreat.prototype:CreateAggroBar()
	if not (self.aggroBar) then
		self.aggroBar = CreateFrame("StatusBar", nil, self.frame)
	end
	
	self.aggroBar:SetFrameStrata("BACKGROUND")
	self.aggroBar:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.aggroBar:SetHeight(self.settings.barHeight)
	
	if not (self.aggroBar.bar) then
		self.aggroBar.bar = self.aggroBar:CreateTexture(nil, "BACKGROUND")
	end
	
	self.aggroBar.bar:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture() .. "BG")
	self.aggroBar.bar:SetAllPoints(self.aggroBar)
	
	self.aggroBar:SetStatusBarTexture(self.aggroBar.bar)
	
	local r, g, b = self:GetColor("ThreatPullAggro")
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor("CastCasting")
	end
	self.aggroBar:SetStatusBarColor(r, g, b, self.moduleSettings.aggroAlpha)
	
	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.aggroBar.bar:SetTexCoord(1, 0, 0, 0)
	else
		self.aggroBar.bar:SetTexCoord(0, 1, 0, 0)
	end
	
	self.aggroBar:ClearAllPoints()
	self.aggroBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
end

-- bar stuff
function IceThreat.prototype:Update(unit)
	IceThreat.super.prototype.Update(self)

	if (unit and (unit ~= self.unit)) then
		return
	end

	if not unit then
		unit = self.unit
	end

	if self.moduleSettings.onlyShowInGroups and (GetNumPartyMembers() == 0 and not UnitExists("pet")) then
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
	local _, _, _, _, tankThreat = UnitDetailedThreatSituation("targettarget", self.unit) -- highest threat target of target (i.e. the tank)
	local scaledPercentZeroToOne, rangeMulti -- for melee and caster range threat values (1.1 or 1.3)

	if threatValue and threatValue < 0 then
		threatValue = threatValue + 410065408 -- the corrected threat while under MI or Fade
		if isTanking then
			tankThreat = threatValue
		end
	end	

	if not self.combat and (scaledPercent == 0 or rawPercent == 0) then
		self:Show(false)
		return
	end

	if not rawPercent then
		rawPercent = 0
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

	if rawPercent < 0 then
		rawPercent = 0
	elseif isTanking then
		rawPercent = 100
		scaledPercent = 100
	end

	if not threatState or not scaledPercent or not rawPercent then
		scaledPercentZeroToOne = 0
		scaledPercent = 0

		IceHUD:Debug( "Threat: nil threat on valid target" )
	else
		if self.moduleSettings.showScaledThreat then
			scaledPercentZeroToOne = scaledPercent / 100
		else
			scaledPercentZeroToOne = rawPercent / 100
		end

		IceHUD:Debug( "isTanking="..(isTanking or "nil").." threatState="..(threatState or "nil").." scaledPercent="..(scaledPercent or "nil").." rawPercent="..(rawPercent or "nil") )
	end
	
	-- set percentage text
	self:SetBottomText1( IceHUD:MathRound(self.moduleSettings.showScaledThreat and scaledPercent or rawPercent) .. "%" )
	self:SetBottomText2()

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
		local y = self.settings.barHeight - ( pos * self.settings.barHeight )

		if ( self.moduleSettings.side == IceCore.Side.Left ) then
			self.aggroBar.bar:SetTexCoord(1, 0, 0, pos)
		else
			self.aggroBar.bar:SetTexCoord(0, 1, 0, pos)
		end

		self.aggroBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, y)
	end

	self:UpdateAlpha()
end


-- Load us up
IceHUD.IceThreat = IceThreat:new()
