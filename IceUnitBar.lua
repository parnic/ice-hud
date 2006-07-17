local AceOO = AceLibrary("AceOO-2.0")

IceUnitBar = AceOO.Class(IceBarElement)
IceUnitBar.virtual = true

IceUnitBar.prototype.unit = nil
IceUnitBar.prototype.alive = nil
IceUnitBar.prototype.combat = nil
IceUnitBar.prototype.tapped = nil

IceUnitBar.prototype.health = nil
IceUnitBar.prototype.maxHealth = nil
IceUnitBar.prototype.healthPercentage = nil

IceUnitBar.prototype.mana = nil
IceUnitBar.prototype.maxMana = nil
IceUnitBar.prototype.manaPercentage = nil

IceUnitBar.prototype.unitClass = nil


-- Constructor --
function IceUnitBar.prototype:init(name, unit)
	IceUnitBar.super.prototype.init(self, name)
	assert(unit, "IceUnitBar 'unit' is nil")
	
	self.unit = unit
	_, self.unitClass = UnitClass(self.unit)
	self:SetColor("dead", 0.5, 0.5, 0.5)
	self:SetColor("tapped", 0.8, 0.8, 0.8)
end



-- 'Public' methods -----------------------------------------------------------

function IceUnitBar.prototype:Enable()
	IceUnitBar.super.prototype.Enable(self)
	
	self:RegisterEvent("PLAYER_UNGHOST", "Alive")
	self:RegisterEvent("PLAYER_ALIVE", "Alive")
	self:RegisterEvent("PLAYER_DEAD", "Dead")
	
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OutCombat")
	
	self.alive = not UnitIsDeadOrGhost(self.unit)
	self.combat = UnitAffectingCombat(self.unit)
end



-- 'Protected' methods --------------------------------------------------------

-- To be overridden
function IceUnitBar.prototype:Update(unit)
	if (self.combat) then
		self.alpha = IceElement.Alpha + 0.2
		self.backgroundAlpha = IceBarElement.BackgroundAlpha
	else
		self.alpha = IceElement.Alpha
		self.backgroundAlpha = IceBarElement.BackgroundAlpha
	end
	
	self.tapped = UnitIsTapped(self.unit) and (not UnitIsTappedByPlayer(self.unit))
	
	self.health = UnitHealth(self.unit)
	self.maxHealth = UnitHealthMax(self.unit)
	self.healthPercentage = math.floor( (self.health/self.maxHealth)*100 )
	
	self.mana = UnitMana(self.unit)
	self.maxMana = UnitManaMax(self.unit)
	self.manaPercentage = math.floor( (self.mana/self.maxMana)*100 )
end


function IceUnitBar.prototype:Alive()
	-- instead of maintaining a state for 3 different things
	-- (dead, dead/ghost, alive) just afford the extra function call here
	self.alive = not UnitIsDeadOrGhost(self.unit)
	self:Update(self.unit)
end


function IceUnitBar.prototype:Dead()
	self.alive = false
	self:Update(self.unit)
end


function IceUnitBar.prototype:InCombat()
	self.combat = true
	self:Update(self.unit)
end


function IceUnitBar.prototype:OutCombat()
	self.combat = false
	self:Update(self.unit)
end
