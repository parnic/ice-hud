local AceOO = AceLibrary("AceOO-2.0")
local deformat = AceLibrary("Deformat-2.0")

local SPELLINTERRUPTOTHERSELF = SPELLINTERRUPTOTHERSELF
local SPELLFAILCASTSELF = SPELLFAILCASTSELF

IceCastBar = AceOO.Class(IceBarElement)


IceCastBar.Actions = { None = 0, Cast = 1, Channel = 2, Instant = 3, Success = 4, Failure = 5 }

IceCastBar.prototype.action = nil
IceCastBar.prototype.actionStartTime = nil
IceCastBar.prototype.actionDuration = nil
IceCastBar.prototype.actionMessage = nil
IceCastBar.prototype.unit = nil
IceCastBar.prototype.current = nil


-- Constructor --
function IceCastBar.prototype:init(name)
	IceCastBar.super.prototype.init(self, name)

	self:SetDefaultColor("CastCasting", 242, 242, 10)
	self:SetDefaultColor("CastChanneling", 117, 113, 161)
	self:SetDefaultColor("CastSuccess", 242, 242, 70)
	self:SetDefaultColor("CastFail", 1, 0, 0)
	self.unit = "player"

	self.delay = 0
	self.action = IceCastBar.Actions.None
end


-- 'Public' methods -----------------------------------------------------------

function IceCastBar.prototype:Enable(core)
	IceCastBar.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_SPELLCAST_SENT", "SpellCastSent") -- "player", spell, rank, target
	self:RegisterEvent("UNIT_SPELLCAST_START", "SpellCastStart") -- unit
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "SpellCastStop") -- unit
	
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "SpellCastFailed") -- unit
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "SpellCastInterrupted") -- unit

	self:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE", "CheckChatInterrupt")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "CheckChatInterrupt")

	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "SpellCastDelayed") -- unit
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "SpellCastSucceeded") -- "player", spell, rank

	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "SpellCastChannelStart") -- unit
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "SpellCastChannelUpdate") -- unit
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "SpellCastChannelStop") -- unit

	self:Show(false)
end


-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function IceCastBar.prototype:CreateFrame()
	IceCastBar.super.prototype.CreateFrame(self)
	
	self.frame.bottomUpperText:SetWidth(self.settings.gap + 30)
end



-- OnUpdate handler
function IceCastBar.prototype:OnUpdate()
	-- safety catch
	if (self.action == IceCastBar.Actions.None) then
		IceHUD:Debug("Stopping action ", self.action)
		self:StopBar()
		return
	end

	local time = GetTime()

	self:Update()
	self:SetTextAlpha()

	-- handle casting and channeling
	if (self.action == IceCastBar.Actions.Cast or self.action == IceCastBar.Actions.Channel) then
		local remainingTime = self.actionStartTime + self.actionDuration - time
		local scale = 1 - (remainingTime / self.actionDuration)

		if (self.action == IceCastBar.Actions.Channel) then
			scale = remainingTime / self.actionDuration
		end

		if (remainingTime < 0) then
			self:StopBar()
		end
		
		-- sanity check to make sure the bar doesn't over/underfill
		scale = scale > 1 and 1 or scale
		scale = scale < 0 and 0 or scale

		self:UpdateBar(scale, "CastCasting")
		self:SetBottomText1(string.format("%.1fs %s", remainingTime , self.actionMessage))

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


function IceCastBar.prototype:FlashBar(color, alpha, text, textColor)
	self.frame:SetAlpha(alpha)

	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor(color)
	end

	self.frame:SetStatusBarColor(r, g, b, 0.3)
	self.barFrame:SetStatusBarColor(self:GetColor(color, 0.8))

	self:SetScale(self.barFrame.bar, 1)
	self:SetBottomText1(text, textColor or "Text")
end


function IceCastBar.prototype:StartBar(action, message)
	self.action = action
	self.actionStartTime = GetTime()
	self.actionMessage = message
	
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
	if not (spell) then
		spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(self.unit)
	end
	
	
	if (startTime and endTime) then
		self.actionDuration = (endTime - startTime) / 1000
		
		-- set start time here in case we start to monitor a cast that is underway already
		self.actionStartTime = startTime / 1000
	else
		self.actionDuration = 1 -- instants/failures
	end
	
	if not (message) then
		self.actionMessage = spell .. self:GetShortRank(rank)
	end

	self:Show(true)
	self.frame:SetScript("OnUpdate", function() self:OnUpdate() end)
end


function IceCastBar.prototype:StopBar()
	self.action = IceCastBar.Actions.None
	self.actionStartTime = nil
	self.actionDuration = nil

	self:Show(false)
	self.frame:SetScript("OnUpdate", nil)
end


function IceCastBar.prototype:GetShortRank(rank)
	if (rank) then
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

function IceCastBar.prototype:SpellCastSent(unit, spell, rank, target)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastSent", unit, spell, rank, target)
end


function IceCastBar.prototype:SpellCastStart(unit, spell, rank)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastStart", unit, spell, rank)
	--UnitCastingInfo(unit)
	
	self:StartBar(IceCastBar.Actions.Cast)
	self.current = spell
end

function IceCastBar.prototype:SpellCastStop(unit, spell, rank)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastStop", unit, spell, self.current)
	
	-- ignore if not coming from current spell
	if (self.current and spell and self.current ~= spell) then
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


function IceCastBar.prototype:SpellCastFailed(unit)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastFailed", unit, self.current)
	
	self.current = nil
	
	-- determine if we want to show failed casts
	if (self.moduleSettings.flashFailures == "Never") then
		return
	elseif (self.moduleSettings.flashFailures == "Caster") then
		if (UnitPowerType("player") ~= 0) then -- 0 == mana user
			return
		end
	end
	
	self:StartBar(IceCastBar.Actions.Failure, "Failed")
end

function IceCastBar.prototype:CheckChatInterrupt(msg)
	local player, spell = deformat(msg, SPELLINTERRUPTOTHERSELF)
	IceHUD:Debug("CheckChatInterrupt", msg, self.current)

	if not player then
		player, spell = deformat(msg, SPELLFAILCASTSELF)
	end

	if player then
		self.current = nil
		self:StartBar(IceCastBar.Actions.Failure, "Interrupted")
	end
end

function IceCastBar.prototype:SpellCastInterrupted(unit)
	if (unit ~= self.unit) then return end
	IceHUD:Debug("SpellCastInterrupted", unit, self.current)
	
	self.current = nil
	
	self:StartBar(IceCastBar.Actions.Failure, "Interrupted")
end

function IceCastBar.prototype:SpellCastDelayed(unit, delay)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastDelayed", unit, UnitCastingInfo(unit))
	
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(self.unit)
	
	if (endTime and self.actionStartTime) then
		-- apparently this check is needed, got nils during a horrible lag spike
		self.actionDuration = endTime/1000 - self.actionStartTime
	end
end


function IceCastBar.prototype:SpellCastSucceeded(unit, spell, rank)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastSucceeded", unit, spell, rank)
	
	-- never show on channeled (why on earth does this event even fire when channeling starts?)
	if (self.action == IceCastBar.Actions.Channel) then
		return
	end
	
	-- ignore if not coming from current spell
	if (self.current and self.current ~= spell) then
		return
	end

	-- show after normal successfull cast
	if (self.action == IceCastBar.Actions.Cast) then
		self:StartBar(IceCastBar.Actions.Success, spell.. self:GetShortRank(rank))
		return
	end
	
	-- determine if we want to show instant casts
	if (self.moduleSettings.flashInstants == "Never") then
		return
	elseif (self.moduleSettings.flashInstants == "Caster") then
		if (UnitPowerType("player") ~= 0) then -- 0 == mana user
			return
		end
	end
	
	self:StartBar(IceCastBar.Actions.Success, spell.. self:GetShortRank(rank))
end



-------------------------------------------------------------------------------
-- CHANNELING SPELLS                                                         --
-------------------------------------------------------------------------------

function IceCastBar.prototype:SpellCastChannelStart(unit)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastChannelStart", unit)
	
	self:StartBar(IceCastBar.Actions.Channel)
end

function IceCastBar.prototype:SpellCastChannelUpdate(unit)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastChannelUpdate", unit, UnitChannelInfo(unit))
	
	local spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
	self.actionDuration = endTime/1000 - self.actionStartTime
end

function IceCastBar.prototype:SpellCastChannelStop(unit)
	if (unit ~= self.unit) then return end
	--IceHUD:Debug("SpellCastChannelStop", unit)
	
	self:StopBar()
end



