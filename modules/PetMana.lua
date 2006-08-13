local AceOO = AceLibrary("AceOO-2.0")

local PetMana = AceOO.Class(IceUnitBar)

-- Constructor --
function PetMana.prototype:init()
	PetMana.super.prototype.init(self, "PetMana", "pet")
	
	self:SetColor("petMana", 62, 54, 152)
	self:SetColor("petRage", 171, 59, 59)
	self:SetColor("petEnergy", 218, 231, 31)
	self:SetColor("targetFocus", 242, 149, 98)
end


-- OVERRIDE
function PetMana.prototype:GetOptions()
	local opts = PetMana.super.prototype.GetOptions(self)
	opts["scale"] = 
	{
		type = 'range',
		name = 'Scale',
		desc = 'Scale of the bar',
		min = 0.2,
		max = 1,
		step = 0.05,
		isPercent = true,
		get = function()
			return self.moduleSettings.scale
		end,
		set = function(value)
			self.moduleSettings.scale = value
			self:Redraw()
		end,
		order = 51
	}
	return opts
end


function PetMana.prototype:GetDefaultSettings()
	local settings = PetMana.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = -1
	settings["scale"] = 0.7
	return settings
end


-- OVERRIDE
function PetMana.prototype:CreateFrame()
	PetMana.super.prototype.CreateFrame(self)
	self.frame:SetScale(self.moduleSettings.scale)
	
	local point, relativeTo, relativePoint, xoff, yoff = self.frame.bottomUpperText:GetPoint()
	if (point == "TOPLEFT") then
		point = "BOTTOMLEFT"
	else
		point = "BOTTOMRIGHT"
	end
	
	self.frame.bottomUpperText:ClearAllPoints()
	self.frame.bottomUpperText:SetPoint(point, relativeTo, relativePoint, 0, 0)
end


function PetMana.prototype:Enable()
	PetMana.super.prototype.Enable(self)

	self:RegisterEvent("PET_UI_UPDATE",	 "CheckPet");
	self:RegisterEvent("PLAYER_PET_CHANGED", "CheckPet");
	self:RegisterEvent("PET_BAR_CHANGED", "CheckPet");
	self:RegisterEvent("UNIT_PET", "CheckPet");
	
	self:RegisterEvent("UNIT_MANA", "Update")
	self:RegisterEvent("UNIT_MAXMANA", "Update")
	self:RegisterEvent("UNIT_RAGE", "Update")
	self:RegisterEvent("UNIT_MAXRAGE", "Update")
	self:RegisterEvent("UNIT_ENERGY", "Update")
	self:RegisterEvent("UNIT_MAXENERGY", "Update")

	self:RegisterEvent("UNIT_DISPLAYPOWER", "ManaType")

	self:CheckPet()
	self:ManaType(self.unit)
end


function PetMana.prototype:CheckPet()
	if (UnitExists(self.unit)) then
		self.frame:Show()
		self:Update(self.unit)
	else
		self.frame:Hide()
	end
end


function PetMana.prototype:ManaType(unit)
	if (unit ~= self.unit) then
		return
	end
	
	self.manaType = UnitPowerType(self.unit)
	self:Update(self.unit)
end


function PetMana.prototype:Update(unit)
	PetMana.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	if ((not UnitExists(unit)) or (self.maxMana == 0)) then
		self.frame:Hide()
		return
	else	
		self.frame:Show()
	end
	
	local color = "petMana"
	if not (self.alive) then
		color = "dead"
	else
		local color = "petMana"
		if (self.manaType == 1) then
			color = "petRage"
		elseif (self.manaType == 2) then
			color = "petFocus"
		elseif (self.manaType == 3) then
			color = "petEnergy"
		end
	end
	
	self:UpdateBar(self.mana/self.maxMana, color)
	self:SetBottomText1(self.manaPercentage)
end



-- Load us up
PetMana:new()
