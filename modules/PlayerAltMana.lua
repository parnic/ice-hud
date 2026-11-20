local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerAltMana = IceCore_CreateClass(IceUnitBar)

PlayerAltMana.prototype.PlayerAltMana = nil
PlayerAltMana.prototype.PlayerAltManaMax = nil

local _, unitClass = UnitClass("player")

local SPELL_POWER_MANA = SPELL_POWER_MANA
local SPELL_POWER_INSANITY = SPELL_POWER_INSANITY
if Enum and Enum.PowerType then
	SPELL_POWER_MANA = Enum.PowerType.Mana
	SPELL_POWER_INSANITY = Enum.PowerType.Insanity
end

local canUseInsanity = unitClass == "PRIEST" and SPELL_POWER_INSANITY ~= nil
local swapPositionOptions = {"side", "offset", "barVerticalOffset", "barHorizontalAdjust"}

-- Constructor --
function PlayerAltMana.prototype:init()
	PlayerAltMana.super.prototype.init(self, "PlayerAltMana", "player")

	self.side = IceCore.Side.Right
	self.offset = 0

	self:SetDefaultColor("PlayerAltMana", 87, 82, 141)
end

function PlayerAltMana.prototype:GetDefaultSettings()
	local settings = PlayerAltMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 0
	settings["textVisible"] = {upper = true, lower = false}
	settings["upperText"] = "[PercentMana:Round]"
	settings["lowerText"] = "[FractionalMana:Color('3071bf'):Bracket]"
	settings["swapWithInsanity"] = true

	return settings
end

function PlayerAltMana.prototype:GetOptions()
	local opts = PlayerAltMana.super.prototype.GetOptions(self)

	opts["swapWithInsanity"] = {
		type = "toggle",
		name = L["Swap with Mana bar for Insanity"],
		desc = L["When your primary resource is Insanity, this bar and the Mana bar switch places so that your mana stays in the same spot."],
		width = 'double',
		get = function()
			return self.moduleSettings.swapWithInsanity
		end,
		set = function(info, value)
			self.moduleSettings.swapWithInsanity = value
			self:UpdateInsanitySwap()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return not canUseInsanity
		end,
		order = 30.02
	}

	self:HookSwapPositionOptions(opts)

	return opts
end

function PlayerAltMana.prototype:HookSwapPositionOptions(opts)
	if not canUseInsanity then
		return
	end

	for i = 1, #swapPositionOptions do
		local opt = opts[swapPositionOptions[i]]
		if opt and opt.set then
			local origSet = opt.set
			opt.set = function(...)
				origSet(...)
				if self:ShouldSwapWithPlayerMana() then
					self:RefreshSwappedBars()
				end
			end
		end
	end
end

function PlayerAltMana.prototype:ShouldSwapWithPlayerMana()
	local playerMana = IceHUD.PlayerMana
	return canUseInsanity
		and self.moduleSettings and self.moduleSettings.enabled and self.moduleSettings.swapWithInsanity
		and playerMana and playerMana.moduleSettings and playerMana.moduleSettings.enabled
		and playerMana.unit == "player"
		and UnitPowerType("player") == SPELL_POWER_INSANITY
		or false
end

function PlayerAltMana.prototype:GetBarPositionSettings()
	if self:ShouldSwapWithPlayerMana() then
		return IceHUD.PlayerMana.moduleSettings
	end

	return PlayerAltMana.super.prototype.GetBarPositionSettings(self)
end

function PlayerAltMana.prototype:UpdateInsanitySwap()
	local swapped = self:ShouldSwapWithPlayerMana()
	if swapped == self.insanitySwapped then
		return
	end

	self.insanitySwapped = swapped
	self:RefreshSwappedBars()
end

function PlayerAltMana.prototype:RefreshSwappedBars()
	local playerMana = IceHUD.PlayerMana
	if self.frame and self.moduleSettings.enabled then
		self:Redraw()
		self:Update()
	end
	if playerMana and playerMana.frame and playerMana.moduleSettings.enabled then
		playerMana:Redraw()
		playerMana:Update(playerMana.unit)
	end
end

function GetEventsToRegister()
	return {"UNIT_DISPLAYPOWER"}
--[[	if unitClass == "PRIEST" then
		return {"PLAYER_SPECIALIZATION_CHANGED"}
	elseif unitClass == "SHAMAN" then
		return {"PLAYER_SPECIALIZATION_CHANGED"}
	elseif unitClass == "DRUID" then
		return {"UPDATE_SHAPESHIFT_FORM"}
	end
]]-- probably not necessary, but could use as a fallback
end

function PlayerAltMana.prototype:Enable(core)
	PlayerAltMana.super.prototype.Enable(self, core)

	local eventsToRegister = GetEventsToRegister()
	for i = 1, #eventsToRegister do
		self:RegisterEvent(eventsToRegister[i], "Update")
	end
	self:RegisterEvent("UNIT_POWER_FREQUENT", "Update")
	self:RegisterEvent("UNIT_MAXPOWER", "Update")

	self:UpdateInsanitySwap()
end


function PlayerAltMana.prototype:Disable(core)
	PlayerAltMana.super.prototype.Disable(self, core)

	self:UpdateInsanitySwap()
end

function ShouldShow(unit)
	if unitClass == "MONK" then
		return IceHUD.GetSpecialization() == SPEC_MONK_MISTWEAVER
	end
	return UnitPowerType(unit) ~= SPELL_POWER_MANA
--[[	if unitClass == "PRIEST" then
		return UnitPowerType(unit) == SPELL_POWER_INSANITY
	elseif unitClass == "SHAMAN" then
		return IceHUD.GetSpecialization() ~= SPEC_SHAMAN_RESTORATION
	elseif unitClass == "DRUID" then
		return UnitPowerType(unit) ~= SPELL_POWER_MANA
	end
]]-- probably not necessary, but could use as a fallback
end

function PlayerAltMana.prototype:Update()
	PlayerAltMana.super.prototype.Update(self)

	self.PlayerAltMana = UnitPower(self.unit, SPELL_POWER_MANA)
	self.PlayerAltManaMax = UnitPowerMax(self.unit, SPELL_POWER_MANA)
	self.PlayerAltManaPercentage = UnitPowerPercent and UnitPowerPercent(self.unit, SPELL_POWER_MANA) or self.PlayerAltManaMax ~= 0 and (self.PlayerAltMana/self.PlayerAltManaMax) or 0

	if self:IsInConfigMode() then
		self:Show(true)
		return
	end

	if (not self.alive or not ShouldShow(self.unit) or not self.PlayerAltMana or not self.PlayerAltManaMax or self.PlayerAltManaMax == 0) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	if not IceHUD.IceCore:ShouldUseDogTags() and self.frame:IsVisible() then
		self:SetBottomText1(string.format("%.0f", UnitPowerPercent and UnitPowerPercent(self.unit, SPELL_POWER_MANA, true, CurveConstants.ScaleTo100) or math.floor(self.PlayerAltManaPercentage * 100)))

		if not IceHUD.CanAccessValue(self.PlayerAltManaMax) or self.PlayerAltManaMax ~= 100 then
			self:SetBottomText2(self:GetFormattedText(self:Round(self.PlayerAltMana), self:Round(self.PlayerAltManaMax)), "PlayerMana")
		else
			self:SetBottomText2()
		end
	end

	self:UpdateBar(self.PlayerAltManaPercentage, "PlayerAltMana")
end

function PlayerAltMana.prototype:IsPowerBar()
	return SPELL_POWER_MANA
end

if (unitClass == "PRIEST" and IceHUD.WowVer >= 70000)
	or (unitClass == "DRUID")
	or (unitClass == "SHAMAN" and IceHUD.WowVer >= 70000)
	or (unitClass == "MONK" and IceHUD.WowVer < 70000) then
	IceHUD.PlayerAltMana = PlayerAltMana:new()
end
