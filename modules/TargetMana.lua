local AceOO = AceLibrary("AceOO-2.0")

IceTargetMana = AceOO.Class(IceUnitBar)
IceTargetMana.prototype.registerEvents = true


-- Constructor --
function IceTargetMana.prototype:init(moduleName, unit)
	if not moduleName or not unit then
		IceTargetMana.super.prototype.init(self, "TargetMana", "target")
	else
		IceTargetMana.super.prototype.init(self, moduleName, unit)
	end
	
	self:SetDefaultColor("TargetMana", 52, 64, 221)
	self:SetDefaultColor("TargetRage", 235, 44, 26)
	self:SetDefaultColor("TargetEnergy", 228, 242, 31)
	self:SetDefaultColor("TargetFocus", 242, 149, 98)
end


function IceTargetMana.prototype:GetDefaultSettings()
	local settings = IceTargetMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 2
	settings["upperText"] = "[PercentMP:Round]"
	settings["lowerText"] = "[FractionalMP:PowerColor]"

	return settings
end


function IceTargetMana.prototype:Enable(core)
	IceTargetMana.super.prototype.Enable(self, core)

	if self.registerEvents then
		self:RegisterEvent("UNIT_MAXMANA", "Update")
		self:RegisterEvent("UNIT_MAXRAGE", "Update")
		self:RegisterEvent("UNIT_MAXENERGY", "Update")
		self:RegisterEvent("UNIT_MAXFOCUS", "Update")
		self:RegisterEvent("UNIT_AURA", "Update")
		self:RegisterEvent("UNIT_FLAGS", "Update")
		-- DK rune stuff
		if IceHUD.WowVer >= 30000 then
			if GetCVarBool("predictedPower") and self.frame then
				self.frame:SetScript("OnUpdate", function() self:Update(self.unit) end)
			else
				self:RegisterEvent("UNIT_MANA", "Update")
				self:RegisterEvent("UNIT_RAGE", "Update")
				self:RegisterEvent("UNIT_ENERGY", "Update")
				self:RegisterEvent("UNIT_FOCUS", "Update")
				self:RegisterEvent("UNIT_RUNIC_POWER", "Update")
			end

			self:RegisterEvent("UNIT_MAXRUNIC_POWER", "Update")
		else
			self:RegisterEvent("UNIT_MANA", "Update")
			self:RegisterEvent("UNIT_RAGE", "Update")
			self:RegisterEvent("UNIT_ENERGY", "Update")
			self:RegisterEvent("UNIT_FOCUS", "Update")
		end
	end

	self:Update(self.unit)
end



function IceTargetMana.prototype:Update(unit)
	IceTargetMana.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end
	
	if ((not UnitExists(unit)) or (self.maxMana == 0)) then
		self:Show(false)
		return
	else	
		self:Show(true)
	end
	
	
	local manaType = UnitPowerType(self.unit)
	
	local color = "TargetMana"
	if (self.moduleSettings.scaleManaColor) then
		color = "ScaledManaColor"
	end
	if (manaType == 1) then
		color = "TargetRage"
	elseif (manaType == 2) then
		color = "TargetFocus"
	elseif (manaType == 3) then
		color = "TargetEnergy"
	end
	
	if (self.tapped) then
		color = "Tapped"
	end
	
	self:UpdateBar(self.mana/self.maxMana, color)

	if not AceLibrary:HasInstance("LibDogTag-3.0") then
		self:SetBottomText1(math.floor(self.manaPercentage * 100))
		self:SetBottomText2(self:GetFormattedText(self.mana, self.maxMana), color)
	end
end


-- OVERRIDE
function IceTargetMana.prototype:GetOptions()
	local opts = IceTargetMana.super.prototype.GetOptions(self)

	opts["scaleManaColor"] = {
		type = "toggle",
		name = "Color bar by mana %",
		desc = "Colors the mana bar from MaxManaColor to MinManaColor based on current mana %",
		get = function()
			return self.moduleSettings.scaleManaColor
		end,
		set = function(value)
			self.moduleSettings.scaleManaColor = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 51
	}

	return opts
end


-- Load us up
IceHUD.TargetMana = IceTargetMana:new()
