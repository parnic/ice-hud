local AceOO = AceLibrary("AceOO-2.0")

local TargetHealth = AceOO.Class(IceUnitBar, "AceHook-2.0")

TargetHealth.prototype.color = nil


-- Constructor --
function TargetHealth.prototype:init()
	TargetHealth.super.prototype.init(self, "TargetHealth", "target")
	
	self:SetColor("targetHealthHostile", 231, 31, 36)
	self:SetColor("targetHealthFriendly", 46, 223, 37)
	self:SetColor("targetHealthNeutral", 210, 219, 87)
end


function TargetHealth.prototype:GetDefaultSettings()
	local settings = TargetHealth.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 2
	settings["mobhealth"] = false
	return settings
end


-- OVERRIDE
function TargetHealth.prototype:GetOptions()
	local opts = TargetHealth.super.prototype.GetOptions(self)
	
	opts["mobhealth"] = {
		type = "toggle",
		name = "MobHealth3 support",
		desc = "Enable/disable MobHealth3 target HP data. If this option is gray, you do not have MobHealth3.",
		get = function()
			return self.moduleSettings.mobhealth
		end,
		set = function(value)
			self.moduleSettings.mobhealth = value
			self:Update(self.unit)
		end,
		disabled = function()
			return (MobHealth3 == nil)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40
	}
	
	return opts
end


function TargetHealth.prototype:Enable(core)
	TargetHealth.super.prototype.Enable(self, core)
	
	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")
		
	self:Update(self.unit)
end


function TargetHealth.prototype:Disable(core)
	TargetHealth.super.prototype.Disable(self, core)
end



function TargetHealth.prototype:Update(unit)
	TargetHealth.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	if not (UnitExists(unit)) then
		self.frame:Hide()
		return
	else	
		self.frame:Show()
	end
	
	self.color = "targetHealthFriendly" -- friendly > 4
	
	local reaction = UnitReaction("target", "player")
	if (reaction and (reaction == 4)) then
		self.color = "targetHealthNeutral"
	elseif (reaction and (reaction < 4)) then
		self.color = "targetHealthHostile"
	end
	
	if (self.tapped) then
		self.color = "tapped"
	end

	self:UpdateBar(self.health/self.maxHealth, self.color)
	self:SetBottomText1(self.healthPercentage)
	
	
	-- assumption that if a unit's max health is 100, it's not actual amount
	-- but rather a percentage - this obviously has one caveat though

	if (self.maxHealth == 100 and self.moduleSettings.mobhealth and MobHealth3) then
		self.health, self.maxHealth, _ = MobHealth3:GetUnitHealth(self.unit, self.health, self.maxHealth)

		self.health = self:Round(self.health)
		self.maxHealth = self:Round(self.maxHealth)
	end


	if (self.maxHealth ~= 100) then
		self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), self.color)
	else
		self:SetBottomText2()
	end
end


function TargetHealth.prototype:Round(health)
	if (health > 1000000) then
		return self:MathRound(health/100000, 1) .. "M"
	end
	if (health > 1000) then
		return self:MathRound(health/1000, 1) .. "k"
	end
	return health
end


function TargetHealth.prototype:MathRound(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num  * mult + 0.5) / mult
end


-- Load us up
TargetHealth:new()
