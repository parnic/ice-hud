local AceOO = AceLibrary("AceOO-2.0")

local DruidMana = AceOO.Class(IceUnitBar)
local gratuity = AceLibrary("Gratuity-2.0")

DruidMana.prototype.druidMana = nil
DruidMana.prototype.druidManaMax = nil
DruidMana.prototype.lastCast = nil
DruidMana.prototype.baseMana = nil

local intMod = 14


-- Constructor --
function DruidMana.prototype:init()
	DruidMana.super.prototype.init(self, "DruidMana", "player")
	self.side = IceCore.Side.Right
	self.offset = 0
	
	self:SetDefaultColor("DruidMana", 87, 82, 141)
end


function DruidMana.prototype:GetDefaultSettings()
	local settings = DruidMana.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	settings["textVisible"] = {upper = true, lower = false}
	return settings
end


function DruidMana.prototype:Enable(core)
	DruidMana.super.prototype.Enable(self, core)
	
	self:FormsChanged(self.unit)
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "FormsChanged")
	self:RegisterEvent("UNIT_MANA", "UpdateMana")
	self:RegisterEvent("UNIT_MAXMANA", "UpdateManaMax")
end


function DruidMana.prototype:Disable(core)
	DruidMana.super.prototype.Disable(self, core)
end


function DruidMana.prototype:FormsChanged(unit)
	if (unit ~= self.unit) then
		return
	end
	
	local forms = (UnitPowerType(self.unit) ~= 0)
	
	if (forms) then
		self.lastCast = GetTime()

		if (not self.druidMana) then
			return
		end
		
		-- deduct the shapeshift cost from last known mana value
		-- when we shift to forms
		local uberTooltips = GetCVar("UberTooltips")
		SetCVar("UberTooltips", 1)
		
		gratuity:SetShapeshift(1) -- 1 = bear form, rawr
		local _, _, manaCost = gratuity:Find("(%d+)", 2, 2) -- 2 = mana cost line
		
		self.druidMana = self.druidMana - (manaCost or 0)
		
		SetCVar("UberTooltips", uberTooltips)
	else
		-- always update with actual mana values when shifting out
		self:UpdateMana(self.unit)
		self:UpdateManaMax(self.unit)
		
		local _, intellect, _, _ = UnitStat(self.unit, 4)
		self.baseMana = UnitMana(self.unit) - (intellect * intMod)
	end

	self:Update()
end


function DruidMana.prototype:UpdateMana(unit)
	if (unit ~= self.unit) then
		return
	end
	
	local forms = (UnitPowerType(self.unit) ~= 0)

	if (forms) then
		if (not self.druidMana or not self.lastCast) then
			return
		end
		
		local time = GetTime()
		local normal, casting = GetManaRegen()
		
		if (time - self.lastCast > 5) then
			self.druidMana = self.druidMana + (normal * 2)
		else
			self.druidMana = self.druidMana + (casting * 2)
		end
		
		-- sanity check, the tick can be off a little sometimes
		if (self.druidMana > self.druidManaMax) then
			self.druidMana = self.druidManaMax
		end
	else
		self.druidMana = UnitMana(self.unit)
	end
	
	self:Update()
end


function DruidMana.prototype:UpdateManaMax(unit)
	if (unit ~= self.unit) then
		return
	end
	
	local forms = (UnitPowerType(self.unit) ~= 0)

	if (forms) then
		if not (self.baseMana) then
			return
		end
		
		local _, intellect, _, _ = UnitStat(self.unit, 4)
		
		self.druidManaMax = self.baseMana + (intellect * intMod)
		
		if (self.druidMana > self.druidManaMax) then
			self.druidMana = self.druidManaMax
		end
	else
		self.druidManaMax = UnitManaMax(self.unit)
	end
	
	self:Update()
end


function DruidMana.prototype:Update()
	DruidMana.super.prototype.Update(self)
	
	local forms = (UnitPowerType(self.unit) ~= 0)
	
	if (not self.alive or not forms or not self.druidMana or not self.druidManaMax) then
		self:Show(false)
		return
	else
		self:Show(true)
	end
	
	self:UpdateBar(self.druidMana / self.druidManaMax, "DruidMana")

	local percentage = (self.druidMana / self.druidManaMax) * 100
	self:SetBottomText1(math.floor(percentage))
	self:SetBottomText2(self:GetFormattedText(string.format("%.0f", self.druidMana),
		string.format("%.0f", self.druidManaMax)), "DruidMana")
end



-- Load us up (if we are a druid)
local _, unitClass = UnitClass("player")
if (unitClass == "DRUID") then
	IceHUD.DruidMana = DruidMana:new()
end
