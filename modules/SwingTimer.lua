local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local SwingTimer = IceCore_CreateClass(IceBarElement)

-- WoW Forever reports every swing itself, so the bar is driven by the client's own timing.
-- Everywhere else it has to be inferred: the combat log says when a swing landed and
-- UnitAttackSpeed says how long the next one takes.
local nativeSwingTypes = IceHUD.HasNativeSwingTimer and {
	MainHand = Enum.PlayerSwingType.MainHand,
	OffHand = Enum.PlayerSwingType.OffHand,
	Ranged = Enum.PlayerSwingType.Ranged,
} or nil

-- Where isOffHand sits, after the eleven arguments every combat log event starts with.
--
-- SWING_MISSED is a plain suffix event, so its position is fixed: missType, isOffHand.
--
-- SWING_DAMAGE is not. It is an advanced-log event, and MoP inserts seventeen parameters
-- between the base arguments and the payload, so a fixed 21 lands inside that block on 5.x and
-- later rather than on isOffHand. The .toc covers 50504, where this path is the one that runs
-- (no Enum.PlayerSwingType, and the secret environment that rules the combat log out is retail
-- only), and a number read from the advanced block is truthy, so every main-hand swing would
-- have looked like an off-hand one and the bar would never have started there.
--
-- Nothing is inserted AFTER the payload, so for SWING_DAMAGE the last argument is the one
-- position that holds on every flavour.
local LAST_ARGUMENT = true
local offHandArg = {
	SWING_DAMAGE = LAST_ARGUMENT,
	SWING_MISSED = 13,
}

-- Ranged is only offered where the client reports it; nothing in the combat log says when
-- an auto shot went out, and UnitRangedDamage alone cannot tell you where in the cycle you are.
local handNames = {
	MainHand = L["Main Hand"],
	OffHand = L["Off Hand"],
}
if IceHUD.HasNativeSwingTimer then
	handNames.Ranged = L["Ranged"]
end

-- Constructor --
function SwingTimer.prototype:init()
	SwingTimer.super.prototype.init(self, "SwingTimer")

	self.unit = "player"
	self.startTime = nil
	self.duration = nil

	self:SetDefaultColor("SwingTimer", 0.9, 0.6, 0.1)
end

-- OVERRIDE
function SwingTimer.prototype:Enable(core)
	SwingTimer.super.prototype.Enable(self, core)

	self.unitGUID = UnitGUID(self.unit)

	if IceHUD.HasNativeSwingTimer then
		self:RegisterEvent("PLAYER_SWING", "PlayerSwing")
	else
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "CombatLogEvent")
		self:RegisterEvent("UNIT_ATTACK_SPEED", "AttackSpeedChanged")
	end

	self:Show(false)

	self.frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
end

-- OVERRIDE
function SwingTimer.prototype:GetDefaultSettings()
	local settings = SwingTimer.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 7
	settings["shouldAnimate"] = false
	settings["hideAnimationSettings"] = true
	settings["lowThreshold"] = 0
	settings["usesDogTagStrings"] = false
	settings["bHideMarkerSettings"] = true
	settings["bAllowExpand"] = false
	settings["hand"] = "MainHand"
	settings["showRemaining"] = true

	return settings
end

-- OVERRIDE
function SwingTimer.prototype:GetOptions()
	local opts = SwingTimer.super.prototype.GetOptions(self)

	opts["lowThreshold"] = nil

	opts["hand"] = {
		type = 'select',
		name = L["Weapon"],
		desc = L["Which weapon's swing to track"],
		values = handNames,
		get = function()
			return self.moduleSettings.hand
		end,
		set = function(info, v)
			self.moduleSettings.hand = v
			self:StopSwing()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 21,
	}

	opts["showRemaining"] = {
		type = 'toggle',
		name = L["Show time remaining"],
		desc = L["Whether to print the seconds left until the next swing under the bar."],
		get = function()
			return self.moduleSettings.showRemaining
		end,
		set = function(info, v)
			self.moduleSettings.showRemaining = v
			if not v then
				self:SetBottomText1()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 22,
	}

	return opts
end

-- The bar fills as the next swing recharges, so a full bar is the normal resting state
-- between swings rather than something to fade out.
function SwingTimer.prototype:IsFull(scale)
	return false
end

-- Falls back to the main hand so a profile carrying Ranged over from a Forever client
-- still resolves to something this one can track.
function SwingTimer.prototype:TrackedHand()
	local hand = self.moduleSettings.hand
	return handNames[hand] and hand or "MainHand"
end

-- Length of the tracked weapon's swing, for the clients that do not report it per swing.
function SwingTimer.prototype:GetSwingDuration()
	local mainSpeed, offSpeed = UnitAttackSpeed(self.unit)
	local speed = self:TrackedHand() == "OffHand" and offSpeed or mainSpeed
	return speed and speed > 0 and speed or nil
end

function SwingTimer.prototype:StartSwing(duration)
	if not duration or duration <= 0 then
		return
	end

	self.startTime = GetTime()
	self.duration = duration

	self:UpdateBar(0, "SwingTimer")
	self:Show(true)
	self:ConditionalSetupUpdate()
end

function SwingTimer.prototype:StopSwing()
	self.startTime = nil
	self.duration = nil

	self:SetBottomText1()
	self:Show(false)
	IceHUD.IceCore:RequestUpdates(self, nil)
end

function SwingTimer.prototype:PlayerSwing(event, swingDuration, swingType)
	if swingType ~= nativeSwingTypes[self:TrackedHand()] then
		return
	end

	self:StartSwing(swingDuration)
end

function SwingTimer.prototype:CombatLogEvent()
	local _, subevent, _, sourceGUID = CombatLogGetCurrentEventInfo()
	local argIdx = offHandArg[subevent]
	if not argIdx or sourceGUID ~= self.unitGUID then
		return
	end

	if argIdx == LAST_ARGUMENT then
		argIdx = select("#", CombatLogGetCurrentEventInfo())
	end

	local isOffHand = select(argIdx, CombatLogGetCurrentEventInfo()) and true or false
	if isOffHand ~= (self:TrackedHand() == "OffHand") then
		return
	end

	self:StartSwing(self:GetSwingDuration())
end

-- Haste that lands mid-swing stretches or shrinks what is left of it rather than restarting
-- the swing, so keep the elapsed fraction and re-scale around it.
function SwingTimer.prototype:AttackSpeedChanged(event, unit)
	if unit ~= self.unit or not self.startTime or not self.duration then
		return
	end

	local newDuration = self:GetSwingDuration()
	if not newDuration or newDuration <= 0 then
		return
	end

	local elapsed = GetTime() - self.startTime
	local remaining = (self.duration - elapsed) * (newDuration / self.duration)

	self.duration = newDuration
	self.startTime = GetTime() - (newDuration - remaining)
end

-- OVERRIDE
function SwingTimer.prototype:MyOnUpdate()
	SwingTimer.super.prototype.MyOnUpdate(self)

	if not self.startTime or not self.duration then
		return
	end

	local remaining = self.startTime + self.duration - GetTime()
	if remaining <= 0 then
		self:StopSwing()
		return
	end

	self:UpdateBar(IceHUD:Clamp((self.duration - remaining) / self.duration, 0, 1), "SwingTimer")

	if self.moduleSettings.showRemaining then
		self:SetBottomText1(string.format("%.1f", remaining))
	end
end

function SwingTimer.prototype:CreateFrame()
	SwingTimer.super.prototype.CreateFrame(self)

	self:SetBarColorRGBA(self:GetColor("SwingTimer", 0.8))
end

function SwingTimer.prototype:ToggleMoveHint()
	local enabled = SwingTimer.super.prototype.ToggleMoveHint(self)
	self:ToggleConfigMode(enabled)
	self:Redraw()
end

-- A swing that is still running stays up when config mode ends.
function SwingTimer.prototype:ToggleConfigMode(enabled)
	self:Show(enabled or self.startTime ~= nil)
end

-- Load us up
if IceHUD.CanTrackSwings then
	IceHUD.SwingTimer = SwingTimer:new()
end
