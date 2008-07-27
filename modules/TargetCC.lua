local AceOO = AceLibrary("AceOO-2.0")

-- needs to not be local so that we can inherit from it
TargetCC = AceOO.Class(IceUnitBar)

-- list of spell ID's for each CC type so we can avoid localization issues
local StunCCList = {
	-- kidney shot
	408,
	-- cheap shot
	1833,
	-- mace stun effect
	5530,
	-- shadowfury
	30283,
	-- hammer of justice
	853,
	-- impact
	12355,
	-- blackout
	15268,
	-- intimidation
	19577,
	-- charge stun
	7922,
	-- intercept stun
	30153,
	-- revenge stun
	12798,
	-- concussion blow
	12809,
	-- bash
	5211,
	-- pounce
	9005,
	-- improved concussive shot
	19407,
	-- starfire stun
	16922,
	-- war stomp
	20549
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
	-- Polymorph
	118,
	-- Polymorph: Pig
	28272,
	-- Polymorph: Turtle
	28271,
	-- Hibernate
	2637,
	-- Freezing Trap Effect
	3355,
	-- Chastise
	44041,
	-- Maim
	22570,
	-- Banish
	710,
	-- Shackle Undead
	9484,
	-- Cyclone
	33786,
	-- Chains of Ice
	45524,
	-- Hungering Cold
	49203
}

local FearCCList = {
	-- Psychic Scream
	8122,
	-- Fear
	5782,
	-- Howl of Terror
	5484
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

	self.debuffList = {}
	self:PopulateSpellList(self.debuffList, StunCCList, "Stun")
	self:PopulateSpellList(self.debuffList, IncapacitateCCList, "Incapacitate")
	self:PopulateSpellList(self.debuffList, FearCCList, "Fear")

	self.previousDebuff = nil
	self.previousDebuffTarget = nil
	self.previousDebuffTime = nil
end

-- grabs the list of CC's and pulls the localized spell name using the wow api
function TargetCC.prototype:PopulateSpellList(debuffListVar, ccList, ccName)
	local spellName

	for i=1,#ccList do
		spellName = GetSpellInfo(ccList[i])

		if spellName and spellName ~= "" then
			debuffListVar[spellName] = ccName
		end
	end
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetCC.prototype:Enable(core)
	TargetCC.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "UpdateTargetDebuffs")

	self:ScheduleRepeatingEvent(self.elementName, self.UpdateTargetDebuffs, 0.1, self)

	self:Show(false)
end

function TargetCC.prototype:Disable(core)
	TargetCC.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function TargetCC.prototype:GetDefaultSettings()
	local settings = TargetCC.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["shouldAnimate"] = false
	settings["desiredLerpTime"] = nil
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3
	settings["usesDogTagStrings"] = false

	return settings
end

-- OVERRIDE
function TargetCC.prototype:GetOptions()
	local opts = TargetCC.super.prototype.GetOptions(self)

	opts["shouldAnimate"] = nil
	opts["desiredLerpTime"] = nil
	opts["lowThreshold"] = nil
	opts["textSettings"].args["upperTextString"] = nil
	opts["textSettings"].args["lowerTextString"] = nil

	opts["alertParty"] = {
		type = "toggle",
		name = "Alert Party",
		desc = "Broadcasts crowd control effects you apply to your target via the party chat channel",
		get = function()
			return self.moduleSettings.alertParty
		end,
		set = function(v)
			self.moduleSettings.alertParty = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	return opts	
end
	
-- 'Protected' methods --------------------------------------------------------

function _GetMaxDebuffDuration(unitName, debuffNames)
	local i = 1
	local debuff, rank, texture, count, debuffType, duration, remaining = UnitDebuff(unitName, i)
	local result = {nil, nil, nil}

	while debuff do
		if debuffNames[debuff] then
			if result[0] then
				if result[2] < remaining then
					result = {debuff, duration, remaining}
				end
			else
				result = {debuff, duration, remaining}
			end
		end

		i = i + 1;

		debuff, rank, texture, count, debuffType, duration, remaining = UnitDebuff(unitName, i)
	end

	return unpack(result)
end

function TargetCC.prototype:UpdateTargetDebuffs()
	local name, duration, remaining = _GetMaxDebuffDuration(self.unit, self.debuffList)
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

		if (duration ~= nil) then
			self:UpdateBar(remaining / duration, "CC:" .. self.debuffList[name])
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
