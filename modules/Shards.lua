local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ShardCounter = IceCore_CreateClass(IceClassPowerCounter)

local CurrentSpec = nil

local AfflictionCoords
if IceHUD.WowVer < 70200 then
	AfflictionCoords =
	{
		{0.01562500, 0.28125000, 0.00781250, 0.13281250},
		{0.01562500, 0.28125000, 0.00781250, 0.13281250},
		{0.01562500, 0.28125000, 0.00781250, 0.13281250},
		{0.01562500, 0.28125000, 0.00781250, 0.13281250},
		{0.01562500, 0.28125000, 0.00781250, 0.13281250},
	}
else
	AfflictionCoords =
	{
		{0, 1, 0, 1},
		{0, 1, 0, 1},
		{0, 1, 0, 1},
		{0, 1, 0, 1},
		{0, 1, 0, 1},
	}
end

local DestructionCoords =
{
	{0.00390625, 0.14453125, 0.32812500, 0.93750000},
	{0.00390625, 0.14453125, 0.32812500, 0.93750000},
	{0.00390625, 0.14453125, 0.32812500, 0.93750000},
	{0.00390625, 0.14453125, 0.32812500, 0.93750000},
}

local DemonologyCoords =
{
	{0.03906250, 0.55468750, 0.10546875, 0.19921875},
}

function ShardCounter.prototype:init()
	ShardCounter.super.prototype.init(self, "Warlock Power")

	self:SetDefaultColor("ShardCounterNumeric", 218, 231, 31)

	self.numericColor = "ShardCounterNumeric"
	self.minLevel = SHARDBAR_SHOW_LEVEL

	if IceHUD.WowVer >= 70000 then
		self.runeHeight = 23
		self.runeWidth = 26
		if IceHUD.WowVer >= 70200 then
			self.runeHeight = 27
			self.runeWidth = 22
		end
		self.runeCoords = AfflictionCoords
		self.unitPower = SPELL_POWER_SOUL_SHARDS
		self.unit = "player"
	end
end

function ShardCounter.prototype:Enable(core)
	if IceHUD.WowVer >= 70000 then
		self.numRunes = UnitPowerMax(self.unit, self.unitPower)

		if GetSpecialization() == SPEC_WARLOCK_DESTRUCTION then
			self.shouldShowUnmodified = true
			self.numericFormat = "%.1f"
			self.round = floor
		else
			self.shouldShowUnmodified = nil
			self.numericFormat = nil
			self.round = nil
		end
	end

	ShardCounter.super.prototype.Enable(self, core)

	if IceHUD.WowVer >= 50000 and IceHUD.WowVer < 70000 then
		self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdatePowerType")
		self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdatePowerType")
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdatePowerType")
		self:RegisterEvent("UNIT_POWER_FREQUENT", "UpdateRunePower")
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "UpdatePowerType")
		self:RegisterEvent("UNIT_MAXPOWER", "UpdatePowerType")
	end
	if IceHUD.WowVer < 70000 then
		self:UpdatePowerType()
	end
end

function ShardCounter.prototype:UpdateRunePower(event, arg1, arg2)
	if IceHUD.WowVer >= 50000 and IceHUD.WowVer < 70000 then
		if event == "UNIT_POWER_FREQUENT" and arg1 == self.unit then
			if CurrentSpec == SPEC_WARLOCK_DESTRUCTION and arg2 ~= "BURNING_EMBERS" then
				return
			elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY and arg2 ~= "DEMONIC_FURY" then
				return
			elseif CurrentSpec == SPEC_WARLOCK_AFFLICTION and arg2 ~= "SOUL_SHARDS" then
				return
			end
		end
	end

	if event == "PLAYER_ENTERING_WORLD" and IceHUD.WowVer < 70000 then
		self:UpdatePowerType(event)
	end

	ShardCounter.super.prototype.UpdateRunePower(self, event, arg1, arg2)
end

function ShardCounter.prototype:CheckGreenFire()
	if IsSpellKnown(WARLOCK_GREEN_FIRE) then
		self:Redraw();
		self:UnregisterEvent("SPELLS_CHANGED")
	end
end

function ShardCounter.prototype:UpdatePowerType(event)
	if IceHUD.WowVer >= 50000 then
		CurrentSpec = GetSpecialization()
	else
		-- all warlocks use shards in pre-5.0, so just act like our spec is affliction
		CurrentSpec = SPEC_WARLOCK_AFFLICTION
	end

	self.shouldShowUnmodified = false
	self.requiredSpec = CurrentSpec
	self.currentGrowMode = nil

	if CurrentSpec == SPEC_WARLOCK_AFFLICTION then
		self.runeCoords = AfflictionCoords
		self.unitPower = SPELL_POWER_SOUL_SHARDS

		local powerMax = UnitPowerMax(self.unit, self.unitPower)
		if powerMax == 0 then -- abort abort! this is bad.
			return
		end

		self.runeHeight = 23
		self.runeWidth = 26
		self.numRunes = powerMax
		self.numConsideredFull = 99

		if IceHUD.WowVer >= 50000 then
			if not IsPlayerSpell(WARLOCK_SOULBURN) then
				self.requiredSpec = nil
				self:RegisterEvent("SPELLS_CHANGED", "UpdatePowerType")
			else
				self:UnregisterEvent("SPELLS_CHANGED", "UpdatePowerType")
			end
		end
	elseif CurrentSpec == SPEC_WARLOCK_DESTRUCTION then
		self.runeCoords = DestructionCoords
		self.unitPower = SPELL_POWER_BURNING_EMBERS

		local powerMax = UnitPowerMax(self.unit, self.unitPower)
		if powerMax == 0 then -- abort abort! this is bad.
			return
		end

		self.shouldShowUnmodified = true
		self.runeHeight = 28
		self.runeWidth = 31
		self.unmodifiedMaxPerRune = MAX_POWER_PER_EMBER
		self.numRunes = powerMax
		self.numConsideredFull = self.numRunes
		self.currentGrowMode = self.growModes["height"]

		if not IsPlayerSpell(WARLOCK_BURNING_EMBERS) then
			self.requiredSpec = nil
			self:RegisterEvent("SPELLS_CHANGED", "UpdatePowerType")
		elseif not IsSpellKnown(WARLOCK_GREEN_FIRE) then
			self:RegisterEvent("SPELLS_CHANGED", "CheckGreenFire")
		else
			self:UnregisterEvent("SPELLS_CHANGED", "UpdatePowerType")
		end
	elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY then
		self.runeCoords = DemonologyCoords
		self.unitPower = SPELL_POWER_DEMONIC_FURY
		self.runeHeight = 28
		self.runeWidth = 93
		self.numRunes = 1
		self.numConsideredFull = 99
		self.currentGrowMode = self.growModes["width"]
	else
		self.requiredSpec = nil
		self:RegisterEvent("SPELLS_CHANGED", "UpdatePowerType")
	end

	self:CreateFrame()

	for i=self.numRunes + 1, #self.frame.graphical do
		self.frame.graphical[i]:Hide()
	end

	self:CheckValidSpec()
	for i=1, self.numRunes do
		self:SetupRuneTexture(i)
	end
	self:UpdateRunePower()
end

function ShardCounter.prototype:GetRuneMode()
	local CurrentRuneMode = ShardCounter.super.prototype.GetRuneMode(self)

	if CurrentSpec == SPEC_WARLOCK_DEMONOLOGY then
		if CurrentRuneMode ~= "Numeric" and CurrentRuneMode ~= "Graphical" then
			CurrentRuneMode = "Graphical"
		end
	end

	return CurrentRuneMode
end

function ShardCounter.prototype:GetOptions()
	local opts = ShardCounter.super.prototype.GetOptions(self)

	opts.hideBlizz.desc = L["Hides Blizzard shard frame and disables all events related to it.\n\nNOTE: Blizzard attaches the shard UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."]
	opts.displayMode.desc = L["Choose whether you'd like a graphical or numeric representation of the runes.\n\nNOTE: The color of 'Numeric' mode can be controlled by the ShardCounterNumeric color."]
	opts.flashWhenReady.desc = L["Shows a flash behind each shard when it becomes available."]

	return opts
end

function ShardCounter.prototype:GetDefaultSettings()
	local defaults =  ShardCounter.super.prototype.GetDefaultSettings(self)

	defaults["pulseWhenFull"] = false

	return defaults
end

function ShardCounter.prototype:GetRuneTexture(rune)
	if IceHUD.WowVer >= 70200 then
		return nil
	end

	if not rune or rune ~= tonumber(rune) then
		return
	end

	if CurrentSpec == SPEC_WARLOCK_DESTRUCTION then
		if IsSpellKnown(WARLOCK_GREEN_FIRE) then
			return "Interface\\PlayerFrame\\Warlock-DestructionUI-Green"
		else
			return "Interface\\PlayerFrame\\Warlock-DestructionUI"
		end
	elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY then
		return "Interface\\PlayerFrame\\Warlock-DemonologyUI"
	end

	return "Interface\\PlayerFrame\\UI-WarlockShard"
end

function ShardCounter.prototype:GetRuneAtlas(rune)
	return "Warlock-ReadyShard"
end

function ShardCounter.prototype:ShowBlizz()
	WarlockPowerFrame:Show()

	WarlockPowerFrame:GetScript("OnLoad")(WarlockPowerFrame)
end

function ShardCounter.prototype:HideBlizz()
	WarlockPowerFrame:Hide()

	WarlockPowerFrame:UnregisterAllEvents()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "WARLOCK" and IceHUD.WowVer >= 40000) then
	IceHUD.ShardCounter = ShardCounter:new()
end
