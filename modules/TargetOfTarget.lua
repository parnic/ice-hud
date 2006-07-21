local AceOO = AceLibrary("AceOO-2.0")
local Metrognome = AceLibrary("Metrognome-2.0")

local TargetOfTarget = AceOO.Class(IceElement)


-- Constructor --
function TargetOfTarget.prototype:init()
	TargetOfTarget.super.prototype.init(self, "TargetOfTarget")
	
	self:SetColor("totHostile", 0.8, 0.1, 0.1)
	self:SetColor("totFriendly", 0.2, 1, 0.2)
	self:SetColor("totNeutral", 0.9, 0.9, 0)
end



function TargetOfTarget.prototype:Enable()
	TargetOfTarget.super.prototype.Enable(self)
	
	Metrognome:Register("TargetOfTarget", self.Update, 0.2, self)
	Metrognome:Start("TargetOfTarget")
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "Update")
	
	self:Update()
end


function TargetOfTarget.prototype:Disable()
	TargetOfTarget.super.prototype.Disable(self)
	Metrognome:Unregister("TargetOfTarget")
end


-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function TargetOfTarget.prototype:CreateFrame()
	TargetOfTarget.super.prototype.CreateFrame(self)
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(260)
	self.frame:SetHeight(50)
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", 0, -50)
	self.frame:Show()
	
	self:CreateToTFrame()
	self:CreateToTHPFrame()
end



function TargetOfTarget.prototype:CreateToTFrame()
	self.frame.totName = self:FontFactory("Bold", 14)
	
	self.frame.totName:SetWidth(120)
	self.frame.totName:SetHeight(14)
	self.frame.totName:SetJustifyH("RIGHT")
	self.frame.totName:SetJustifyV("BOTTOM")
	
	self.frame.totName:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -2)
	self.frame.totName:Show()
end

function TargetOfTarget.prototype:CreateToTHPFrame()
	self.frame.totHealth = self:FontFactory(nil, 12)
	
	self.frame.totHealth:SetWidth(120)
	self.frame.totHealth:SetHeight(14)
	self.frame.totHealth:SetJustifyH("RIGHT")
	self.frame.totHealth:SetJustifyV("TOP")
	
	self.frame.totHealth:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -16)
	self.frame.totHealth:Show()
end


function TargetOfTarget.prototype:Update()
	if not (UnitExists("targettarget")) then
		self.frame.totName:SetText()
		self.frame.totHealth:SetText()
		return
	end
	
	local _, unitClass = UnitClass("targettarget")
	local name = UnitName("targettarget")
	
	self.frame.totName:SetTextColor(self:GetColor(unitClass, 1))
	self.frame.totName:SetText(name)
	
	
	local color = "totFriendly" -- friendly > 4
	local reaction = UnitReaction("targettarget", "player")
	if (reaction and (reaction == 4)) then
		color = "totNeutral"
	elseif (reaction and (reaction < 4)) then
		color = "totHostile"
	end
	
	local health = UnitHealth("targettarget")
	local maxHealth = UnitHealthMax("targettarget")
	local healthPercentage = math.floor( (health/maxHealth)*100 )
	
	self.frame.totHealth:SetTextColor(self:GetColor(color, 1))
	self.frame.totHealth:SetText(healthPercentage .. "%")
end



-- load us up
TargetOfTarget:new()
