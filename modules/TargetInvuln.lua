local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
-- needs to not be local so that we can inherit from it
TargetInvuln = IceCore_CreateClass(IceUnitBar)

TargetInvuln.prototype.buffName = nil
TargetInvuln.prototype.buffRemaining = 0
TargetInvuln.prototype.buffDuration = 0

local GetNumPartyMembers, GetNumRaidMembers = GetNumPartyMembers, GetNumRaidMembers
if GetNumGroupMembers then
	GetNumPartyMembers = GetNumGroupMembers
	GetNumRaidMembers = GetNumGroupMembers
end

local GetSpellInfo = GetSpellInfo
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
	GetSpellInfo = function(spellID)
		if not spellID then
			return nil
		end

		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo then
			return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
		end
	end
end

local GetSpellName = GetSpellInfo
if C_Spell and C_Spell.GetSpellName then
	GetSpellName = C_Spell.GetSpellName
end

-- list of spell ID's for each CC type so we can avoid localization issues
local InvulnList= {
	-- Anti-Magic Shell
	48707,
	-- Hand of Protection
	10278,
	-- Divine Shield
	642,
	-- Deterrence
	19263,
	-- Spell Reflection
	23920,
	-- Ice Block
	45438,
	-- Pain Suppression
	33206,
	-- Cloak of Shadows
	31224,
	-- Hand of Freedom
	1044,
	-- Dispersion
	47585,
	-- Bladestorm
	46924,
	-- Grounding Totem Effect
	8178,
	-- Aura Mastery
	31821,
	-- Lichborne
	49039,
	-- Killing Spree
	51690,
}



-- Constructor --
function TargetInvuln.prototype:init(moduleName, unit)
	-- not sure if this is necessary...i think it is...this way, we can instantiate this bar on its own or as a parent class
	if moduleName == nil or unit == nil then
		TargetInvuln.super.prototype.init(self, "TargetInvuln", "target")
	else
		TargetInvuln.super.prototype.init(self, moduleName, unit)
	end

	self.moduleSettings = {}
	self.moduleSettings.desiredLerpTime = 0
--	self.moduleSettings.shouldAnimate = false

	self:SetDefaultColor("CC:Invuln", 0.99, 0.99, 0.99)

	self.buffList = {}
	self:PopulateSpellList(self.buffList, InvulnList,"Invuln")

	self.previousbuff = nil
	self.previousbuffTarget = nil
	self.previousbuffTime = nil
end

-- grabs the list of CC's and pulls the localized spell name using the wow api
function TargetInvuln.prototype:PopulateSpellList(buffListVar, ccList, ccName)
	local spellName

	for i=1,#ccList do
		spellName = GetSpellName(ccList[i])

		if spellName and spellName ~= "" then
			buffListVar[spellName] = ccName
		end
	end
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetInvuln.prototype:Enable(core)
	TargetInvuln.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "UpdateTargetBuffs")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateTargetBuffs")

	self:Show(false)
end

function TargetInvuln.prototype:Disable(core)
	TargetInvuln.super.prototype.Disable(self, core)
end

-- OVERRIDE
function TargetInvuln.prototype:GetDefaultSettings()
	local settings = TargetInvuln.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["shouldAnimate"] = false
	settings["hideAnimationSettings"] = true
	settings["desiredLerpTime"] = nil
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 7
	settings["usesDogTagStrings"] = false

	return settings
end

-- OVERRIDE
function TargetInvuln.prototype:GetOptions()
	local opts = TargetInvuln.super.prototype.GetOptions(self)

	opts["lowThreshold"] = nil
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

	return opts
end

-- 'Protected' methods --------------------------------------------------------

function TargetInvuln.prototype:GetMaxbuffDuration(unitName, buffNames)
	local i = 1
	local buff, rank, texture, count, buffType, duration, endTime, unitCaster
	if IceHUD.SpellFunctionsReturnRank then
		buff, rank, texture, count, buffType, duration, endTime, unitCaster = IceHUD.UnitAura(unitName, i, "HELPFUL")
	else
		buff, texture, count, buffType, duration, endTime, unitCaster = IceHUD.UnitAura(unitName, i, "HELPFUL")
	end
	local isMine = unitCaster == "player"
	local result = {nil, nil, nil}
	local remaining

	while buff do
		remaining = endTime - GetTime()


		if (duration == 0) and (remaining<0) then

		duration =100000
		remaining =100000
		end

		if buffNames[buff] and (not self.moduleSettings.onlyShowForMybuffs or isMine) then
			if result[0] then
				if result[2] <= remaining then
					result = {buff, duration, remaining}
				end
			else
				result = {buff, duration, remaining}
			end
		end

		i = i + 1;

		if IceHUD.SpellFunctionsReturnRank then
			buff, rank, texture, count, buffType, duration, endTime, unitCaster = IceHUD.UnitAura(unitName, i, "HELPFUL")
		else
			buff, texture, count, buffType, duration, endTime, unitCaster = IceHUD.UnitAura(unitName, i, "HELPFUL")
		end
		isMine = unitCaster == "player"
	end

	return unpack(result)
end

function TargetInvuln.prototype:MyOnUpdate()
	TargetInvuln.super.prototype.MyOnUpdate(self)
	self:UpdateTargetBuffs("internal", self.unit)
end

function TargetInvuln.prototype:UpdateTargetBuffs(event, unit)
	local name, duration, remaining
	local isUpdate = event == "internal"

	if not isUpdate or not self.lastUpdateTime then
		self.buffName, self.buffDuration, self.buffRemaining = self:GetMaxbuffDuration(self.unit, self.buffList)
	else
		self.buffRemaining = math.max(0, self.buffRemaining - (GetTime() - self.lastUpdateTime))

		if self.buffRemaining <= 0 then
			self.buffName = nil
		end
	end
	self.lastUpdateTime = GetTime()

	name = self.buffName
	duration = self.buffDuration
	remaining = self.buffRemaining



	local targetName = UnitName(self.unit)

	if (name ~= nil) and (self.previousbuff == nil) and (duration ~= nil) and (remaining ~= nil) then
		if (duration > 1) and (self.moduleSettings.alertParty) and ((GetNumPartyMembers() >= 1) or (GetNumRaidMembers() >= 1)) then
			SendChatMessage(targetName .. ": " .. name .. " (" .. tostring(floor(remaining * 10) / 10) .. "/" .. tostring(duration) .. "s)", "PARTY")
		end

		self.previousbuff = name
		self.previousbuffTarget = targetName
		self.previousbuffTime = GetTime() + duration
	-- Parnic: Force the CurrScale to 1 so that the lerping doesn't make it animate up and back down
	self.CurrScale = 1.0
	elseif (self.previousbuff ~= nil) then
		if (targetName ~= self.previousbuffTarget) then
			self.previousbuff = nil
			self.previousbuffTarget = nil
			self.previousbuffTime = nil
		elseif (GetTime() > self.previousbuffTime) then
			self.previousbuff = nil
			self.previousbuffTarget = nil
			self.previousbuffTime = nil
		end
	end

	if (name ~= nil) then
		self:Show(true)

		if (duration ~= nil and duration >= 0) then
			self:UpdateBar(duration ~= 0 and remaining / duration or 0, "CC:" .. self.buffList[name])
			self:SetBottomText2(floor(remaining * 10) / 10)
		else
			self:UpdateBar(0, "CC:" .. self.buffList[name])
			self:SetBottomText2("")
		end

		self:SetBottomText1(name)
	else
		self:Show(false)
	end
end

-- Load us up
IceHUD.TargetInvuln = TargetInvuln:new()
