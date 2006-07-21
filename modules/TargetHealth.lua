local AceOO = AceLibrary("AceOO-2.0")

local TargetHealth = AceOO.Class(IceUnitBar)

-- Constructor --
function TargetHealth.prototype:init()
	TargetHealth.super.prototype.init(self, "TargetHealth", "target")
	
	self:SetColor("targetHealthHostile", 231, 31, 36)
	self:SetColor("targetHealthFriendly", 46, 223, 37)
	self:SetColor("targetHealthNeutral", 210, 219, 87)
end


function TargetHealth.prototype:GetDefaultSettings()
	local settings = TargetHealth.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 2
	return settings
end



function TargetHealth.prototype:Enable()
	TargetHealth.super.prototype.Enable(self)
	
	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	
	self:Update("target")
end


function TargetHealth.prototype:TargetChanged()
	self:Update("target")
end


function TargetHealth.prototype:Update(unit)
	TargetHealth.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	if not (UnitExists(unit)) then
		self.frame:Hide()
		return
	else	
		self.frame:Show()
	end
	
	local color = "targetHealthFriendly" -- friendly > 4
	
	local reaction = UnitReaction("target", "player")
	if (reaction and (reaction == 4)) then
		color = "targetHealthNeutral"
	elseif (reaction and (reaction < 4)) then
		color = "targetHealthHostile"
	end
	
	if (self.tapped) then
		color = "tapped"
	end

	self:UpdateBar(self.health/self.maxHealth, color)
	self:SetBottomText1(self.healthPercentage)
	
	-- assumption that if a unit's max health is 100, it's not actual amount
	-- but rather a percentage - this obviously has one caveat though
	if (self.maxHealth ~= 100) then
		self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), color)
	else
		self:SetBottomText2(nil, color)
	end
end



-- Load us up
TargetHealth:new()
