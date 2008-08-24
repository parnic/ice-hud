local AceOO = AceLibrary("AceOO-2.0")

local DruidMana = AceOO.Class(IceUnitBar)

DruidMana.prototype.druidMana = nil
DruidMana.prototype.druidManaMax = nil

local LibDruidMana = nil


-- Constructor --
function DruidMana.prototype:init()
	DruidMana.super.prototype.init(self, "DruidMana", "player")

	self.side = IceCore.Side.Right
	self.offset = 0
	
	self:SetDefaultColor("DruidMana", 87, 82, 141)

	if AceLibrary:HasInstance("LibDogTag-3.0") and AceLibrary:HasInstance("LibDruidMana-1.0") then
		LibDruidMana = AceLibrary("LibDruidMana-1.0")
	end
end


function DruidMana.prototype:GetDefaultSettings()
	local settings = DruidMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	settings["textVisible"] = {upper = true, lower = false}

	if LibDruidMana then
		settings["upperText"] = "[PercentDruidMP:Round]"
		settings["lowerText"] = "[FractionalDruidMP:Color('3071bf'):Bracket]"
	end

	return settings
end


function DruidMana.prototype:Enable(core)
	DruidMana.super.prototype.Enable(self, core)

	if LibDruidMana then
		self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "Update")
		self:RegisterEvent("UNIT_MAXMANA", "Update")

		if IceHUD.WowVer >= 30000 then
			if GetCVarBool("predictedPower") and self.frame then
				self.frame:SetScript("OnUpdate", function() self:Update(self.unit) end)
			else
				self:RegisterEvent("UNIT_MANA", "Update")
			end
		else
			self:RegisterEvent("UNIT_MANA", "Update")
		end
	end
end


function DruidMana.prototype:Disable(core)
	DruidMana.super.prototype.Disable(self, core)
end


function DruidMana.prototype:Update()
	DruidMana.super.prototype.Update(self)

	local forms = (UnitPowerType(self.unit) ~= 0)

	if LibDruidMana then
		self.druidMana = LibDruidMana:GetCurrentMana()
		self.druidManaMax = LibDruidMana:GetMaximumMana()
	end

	if (not self.alive or not forms or not self.druidMana or not self.druidManaMax or self.druidManaMax == 0) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.druidMana / self.druidManaMax, "DruidMana")
end



-- Load us up (if we are a druid)
local _, unitClass = UnitClass("player")
if (unitClass == "DRUID") then
	IceHUD.DruidMana = DruidMana:new()
end
