local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceTargetMana = IceCore_CreateClass(IceUnitBar)
IceTargetMana.prototype.registerEvents = true
IceTargetMana.prototype.color = nil
IceTargetMana.prototype.determineColor = true


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
	self:SetDefaultColor("TargetRunicPower", 52, 64, 221)
	if IceHUD.WowVer >= 70000 then
		self:SetDefaultColor("TargetInsanity", 150, 50, 255)
		self:SetDefaultColor("TargetFury", 255, 50, 255)
		self:SetDefaultColor("TargetMaelstrom", 52, 64, 221)
		self:SetDefaultColor("TargetPain", 255, 50, 255)
	end
end


function IceTargetMana.prototype:GetDefaultSettings()
	local settings = IceTargetMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 2
	settings["upperText"] = "[PercentMP:Round]"
	settings["lowerText"] = "[FractionalMP:Short:PowerColor]"
	settings["onlyShowMana"] = false

	return settings
end


function IceTargetMana.prototype:Enable(core)
	IceTargetMana.super.prototype.Enable(self, core)

	if self.registerEvents then
		if IceHUD.WowVer >= 40000 then
			self:RegisterEvent("UNIT_POWER", "UpdateEvent")
			self:RegisterEvent("UNIT_MAXPOWER", "UpdateEvent")
		else
			self:RegisterEvent("UNIT_MAXMANA", "UpdateEvent")
			self:RegisterEvent("UNIT_MAXRAGE", "UpdateEvent")
			self:RegisterEvent("UNIT_MAXENERGY", "UpdateEvent")
			self:RegisterEvent("UNIT_MAXFOCUS", "UpdateEvent")

			self:RegisterEvent("UNIT_MANA", "UpdateEvent")
			self:RegisterEvent("UNIT_RAGE", "UpdateEvent")
			self:RegisterEvent("UNIT_ENERGY", "UpdateEvent")
			self:RegisterEvent("UNIT_FOCUS", "UpdateEvent")

			-- DK rune stuff
			if IceHUD.WowVer >= 30000 then
				self:RegisterEvent("UNIT_RUNIC_POWER", "UpdateEvent")
				self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UpdateEvent")
			end
		end
		self:RegisterEvent("UNIT_AURA", "UpdateEvent")
		self:RegisterEvent("UNIT_FLAGS", "UpdateEvent")
	end

	self:Update(self.unit)
end


function IceTargetMana.prototype:UpdateEvent(event, unit)
	self:Update(unit)
end

function IceTargetMana.prototype:Update(unit)
	IceTargetMana.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end

	if ((not UnitExists(self.unit)) or (self.maxMana == 0)) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	local manaType = UnitPowerType(self.unit)

	if self.moduleSettings.onlyShowMana and manaType ~= SPELL_POWER_MANA then
		self:Show(false)
		return
	end

	if self.determineColor then
		self.color = "TargetMana"

		if (self.moduleSettings.scaleManaColor) then
			self.color = "ScaledManaColor"
		end

		if (manaType == SPELL_POWER_RAGE) then
			self.color = "TargetRage"
		elseif (manaType == SPELL_POWER_FOCUS) then
			self.color = "TargetFocus"
		elseif (manaType == SPELL_POWER_ENERGY) then
			self.color = "TargetEnergy"
		elseif (manaType == SPELL_POWER_RUNIC_POWER) then
			self.color = "TargetRunicPower"
		elseif (IceHUD.WowVer >= 70000 and manaType == SPELL_POWER_INSANITY) then
			self.color = "TargetInsanity"
		elseif (IceHUD.WowVer >= 70000 and manaType == SPELL_POWER_FURY) then
			self.color = "TargetFury"
		elseif (IceHUD.WowVer >= 70000 and manaType == SPELL_POWER_MAELSTROM) then
			self.color = "TargetMaelstrom"
		elseif (IceHUD.WowVer >= 70000 and manaType == SPELL_POWER_PAIN) then
			self.color = "TargetPain"
		end

		if (self.tapped) then
			self.color = "Tapped"
		end
	end

	self.bTreatEmptyAsFull = self:TreatEmptyAsFull(manaType)

	self:UpdateBar(self.manaPercentage, self.color)

	if not IceHUD.IceCore:ShouldUseDogTags() then
		self:SetBottomText1(math.floor(self.manaPercentage * 100))
		self:SetBottomText2(self:GetFormattedText(self.mana, self.maxMana), color)
	end
end

function IceTargetMana.prototype:TreatEmptyAsFull(manaType)
	return manaType == SPELL_POWER_RAGE or manaType == SPELL_POWER_RUNIC_POWER
		or (IceHUD.WowVer >= 70000 and (manaType == SPELL_POWER_LUNAR_POWER or manaType == SPELL_POWER_INSANITY
		or manaType == SPELL_POWER_FURY or manaType == SPELL_POWER_PAIN or manaType == SPELL_POWER_MAELSTROM))
end

-- OVERRIDE
function IceTargetMana.prototype:GetOptions()
	local opts = IceTargetMana.super.prototype.GetOptions(self)

	opts["scaleManaColor"] = {
		type = "toggle",
		name = L["Color bar by mana %"],
		desc = L["Colors the mana bar from MaxManaColor to MinManaColor based on current mana %"],
		get = function()
			return self.moduleSettings.scaleManaColor
		end,
		set = function(info, value)
			self.moduleSettings.scaleManaColor = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 51
	}

	opts["onlyShowMana"] = {
		type = 'toggle',
		name = L["Only show if target uses mana"],
		desc = L["Will only show this bar if the target uses mana (as opposed to rage, energy, runic power, etc.)"],
		width = 'double',
		get = function()
			return self.moduleSettings.onlyShowMana
		end,
		set = function(info, v)
			self.moduleSettings.onlyShowMana = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	return opts
end


-- Load us up
IceHUD.TargetMana = IceTargetMana:new()
