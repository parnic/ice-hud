local AceOO = AceLibrary("AceOO-2.0")

local PlayerHealth = AceOO.Class(IceUnitBar)

-- Constructor --
function PlayerHealth.prototype:init()
	PlayerHealth.super.prototype.init(self, "PlayerHealth", "player")
	self.side = IceCore.Side.Left
	self.offset = 1
	
	self:SetColor("playerHealth", 37, 164, 30)
end


function PlayerHealth.prototype:Enable()
	PlayerHealth.super.prototype.Enable(self)
	
	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")

	
	self:Update(self.unit)
end


function PlayerHealth.prototype:Update(unit)
	PlayerHealth.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	local color = "playerHealth"
	if not (self.alive) then
		color = "dead"
	end

	
	
	self:UpdateBar(self.health/self.maxHealth, color)
	self:SetBottomText1(self.healthPercentage)
	self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), color)
end



-- Load us up
PlayerHealth:new()
