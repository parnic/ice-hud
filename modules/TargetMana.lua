local AceOO = AceLibrary("AceOO-2.0")

local TargetMana = AceOO.Class(IceUnitBar)

-- Constructor --
function TargetMana.prototype:init()
	TargetMana.super.prototype.init(self, "TargetMana", "target")
	self.side = IceCore.Side.Right
	self.offset = 2
	
	self:SetColor("targetMana", 52, 64, 221)
	self:SetColor("targetRage", 235, 44, 26)
	self:SetColor("targetEnergy", 228, 242, 31)
	self:SetColor("targetFocus", 242, 149, 98)
end


function TargetMana.prototype:Enable()
	TargetMana.super.prototype.Enable(self)
	
	self:RegisterEvent("UNIT_MANA", "Update")
	self:RegisterEvent("UNIT_MAXMANA", "Update")
	self:RegisterEvent("UNIT_RAGE", "Update")
	self:RegisterEvent("UNIT_MAXRAGE", "Update")
	self:RegisterEvent("UNIT_ENERGY", "Update")
	self:RegisterEvent("UNIT_MAXENERGY", "Update")
	self:RegisterEvent("UNIT_AURA", "Update")
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	
	self:Update("target")
end


function TargetMana.prototype:TargetChanged()
	self:Update("target")
end


function TargetMana.prototype:Update(unit)
	TargetMana.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	if ((not UnitExists(unit)) or (self.maxMana == 0)) then
		self.frame:Hide()
		return
	else	
		self.frame:Show()
	end
	
	
	local manaType = UnitPowerType(self.unit)
	
	local color = "targetMana"
	if (manaType == 1) then
		color = "targetRage"
	elseif (manaType == 2) then
		color = "targetFocus"
	elseif (manaType == 3) then
		color = "targetEnergy"
	end
	
	if (self.tapped) then
		color = "tapped"
	end
	
	self:UpdateBar(self.mana/self.maxMana, color)
	self:SetBottomText1(self.manaPercentage)
	self:SetBottomText2(self:GetFormattedText(self.mana, self.maxMana), color)
end



-- Load us up
TargetMana:new()
