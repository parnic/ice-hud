--[[
Name: IHUD_Threat
Version: 1.2
Author: Caryna/Turalyon EU (Alliance) (updated for Threat-2.0 by 'acapela' of WoWI and merged into IceHUD by Parnic)
Description: adds a threat bar to IceHUD
]]

local AceOO = AceLibrary("AceOO-2.0")

local IHUD_Threat = AceOO.Class(IceUnitBar)

IHUD_Threat.prototype.color = nil
IHUD_Threat.aggroBar = nil
IHUD_Threat.aggroBarMulti = nil

-- constructor
function IHUD_Threat.prototype:init()
	IHUD_Threat.super.prototype.init(self, "Threat", "target")

	self:SetDefaultColor("ThreatLow", 102, 204, 51)
	self:SetDefaultColor("ThreatMedium", 0, 204, 204)
	self:SetDefaultColor("ThreatHigh", 204, 0, 153)
	self:SetDefaultColor("ThreatDanger", 255, 0, 0)
	self:SetDefaultColor("ThreatCustom", 255, 255, 0)
	self:SetDefaultColor("ThreatPullAggro", 255, 0, 0)

	self:OnCoreLoad()
end

-- default settings
function IHUD_Threat.prototype:GetDefaultSettings()
	local settings = IHUD_Threat.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3
	settings["enabled"] = false
	settings["aggroAlpha"] = 0.7
	settings["usesDogTagStrings"] = false
	return settings
end

-- options stuff
function IHUD_Threat.prototype:GetOptions()
	local opts = IHUD_Threat.super.prototype.GetOptions(self)

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
		name = 'Aggro Indicator',
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
		order = 21
	}

	return opts
end

-- enable plugin
function IHUD_Threat.prototype:Enable(core)
	IHUD_Threat.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "Update")
	self:ScheduleRepeatingEvent(self.elementName, self.Update, 0.2, self)

	self:Update(self.unit)
end

-- disable plugin
function IHUD_Threat.prototype:Disable(core)
	IHUD_Threat.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function IHUD_Threat.prototype:CreateFrame()
	IHUD_Threat.super.prototype.CreateFrame(self)
	
	self:CreateAggroBar()
end

-- create the aggro range indicator bar
function IHUD_Threat.prototype:CreateAggroBar()
	if not (self.aggroBar) then
		self.aggroBar = CreateFrame("StatusBar", nil, self.frame)
	end
	
	self.aggroBar:SetFrameStrata("BACKGROUND")
	self.aggroBar:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.aggroBar:SetHeight(self.settings.barHeight)
	
	if not (self.aggroBar.bar) then
		self.aggroBar.bar = self.aggroBar:CreateTexture(nil, "BACKGROUND")
	end
	
	self.aggroBar.bar:SetTexture(IceElement.TexturePath .. self.settings.barTexture .. "BG")
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
function IHUD_Threat.prototype:Update(unit)
	IHUD_Threat.super.prototype.Update(self)

	if (unit and (unit ~= self.unit)) then
		return
	end

	if not unit then
		unit = self.unit
	end

	if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") or UnitIsFriend("player", "target") or UnitPlayerControlled("target") then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	local isTanking, threatState, scaledPercent, rawPercent = UnitDetailedThreatSituation("player", "target")
	local scaledPercentZeroToOne

	if not threatState or not scaledPercent or not rawPercent then
		scaledPercentZeroToOne = 0
		scaledPercent = 0

		IceHUD:Debug( "Threat: nil threat on valid target" )
	else
		scaledPercentZeroToOne = scaledPercent / 100

		IceHUD:Debug( "isTanking="..(isTanking or "nil").." threatState="..(threatState or "nil").." scaledPercent="..(scaledPercent or "nil").." rawPercent="..(rawPercent or "nil") )
	end
	
	-- set percentage text
	self:SetBottomText1( IceHUD:MathRound(scaledPercent) .. "%" )
	self:SetBottomText2()

	-- Parnic: threat lib is no longer used in wotlk
	--         ...assuming a 1.1 threat multi if not tanking for the time being unless we decide to switch it back to 1.3/1.1 based on ranged/melee status later
	local threatMulti = 1.1
	if ( isTanking ) then
		threatMulti = 1
	end

	-- Parnic: this should probably be switched to use the new api colors for threat...
	-- set bar color
	if( threatMulti == 1 ) then
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
	if ( self.aggroBarMulti ~= threatMulti ) then
		self.aggroBarMulti = threatMulti

		local pos = 1 - (1 / threatMulti)
		local y = self.settings.barHeight - ( pos * self.settings.barHeight )

		if ( self.moduleSettings.side == IceCore.Side.Left ) then
			self.aggroBar.bar:SetTexCoord(1, 0, 0, pos)
		else
			self.aggroBar.bar:SetTexCoord(0, 1, 0, pos)
		end

		self.aggroBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, y)
	end
end


-- Load us up
IceHUD.IHUD_Threat = IHUD_Threat:new()
