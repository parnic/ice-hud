local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Totems = IceCore_CreateClass(IceElement)

local CooldownFrame_SetTimer = CooldownFrame_SetTimer
if CooldownFrame_Set then
	CooldownFrame_SetTimer = CooldownFrame_Set
end

-- the below block is copied from TotemFrame.lua
local FIRE_TOTEM_SLOT = 1;
local EARTH_TOTEM_SLOT = 2;
local WATER_TOTEM_SLOT = 3;
local AIR_TOTEM_SLOT = 4;

local MAX_TOTEMS = 4;

-- On some clients (WoW Forever) DestroyTotem() is protected and can't be called from addon code.
-- There we put invisible secure action buttons over the totem icons and let Blizzard's
-- "destroytotem" secure action do the work on right-click.
local UseSecureDestroy = IceHUD.UseSecureTotemButtons

local TOTEM_PRIORITIES =
{
	AIR_TOTEM_SLOT,
	WATER_TOTEM_SLOT,
	EARTH_TOTEM_SLOT,
	FIRE_TOTEM_SLOT
};

-- setup the names to be more easily readable
Totems.prototype.totemNames = {
	[FIRE_TOTEM_SLOT] = "Fire",
	[EARTH_TOTEM_SLOT] = "Earth",
	[WATER_TOTEM_SLOT] = "Water",
	[AIR_TOTEM_SLOT] = "Air",
}

Totems.prototype.totemSize = 25
Totems.prototype.numTotems = MAX_TOTEMS

-- Constructor --
function Totems.prototype:init()
	Totems.super.prototype.init(self, "Totems")
--[[
	self:SetDefaultColor("Totems"..self.totemNames[FIRE_TOTEM_SLOT], 0, 0, 0)
	self:SetDefaultColor("Totems"..self.totemNames[EARTH_TOTEM_SLOT], 0, 0, 0)
	self:SetDefaultColor("Totems"..self.totemNames[WATER_TOTEM_SLOT], 0, 255, 255)
	self:SetDefaultColor("Totems"..self.totemNames[AIR_TOTEM_SLOT], 204, 26, 255)--]]
	self.scalingEnabled = true
end
-- 'Public' methods -----------------------------------------------------------

function Totems.prototype:GetTotemInfo(totem)
	if self:IsInConfigMode() then
		return true, "config", GetTime() - 3, 1.5, "Interface\\Icons\\Spell_Frost_Frost"
	end

	if not GetTotemInfo then
		return
	end

	local haveTotem, name, startTime, duration, icon = GetTotemInfo(totem)
	return haveTotem, name, startTime, duration, icon
end

-- OVERRIDE
function Totems.prototype:GetOptions()
	local opts = Totems.super.prototype.GetOptions(self)

	self:AddDragMoveOption(opts, 30.91)

	opts["vpos"] = {
		type = "range",
		name = L["Vertical Position"],
		desc = L["Vertical Position"],
		get = function()
			return self.moduleSettings.vpos
		end,
		set = function(info, v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -300,
		max = 300,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hpos"] = {
		type = "range",
		name = L["Horizontal Position"],
		desc = L["Horizontal Position"],
		get = function()
			return self.moduleSettings.hpos
		end,
		set = function(info, v)
			self.moduleSettings.hpos = v
			self:Redraw()
		end,
		min = -500,
		max = 500,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hideBlizz"] = {
		type = "toggle",
		name = L["Hide Blizzard Frame"],
		desc = L["Hides Blizzard frame and disables all events related to it.\n\nNOTE: Blizzard attaches this UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything."],
		get = function()
			return self.moduleSettings.hideBlizz
		end,
		set = function(info, value)
			self.moduleSettings.hideBlizz = value
			if (value) then
				self:HideBlizz()
			else
				self:ShowBlizz()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["displayMode"] = {
		type = 'select',
		name = L["Totem orientation"],
		desc = L["Whether the totems should draw side-by-side or on top of one another"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.displayMode)
		end,
		set = function(info, v)
			self.moduleSettings.displayMode = info.option.values[v]
			self:Redraw()
		end,
		values = { "Horizontal", "Vertical" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 35
	}
--[[
	opts["cooldownMode"] = {
		type = 'select',
		name = L["Totem cooldown mode"],
		desc = L["Choose whether the totems use a cooldown-style wipe or simply an alpha fade to show availability."],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.cooldownMode)
		end,
		set = function(info, v)
			self.moduleSettings.cooldownMode = info.option.values[v]
			self:Redraw()
		end,
		values = { "Cooldown" }, -- "Alpha" not supported?
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 36
	}
]]--
	opts["totemGap"] = {
		type = 'range',
		name = L["Totem gap"],
		desc = L["Spacing between each totem (only works for graphical mode)"],
		min = 0,
		max = 100,
		step = 1,
		get = function()
			return self.moduleSettings.totemGap
		end,
		set = function(info, v)
			self.moduleSettings.totemGap = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34.1
	}

	opts["allowMouseClick"] = {
		type = 'toggle',
		name = L["Allow mouse interaction"],
		desc = L["Whether or not to allow the mouse to interact with the totems. If this is enabled, then right-clicking a totem will cancel it. Otherwise mouse clicks will not get caught by the totems and no tooltips will be shown."],
		get = function()
			return self.moduleSettings.allowMouseClick
		end,
		set = function(info, v)
			self.moduleSettings.allowMouseClick = v
			self:Redraw()
		end,
		order = 34.2
	}

	return opts
end

-- OVERRIDE
function Totems.prototype:GetDefaultSettings()
	local defaults =  Totems.super.prototype.GetDefaultSettings(self)

	defaults["vpos"] = 0
	defaults["hpos"] = 10
	defaults["totemFontSize"] = 20
	defaults["totemMode"] = "Graphical"
	defaults["usesDogTagStrings"] = false
	defaults["hideBlizz"] = IceHUD.CanHookDestroyTotem or IceHUD.UseSecureTotemButtons
	defaults["alwaysFullAlpha"] = false
	defaults["displayMode"] = "Horizontal"
	defaults["cooldownMode"] = "Cooldown"
	defaults["totemGap"] = 0
	defaults["allowMouseClick"] = true

	return defaults
end

-- OVERRIDE
function Totems.prototype:Redraw()
	Totems.super.prototype.Redraw(self)

	self:CreateFrame()
	self:ResetTotemAvailability()
end

-- OVERRIDE
function Totems.prototype:Enable(core)
	Totems.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_TOTEM_UPDATE", "UpdateTotem");
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringWorld");

	if self.moduleSettings.hideBlizz then
		self:HideBlizz()
	end

	if UseSecureDestroy then
		self:RegisterEvent("UI_SCALE_CHANGED", "QueueSecureOverlaySync")
		self:RegisterEvent("DISPLAY_SIZE_CHANGED", "QueueSecureOverlaySync")
		-- secure frames can't be created during combat lockdown, so make them up front
		-- (e.g. so a /reload in combat still leaves totems dismissable)
		for i = 1, self.numTotems do
			self:GetSecureOverlay(i)
		end
	end
end

function Totems.prototype:Disable(core)
	Totems.super.prototype.Disable(self, core)

	if self.moduleSettings.hideBlizz then
		self:ShowBlizz()
	end

	if self.secureOverlays then
		-- protected frames can't be hidden in combat; re-check (and hide) as soon as we're allowed to
		IceHUD:RunOnLeaveCombat(function()
			self:SyncSecureOverlays()
		end)
	end
end

function Totems.prototype:EnteringWorld()
	self:CheckCombat()
	self:Redraw()
	self:ResetTotemAvailability()
end

function Totems.prototype:ResetTotemAvailability()
	for i=1, self.numTotems do
		self:UpdateTotem(nil, i)
	end
end

function Totems.prototype:UpdateTotem(event, totem, ...)
	if not totem or tonumber(totem) ~= totem or totem < 1 or totem > self.numTotems then
		return
	end

	local haveTotem, name, startTime, duration, icon = self:GetTotemInfo(totem)
	local active = false
	if IceHUD.CanAccessValue(haveTotem) and not haveTotem then
		-- definitely an empty slot
	elseif IceHUD.CanAccessValue(duration) then
		if duration and duration > 0 then
			CooldownFrame_SetTimer(self.frame.graphical[totem].cd, startTime, duration, true)
			active = true
		end
	elseif GetTotemDuration then
		-- duration is a secret value (e.g. in combat): let the cooldown frame read it directly
		local durationObj = GetTotemDuration(totem)
		if durationObj then
			self.frame.graphical[totem].cd:SetCooldownFromDurationObject(durationObj)
			active = true
		end
	end

	if active then
		self.frame.graphical[totem].totem:SetTexture(icon)
		self.frame.graphical[totem].cd:Show()
		self.frame.graphical[totem]:Show()
		self.frame.graphical[totem].name = name
		self.frame.graphical[totem].isEmpty = false
	else
		self.frame.graphical[totem].cd:Hide()
		self.frame.graphical[totem].name = nil
		self.frame.graphical[totem].isEmpty = true
		if self:ShowEmptyTotemSlots() then
			self.frame.graphical[totem].totem:SetColorTexture(0, 0, 0, 0.5)
			self.frame.graphical[totem]:Show()
		else
			self.frame.graphical[totem]:Hide()
		end
	end

	if UseSecureDestroy then
		self:QueueSecureOverlaySync()
	end
end

-- Secure buttons can't be shown, hidden, or moved during combat, so every slot keeps its click button
-- for the whole fight. Draw empty slots as placeholders then so those buttons aren't invisible.
function Totems.prototype:ShowEmptyTotemSlots()
	return UseSecureDestroy and self.combat and self.moduleSettings.allowMouseClick
end

function Totems.prototype:ShowTotemTooltip(owner, slot)
	local g = self.frame.graphical[slot]
	if g and g.isEmpty then
		return
	end

	GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMRIGHT")
	if IceHUD.WowClassic or not GameTooltip.SetTotem then
		if g and g.name then
			GameTooltip:SetText(g.name)
		end
	else
		GameTooltip:SetTotem(slot)
	end
end

-- Secure right-click-to-dismiss overlays (see UseSecureDestroy) ---------------
--
-- These are parented/anchored to UIParent rather than to our own frames: anything a protected
-- frame is anchored to (or parented under) becomes protected as well, and this module moves,
-- shows and hides its frames during combat. The trade-off is that the overlays have to be
-- positioned by hand, and like any protected frame they can only be changed out of combat.

local GetCVarBool = (C_CVar and C_CVar.GetCVarBool) or GetCVarBool

local function GetClickEdge()
	-- secure action buttons act on either the down or the up edge depending on this CVar;
	-- register only that edge so a click can't fire the action twice
	if GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") then
		return "RightButtonDown"
	end
	return "RightButtonUp"
end

function Totems.prototype:GetSecureOverlay(i)
	self.secureOverlays = self.secureOverlays or {}
	local b = self.secureOverlays[i]
	if b or InCombatLockdown() then
		return b
	end

	b = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")
	b:RegisterForClicks(GetClickEdge())
	b:SetAttribute("*type2", "destroytotem")
	b:SetAttribute("totem-slot", i)
	b.slot = i
	b:SetScript("OnEnter", function(btn)
		local g = self.frame and self.frame.graphical and self.frame.graphical[btn.slot]
		if g and g:IsVisible() then
			self:ShowTotemTooltip(btn, btn.slot)
		end
	end)
	b:SetScript("OnLeave", function() GameTooltip:Hide() end)
	b:Hide()

	self.secureOverlays[i] = b
	return b
end

-- Places overlay i on top of totem icon i, or hides it when it shouldn't take clicks.
-- showAlways keeps it clickable even if that slot is empty right now: used when entering
-- combat, because an overlay can't be shown later for a totem dropped during combat.
function Totems.prototype:SyncSecureOverlay(i, showAlways)
	if InCombatLockdown() then
		return
	end

	local b = self:GetSecureOverlay(i)
	if not b then
		return
	end

	local g = self.frame and self.frame.graphical and self.frame.graphical[i]
	if not g or not self.moduleSettings.enabled or not self.moduleSettings.allowMouseClick
		or not self.frame:IsVisible() or self:IsInConfigMode()
		or (not showAlways and not self.combat and g:GetEffectiveAlpha() <= 0) then
		-- hidden HUD, config/move mode (where the move hint needs the mouse), or an icon that's
		-- faded out out of combat. (In combat the layout is locked in before alpha settles.)
		b:Hide()
		return
	end

	local left, bottom, width, height = g:GetRect()
	if left then
		local s = g:GetEffectiveScale() / UIParent:GetEffectiveScale()
		b:SetFrameStrata(g:GetFrameStrata())
		b:SetFrameLevel(g:GetFrameLevel() + 5)
		b:ClearAllPoints()
		b:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * s, bottom * s)
		b:SetWidth(width * s)
		b:SetHeight(height * s)
		b.placed = true
	elseif not b.placed then
		-- never laid out yet, so there's nowhere sensible to put it
		b:Hide()
		return
	end
	-- (if the rect is temporarily unavailable, keep the last known position)

	b:RegisterForClicks(GetClickEdge())

	if showAlways or g:IsShown() then
		b:Show()
	else
		b:Hide()
	end
end

function Totems.prototype:SyncSecureOverlays(showAlways)
	for i = 1, self.numTotems do
		self:SyncSecureOverlay(i, showAlways)
	end
end

-- Layout isn't resolved until the next frame after a Redraw, so batch everything into one
-- deferred sync. Requests during combat are dropped: OutCombat redraws, which re-syncs.
function Totems.prototype:QueueSecureOverlaySync()
	if self.overlaySyncQueued or InCombatLockdown() then
		return
	end
	self.overlaySyncQueued = true
	local function run()
		self.overlaySyncQueued = false
		self:SyncSecureOverlays(self.combat)
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0, run)
	else
		run()
	end
end

-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function Totems.prototype:CreateFrame()
	Totems.super.prototype.CreateFrame(self)

	self:CreateMoveHintFrame()

	self.frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
	self.frame:SetWidth(self.totemSize*self.numTotems)
	self.frame:SetHeight(28)
	self.frame:ClearAllPoints()
	self:SetFramePosition()

	if UseSecureDestroy and not self.overlayVisibilityHooked then
		-- e.g. the whole HUD being hidden for a pet battle or the barber shop
		self.overlayVisibilityHooked = true
		self.frame:HookScript("OnShow", function() self:QueueSecureOverlaySync() end)
		self.frame:HookScript("OnHide", function() self:QueueSecureOverlaySync() end)
	end

	self:CreateTotemFrame()
end

function Totems.prototype:CreateTotemFrame()
	self.frame.numeric = self:FontFactory(self.moduleSettings.totemFontSize, nil, self.frame.numeric)

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	self.frame.numeric:Hide()

	if (not self.frame.graphical) then
		self.frame.graphical = {}
	end

	for i=1, self.numTotems do
		local slot = TOTEM_PRIORITIES[i]
		self:CreateTotem(slot, self.totemNames[slot])
	end
end

function Totems.prototype:GetAlphaAdd()
	return 0.15
end

function Totems.prototype:ShowBlizz()
	if TotemFrame then
		TotemFrame:Show()
		TotemFrame:GetScript("OnLoad")(TotemFrame)
	end
end


function Totems.prototype:HideBlizz()
	if TotemFrame then
		TotemFrame:Hide()
		TotemFrame:UnregisterAllEvents()
	end
end

function Totems.prototype:TargetChanged()
	Totems.super.prototype.TargetChanged(self)
	-- sort of a hack fix...if "ooc" alpha is set to 0, then the runes frame is all jacked up when the user spawns in
	-- need to re-run CreateFrame in order to setup the frame properly. not sure why :(
	self:Redraw()
end

function Totems.prototype:InCombat()
	Totems.super.prototype.InCombat(self)
	self:Redraw()

	-- PLAYER_REGEN_DISABLED is the last chance before combat lockdown, so this can't wait for
	-- the deferred sync. Make every slot right-clickable so totems dropped during combat can
	-- be dismissed too. (Redraw just re-applied the same anchors, so the totem frames' rects
	-- are unchanged.)
	if UseSecureDestroy then
		self:SyncSecureOverlays(true)
	end
end

function Totems.prototype:OutCombat()
	Totems.super.prototype.OutCombat(self)
	self:Redraw()
end

function Totems.prototype:CheckCombat()
	Totems.super.prototype.CheckCombat(self)
	self:Redraw()
end

function Totems.prototype:CreateTotem(i, name)
	if not name then
		return
	end
	local haveTotem, name, startTime, duration, icon = self:GetTotemInfo(i)
	if (not self.frame.graphical[i]) then
		self.frame.graphical[i] = CreateFrame("Frame", nil, self.frame)
		self.frame.graphical[i].totem = self.frame.graphical[i]:CreateTexture(nil, "BACKGROUND")
		self.frame.graphical[i].cd = CreateFrame("Cooldown", nil, self.frame.graphical[i], "CooldownFrameTemplate")
		self.frame.graphical[i].shine = self.frame.graphical[i]:CreateTexture(nil, "OVERLAY")

		self.frame.graphical[i].totem:SetTexture(icon)
		self.frame.graphical[i].totem:SetAllPoints(self.frame.graphical[i])
	end

	self.frame.graphical[i]:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
	self.frame.graphical[i]:SetWidth(self.totemSize)
	self.frame.graphical[i]:SetHeight(self.totemSize)

	if self.moduleSettings.displayMode == "Horizontal" then
		self.frame.graphical[i]:SetPoint("TOPLEFT", (i-1) * (self.totemSize-(MAX_TOTEMS - 1)) + (i-1) + ((i-1) * self.moduleSettings.totemGap), 0)
	else
		self.frame.graphical[i]:SetPoint("TOPLEFT", 0, -1 * ((i-1) * (self.totemSize-(MAX_TOTEMS - 1)) + (i-1) + ((i-1) * self.moduleSettings.totemGap)))
	end

	if not self.graphicalOnEnter then
		self.graphicalOnEnter = function(button)
			self:ShowTotemTooltip(button, button.slot)
		end
	end
	if not self.graphicalOnLeave then
		self.graphicalOnLeave = function() GameTooltip:Hide() end
	end
	if not self.graphicalOnMouseUp then
		self.graphicalOnMouseUp = function (button, mouseButton)
			if mouseButton == "RightButton" then
				DestroyTotem(button.slot)
			end
		end
	end

	self.frame.graphical[i].cd:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
	self.frame.graphical[i].cd:SetFrameLevel(self.frame.graphical[i]:GetFrameLevel()+1)
	self.frame.graphical[i].cd:ClearAllPoints()
	self.frame.graphical[i].cd:SetAllPoints(self.frame.graphical[i])
	if not IceHUD.CanAccessValue(haveTotem) or (haveTotem and duration) then
		local hasDuration = true

		if not IceHUD.CanAccessValue(duration) and GetTotemDuration then
			local durationObj = GetTotemDuration(i)
			if durationObj then
				self.frame.graphical[i].cd:SetCooldownFromDurationObject(durationObj)
			else
				hasDuration = false
			end
		else
			self.frame.graphical[i].cd:SetCooldown(startTime, duration)
		end

		if hasDuration then
			self.frame.graphical[i].cd:Show()
			self.frame.graphical[i]:Show()
		end
	end

	self.frame.graphical[i].shine:SetTexture("Interface\\ComboFrame\\ComboPoint")
	self.frame.graphical[i].shine:SetBlendMode("ADD")
	self.frame.graphical[i].shine:SetTexCoord(0.5625, 1, 0, 1)
	self.frame.graphical[i].shine:ClearAllPoints()
	self.frame.graphical[i].shine:SetPoint("CENTER", self.frame.graphical[i], "CENTER")
	self.frame.graphical[i].shine:SetWidth(self.totemSize + 25)
	self.frame.graphical[i].shine:SetHeight(self.totemSize + 10)
	self.frame.graphical[i].shine:Hide()

	if UseSecureDestroy then
		-- the secure overlay button handles tooltip + right-click
		self.frame.graphical[i]:EnableMouse(false)
		self.frame.graphical[i]:SetScript("OnEnter", nil)
		self.frame.graphical[i]:SetScript("OnLeave", nil)
		self.frame.graphical[i]:SetScript("OnMouseUp", nil)
		self:QueueSecureOverlaySync()
	elseif self.moduleSettings.allowMouseClick then
		self.frame.graphical[i]:EnableMouse(true)
		self.frame.graphical[i]:SetScript("OnEnter", self.graphicalOnEnter)
		self.frame.graphical[i]:SetScript("OnLeave", self.graphicalOnLeave)
		if IceHUD.CanHookDestroyTotem then
			self.frame.graphical[i]:SetScript("OnMouseUp", self.graphicalOnMouseUp)
		end
	else
		self.frame.graphical[i]:EnableMouse(false)
		self.frame.graphical[i]:SetScript("OnEnter", nil)
		self.frame.graphical[i]:SetScript("OnLeave", nil)
		if IceHUD.CanHookDestroyTotem then
			self.frame.graphical[i]:SetScript("OnMouseUp", nil)
		end
	end
	self.frame.graphical[i].slot = i
	self.frame.graphical[i].name = name
end

-- Load us up
local _, unitClass = UnitClass("player")
if IceHUD.WowVer >= 90000 or (unitClass == "SHAMAN") or (unitClass == "DRUID") then
	IceHUD.Totems = Totems:new()
end
