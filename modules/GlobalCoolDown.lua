local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local GlobalCoolDown = IceCore_CreateClass(IceBarElement)

-- Constructor --
function GlobalCoolDown.prototype:init()
	GlobalCoolDown.super.prototype.init(self, "GlobalCoolDown")

	self.unit = "player"
	self.startTime = nil
	self.duration = nil

	self:SetDefaultColor("GlobalCoolDown", 0.1, 0.1, 0.1)
end

-- OVERRIDE
function GlobalCoolDown.prototype:Enable(core)
	GlobalCoolDown.super.prototype.Enable(self, core)

	if self.moduleSettings.inverse == "EXPAND" then
		self.moduleSettings.inverse = "NORMAL"
	end

	self:RegisterEvent("UNIT_SPELLCAST_SENT","SpellCastSent")

	--self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "CooldownStateChanged")
	self:RegisterEvent("UNIT_SPELLCAST_START","CooldownStateChanged")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START","CooldownStateChanged")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED","CooldownStateChanged")

	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP","SpellCastStop")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED","SpellCastStop")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED","SpellCastStop")
	self:RegisterEvent("UNIT_SPELLCAST_STOP","SpellCastStop")

	self:RegisterEvent("CVAR_UPDATE", "CVarUpdate")

	self:CVarUpdate()

	self:Show(false)

	self.frame:SetFrameStrata("LOW")

	self.CDSpellId = self:GetSpellId()
end

function GlobalCoolDown.prototype:CVarUpdate()
	self.useFixedLatency = self.moduleSettings.respectLagTolerance and GetCVar("reducedLagTolerance") == "1"
	local recoveryOffset = GetCVar("maxSpellStartRecoveryoffset")
	if recoveryOffset ~= nil then
		self.fixedLatency = tonumber(recoveryOffset) / 1000.0
	end
end

-- OVERRIDE
function GlobalCoolDown.prototype:GetDefaultSettings()
	local settings = GlobalCoolDown.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 6
	settings["shouldAnimate"] = true
	settings["hideAnimationSettings"] = true
	settings["desiredLerpTime"] = 1
	settings["lowThreshold"] = 0
	settings["barVisible"]["bg"] = false
	settings["usesDogTagStrings"] = false
	settings["bHideMarkerSettings"] = true
	settings["showDuringCast"] = true
	settings["barVisible"]["bg"] = false
	settings["bAllowExpand"] = false
	settings["lagAlpha"] = 0.7
	settings["respectLagTolerance"] = true

	return settings
end

-- OVERRIDE
function GlobalCoolDown.prototype:GetOptions()
	local opts = GlobalCoolDown.super.prototype.GetOptions(self)

	opts["lowThreshold"] = nil
	opts["textSettings"] = nil

	opts["showDuringCast"] = {
		type = 'toggle',
		name = L["Show during cast"],
		desc = L["Whether to show this bar when a spellcast longer than the global cooldown is being cast."],
		get = function()
			return self.moduleSettings.showDuringCast
		end,
		set = function(info, v)
			self.moduleSettings.showDuringCast = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 21,
	}

	opts["lagAlpha"] =
	{
		type = 'range',
		name = L["Lag Indicator alpha"],
		desc = L["Lag indicator alpha (0 is disabled)"],
		min = 0,
		max = 1,
		step = 0.1,
		get = function()
			return self.moduleSettings.lagAlpha
		end,
		set = function(info, value)
			self.moduleSettings.lagAlpha = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 42
	}

	opts["respectLagTolerance"] =
	{
		type = 'toggle',
		name = L["Respect lag tolerance"],
		desc = L["When checked, if a 'Custom Lag Tolerance' is set in the game's Combat options, the lag indicator will always use that tolerance value. Otherwise, it uses the computed latency."],
		get = function()
			return self.moduleSettings.respectLagTolerance
		end,
		set = function(info, value)
			self.moduleSettings.respectLagTolerance = value
			self:CVarUpdate()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or GetCVar("reducedLagTolerance") == "0"
		end,
		order = 42.1,
	}

	return opts
end

function GlobalCoolDown.prototype:IsFull(scale)
	return false
end

function GlobalCoolDown.prototype:SpellCastSent(event, unit, spell)
	if unit ~= "player" or not spell then
		return
	end

	self.spellCastSent = GetTime()
end

function GlobalCoolDown.prototype:SpellCastStop(event, unit, spell, _, _, spellId)
	if unit ~= "player" or not spellId or not self.CurrSpellId or self.CurrSpellId ~= spellId then
		return
	end

	self.CurrSpellId = nil

	if event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" then
		self.CurrLerpTime = self.moduleSettings.desiredLerpTime
	end
end

function GlobalCoolDown.prototype:GetSpellCastTime(spell)
	if not spell then
		return nil, nil
	end

	local spellname, castTime, _
	if IceHUD.WowVer < 60000 then
		spellName, _, _, _, _, _, castTime = GetSpellInfo(spell)
	else
		spellName, _, _, castTime = GetSpellInfo(spell)
	end

	if spellName == nil or spellName == "" then
		return nil, nil
	else
		return castTime
	end
end

function GlobalCoolDown.prototype:CooldownStateChanged(event, unit, spell, _, _, spellId)
	if unit ~= "player" or not spellId then
		return
	end

	-- Ignore all events unrelated to the spell currently being cast
	if self.CurrSpellId and self.CurrSpellId ~= spellId then
		return
	end

	-- Update the current spell ID for all events indicating a spellcast is starting
	if event ~= "UNIT_SPELLCAST_SUCCEEDED" then
		self.CurrSpellId = spellId
	end

	local start, dur = GetSpellCooldown(self.CDSpellId)

	if not self.moduleSettings.showDuringCast then
		local castTime = self:GetSpellCastTime(spellId)
		local channeledSpellName = UnitChannelInfo(unit)
		if (castTime and castTime >= dur*1000) or channeledSpellName then
			return
		end
	end

	if start and dur ~= nil and dur > 0 and dur <= 1.5 then
		local bRestart = not self.startTime or start > self.startTime + 0.5
		if bRestart then
			self.startTime = start
			self.duration = dur

			self:SetScale(1, true)
			self.LastScale = 1
			self.DesiredScale = 0
			self.CurrLerpTime = 0
			self.lastLerpTime = GetTime()
			self.moduleSettings.desiredLerpTime = dur or 1

			self:UpdateBar(0, "GlobalCoolDown")
			self:Show(true)

			-- Update latency indicator
			local scale = 0
			if self.useFixedLatency then
				scale = IceHUD:Clamp(self.fixedLatency / self.duration, 0, 1)
			else
				local now = GetTime()
				local lag = now - (self.spellCastSent or now)
				scale = IceHUD:Clamp(lag / self.duration, 0, 1)
			end

			self:SetBarCoord(self.lagBar, scale, false, true)
			self.spellCastSent = nil
		end
	end
end

function GlobalCoolDown.prototype:MyOnUpdate()
	GlobalCoolDown.super.prototype.MyOnUpdate(self)

	if self:IsVisible() and self.startTime ~= nil and self.duration ~= nil
		and self.CurrScale <= 0.01 then
		self:Show(false)
	end
end

function GlobalCoolDown.prototype:CreateFrame()
	GlobalCoolDown.super.prototype.CreateFrame(self)

	self.barFrame.bar:SetVertexColor(self:GetColor("GlobalCoolDown", 0.8))
	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	self.frame.bg:SetVertexColor(r, g, b, 0.6)

	self:CreateLagBar()
end

function GlobalCoolDown.prototype:CreateLagBar()
	self.lagBar = self:BarFactory(self.lagBar, "LOW", "OVERLAY")

	local r, g, b = self:GetColor("CastLag")
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor("CastCasting")
	end

	self.lagBar.bar:SetVertexColor(r, g, b, self.moduleSettings.lagAlpha)
	self.lagBar.bar:Hide()
end

function GlobalCoolDown.prototype:GetSpellId()
	return 61304
--[[
	local defaultSpells

	defaultSpells = {
		ROGUE=1752, -- sinister strike
		PRIEST=585, -- smite
		DRUID=5176, -- wrath
		WARRIOR=34428, -- victory rush (not available until 5, sadly)
		MAGE=44614, -- frostfire bolt
		WARLOCK=686, -- shadow bolt
		PALADIN=105361, -- seal of command (level 3)
		SHAMAN=403, -- lightning bolt
		HUNTER=3044, -- arcane shot
		DEATHKNIGHT=47541, -- death coil
		MONK=100780, -- jab
	}

	local _, unitClass = UnitClass("player")
	return defaultSpells[unitClass]
]]
end

-- Load us up
IceHUD.GlobalCoolDown = GlobalCoolDown:new()
