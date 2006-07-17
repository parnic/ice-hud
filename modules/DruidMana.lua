local AceOO = AceLibrary("AceOO-2.0")
local Metrognome = AceLibrary("Metrognome-2.0")

local DruidMana = AceOO.Class(IceUnitBar)

DruidMana.prototype.inForms = nil


-- Constructor --
function DruidMana.prototype:init()
	DruidMana.super.prototype.init(self, "DruidMana", "player")
	self.side = IceCore.Side.Right
	self.offset = 0
	
	self:SetColor("druidMana", 87, 82, 141)
end


function DruidMana.prototype:Enable()
	DruidMana.super.prototype.Enable(self)
	
	if (DruidBar_OnLoad) then
		Metrognome:Register("DruidMana", self.Update, 0.1, self)
		Metrognome:Start("DruidMana")
	end
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "FormsChanged")
	
	self:Update()
end


function DruidMana.prototype:FormsChanged(unit)
	if (unit ~= self.unit) then
		return
	end

	self.inForms = (UnitPowerType(self.unit) ~= 0)
end


function DruidMana.prototype:Update(unit)
	if ((not self.alive) or (not self.inForms)) then
		self.frame:Hide()
		return
	else
		self.frame:Show()
	end
	
	--IceHUD:Debug(self.alive, self.inForms)
	
	local color = "druidMana"
	self:UpdateBar(DruidBarKey.keepthemana / DruidBarKey.maxmana, color)
	local percentage = DruidBarKey.keepthemana / DruidBarKey.maxmana * 100
	self:SetBottomText1(math.floor(percentage))
	--self:SetBottomText2(self:GetFormattedText(DruidBarKey.keepthemana, DruidBarKey.maxmana), color)
end



-- Load us up (if we are a druid)
local _, unitClass = UnitClass("player")
if (unitClass == "DRUID") then
	DruidMana:new()
end
