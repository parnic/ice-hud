local AceOO = AceLibrary("AceOO-2.0")
local SpellCache = AceLibrary("SpellCache-1.0")

local CastBar = AceOO.Class(IceBarElement)

CastBar.prototype.casting = nil
CastBar.prototype.channeling = nil
CastBar.prototype.failing = nil
CastBar.prototype.succeeding = nil
CastBar.prototype.instanting = nil

CastBar.prototype.spellName = nil
CastBar.prototype.spellRank = nil

CastBar.prototype.startTime = nil
CastBar.prototype.castTime = nil
CastBar.prototype.delay = nil

CastBar.prototype.debug = 0


-- Constructor --
function CastBar.prototype:init()
	CastBar.super.prototype.init(self, "CastBar")

	self:SetColor("castCasting", 242, 242, 10)
	self:SetColor("castChanneling", 117, 113, 161)
	self:SetColor("castSuccess", 242, 242, 10)
	self:SetColor("castFail", 1, 0, 0)
end



-- 'Public' methods -----------------------------------------------------------


function CastBar.prototype:GetDefaultSettings()
	local settings = CastBar.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 0
	settings["showInstants"] = true
	return settings
end


-- OVERRIDE
function CastBar.prototype:GetOptions()
	local opts = CastBar.super.prototype.GetOptions(self)
	
	opts["showInstants"] = 
	{
		type = 'toggle',
		name =  'Show Instant Casts',
		desc = 'Toggles showing instant spell names',
		get = function()
			return self.moduleSettings.showInstants
		end,
		set = function(value)
			self.moduleSettings.showInstants = value
		end,
		order = 50
	}
	
	return opts
end


function CastBar.prototype:Enable()
	CastBar.super.prototype.Enable(self)
	
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	self:RegisterEvent("SpellStatus_SpellCastCastingStart")
	self:RegisterEvent("SpellStatus_SpellCastCastingChange")
	self:RegisterEvent("SpellStatus_SpellCastCastingFinish")
	self:RegisterEvent("SpellStatus_SpellCastFailure")
	
	self:RegisterEvent("SpellStatus_SpellCastChannelingStart")
	self:RegisterEvent("SpellStatus_SpellCastChannelingChange")
	self:RegisterEvent("SpellStatus_SpellCastChannelingFinish")


	self.frame:Hide()
	
	-- remove blizz cast bar
	CastingBarFrame:UnregisterAllEvents()
end


function CastBar.prototype:Disable()
	CastBar.super.prototype.Disable(self)
	
	CastingBarFrame:RegisterEvent("SPELLCAST_START");
	CastingBarFrame:RegisterEvent("SPELLCAST_STOP");
	CastingBarFrame:RegisterEvent("SPELLCAST_FAILED");
	CastingBarFrame:RegisterEvent("SPELLCAST_INTERRUPTED");
	CastingBarFrame:RegisterEvent("SPELLCAST_DELAYED");
	CastingBarFrame:RegisterEvent("SPELLCAST_CHANNEL_START");
	CastingBarFrame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE");
	CastingBarFrame:RegisterEvent("SPELLCAST_CHANNEL_STOP");
end


-- OVERRIDE
function CastBar.prototype:Redraw()
	CastBar.super.prototype.Redraw(self)
end



-- 'Protected' methods --------------------------------------------------------


-- OVERRIDE
function CastBar.prototype:CreateFrame()
	CastBar.super.prototype.CreateFrame(self)
	
	self.frame.bottomUpperText:SetWidth(self.settings.gap + 30)
end


function CastBar.prototype:OnUpdate()
	local taken = GetTime() - self.startTime
	local scale = taken / (self.castTime + self.delay)
		
	self:Update()
	
	if (self.casting or self.channeling) then
		if (scale > 1) then -- lag compensation
			scale = 1
		end
		
		local timeRemaining = self.castTime + self.delay - taken
		local remaining = string.format("%.1f", timeRemaining)
		if (timeRemaining < 0 and timeRemaining > -1.5) then -- lag compensation
			remaining = 0
		end
		
		if (self.channeling) then
			scale = 1 - scale
		end
		
		self:UpdateBar(scale, "castCasting")
		
		self.spellName = self.spellName or ''
		self:SetBottomText1(remaining .. "s  " .. self.spellName .. self:FormatRank(self.spellRank))
	
	elseif (self.failing) then
		self.alpha = 0.7
		self:UpdateBar(1, "castFail", 1-scale)
		self:SetBottomText1(self.spellName, "castFail")
		
		if (scale >= 1) then
			self:CleanUp()
			self.frame:Hide()
			self.frame:SetScript("OnUpdate", nil)
		end
	
	elseif (self.succeeding) then
		if (scale < 0.1) then -- "wait" for possible fail event before showing success animation
			return
		end
		self.alpha = 0.9
		self:UpdateBar(1, "castSuccess", 1.1-scale)
		
		if (scale >= 1) then
			self:CleanUp()
			self.frame:Hide()
			self.frame:SetScript("OnUpdate", nil)
		end
		
	elseif (self.instanting) then
		self:UpdateBar(1, "castSuccess", 1-scale)
		self.frame.bg:Hide()
		self.barFrame:Hide()
		
		self.spellName = self.spellName or ''
		self:SetBottomText1(self.spellName .. self:FormatRank(self.spellRank))
		
		if (scale >= 1) then
			self.frame.bg:Show()
			self.barFrame:Show()
		
			self:CleanUp()
			self.frame:SetScript("OnUpdate", nil)
		end
	
	else -- shouldn't be needed
		self:CleanUp()
		self.frame:Hide()
		self.frame:SetScript("OnUpdate", nil)
	end
end



function CastBar.prototype:CleanUp()
	self.spellName = nil
	self.spellRank = nil
	self.castTime = nil
	self.startTime = nil
	self.delay = 0
	self.casting = false
	self.channeling = false
	self.failing = false
	self.succeeding = false
	self.instanting = false
	self:SetBottomText1()
	self.alpha = self.settings.alphaooc
end


function CastBar.prototype:FormatRank(rank)
	if (rank) then
		return " (" .. rank .. ")"
	else
		return ""
	end
end



-------------------------------------------------------------------------------
-- INSTANT SPELLS                                                            --
-------------------------------------------------------------------------------

function CastBar.prototype:SpellStatus_SpellCastInstant(sId, sName, sRank, sFullName, sCastTime)
	IceHUD:Debug("SpellStatus_SpellCastInstant", sId, sName, sRank, sFullName, sCastTime)
	
	if not (self.moduleSettings.showInstants) then
		return
	end
	
	self:CleanUp()
	
	self.spellName = sName
	self.spellRank = SpellCache:GetRankNumber(sRank or '')
	self.castTime = 1
	self.startTime = GetTime()
	self.instanting = true	

	self.frame:Show()
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end




-------------------------------------------------------------------------------
-- NORMAL SPELLS                                                             --
-------------------------------------------------------------------------------

function CastBar.prototype:SpellStatus_SpellCastCastingStart(sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration)
	IceHUD:Debug("SpellStatus_SpellCastCastingStart", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration)
	
	self.spellName = sName
	self.spellRank = SpellCache:GetRankNumber(sRank or '')
	
	self.castTime = sCastDuration / 1000
	self.startTime = sCastStartTime
	self.delay = 0
	self.casting = true	

	self.frame:Show()
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end


function CastBar.prototype:SpellStatus_SpellCastCastingFinish (sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sCastDelayTotal)
	IceHUD:Debug("SpellStatus_SpellCastCastingFinish ", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sCastDelayTotal)
	
	self:CleanUp()
	
	self.castTime = 1
	self.startTime = GetTime()
	self.succeeding = true	

	self.frame:Show()
end


function CastBar.prototype:SpellStatus_SpellCastCastingChange(sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sCastDelay, sCastDelayTotal)
	IceHUD:Debug("SpellStatus_SpellCastCastingChange", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sCastDelay, sCastDelayTotal)
	self.delay = sCastDelayTotal
end


function CastBar.prototype:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	IceHUD:Debug("SpellStatus_SpellCastFailure", sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	
	if (not (isActiveSpell) or not (self.casting or self.channeling)) then
		return
	end
	
	self:CleanUp()
	
	self.spellName = UIEM_Message
	self.castTime = 1
	self.startTime = GetTime()
	self.failing = true	

	self.frame:Show()
end







-------------------------------------------------------------------------------
-- CHANNELING SPELLS                                                         --
-------------------------------------------------------------------------------

function CastBar.prototype:SpellStatus_SpellCastChannelingStart(sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction)
	IceHUD:Debug("SpellStatus_SpellCastChannelingStart", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction)
	
	self.spellName = sName
	self.spellRank = SpellCache:GetRankNumber(sRank or '')
	self.castTime = sCastDuration
	self.startTime = sCastStartTime
	self.delay = 0
	self.channeling = true	

	self.frame:Show()
	
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end


function CastBar.prototype:SpellStatus_SpellCastChannelingFinish(sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction, sCastDisruptionTotal)
	IceHUD:Debug("SpellStatus_SpellCastChannelingFinish", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction, sCastDisruptionTotal)

	self:CleanUp()
	self.frame:Hide()
end


function CastBar.prototype:SpellStatus_SpellCastChannelingChange(sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction, sCastDisruption, sCastDisruptionTotal)
	IceHUD:Debug("SpellStatus_SpellCastChannelingChange", sId, sName, sRank, sFullName, sCastStartTime, sCastStopTime, sCastDuration, sAction, sCastDisruption, sCastDisruptionTotal)
	self.castTime = sCastDuration / 1000
end











-- Load us up
CastBar:new()
