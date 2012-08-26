local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ShardCounter = IceCore_CreateClass(IceClassPowerCounter)

local CurrentSpec = nil

function ShardCounter.prototype:init()
	ShardCounter.super.prototype.init(self, "Warlock Power")

	self:SetDefaultColor("ShardCounterNumeric", 218, 231, 31)

	self.numericColor = "ShardCounterNumeric"
	self.minLevel = SHARDBAR_SHOW_LEVEL
end

function ShardCounter.prototype:Enable(core)
	ShardCounter.super.prototype.Enable(self, core)

	if IceHUD.WowVer >= 50000 then
		self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdatePowerType")
		self:RegisterEvent("UNIT_POWER_FREQUENT", "UpdateRunePower")
	end
	self:UpdatePowerType()
end

function ShardCounter.prototype:UpdateRunePower(event, arg1, arg2)
	if IceHUD.WowVer >= 50000 then
		if event == "UNIT_POWER_FREQUENT" and arg1 == "player" then
			if CurrentSpec == SPEC_WARLOCK_DESTRUCTION and arg2 ~= "BURNING_EMBERS" then
				return
			elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY and arg2 ~= "DEMONIC_FURY" then
				return
			elseif CurrentSpec == SPEC_WARLOCK_AFFLICTION and arg2 ~= "SOUL_SHARDS" then
				return
			end
		end
	end

	ShardCounter.super.prototype.UpdateRunePower(self, event, arg1, arg2)
end

function ShardCounter.prototype:UpdatePowerType()
	if IceHUD.WowVer >= 50000 then
		CurrentSpec = GetSpecialization()
	else
		-- all warlocks use shards in pre-5.0, so just act like our spec is affliction
		CurrentSpec = SPEC_WARLOCK_AFFLICTION
	end
	self.shouldShowUnmodified = false
	if CurrentSpec == SPEC_WARLOCK_AFFLICTION then
		self.runeCoords =
		{
			{0.01562500, 0.28125000, 0.00781250, 0.13281250},
			{0.01562500, 0.28125000, 0.00781250, 0.13281250},
			{0.01562500, 0.28125000, 0.00781250, 0.13281250},
		}
		self.unitPower = SPELL_POWER_SOUL_SHARDS
		self.runeHeight = 23
		self.runeWidth = 26
	elseif CurrentSpec == SPEC_WARLOCK_DESTRUCTION then
		self.runeCoords =
		{
			{0.00390625, 0.14453125, 0.32812500, 0.93750000},
			{0.00390625, 0.14453125, 0.32812500, 0.93750000},
			{0.00390625, 0.14453125, 0.32812500, 0.93750000},
		}
		self.unitPower = SPELL_POWER_BURNING_EMBERS
		self.shouldShowUnmodified = true
		self.runeHeight = 28
		self.runeWidth = 31
		self.unmodifiedMaxPerRune = MAX_POWER_PER_EMBER
	elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY then
		self.runeCoords =
		{
			{0.00390625, 0.03125000, 0.09765625, 0.18359375},
			{0.00390625, 0.03125000, 0.09765625, 0.18359375},
			{0.00390625, 0.03125000, 0.09765625, 0.18359375},
		}
		self.unitPower = SPELL_POWER_DEMONIC_FURY
		self.runeHeight = 28
		self.runeWidth = 31
	end

	self:CreateFrame()
	for i=1, self.numRunes do
		self:SetupRuneTexture(i)
	end
	self:UpdateRunePower()
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
	if not rune or rune ~= tonumber(rune) then
		return
	end

	if CurrentSpec == SPEC_WARLOCK_DESTRUCTION then
		return "Interface\\PlayerFrame\\Warlock-DestructionUI"
	elseif CurrentSpec == SPEC_WARLOCK_DEMONOLOGY then
		return "Interface\\PlayerFrame\\Warlock-DemonologyUI"
	end

	return "Interface\\PlayerFrame\\UI-WarlockShard"
end

function ShardCounter.prototype:ShowBlizz()
	ShardBarFrame:Show()

	ShardBarFrame:GetScript("OnLoad")(ShardBarFrame)
end

function ShardCounter.prototype:HideBlizz()
	ShardBarFrame:Hide()

	ShardBarFrame:UnregisterAllEvents()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "WARLOCK" and IceHUD.WowVer >= 40000) then
	IceHUD.ShardCounter = ShardCounter:new()
end
