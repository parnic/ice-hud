local AceOO = AceLibrary("AceOO-2.0")

local PlayerMana = AceOO.Class(IceUnitBar)

PlayerMana.prototype.manaType = nil

-- Constructor --
function PlayerMana.prototype:init()
	PlayerMana.super.prototype.init(self, "PlayerMana", "player")
	self.side = IceCore.Side.Right
	self.offset = 1
	
	self:SetColor("playerMana", 62, 54, 152)
	self:SetColor("playerRage", 171, 59, 59)
	self:SetColor("playerEnergy", 218, 231, 31)	
end


function PlayerMana.prototype:Enable()
	PlayerMana.super.prototype.Enable(self)
	
	self:RegisterEvent("UNIT_MANA", "Update")
	self:RegisterEvent("UNIT_MAXMANA", "Update")
	self:RegisterEvent("UNIT_RAGE", "Update")
	self:RegisterEvent("UNIT_MAXRAGE", "Update")
	self:RegisterEvent("UNIT_ENERGY", "Update")
	self:RegisterEvent("UNIT_MAXENERGY", "Update")
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "ManaType")
	
	self:ManaType(self.unit)
	self:Update("player")
end


function PlayerMana.prototype:ManaType(unit)
	if (unit ~= self.unit) then
		return
	end
	
	self.manaType = UnitPowerType(self.unit)
	self:Update(self.unit)
end


function PlayerMana.prototype:Update(unit)
	PlayerMana.super.prototype.Update(self)
	if (unit and (unit ~= "player")) then
		return
	end
	
	local color = "playerMana"
	if not (self.alive) then
		color = "dead"
	else
		if (self.manaType == 1) then
			color = "playerRage"
		elseif (self.manaType == 3) then
			color = "playerEnergy"
		end
	end
	
	self:UpdateBar(self.mana/self.maxMana, color)
	self:SetBottomText1(self.manaPercentage)
	
	local amount = self:GetFormattedText(self.mana, self.maxMana)
	
	-- druids get a little shorted string to make room for druid mana in forms
	if (self.unitClass == "DRUID" and self.manaType ~= 0) then
		amount = self:GetFormattedText(self.mana)
	end
	self:SetBottomText2(amount, color)
end



-- Load us up
PlayerMana:new()
