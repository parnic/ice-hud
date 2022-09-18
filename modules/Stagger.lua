local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local StaggerBar = IceCore_CreateClass(IceUnitBar)
local IceHUD = _G.IceHUD

local tostring = tostring
local floor = math.floor
local min = math.min
local strform = string.format

local playerName = ""
local LightID = 124275
local ModerateID = 124274
local HeavyID = 124273
local StaggerID = 124255
local staggerNames = {"", "", ""}
local staggerIds = {LightID, ModerateID, HeavyID}

local MinLevel = 10

StaggerBar.prototype.StaggerDuration = 0
StaggerBar.prototype.StaggerEndTime = 0

function StaggerBar.prototype:init()
	StaggerBar.super.prototype.init(self, "Stagger", "player")

	self:SetDefaultColor("Stagger1", 200, 180, 20)
	self:SetDefaultColor("Stagger2", 200, 90, 10)
	self:SetDefaultColor("Stagger3", 200, 0, 0)
	self:SetDefaultColor("StaggerTime", 255, 255, 255)

	self.bTreatEmptyAsFull = false
end

function StaggerBar.prototype:Redraw()
	StaggerBar.super.prototype.Redraw(self)

	self:MyOnUpdate()
end

function StaggerBar.prototype:GetDefaultSettings()
	local settings =  StaggerBar.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = true
	settings["shouldAnimate"] = true
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3
	settings["upperText"]=""
	settings["showAsPercentOfMax"] = true
	settings["maxPercent"] = 20
	settings["timerAlpha"] = 0.3
	settings["lockLowerFontAlpha"] = false
	settings["lowerTextString"] = ""
	settings["lowerTextVisible"] = false
	settings["hideAnimationSettings"] = true
	settings["bAllowExpand"] = true
	settings["bShowWithNoTarget"] = true
	settings["upperText"] = "[PercentStagger]"
	settings["lowerText"] = "[FractionalStagger:Short]"

	return settings
end

function StaggerBar.prototype:GetOptions()
	local opts = StaggerBar.super.prototype.GetOptions(self)

	opts.reverse.hidden = true

	opts["maxPercent"] =
	{
		type = "range",
		name = "Max Percent",
		desc = "Maximum percentage of your maximum health for the Stagger bar to represent. I.e, if set to 20%, the bar will be full when the Stagger damage over time effect is dealing 20% of your maximum health per second.",
		min = 0,
		max = 100,
		step = 1,
		get = function()
			return self.moduleSettings.maxPercent
		end,
		set = function(info, v)
			self.moduleSettings.maxPercent = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	opts["timerAlpha"] =
	{
		type = "range",
		name = "Timer bar alpha",
		desc = "What alpha value to use for the bar that displays how long until Stagger wears off.",
		min = 0,
		max = 100,
		step = 5,
		get = function()
			return self.moduleSettings.timerAlpha * 100
		end,
		set = function(info, v)
			self.moduleSettings.timerAlpha = v / 100
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	return opts
end

function StaggerBar.prototype:Enable(core)
	StaggerBar.super.prototype.Enable(self, core)

	playerName = UnitName(self.unit)
	staggerNames[1] = GetSpellInfo(LightID)
	staggerNames[2] = GetSpellInfo(ModerateID)
	staggerNames[3] = GetSpellInfo(HeavyID)

	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

	self:UpdateShown()
end

function StaggerBar.prototype:Disable(core)
	StaggerBar.super.prototype.Disable(self, core)
end

function StaggerBar.prototype:CreateFrame()
	StaggerBar.super.prototype.CreateFrame(self)
	self:CreateTimerBar()

	self:UpdateShown()
	self:UpdateAlpha()
end

function StaggerBar.prototype:CreateTimerBar()
	self.timerFrame = self:BarFactory(self.timerFrame, "MEDIUM","ARTWORK", "Timer")

	self.CurrScale = 0

	self.timerFrame.bar:SetVertexColor(self:GetColor("StaggerTime", self.moduleSettings.timerAlpha))
	self.timerFrame.bar:SetHeight(0)

	self:UpdateBar(1, "undef")
	self:UpdateTimerFrame()
end

function StaggerBar.prototype:UpdateShown()
	if GetSpecialization() == SPEC_MONK_BREWMASTER and not UnitInVehicle(self.unit) and UnitLevel(self.unit) >= MinLevel then
		self:Show(true)
	else
		self:Show(false)
	end
end

function StaggerBar.prototype:PLAYER_ENTERING_WORLD()
	self:TargetChanged()
	self:UpdateStaggerBar()
end

function StaggerBar.prototype:ACTIVE_TALENT_GROUP_CHANGED()
	self:UpdateStaggerBar()
end

function StaggerBar.prototype:GetDebuffInfo()
	if IceHUD.WowVer >= 70000 then
		self.amount = UnitStagger(self.unit) or 0
		self.staggerLevel = 1

		local healthMax = UnitHealthMax(self.unit)
		local percent = self.amount / healthMax
		if percent >= STAGGER_YELLOW_TRANSITION then
			self.staggerLevel = 2
		elseif percent >= STAGGER_RED_TRANSITION then
			self.staggerLevel = 3
		end
		return
	end

	local amount = 0
	local duration = 0
	local staggerLevel = 1

	for i = 1, IceCore.BuffLimit do
		local debuffID = select(IceHUD.SpellFunctionsReturnRank and 11 or 10, UnitDebuff(self.unit, i))

		if debuffID == LightID or debuffID == ModerateID or debuffID == HeavyID then
			local spellName = UnitDebuff(self.unit, i)

			duration = select(IceHUD.SpellFunctionsReturnRank and 6 or 5, UnitAura(self.unit, spellName, "", "HARMFUL"))
			amount = select(IceHUD.SpellFunctionsReturnRank and 15 or 14, UnitAura(self.unit, spellName, "", "HARMFUL"))
			staggerLevel = (debuffID == LightID) and 1 or (debuffID == ModerateID) and 2 or 3

			break
		end
	end

	self.amount = amount or 0
	self.duration = duration or 0
	self.staggerLevel = staggerLevel or 1
end

function StaggerBar.prototype:COMBAT_LOG_EVENT_UNFILTERED(...)
	local eventArgs = {...}
    if (CombatLogGetCurrentEventInfo) then
        eventArgs = {CombatLogGetCurrentEventInfo()}
    end

	if eventArgs[9] == playerName then
		if eventArgs[12] == StaggerID or eventArgs[2] == "SWING_DAMAGE" or eventArgs[2] == "SPELL_AURA_APPLIED" or eventArgs[2] == "SPELL_AURA_REMOVED" then
			self:UpdateStaggerBar()
		end
	end
end

function StaggerBar.prototype:UpdateStaggerBar()
	self:GetDebuffInfo()

	-- local health = UnitHealth(self.unit)
	local maxHealth = UnitHealthMax(self.unit)
	local scale = IceHUD:Clamp((self.amount / maxHealth) * (100 / self.moduleSettings.maxPercent), 0, 1)

	if self.amount > 0 and (IceHUD.WowVer >= 70000 or self.duration <= 10) then
		-- self.timerFrame.bar:SetVertexColor(self:GetColor("StaggerTime", self.moduleSettings.timerAlpha))
		self:UpdateBar(scale or 0, "Stagger"..self.staggerLevel)
		self:UpdateShown()
		self:UpdateTimerFrame()
	else
		self:UpdateBar(0, "Stagger1")
		self:Show(false)
	end
end

function StaggerBar.prototype:GetDebuffDuration(unitName, buffId)
	local name, _, duration, endTime
	if IceHUD.SpellFunctionsReturnRank then
		name, _, _, _, _, duration, endTime = UnitDebuff(unitName, buffName)
	else
		for i = 1, IceCore.BuffLimit do
			local id
			name, _, _, _, duration, endTime, _, _, _, id = UnitDebuff(unitName, i)

			if id == buffId then
				break
			end
		end
	end

	if name then
		return duration, endTime - GetTime()
	end

	return nil, nil
end

function StaggerBar.prototype:MyOnUpdate()
	StaggerBar.super.prototype.MyOnUpdate(self)

	if self.bUpdateTimer then
		self:UpdateTimerFrame(nil, self.unit, true)
	end
end

function StaggerBar.prototype:UpdateTimerFrame(event, unit, fromUpdate)
	if unit and unit ~= self.unit then
		return
	end

	local now = GetTime()
	local remaining = nil

	if not fromUpdate then
		for i = 1, 3 do
			self.StaggerDuration, remaining = self:GetDebuffDuration(self.unit, staggerIds[i])

			if remaining then
				break
			end
		end

		if not remaining then
			self.StaggerEndTime = 0
		else
			self.StaggerEndTime = remaining + now
		end
	end

	if self.StaggerEndTime and self.StaggerEndTime >= now then
		if not fromUpdate then
			self.bUpdateTimer = true
		end

		if not remaining and (self.StaggerEndTime and self.StaggerEndTime >= now) then
			remaining = self.StaggerEndTime - now
		end

		if remaining then
			self:SetBarCoord(self.timerFrame, IceHUD:Clamp(remaining / 10, 0, 1))
			self.timerFrame:Show()
		else
			self:SetBarCoord(self.timerFrame, 0)
			self.timerFrame:Hide()
		end
	else
		self:SetBarCoord(self.timerFrame, 0)
		self.timerFrame:Hide()
		self.bUpdateTimer = false
	end
end

local _, unitClass = UnitClass("player")
if unitClass == "MONK" then
	IceHUD.StaggerBar = StaggerBar:new()
end