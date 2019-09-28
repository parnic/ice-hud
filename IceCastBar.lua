local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceCastBar = IceCore_CreateClass(IceBarElement)

local IceHUD = _G.IceHUD

IceCastBar.Actions = { None = 0, Cast = 1, Channel = 2, Instant = 3, Success = 4, Failure = 5 }

IceCastBar.prototype.action = nil
IceCastBar.prototype.actionStartTime = nil
IceCastBar.prototype.actionDuration = nil
IceCastBar.prototype.actionMessage = nil
IceCastBar.prototype.unit = nil
IceCastBar.prototype.current = nil

local SPELL_POWER_MANA = SPELL_POWER_MANA
if IceHUD.WowVer >= 80000 or IceHUD.WowClassic then
	SPELL_POWER_MANA = Enum.PowerType.Mana
end

local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
if IceHUD.WowClassic then
	UnitCastingInfo = CastingInfo
	UnitChannelInfo = ChannelInfo
end

-- Fulzamoth 2019-09-27 : Use LibClassicCasterino if it's there so we can use TargetCast 
--                        module in Classic WoW
if IceHUD.WowClassic then
	LibClassicCasterino = LibStub("LibClassicCasterino", true)
	UnitCastingInfo = function(unit)
		return LibClassicCasterino:UnitCastingInfo(unit)
	end
	UnitChannelInfo = function(unit)
		return LibClassicCasterino:UnitChannelInfo(unit)
	end
end
-- end Fulzamoth change

local AuraIconWidth = 20
local AuraIconHeight = 20

-- Constructor --
function IceCastBar.prototype:init(name)
	IceCastBar.super.prototype.init(self, name)

	self:SetDefaultColor("CastCasting", 242, 242, 10)
	self:SetDefaultColor("CastChanneling", 242, 242, 10)
	self:SetDefaultColor("CastSuccess", 242, 242, 70)
	self:SetDefaultColor("CastFail", 1, 0, 0)
	self.unit = "player"

	self.delay = 0
	self.action = IceCastBar.Actions.None
end


-- 'Public' methods -----------------------------------------------------------

function IceCastBar.prototype:Enable(core)
	IceCastBar.super.prototype.Enable(self, core)

	-- Fulzamoth 2019-09-27 : LibClassicCasterino support
	--                        Setup callback to the library, and route events to
	--                        IceHUD's handler functions.
	if LibClassicCasterino then
			local CastbarEventHandler = function(event, ...) -- unitTarget, castGUID, spellID
				if (event == "UNIT_SPELLCAST_START") then
					return IceCastBar.prototype.SpellCastStart(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_DELAYED") then
					return IceCastBar.prototype.SpellCastDelayed(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_STOP") then
					return IceCastBar.prototype.SpellCastStop(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_FAILED") then
					return IceCastBar.prototype.SpellCastFailed(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_INTERRUPTED") then
					return IceCastBar.prototype.SpellCastInterrupted(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_CHANNEL_START") then
					return IceCastBar.prototype.SpellCastChannelStart(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_CHANNEL_UPDATE") then
					return IceCastBar.prototype.SpellCastChannelUpdate(self, event, ...)
				elseif (event == "UNIT_SPELLCAST_CHANNEL_STOP") then
					return IceCastBar.prototype.SpellCastChannelStop(self, event, ...)
				end
			end
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_START", CastbarEventHandler) 
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_DELAYED", CastbarEventHandler) -- only for player
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_STOP", CastbarEventHandler)
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_FAILED", CastbarEventHandler)
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_INTERRUPTED", CastbarEventHandler)
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_CHANNEL_START", CastbarEventHandler)
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_CHANNEL_UPDATE", CastbarEventHandler) -- only for player
			LibClassicCasterino.RegisterCallback(self,"UNIT_SPELLCAST_CHANNEL_STOP", CastbarEventHandler)
	else -- No LibClassicCasterino, or we're not on Classic, so use IceHUD's normal event handlers.

		self:RegisterEvent("UNIT_SPELLCAST_SENT", "SpellCastSent") -- "player", spell, rank, target
		self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED", "SpellCastChanged")
		self:RegisterEvent("UNIT_SPELLCAST_START", "SpellCastStart") -- unit, spell, rank
		self:RegisterEvent("UNIT_SPELLCAST_STOP", "SpellCastStop") -- unit, spell, rank

		self:RegisterEvent("UNIT_SPELLCAST_FAILED", "SpellCastFailed") -- unit, spell, rank
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "SpellCastInterrupted") -- unit, spell, rank

		self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "SpellCastDelayed") -- unit, spell, rank
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "SpellCastSucceeded") -- "player", spell, rank

		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "SpellCastChannelStart") -- unit, spell, rank
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "SpellCastChannelUpdate") -- unit, spell, rank
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "SpellCastChannelStop") -- unit, spell, rank

	end
	self:Show(false)
end

function IceCastBar.prototype:GetDefaultSettings()
	local settings = IceCastBar.super.prototype.GetDefaultSettings(self)

	settings["showSpellRank"] = true
	settings["showCastTime"] = true
	settings["displayAuraIcon"] = false
	settings["auraIconXOffset"] = 40
	settings["auraIconYOffset"] = 0
	settings["auraIconScale"] = 1
	settings["reverseChannel"] = true

	return settings
end

function IceCastBar.prototype:GetOptions()
	local opts = IceCastBar.super.prototype.GetOptions(self)

	opts["showCastTime"] =
	{
		type = 'toggle',
		name = L["Show spell cast time"],
		desc = L["Whether or not to show the remaining cast time of a spell being cast."],
		get = function()
			return self.moduleSettings.showCastTime
		end,
		set = function(info, value)
			self.moduleSettings.showCastTime = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 39.998
	}
if IceHUD.WowVer < 80000 then
	opts["showSpellRank"] =
	{
		type = 'toggle',
		name = L["Show spell rank"],
		desc = L["Whether or not to show the rank of a spell being cast."],
		get = function()
			return self.moduleSettings.showSpellRank
		end,
		set = function(info, value)
			self.moduleSettings.showSpellRank = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 39.999
	}
end
	opts["iconSettings"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Icon Settings"].."|r",
		args = {
			displayAuraIcon = {
				type = 'toggle',
				name = L["Display aura icon"],
				desc = L["Whether or not to display an icon for the aura that this bar is tracking"],
				get = function()
					return self.moduleSettings.displayAuraIcon
				end,
				set = function(info, v)
					self.moduleSettings.displayAuraIcon = v
					if self.barFrame.icon then
						if v then
							self.barFrame.icon:Show()
						else
							self.barFrame.icon:Hide()
						end
					end
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 51,
			},

			auraIconXOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon horizontal offset"],
				desc = L["Adjust the horizontal position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconXOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconXOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 52,
			},

			auraIconYOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon vertical offset"],
				desc = L["Adjust the vertical position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconYOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconYOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 53,
			},

			auraIconScale = {
				type = 'range',
				min = 0.1,
				max = 3.0,
				step = 0.05,
				name = L["Aura icon scale"],
				desc = L["Adjusts the size of the aura icon for this bar"],
				get = function()
					return self.moduleSettings.auraIconScale
				end,
				set = function(info, v)
					self.moduleSettings.auraIconScale = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 54,
			},
		},
	}

	opts["reverseChannel"] = {
		type = 'toggle',
		name = L["Reverse channeling"],
		desc = L["Whether or not to reverse the direction of the cast bar when a spell is being channeled. For example, if a normal cast causes this bar to fill up, then checking this option will cause a channeled spell to empty the bar instead."],
		get = function()
			return self.moduleSettings.reverseChannel
		end,
		set = function(info, v)
			self.moduleSettings.reverseChannel = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32.5,
	}

	return opts
end

function IceCastBar.prototype:IsFull(scale)
	local retval = IceCastBar.super.prototype.IsFull(self, scale)
	if retval then
		if self.action and self.action ~= IceCastBar.Actions.None then
			return false
		end
	end
	return retval
end

-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function IceCastBar.prototype:CreateFrame()
	IceCastBar.super.prototype.CreateFrame(self)

	self.frame.bottomUpperText:SetWidth(self.settings.gap + 30)

	if not self.barFrame.icon then
		self.barFrame.icon = self.masterFrame:CreateTexture(nil, "OVERLAY")
		-- default texture so that 'config mode' can work without activating the bar first
		self.barFrame.icon:SetTexture("Interface\\Icons\\Spell_Frost_Frost")
		-- this cuts off the border around the buff icon
		self.barFrame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	end
	self:PositionIcons()
end

function IceCastBar.prototype:PositionIcons()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	self.barFrame.icon:ClearAllPoints()
	self.barFrame.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.moduleSettings.auraIconXOffset, self.moduleSettings.auraIconYOffset)
	self.barFrame.icon:SetWidth(AuraIconWidth * self.moduleSettings.auraIconScale)
	self.barFrame.icon:SetHeight(AuraIconHeight * self.moduleSettings.auraIconScale)
end



-- OnUpdate handler
function IceCastBar.prototype:MyOnUpdate()
	-- safety catch
	if (self.action == IceCastBar.Actions.None) then
		--IceHUD:Debug("Stopping action ", self.action)
		self:StopBar()
		return
	end

	local time = GetTime()

	self:Update()
	self:SetTextAlpha()

	-- handle casting and channeling
	if (self.action == IceCastBar.Actions.Cast or self.action == IceCastBar.Actions.Channel) then
		local remainingTime = self.actionStartTime + self.actionDuration - time
		local scale = 1 - (self.actionDuration ~= 0 and remainingTime / self.actionDuration or 0)

		if (self.moduleSettings.reverseChannel and self.action == IceCastBar.Actions.Channel) then
			scale = self.actionDuration ~= 0 and remainingTime / self.actionDuration or 0
		end

		self:UpdateBar(IceHUD:Clamp(scale, 0, 1), self:GetCurrentCastingColor())

		if (remainingTime <= 0) then
			self:StopBar()
		end

		local timeString = self.moduleSettings.showCastTime and string.format("%.1fs ", remainingTime) or ""
		self:SetBottomText1(timeString .. self.actionMessage)

		return
	end


	-- stop bar if casting or channeling is done (in theory this should not be needed)
	if (self.action == IceCastBar.Actions.Cast or self.action == IceCastBar.Actions.Channel) then
		self:StopBar()
		return
	end


	-- handle bar flashes
	if (self.action == IceCastBar.Actions.Instant or
		self.action == IceCastBar.Actions.Success or
		self.action == IceCastBar.Actions.Failure)
	then
		local scale = time - self.actionStartTime

		if (scale > 1) then
			self:StopBar()
			return
		end

		if (self.action == IceCastBar.Actions.Failure) then
			self:FlashBar("CastFail", 1-scale, self.actionMessage, "CastFail")
		else
			self:FlashBar("CastSuccess", 1-scale, self.actionMessage)
		end
		return
	end

	-- something went wrong
	IceHUD:Debug("OnUpdate error ", self.action, " -- ", self.actionStartTime, self.actionDuration, self.actionMessage)
	self:StopBar()
end

function IceCastBar.prototype:GetCurrentCastingColor()
	local updateColor = "CastCasting"
	if self.action == IceCastBar.Actions.Channel then
		updateColor = "CastChanneling"
	end
	return updateColor
end

function IceCastBar.prototype:FlashBar(color, alpha, text, textColor)
	self.frame:SetAlpha(alpha)

	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor(color)
	end

	self.frame.bg:SetVertexColor(r, g, b, 0.3)
	self.barFrame.bar:SetVertexColor(self:GetColor(color, 0.8))

	self:SetScale(1)
	self:SetBottomText1(text, textColor or "Text")
end


function IceCastBar.prototype:StartBar(action, message)
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill
	if IceHUD.WowVer < 80000 and not IceHUD.WowClassic then
		spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
	else
		spell, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
	end
	if not (spell) then
		if IceHUD.WowVer < 80000 and not IceHUD.WowClassic then
			spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(self.unit)
		else
			spell, displayName, icon, startTime, endTime = UnitChannelInfo(self.unit)
		end
	end

	-- Fulzamoth 2019-09-27 : LibClassicCasterino won't return spell info on target's failed or interrupted cast
	if LibClassicCasterino and not spell then
		self:StopBar()
	elseif not spell then
	  return
	end

	if icon ~= nil then
		self.barFrame.icon:SetTexture(icon)
	end

	if IceHUD.IceCore:IsInConfigMode() or self.moduleSettings.displayAuraIcon then
		self.barFrame.icon:Show()
	else
		self.barFrame.icon:Hide()
	end

	self.action = action
	self.actionStartTime = GetTime()
	self.actionMessage = message

	if (startTime and endTime) then
		self.actionDuration = (endTime - startTime) / 1000

		-- set start time here in case we start to monitor a cast that is underway already
		self.actionStartTime = startTime / 1000
	else
		self.actionDuration = 1 -- instants/failures
	end

	if not (message) then
		self.actionMessage = spell .. (self.moduleSettings.showSpellRank and self:GetShortRank(rank) or "")
	end

	self:Show(true)
	self:ConditionalSetupUpdate()
end


function IceCastBar.prototype:StopBar()
	self.action = IceCastBar.Actions.None
	self.actionStartTime = nil
	self.actionDuration = nil

	self:SetBottomText1()
	self:SetScale(0)
	self:Show(false)
end

function IceCastBar.prototype:GetShortRank(rank)
	if IceHUD.WowVer < 80000 and rank then
		local _, _, sRank = string.find(rank, "(%d+)")
		if (sRank) then
			return " (" .. sRank .. ")"
		end
	end
	return ""
end



-------------------------------------------------------------------------------
-- NORMAL SPELLS                                                             --
-------------------------------------------------------------------------------

function IceCastBar.prototype:SpellCastSent(event, unit, target, castGuid, spellId)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastSent", unit, target, castGuid, spellId)
end

function IceCastBar.prototype:SpellCastChanged(event, cancelled)
	IceHUD:Debug("SpellCastChanged", cancelled)
end

function IceCastBar.prototype:SpellCastStart(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastStart", unit, castGuid, spellId)
	--UnitCastingInfo(unit)

	self:StartBar(IceCastBar.Actions.Cast)
	self.current = castGuid
end

function IceCastBar.prototype:SpellCastStop(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastStop", unit, castGuid, spellId)

	-- ignore if not coming from current spell
	if (self.current and castGuid and self.current ~= castGuid) then
		return
	end

	if (self.action ~= IceCastBar.Actions.Success and
		self.action ~= IceCastBar.Actions.Failure and
		self.action ~= IceCastBar.Actions.Channel)
	then
		self:StopBar()
		self.current = nil
	end
end


function IceCastBar.prototype:SpellCastFailed(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastFailed", unit, castGuid, spellId)

	-- ignore if not coming from current spell
	if (self.current and castGuid and self.current ~= castGuid) then
		return
	end

	-- channeled spells will call ChannelStop, not cast failed
	if self.action == IceCastBar.Actions.Channel then
		return
	end

	self.current = nil

	-- determine if we want to show failed casts
	if (self.moduleSettings.flashFailures == "Never") then
		return
	elseif (self.moduleSettings.flashFailures == "Caster") then
		if (UnitPowerType("player") ~= SPELL_POWER_MANA) then
			return
		end
	end

	self:StartBar(IceCastBar.Actions.Failure, "Failed")
end

function IceCastBar.prototype:SpellCastInterrupted(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastInterrupted", unit, castGuid, spellId)

	-- ignore if not coming from current spell
	if (self.current and castGuid and self.current ~= castGuid) then
		return
	end

	self.current = nil

	self:StartBar(IceCastBar.Actions.Failure, "Interrupted")
end

function IceCastBar.prototype:SpellCastDelayed(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastDelayed", unit, UnitCastingInfo(unit))

	local endTime = select((IceHUD.WowVer < 80000 and not IceHUD.WowClassic) and 6 or 5, UnitCastingInfo(self.unit))

	if (endTime and self.actionStartTime) then
		-- apparently this check is needed, got nils during a horrible lag spike
		self.actionDuration = endTime/1000 - self.actionStartTime
	end
end


function IceCastBar.prototype:SpellCastSucceeded(event, unit, castGuid, spellId)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastSucceeded", unit, castGuid, spellId)

	-- never show on channeled (why on earth does this event even fire when channeling starts?)
	if (self.action == IceCastBar.Actions.Channel) then
		return
	end

	-- ignore if not coming from current spell
	if (self.current and self.current ~= castGuid) then
		return
	end

	local spell = GetSpellInfo(spellId)

	-- show after normal successfull cast
	if (self.action == IceCastBar.Actions.Cast) then
		self:StartBar(IceCastBar.Actions.Success, spell.. self:GetShortRank(rank))
		return
	end

	-- determine if we want to show instant casts
	if (self.moduleSettings.flashInstants == "Never") then
		return
	elseif (self.moduleSettings.flashInstants == "Caster") then
		if (UnitPowerType("player") ~= SPELL_POWER_MANA) then
			return
		end
	end

	self:StartBar(IceCastBar.Actions.Success, spell.. self:GetShortRank(rank))
end



-------------------------------------------------------------------------------
-- CHANNELING SPELLS                                                         --
-------------------------------------------------------------------------------

function IceCastBar.prototype:SpellCastChannelStart(event, unit)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastChannelStart", unit)

	self:StartBar(IceCastBar.Actions.Channel)
end

function IceCastBar.prototype:SpellCastChannelUpdate(event, unit)
	if (unit ~= self.unit or not self.actionStartTime) then return end
	--IceHUD:Debug("SpellCastChannelUpdate", unit, UnitChannelInfo(unit))

	local spell, rank, displayName, icon, startTime, endTime
	if IceHUD.WowVer < 80000 and not IceHUD.WowClassic then
		spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
	else
		spell, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
	end
    if not spell then
        self.actionDuration = 0
    else
        self.actionDuration = endTime/1000 - self.actionStartTime
    end
end

function IceCastBar.prototype:SpellCastChannelStop(event, unit)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastChannelStop", unit)

	self:StopBar()
end



