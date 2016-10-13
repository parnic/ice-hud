local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Runes = IceCore_CreateClass(IceElement)

local IceHUD = _G.IceHUD

local CooldownFrame_SetTimer = CooldownFrame_SetTimer
if IceHUD.WowVer >= 70000 then
	CooldownFrame_SetTimer = CooldownFrame_Set
end

-- blizzard cracks me up. the below block is copied verbatim from RuneFrame.lua ;)
--Readability == win
local RUNETYPE_BLOOD = 1;
local RUNETYPE_DEATH = 2;
local RUNETYPE_FROST = 3;
local RUNETYPE_CHROMATIC = 4;
local RUNETYPE_LEGION = 5; -- not real, but makes for an easy update

local GetRuneType = GetRuneType
if IceHUD.WowVer >= 70000 then
	GetRuneType = function() return RUNETYPE_LEGION end
end

local RUNEMODE_DEFAULT = "Blizzard"
local RUNEMODE_NUMERIC = "Numeric"
local RUNEMODE_BAR = "Graphical Bar"
local RUNEMODE_CIRCLE = "Graphical Circle"
local RUNEMODE_GLOW = "Graphical Glow"
local RUNEMODE_CLEANCIRCLE = "Graphical Clean Circle"

-- setup the names to be more easily readable
Runes.prototype.runeNames = {
	[RUNETYPE_BLOOD] = "Blood",
	[RUNETYPE_DEATH] = "Unholy",
	[RUNETYPE_FROST] = "Frost",
	[RUNETYPE_CHROMATIC] = "Death",
	[RUNETYPE_LEGION] = "SingleRune",
}

Runes.prototype.runeSize = 25
-- blizzard has hardcoded 6 runes right now, so i'll do the same...see RuneFrame.xml
Runes.prototype.numRunes = 6

Runes.prototype.lastRuneState = {}

-- Constructor --
function Runes.prototype:init()
	Runes.super.prototype.init(self, "Runes")

	if IceHUD.WowVer < 70000 then
		self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_BLOOD], 255, 0, 0)
		self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_DEATH], 0, 207, 0)
		self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_FROST], 0, 255, 255)
		self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_CHROMATIC], 204, 26, 255)
	else
		self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_LEGION], 204, 204, 255)
	end
	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function Runes.prototype:GetOptions()
	local opts = Runes.super.prototype.GetOptions(self)

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
		desc = L["Hides Blizzard Rune frame and disables all events related to it"],
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
		name = L["Rune orientation"],
		desc = L["Whether the runes should draw side-by-side or on top of one another"],
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

	opts["cooldownMode"] = {
		type = 'select',
		name = L["Rune cooldown mode"],
		desc = L["Choose whether the runes use a cooldown-style wipe, simply an alpha fade to show availability or both."],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.cooldownMode)
		end,
		set = function(info, v)
			self.moduleSettings.cooldownMode = info.option.values[v]
			self:Redraw()
		end,
		values = { "Cooldown", "Alpha", "Both" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode ~= RUNEMODE_DEFAULT
		end,
		order = 36
	}

	opts["runeGap"] = {
		type = 'range',
		name = L["Rune gap"],
		desc = L["Spacing between each rune (only works for graphical mode)"],
		min = 0,
		max = 100,
		step = 1,
		get = function()
			return self.moduleSettings.runeGap
		end,
		set = function(info, v)
			self.moduleSettings.runeGap = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34.1
	}

	opts["runeMode"] = {
		type = 'select',
		name = L["Rune display mode"],
		desc = L["What graphical representation each rune should have. When setting to anything other than 'graphical', the module will behave more like combo points and simply show how many are active."],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.runeMode)
		end,
		set = function(info, v)
			self.moduleSettings.runeMode = info.option.values[v]
			self:ResetRuneAvailability()
			self:Redraw()
		end,
		values = { RUNEMODE_DEFAULT, RUNEMODE_NUMERIC, RUNEMODE_BAR, RUNEMODE_CIRCLE, RUNEMODE_GLOW, RUNEMODE_CLEANCIRCLE },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 35.5,
	}

	opts["showWhenNotFull"] = {
		type = 'toggle',
		name = L["Show when not full"],
		desc = L["Whether to show the Runes module any time the player has fewer than max runes available (regardless of combat/target status)."],
		get = function()
			return self.moduleSettings.showWhenNotFull
		end,
		set = function(info, v)
			self.moduleSettings.showWhenNotFull = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 38,
	}

	return opts
end


-- OVERRIDE
function Runes.prototype:GetDefaultSettings()
	local defaults =  Runes.super.prototype.GetDefaultSettings(self)

	defaults["vpos"] = 0
	defaults["hpos"] = 10
	defaults["runeFontSize"] = 20
	defaults["runeMode"] = "Graphical"
	defaults["usesDogTagStrings"] = false
	defaults["hideBlizz"] = true
	defaults["alwaysFullAlpha"] = false
	defaults["displayMode"] = "Horizontal"
	defaults["cooldownMode"] = "Cooldown"
	defaults["runeMode"] = RUNEMODE_DEFAULT
	defaults["runeGap"] = 0
	defaults["showWhenNotFull"] = false

	return defaults
end


-- OVERRIDE
function Runes.prototype:Redraw()
	Runes.super.prototype.Redraw(self)

	self:CreateFrame()
end


-- OVERRIDE
function Runes.prototype:Enable(core)
	if IceHUD.WowVer >= 70000 then
		self.numRunes = UnitPowerMax("player", SPELL_POWER_RUNES)
	end

	for i=1,self.numRunes do
		self.lastRuneState[i] = select(3, GetRuneCooldown(i))
	end

	Runes.super.prototype.Enable(self, core)

	self:RegisterEvent("RUNE_POWER_UPDATE", "UpdateRunePower")
	self:RegisterEvent("RUNE_TYPE_UPDATE", "UpdateRuneType")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ResetRuneAvailability")
	self:RegisterEvent("UNIT_MAXPOWER", "CheckMaxNumRunes")

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function Runes.prototype:Disable(core)
	Runes.super.prototype.Disable(self, core)

	if self.moduleSettings.hideBlizz then
		self:ShowBlizz()
	end
end

function Runes.prototype:CheckMaxNumRunes(event, unit, powerType)
	if unit ~= "player" then
		return
	end

	if UnitPowerMax("player", SPELL_POWER_RUNES) ~= self.numRunes then
		self.numRunes = UnitPowerMax("player", SPELL_POWER_RUNES)
		for i = 1, #self.frame.graphical do
			self.frame.graphical[i]:Hide()
		end
		self:Redraw()
	end
end

function Runes.prototype:ResetRuneAvailability()
	for i=1, self.numRunes do
		self:UpdateRunePower(nil, i, true)
	end
	self:Redraw()
end

-- simply shows/hides the foreground rune when it becomes usable/unusable. this allows the background transparent rune to show only
function Runes.prototype:UpdateRunePower(event, rune, dontFlash)
	if not rune or not self.frame.graphical or #self.frame.graphical < rune then
		return
	end

	if self.moduleSettings.runeMode == RUNEMODE_NUMERIC then
		self.frame.numeric:SetText(tostring(self:GetNumRunesAvailable()))
		return
	end

	local start, duration, usable = GetRuneCooldown(rune)

	local lastState = self.lastRuneState[rune]
	self.lastRuneState[rune] = usable

	if self.moduleSettings.runeMode ~= RUNEMODE_DEFAULT then
		if lastState == usable then
			return
		end

		if usable then
			for i=1,self.numRunes do
				if self.frame.graphical[i]:GetAlpha() == 0 then
					rune = i
					break
				end
			end
		else
			for i=1,self.numRunes do
				if self.frame.graphical[i]:GetAlpha() == 0 then
					break
				end
				rune = i
			end
		end
	end

--	print("Runes.prototype:UpdateRunePower: rune="..rune.." usable="..(usable and "yes" or "no").." GetRuneType(rune)="..GetRuneType(rune));

	if usable then
		if self.moduleSettings.cooldownMode == "Alpha" or self.moduleSettings.runeMode ~= RUNEMODE_DEFAULT then
			self.frame.graphical[rune]:SetAlpha(1)
		elseif self.moduleSettings.cooldownMode == "Cooldown" then
			self.frame.graphical[rune].cd:Hide()
		elseif self.moduleSettings.cooldownMode == "Both" then
			self.frame.graphical[rune].cd:Hide()
			self.frame.graphical[rune]:SetAlpha(1)
		end

		if not dontFlash then
			local fadeInfo={
				mode = "IN",
				timeToFade = 0.5,
				finishedFunc = function(rune) self:ShineFinished(rune) end,
				finishedArg1 = rune
			}
			UIFrameFade(self.frame.graphical[rune].shine, fadeInfo);
		end
	elseif start ~= nil and duration ~= nil then
		if self.moduleSettings.runeMode ~= RUNEMODE_DEFAULT then
			self.frame.graphical[rune]:SetAlpha(0)
		elseif self.moduleSettings.cooldownMode == "Cooldown" then
			CooldownFrame_SetTimer(self.frame.graphical[rune].cd, start, duration, true)
			self.frame.graphical[rune].cd:Show()
		elseif self.moduleSettings.cooldownMode == "Alpha" then
			self.frame.graphical[rune]:SetAlpha(0.2)
	 	elseif self.moduleSettings.cooldownMode == "Both" then
	 		CooldownFrame_SetTimer(self.frame.graphical[rune].cd, start, duration, true)
			self.frame.graphical[rune].cd:Show()
			self.frame.graphical[rune]:SetAlpha(0.2)
		end
	end

	self:Redraw()
end

function Runes.prototype:GetNumRunesAvailable()
	local available = 0

	for i=1,self.numRunes do
		if select(3, GetRuneCooldown(i)) then
			available = available + 1
		end
	end

	return available
end

function Runes.prototype:ShineFinished(rune)
	UIFrameFadeOut(self.frame.graphical[rune].shine, 0.5);
end

function Runes.prototype:UpdateRuneType(event, rune)
	IceHUD:Debug("Runes.prototype:UpdateRuneType: rune="..rune.." GetRuneType(rune)="..GetRuneType(rune));

	if not rune or tonumber(rune) ~= rune or rune < 1 or rune > self.numRunes then
		return
	end

	local thisRuneName = self.runeNames[GetRuneType(rune)]

	-- i have no idea how this could happen but it's been reported, so...
	if not thisRuneName then
		return
	end

	self.frame.graphical[rune].rune:SetTexture(self:GetRuneTexture(thisRuneName))
	self.frame.graphical[rune].rune:SetVertexColor(self:GetColor("Runes"..thisRuneName))
end

function Runes.prototype:GetRuneTexture(runeName)
	if self.moduleSettings.runeMode == RUNEMODE_DEFAULT and runeName then
		return "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-"..runeName
	elseif self.moduleSettings.runeMode == RUNEMODE_BAR then
		return IceElement.TexturePath .. "Combo"
	elseif self.moduleSettings.runeMode == RUNEMODE_CIRCLE then
		return IceElement.TexturePath .. "ComboRound"
	elseif self.moduleSettings.runeMode == RUNEMODE_GLOW then
		return IceElement.TexturePath .. "ComboGlow"
	elseif self.moduleSettings.runeMode == RUNEMODE_CLEANCIRCLE then
		return IceElement.TexturePath .. "ComboCleanCurves"
	end

	return ""
end

-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function Runes.prototype:CreateFrame()
	Runes.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.runeSize*self.numRunes)
	self.frame:SetHeight(1)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)

	self:CreateRuneFrame()
end



function Runes.prototype:CreateRuneFrame()
	-- create numeric runes
	if not self.frame.numeric then
		self.frame.numeric = self:FontFactory(self.moduleSettings.runeFontSize, self.frame)
	end

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	if self.moduleSettings.runeMode == RUNEMODE_NUMERIC then
		self.frame.numeric:Show()
	else
		self.frame.numeric:Hide()
	end

	if (not self.frame.graphical) then
		self.frame.graphical = {}
	end

	local runeType
	for i=1, self.numRunes do
		runeType = GetRuneType(i)

		-- Parnic debug stuff for arena rune problem
		--DEFAULT_CHAT_FRAME:AddMessage("i="..i.." GetRuneType(i)=="..(runeType and runeType or "nil").." self.runeNames[type]=="..(self.runeNames[runeType] and self.runeNames[runeType] or "nil"))

		-- runeType really shouldn't be nil here, but blizzard's code checks GetRuneType's return value, so I guess I should too...
		if runeType then
			self:CreateRune(i, runeType, self.runeNames[runeType])
		end
	end
end

function Runes.prototype:CreateRune(i, type, name)
	-- whiskey tango foxtrot?! apparently arenas can cause this? I can't test out the real cause myself, so putting in a stopgap for now
	if not name then
		return
	end

	-- create runes
	if (not self.frame.graphical[i]) then
		self.frame.graphical[i] = CreateFrame("Frame", nil, self.frame)
		self.frame.graphical[i].rune = self.frame.graphical[i]:CreateTexture(nil, "LOW")
		self.frame.graphical[i].rune:SetAllPoints(self.frame.graphical[i])
		self.frame.graphical[i].cd = CreateFrame("Cooldown", nil, self.frame.graphical[i], "CooldownFrameTemplate")
		self.frame.graphical[i].shine = self.frame.graphical[i]:CreateTexture(nil, "OVERLAY")
	end

	self.frame.graphical[i]:SetFrameStrata("BACKGROUND")
	self.frame.graphical[i]:SetWidth(self.runeSize)
	self.frame.graphical[i]:SetHeight(self.runeSize)

	-- hax for blizzard's swapping the unholy and frost rune placement on the default ui...
	local runeSwapI = i
	if IceHUD.WowVer < 70000 then
		if i == 3 or i == 4 then
			runeSwapI = i + 2
		elseif i == 5 or i == 6 then
			runeSwapI = i - 2
		else
			runeSwapI = i
		end
	end
	if self.moduleSettings.displayMode == "Horizontal" then
		self.frame.graphical[i]:SetPoint("TOPLEFT", (runeSwapI-1) * (self.runeSize-5) + (runeSwapI-1) + ((runeSwapI-1) * self.moduleSettings.runeGap), 0)
	else
		self.frame.graphical[i]:SetPoint("TOPLEFT", 0, -1 * ((runeSwapI-1) * (self.runeSize-5) + (runeSwapI-1) + ((runeSwapI-1) * self.moduleSettings.runeGap)))
	end

	local runeTex = self:GetRuneTexture(name)
	self.frame.graphical[i].rune:SetTexture(runeTex)
	self.frame.graphical[i].rune:SetVertexColor(self:GetColor("Runes"..name))
	if self.moduleSettings.runeMode ~= RUNEMODE_NUMERIC then
		self.frame.graphical[i]:Show()
	else
		self.frame.graphical[i]:Hide()
	end

	self.frame.graphical[i].cd:SetFrameStrata("BACKGROUND")
	self.frame.graphical[i].cd:SetFrameLevel(self.frame.graphical[i]:GetFrameLevel()+1)
	self.frame.graphical[i].cd:ClearAllPoints()
	self.frame.graphical[i].cd:SetAllPoints(self.frame.graphical[i])
	self.frame.graphical[i].cd:SetSwipeTexture(runeTex)
	self.frame.graphical[i].cd:SetDrawEdge(false)

	self.frame.graphical[i].shine:SetTexture("Interface\\ComboFrame\\ComboPoint")
	self.frame.graphical[i].shine:SetBlendMode("ADD")
	self.frame.graphical[i].shine:SetTexCoord(0.5625, 1, 0, 1)
	self.frame.graphical[i].shine:ClearAllPoints()
	self.frame.graphical[i].shine:SetPoint("CENTER", self.frame.graphical[i], "CENTER")
	self.frame.graphical[i].shine:SetWidth(self.runeSize + 25)
	self.frame.graphical[i].shine:SetHeight(self.runeSize + 10)
	self.frame.graphical[i].shine:Hide()
end

function Runes.prototype:GetAlphaAdd()
	return 0.15
end

function Runes.prototype:ShowBlizz()
	RuneFrame:Show()

	RuneFrame:GetScript("OnLoad")(RuneFrame)
	RuneFrame:GetScript("OnEvent")(frame, "PLAYER_ENTERING_WORLD")
	for i=1, self.numRunes do
		local frame = _G["RuneButtonIndividual"..i]
		if frame then
			frame:GetScript("OnLoad")(frame)
		end
	end
end

local function hook_playerframe()
	hooksecurefunc("PlayerFrame_HideVehicleTexture",function()
		if IceHUD.Runes.moduleSettings.hideBlizz then
			IceHUD.Runes:HideBlizz()
		end
	end)
	hook_playerframe = nil
end

function Runes.prototype:HideBlizz()
	RuneFrame:Hide()
	RuneFrame:UnregisterAllEvents()

	if hook_playerframe then
		hook_playerframe()
	end
end

function Runes.prototype:TargetChanged()
	Runes.super.prototype.TargetChanged(self)
	-- sort of a hack fix...if "ooc" alpha is set to 0, then the runes frame is all jacked up when the user spawns in
	-- need to re-run CreateFrame in order to setup the frame properly. not sure why :(
	self:Redraw()
end

function Runes.prototype:InCombat()
	Runes.super.prototype.InCombat(self)
	self:Redraw()
end

function Runes.prototype:OutCombat()
	Runes.super.prototype.OutCombat(self)
	self:Redraw()
end

function Runes.prototype:CheckCombat()
	Runes.super.prototype.CheckCombat(self)
	self:Redraw()
end

function Runes.prototype:UseTargetAlpha(scale)
	if not self.moduleSettings.showWhenNotFull then
		return Runes.super.prototype.UseTargetAlpha(scale)
	else
		return self:GetNumRunesAvailable() ~= self.numRunes
	end
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "DEATHKNIGHT") then
	IceHUD.Runes = Runes:new()
end
