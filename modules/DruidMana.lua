local AceOO = AceLibrary("AceOO-2.0")
local Metrognome = AceLibrary("Metrognome-2.0")

local DruidMana = AceOO.Class(IceUnitBar)

DruidMana.prototype.inForms = nil
DruidMana.prototype.mode = nil
DruidMana.prototype.mana = nil
DruidMana.prototype.maxMana = nil


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


function DruidMana.prototype:Enable()
	DruidMana.super.prototype.Enable(self)
	
	if (IsAddOnLoaded("SoleManax")) then
		self.mode = "SoleManax"
		SoleManax:AddUser(self.UpdateSoleManax, TRUE, self)
		self:UpdateSoleManax(SoleManax:GetPlayerMana())
		
	elseif (DruidBar_OnLoad) then
		self.mode = "DruidBar"
		Metrognome:Register("DruidMana", self.UpdateDruidBarMana, 0.1, self)
		Metrognome:Start("DruidMana")
	end
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "FormsChanged")
	
	self:FormsChanged(self.unit)
end


function DruidMana.prototype:Disable()
	DruidMana.super.prototype.Disable(self)
	
	if (IsAddOnLoaded("SoleManax")) then
        SoleManax.DelUser(self.UpdateSoleManax)
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
	self.mana = mana
	self.maxMana = maxMana
	self:Update()
end


function DruidMana.prototype:UpdateDruidBarMana()
	self.mana = DruidBarKey.keepthemana
	self.maxMana = DruidBarKey.maxmana
	self:Update()
end


function DruidMana.prototype:Update()
	if ((not self.alive) or (not self.inForms)) then
		self.frame:Hide()
		return
	else
		self.frame:Show()
	end
	
	local color = "druidMana"

	self:UpdateBar(self.mana / self.maxMana, color)

	local percentage = (self.mana / self.maxMana) * 100
	self:SetBottomText1(math.floor(percentage))
end



-- Load us up (if we are a druid)
local _, unitClass = UnitClass("player")
if (unitClass == "DRUID") then
	DruidMana:new()
end
