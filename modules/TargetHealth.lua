local AceOO = AceLibrary("AceOO-2.0")

local TargetHealth = AceOO.Class(IceUnitBar, "AceHook-2.0")

TargetHealth.prototype.mobHealthEnabled = nil
TargetHealth.prototype.mobHealth = nil
TargetHealth.prototype.mobMaxHealth = nil
TargetHealth.prototype.color = nil


-- Constructor --
function TargetHealth.prototype:init()
	TargetHealth.super.prototype.init(self, "TargetHealth", "target")
	
	self:SetColor("targetHealthHostile", 231, 31, 36)
	self:SetColor("targetHealthFriendly", 46, 223, 37)
	self:SetColor("targetHealthNeutral", 210, 219, 87)
	
	self.mobHealthEnabled = IsAddOnLoaded("MobHealth")
end


function TargetHealth.prototype:GetDefaultSettings()
	local settings = TargetHealth.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 2
	return settings
end



function TargetHealth.prototype:Enable()
	TargetHealth.super.prototype.Enable(self)
	
	self:RegisterEvent("UNIT_HEALTH", "Update")
	self:RegisterEvent("UNIT_MAXHEALTH", "Update")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")
	
	if (self.mobHealthEnabled) then
		self:Hook("MobHealth_OnEvent", "MobHealth")
	end
	
	self:Update("target")
end


function TargetHealth.prototype:Disable()
	TargetHealth.super.prototype.Disable(self)
	
	if (self.mobHealthEnabled) then
		self:Unhook("MobHealth_OnEvent")
	end
end


function TargetHealth.prototype:TargetChanged()
	self:Update("target")
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
	
	self:UpdateHealthText(false)
end


function TargetHealth.prototype:MobHealth(event)
	self.hooks.MobHealth_OnEvent.orig(event)
	
	if (self.maxHealth ~= 100) then
		return
	end
	
	self.mobHealth = MobHealth_GetTargetCurHP()
	self.mobMaxHealth = MobHealth_GetTargetMaxHP()

	self:UpdateHealthText(true)
end


function TargetHealth.prototype:UpdateHealthText(mobHealth)
	local validData = (self.mobHealth and self.mobMaxHealth and self.health > 0 and self.mobMaxHealth > 0)

	if (mobHealth) then
		if (validData)  then
			self:SetBottomText2(self:GetFormattedText(self.mobHealth, self.mobMaxHealth), self.color)
		else
			self:SetBottomText2()
		end
	else
		if (validData) then
			return
		end
	
		-- assumption that if a unit's max health is 100, it's not actual amount
		-- but rather a percentage - this obviously has one caveat though
	
		if (self.maxHealth ~= 100) then
			self:SetBottomText2(self:GetFormattedText(self.health, self.maxHealth), self.color)
		else
			self:SetBottomText2()
		end
	end
end



-- Load us up
TargetHealth:new()
