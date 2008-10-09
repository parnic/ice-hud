--[[
Name: IHUD_Threat
Version: 1.2
Author: Caryna/Turalyon EU (Alliance) (updated for Threat-2.0 by 'acapela' of WoWI and merged into IceHUD by Parnic)
Description: adds a threat bar to IceHUD
]]

local AceOO = AceLibrary("AceOO-2.0")
local Threat = LibStub("Threat-2.0")

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

	self:OnCoreLoad()
end

-- default settings
function IHUD_Threat.prototype:GetDefaultSettings()
	local settings = IHUD_Threat.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3
	settings["enabled"] = false
	settings["aggroAlpha"] = 0.7
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
		disabled = function()
			return Threat == nil
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
	self.aggroBar:SetWidth(self.settings.barWidth)
	self.aggroBar:SetHeight(self.settings.barHeight)
	
	if not (self.aggroBar.bar) then
		self.aggroBar.bar = self.aggroBar:CreateTexture(nil, "BACKGROUND")
	end
	
	self.aggroBar.bar:SetTexture(IceElement.TexturePath .. self.settings.barTexture .. "BG")
	self.aggroBar.bar:SetAllPoints(self.aggroBar)
	
	self.aggroBar:SetStatusBarTexture(self.aggroBar.bar)
	
	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
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
	-- only show bar if the user has Threat-2.0 and there's any threat
	if not Threat or not Threat:IsActive() then
		self:Show(false)
		return
	end

	IHUD_Threat.super.prototype.Update(self)

	if (unit and (unit ~= self.unit)) then
		return
	end

	if not unit then
		unit = self.unit
	end
	
	if not UnitExists("target") or not UnitCanAttack("player", "target") or UnitIsDead("target") or UnitIsFriend("player", "target") or UnitPlayerControlled("target")
	then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	-- get my threat and the tank threat
	local threatMe = Threat:GetThreat( UnitGUID("player") , UnitGUID("target") )
	local threatTank = 0
	local threatTankName = ""
	
	if UnitExists("targettarget") then
		threatTankName = UnitGUID("targettarget")
		threatTank = Threat:GetThreat( UnitGUID("targettarget"), UnitGUID("target") )
	else
		threatTank, threatTankName = Threat:GetMaxThreatOnTarget( UnitGUID("target") )
	end

	-- adjust max threat to avoid divide by 0
	if ( threatTank == 0 ) then
		threatTank = 1
	end

	-- aggro gain limit
	local threatMulti = 1.3
	if ( Threat:UnitInMeleeRange( "target" ) ) then
		threatMulti = 1.1
--	elseif ( UnitExists("targettarget") and ( UnitName("targettarget") == UnitName("player") ) ) then
--		threatMulti = 1
	elseif ( threatTankName == UnitGUID("player") ) then
		threatMulti = 1
	end
	
	-- get my threat percentage
	local threatPct = self:MathRound( (100/threatTank) * threatMe, 1 )

	IceHUD:Debug( "threatMe = " .. threatMe .. ", threatTank = " .. threatTank .. ", threatPct = " .. threatPct )
	
	-- set percentage text
	self:SetBottomText1( threatPct .. "%" )
	self:SetBottomText2()

	-- set bar color
	if( threatMulti == 1 ) then
		self.color = "ThreatDanger"
	elseif( threatPct < 50 ) then
		self.color = "ThreatLow"
	elseif ( threatPct < 80 ) then
		self.color = "ThreatMedium"
	else
		self.color = "ThreatHigh"
	end

--[[	local g = floor( (255 / (threatTank*threatMulti) ) *threatMe )
	
	if(g>255) then g=255 end
	if(g<0) then g=0 end
	
	IceHUD.IceCore:SetColor("ThreatCustom", 255, 255, 0)	
	self.color = "ThreatCustom"
]]	
	-- set the bar value
	self:UpdateBar( threatMe / ( threatTank*threatMulti ), self.color )
	
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

-- rounding stuff
function IHUD_Threat.prototype:MathRound(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num  * mult + 0.5) / mult
end

-- Load us up
IceHUD.IHUD_Threat = IHUD_Threat:new()
