local AceOO = AceLibrary("AceOO-2.0")

local CastBar = AceOO.Class(IceBarElement)

CastBar.prototype.casting = nil
CastBar.prototype.channeling = nil
CastBar.prototype.failing = nil
CastBar.prototype.succeeding = nil

CastBar.prototype.spellName = nil

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
	return settings
end


function CastBar.prototype:Enable()
	CastBar.super.prototype.Enable(self)
	
	self.frame.bottomUpperText:SetWidth(180)
	
	self:RegisterEvent("SPELLCAST_START", "CastStart")
	self:RegisterEvent("SPELLCAST_STOP", "CastStop")
	self:RegisterEvent("SPELLCAST_FAILED", "CastFailed")
	self:RegisterEvent("SPELLCAST_INTERRUPTED", "CastInterrupted")
	
	self:RegisterEvent("SPELLCAST_DELAYED", "CastDelayed")
	
	self:RegisterEvent("SPELLCAST_CHANNEL_START", "ChannelingStart")
	self:RegisterEvent("SPELLCAST_CHANNEL_STOP", "ChannelingStop")
	self:RegisterEvent("SPELLCAST_CHANNEL_UPDATE", "ChannelingUpdate")
	
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
	
	self.frame.bottomUpperText:SetWidth(180)
end



-- 'Protected' methods --------------------------------------------------------


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
		self:SetBottomText1(remaining .. "s  " .. self.spellName)
	
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
	
	else -- shouldn't be needed
		self:CleanUp()
		self.frame:Hide()
		self.frame:SetScript("OnUpdate", nil)
	end
end



function CastBar.prototype:CastStart(name, castTime)
	self.spellName = name
	self.castTime = castTime / 1000
	self.startTime = GetTime()
	self.delay = 0
	self.casting = true	

	self.frame:Show()
	
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end


function CastBar.prototype:CastStop()
	if not (self.casting) then
		return
	end
	self:CleanUp()
	
	self.spellName = nil
	self.castTime = 1
	self.startTime = GetTime()
	self.succeeding = true	

	self.frame:Show()
end


function CastBar.prototype:CastFailed()
	self:CastTerminated("Failed")
end


function CastBar.prototype:CastInterrupted()
	self:CastTerminated("Interrupted")
end


function CastBar.prototype:CastTerminated(reason)
	if not (self.casting or self.channeling or self.succeeding) then
		return
	end
	self:CleanUp()
	
	self.spellName = reason
	self.castTime = 1
	self.startTime = GetTime()
	self.failing = true	

	self.frame:Show()
end


function CastBar.prototype:CastDelayed(delay)
	self.delay = self.delay + (delay / 1000)
end




function CastBar.prototype:ChannelingStart(duration, spell)
	self.spellName = spell
	self.castTime = duration / 1000
	self.startTime = GetTime()
	self.delay = 0
	self.channeling = true	

	self.frame:Show()
	
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end


function CastBar.prototype:ChannelingStop()
	self:CleanUp()
	self.frame:Hide()
end


function CastBar.prototype:ChannelingUpdate(duration)
	self.castTime = duration / 1000
end



function CastBar.prototype:CleanUp()
	self.spellName = nil
	self.castTime = nil
	self.startTime = nil
	self.delay = 0
	self.casting = false
	self.channeling = false
	self.failing = false
	self.succeeding = false
	self:SetBottomText1()
	self.alpha = self.settings.alphaooc
end


-- Load us up
CastBar:new()
