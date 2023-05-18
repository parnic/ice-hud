local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
-- needs to not be local so that we can inherit from it
TargetCC = IceCore_CreateClass(IceUnitBar)

TargetCC.prototype.debuffName = nil
TargetCC.prototype.debuffRemaining = 0
TargetCC.prototype.debuffDuration = 0

local GetNumPartyMembers, GetNumRaidMembers = GetNumPartyMembers, GetNumRaidMembers
if GetNumGroupMembers then
	GetNumPartyMembers = GetNumGroupMembers
	GetNumRaidMembers = GetNumGroupMembers
end

-- list of spell ID's for each CC type so we can avoid localization issues
local StunCCList = {
	-- kidney shot
	408,
	-- cheap shot
	1833,
	-- shadowfury
	30283,
	-- hammer of justice
	853,
	-- impact
	12355,
	-- blackout
	44415,
	-- intimidation
	19577,
	-- charge stun
	7922,
	-- concussion blow
	12809,
	-- bash
	5211,
	-- Maim
	203123,
	-- Rake
	163505,
	-- war stomp
	20549,
	-- deep freeze
	44572,
	-- shockwave
	46968,
	-- Gnaw
	91800,
	91797,
    -- Fists of Fury
    113656,
    -- Fist of Justice
    105593,
    -- Remorseless Winter
    115001,
    -- Between the Eyes
    199804,
}

local IncapacitateCCList = {
	-- Repentance
	20066,
	-- sap
	6770,
	-- gouge
	1776,
	-- blind
	2094,
	-- Wyvern Sting
	19386,
	-- Scatter Shot
	19503,
	-- Sleep
	700,
	-- Polymorph (rank 1)
	118,
	-- Also Polymorph
	65801,
	-- Polymorph rank 2
	12824,
	-- Polymorph rank 3
	12825,
	-- Polymorph rank 4
	12826,
	-- Polymorph: Pig
	28272,
	-- Also Polymorph: Pig
	28285,
	-- Polymorph: Turtle
	28271,
	-- Polymorph: Penguin
	59634,
	-- Polymorph: Monkey
	161354,
	-- Polymorph: Polar Bear Cub
	120137,
	-- Polymorph: Porcupine
	120140,
	-- Polymorph: Direhorn
	162625,
	-- Hibernate
	2637,
	-- Freezing Trap Effect
	3355,
	-- Holy Word: Chastise
	88625,
	-- Banish
	710,
	-- Shackle Undead
	9484,
	-- Cyclone
	33786,
	-- Hungering Cold
	49203,
	-- Seduction
	6358,
	-- Turn Evil
	10326,
    -- Paralysis
    115078,
}

local FearCCList = {
	-- Psychic Scream
	8122,
	-- Fear (Retail)
	118699,
	-- Fear
	5782,
	-- Howl of Terror
	5484,
	-- Death Coil
	6789,
	-- Intimidating Shout
	5246,
	-- Hex
	51514,
	-- Hex: Compy
	210873,
	-- Hex: Wicker Mongrel
	277784,
	-- Hex: Zandalari Tendonripper
	277778,
	-- Hex: Spider
	211004,
	-- Hex: Skeletal Hatchling
	269352,
	-- Scare Beast
	1513,
}

local SilenceCCList = {
	-- Avenger's Shield with Daze  (unsure, need to test if this is needed with the Glyph, otherwise 31935 covers it)
	63529,
	-- Avenger's Shield without Daze glyph
	31935,
	-- Silence
	15487,
	-- Silencing Shot
	34490,
	-- Spell Lock
	19647,
	-- Gag Order
	18498,
	-- Arcane Torrent
	50613,
	-- Arcane Torrent
	28730,
	-- Arcane Torrent
	25046,
	-- Improved Kick
	18425,
	-- Improved Counterspell
	55021,
	-- Strangulate
	47476,
	-- Garotte - Silence
	1330,
	-- Disarm
	676,
	-- Dismantle
	51722,
	-- Psychic Horror
	64058,
	-- Elemental Disruption (weapon enchant)
	74208,
    -- Grapple Weapon
    117368,
}

local RootCCList = {
	-- Entangling Roots
	339,
	-- Entangling Roots - Nature's Grasp
	16689,
	-- Frost Nova
	122,
	-- Earthbind Effect
	64695,
	-- Shattered Barrier
	55080,
	-- Imp Hamstring
	23694,
	-- Freeze
	33395,
	-- Entrapment 2 sec
	19185,
	-- Entrapment 4 sec
	64803,
	-- Web
	4167,
	-- Pin
	50245,
	-- Venom Web Spray
	54706,
	-- Chains of Ice
	96294,
    -- Disable
    116095,
}



-- Constructor --
function TargetCC.prototype:init(moduleName, unit)
	-- not sure if this is necessary...i think it is...this way, we can instantiate this bar on its own or as a parent class
	if moduleName == nil or unit == nil then
		TargetCC.super.prototype.init(self, "TargetCC", "target")
	else
		TargetCC.super.prototype.init(self, moduleName, unit)
	end

	self.moduleSettings = {}
	self.moduleSettings.desiredLerpTime = 0
--	self.moduleSettings.shouldAnimate = false

	self:SetDefaultColor("CC:Stun", 0.85, 0.55, 0.2)
	self:SetDefaultColor("CC:Incapacitate", 0.90, 0.6, 0.2)
	self:SetDefaultColor("CC:Fear", 0.85, 0.2, 0.65)
	self:SetDefaultColor("CC:Silence", 1, 0.5, 0.04)
	self:SetDefaultColor("CC:Root", .1, 0.5, 1)

	self.debuffList = {}
	self:PopulateSpellList(self.debuffList, StunCCList, "Stun")
	self:PopulateSpellList(self.debuffList, IncapacitateCCList, "Incapacitate")
	self:PopulateSpellList(self.debuffList, FearCCList, "Fear")
	self:PopulateSpellList(self.debuffList, SilenceCCList, "Silence")
	self:PopulateSpellList(self.debuffList, RootCCList, "Root")

	self.previousDebuff = nil
	self.previousDebuffTarget = nil
	self.previousDebuffTime = nil

	self.bTreatEmptyAsFull = true
end

-- grabs the list of CC's and pulls the localized spell name using the wow api
function TargetCC.prototype:PopulateSpellList(debuffListVar, ccList, ccName)
	local spellName

	for i=1,#ccList do
		spellName = GetSpellInfo(ccList[i])

		if spellName and spellName ~= "" then
			debuffListVar[spellName] = ccName
			debuffListVar[ccList[i]] = ccName
		end
	end
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetCC.prototype:Enable(core)
	TargetCC.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "UpdateTargetDebuffs")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateTargetDebuffs")

	self:Show(false)
end

function TargetCC.prototype:Disable(core)
	TargetCC.super.prototype.Disable(self, core)
end

-- OVERRIDE
function TargetCC.prototype:GetDefaultSettings()
	local settings = TargetCC.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["shouldAnimate"] = false
	settings["hideAnimationSettings"] = true
	settings["desiredLerpTime"] = nil
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 5
	settings["usesDogTagStrings"] = false
	settings["onlyShowForMyDebuffs"] = false

	return settings
end

-- OVERRIDE
function TargetCC.prototype:GetOptions()
	local opts = TargetCC.super.prototype.GetOptions(self)

	opts["lowThresholdColor"] = nil
	opts["textSettings"].args["upperTextString"] = nil
	opts["textSettings"].args["lowerTextString"] = nil

	opts["alertParty"] = {
		type = "toggle",
		name = L["Alert Party"],
		desc = L["Broadcasts crowd control effects you apply to your target via the party chat channel"],
		get = function()
			return self.moduleSettings.alertParty
		end,
		set = function(info, v)
			self.moduleSettings.alertParty = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	opts["onlyShowForMyDebuffs"] = {
		type = 'toggle',
		name = L["Only show for my debuffs"],
		desc = L["With this checked, the bar will only activate for your own CC spells and not those of others."],
		width = 'double',
		get = function()
			return self.moduleSettings.onlyShowForMyDebuffs
		end,
		set = function(info, v)
			self.moduleSettings.onlyShowForMyDebuffs = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	return opts
end

-- 'Protected' methods --------------------------------------------------------

function TargetCC.prototype:GetMaxDebuffDuration(unitName, debuffNames)
	local i = 1
	local debuff, rank, texture, count, debuffType, duration, endTime, unitCaster, _, _, spellId
	if IceHUD.SpellFunctionsReturnRank then
		debuff, rank, texture, count, debuffType, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, "HARMFUL")
	else
		debuff, texture, count, debuffType, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, "HARMFUL")
	end
	local isMine = unitCaster == "player"
	local result = {nil, nil, nil}
	local remaining

	while debuff do
		remaining = endTime - GetTime()

		if (debuffNames[spellId] or debuffNames[debuff]) and (not self.moduleSettings.onlyShowForMyDebuffs or isMine) then
			if result[0] then
				if result[2] < remaining then
					result = {debuff, duration, remaining}
				end
			else
				result = {debuff, duration, remaining}
			end
		end

		i = i + 1;

		if IceHUD.SpellFunctionsReturnRank then
			debuff, rank, texture, count, debuffType, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, "HARMFUL")
		else
			debuff, texture, count, debuffType, duration, endTime, unitCaster, _, _, spellId = UnitAura(unitName, i, "HARMFUL")
		end
		isMine = unitCaster == "player"
	end

	return unpack(result)
end

function TargetCC.prototype:MyOnUpdate()
	TargetCC.super.prototype.MyOnUpdate(self)
	self:UpdateTargetDebuffs("internal", self.unit)
end

function TargetCC.prototype:UpdateTargetDebuffs(event, unit)
	local name, duration, remaining
	local isUpdate = event == "internal"

	if not isUpdate or not self.lastUpdateTime then
		self.debuffName, self.debuffDuration, self.debuffRemaining = self:GetMaxDebuffDuration(self.unit, self.debuffList)
	else
		self.debuffRemaining = math.max(0, self.debuffRemaining - (GetTime() - self.lastUpdateTime))
		if self.debuffRemaining <= 0 then
			self.debuffName = nil
		end
	end
	self.lastUpdateTime = GetTime()

	name = self.debuffName
	duration = self.debuffDuration
	remaining = self.debuffRemaining

	local targetName = UnitName(self.unit)

	if (name ~= nil) and (self.previousDebuff == nil) and (duration ~= nil) and (remaining ~= nil) then
		if (duration > 1) and (self.moduleSettings.alertParty) and ((GetNumPartyMembers() >= 1) or (GetNumRaidMembers() >= 1)) then
			SendChatMessage(targetName .. ": " .. name .. " (" .. tostring(floor(remaining * 10) / 10) .. "/" .. tostring(duration) .. "s)", "PARTY")
		end

		self.previousDebuff = name
		self.previousDebuffTarget = targetName
		self.previousDebuffTime = GetTime() + duration
	-- Parnic: Force the CurrScale to 1 so that the lerping doesn't make it animate up and back down
	self.CurrScale = 1.0
	elseif (self.previousDebuff ~= nil) then
		if (targetName ~= self.previousDebuffTarget) then
			self.previousDebuff = nil
			self.previousDebuffTarget = nil
			self.previousDebuffTime = nil
		elseif (GetTime() > self.previousDebuffTime) then
			self.previousDebuff = nil
			self.previousDebuffTarget = nil
			self.previousDebuffTime = nil
		end
	end

	if (name ~= nil) then
		self:Show(true)

		if (duration ~= nil and duration > 0) then
			self:UpdateBar(duration ~= 0 and remaining / duration or 0, "CC:" .. self.debuffList[name])
			self:SetBottomText2(floor(remaining * 10) / 10)
		else
			self:UpdateBar(0, "CC:" .. self.debuffList[name])
			self:SetBottomText2("")
		end

		self:SetBottomText1(name)
	else
		self:Show(false)
	end
end

-- Load us up
IceHUD.TargetCC = TargetCC:new()
