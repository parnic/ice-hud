local AceOO = AceLibrary("AceOO-2.0")
local Metrognome = AceLibrary("Metrognome-2.0")

local DruidMana = AceOO.Class(IceUnitBar)

DruidMana.prototype.inForms = nil
DruidMana.prototype.mode = nil
DruidMana.prototype.druidMana = nil
DruidMana.prototype.druidMaxMana = nil


-- Constructor --
function DruidMana.prototype:init()
	DruidMana.super.prototype.init(self, "DruidMana", "player")
	self.side = IceCore.Side.Right
	self.offset = 0
	
	self:SetColor("druidMana", 87, 82, 141)
end


function DruidMana.prototype:GetDefaultSettings()
	local settings = DruidMana.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	return settings
end


function DruidMana.prototype:Enable(core)
	DruidMana.super.prototype.Enable(self, core)
	
	if (IsAddOnLoaded("SoleManax")) then
		self.mode = "SoleManax"
		SoleManax:AddUser(self.UpdateSoleManax, TRUE, self)
		self:UpdateSoleManax(SoleManax:GetPlayerMana())
		
	elseif (IsAddOnLoaded("DruidBar")) then
		self.mode = "DruidBar"
		Metrognome:Register("DruidMana", self.UpdateDruidBarMana, 0.1, self)
		Metrognome:Start("DruidMana")
	end
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "FormsChanged")
	
	self:FormsChanged(self.unit)
end


function DruidMana.prototype:Disable(core)
	DruidMana.super.prototype.Disable(self, core)
	
	if (IsAddOnLoaded("SoleManax")) then
        SoleManax.DelUser(self.UpdateSoleManax)
    end
	
	if (IsAddOnLoaded("DruidBar")) then
		Metrognome:Unregister("DruidMana")
	end
end


function DruidMana.prototype:FormsChanged(unit)
	if (unit ~= self.unit) then
		return
	end

	self.inForms = (UnitPowerType(self.unit) ~= 0)
	self:Update()
end


function DruidMana.prototype:UpdateSoleManax(mana, maxMana)
	self:Update()
	self.druidMana = mana
	self.druidMaxMana = maxMana
end


function DruidMana.prototype:UpdateDruidBarMana()
	self:Update()
	self.druidMana = DruidBarKey.keepthemana
	self.druidMaxMana = DruidBarKey.maxmana
end


function DruidMana.prototype:Update()
	DruidMana.super.prototype.Update(self)
	if ((not self.alive) or (not self.inForms)) then
		self.frame:Hide()
		return
	else
		self.frame:Show()
	end
	
	local color = "druidMana"

	self:UpdateBar(self.druidMana / self.druidMaxMana, color)

	local percentage = (self.druidMana / self.druidMaxMana) * 100
	self:SetBottomText1(math.floor(percentage))
end



-- Load us up (if we are a druid)
local _, unitClass = UnitClass("player")
if (unitClass == "DRUID" and (IsAddOnLoaded("SoleManax") or IsAddOnLoaded("DruidBar"))) then
	DruidMana:new()
end
