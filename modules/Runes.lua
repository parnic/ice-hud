local AceOO = AceLibrary("AceOO-2.0")

local Runes = AceOO.Class(IceElement)

-- blizzard cracks me up. the below block is copied verbatim from RuneFrame.lua ;)
--Readability == win
local RUNETYPE_BLOOD = 1;
local RUNETYPE_DEATH = 2;
local RUNETYPE_FROST = 3;
local RUNETYPE_CHROMATIC = 4;

-- setup the names to be more easily readable
Runes.prototype.runeNames = {
	[RUNETYPE_BLOOD] = "Blood",
	[RUNETYPE_DEATH] = "Unholy",
	[RUNETYPE_FROST] = "Frost",
	[RUNETYPE_CHROMATIC] = "Death",
}

Runes.prototype.runeSize = 25
-- blizzard has hardcoded 6 runes right now, so i'll do the same...see RuneFrame.xml
Runes.prototype.numRunes = 6

-- Constructor --
function Runes.prototype:init()
	Runes.super.prototype.init(self, "Runes")

	self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_BLOOD], 255, 0, 0)
	self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_DEATH], 0, 229, 0)
	self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_FROST], 88, 195, 239)
	-- todo: i guess i should figure out the chromatic rune's default color...set to white for now
	self:SetDefaultColor("Runes"..self.runeNames[RUNETYPE_CHROMATIC], 255, 255, 255)
	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function Runes.prototype:GetOptions()
	local opts = Runes.super.prototype.GetOptions(self)

	opts["vpos"] = {
		type = "range",
		name = "Vertical Position",
		desc = "Vertical Position",
		get = function()
			return self.moduleSettings.vpos
		end,
		set = function(v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -300,
		max = 300,
		step = 10,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hpos"] = {
		type = "range",
		name = "Horizontal Position",
		desc = "Horizontal Position",
		get = function()
			return self.moduleSettings.hpos
		end,
		set = function(v)
			self.moduleSettings.hpos = v
			self:Redraw()
		end,
		min = -500,
		max = 500,
		step = 10,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hideBlizz"] = {
		type = "toggle",
		name = "Hide Blizzard Frame",
		desc = "Hides Blizzard Rune frame and disables all events related to it",
		get = function()
			return self.moduleSettings.hideBlizz
		end,
		set = function(value)
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
-- todo: numeric mode isn't supported just yet...so these options are removed for now
--[[
	opts["runeFontSize"] = {
		type = "range",
		name = "Runes Font Size",
		desc = "Runes Font Size",
		get = function()
			return self.moduleSettings.runeFontSize
		end,
		set = function(v)
			self.moduleSettings.runeFontSize = v
			self:Redraw()
		end,
		min = 10,
		max = 40,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 33
	}

	opts["runeMode"] = {
		type = "text",
		name = "Display Mode",
		desc = "Show graphical or numeric runes",
		get = function()
			return self.moduleSettings.runeMode
		end,
		set = function(v)
			self.moduleSettings.runeMode = v
			self:Redraw()
		end,
		validate = { "Numeric", "Graphical" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34
	}
]]--
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

	return defaults
end


-- OVERRIDE
function Runes.prototype:Redraw()
	Runes.super.prototype.Redraw(self)
	
	self:CreateFrame()
end


-- OVERRIDE
function Runes.prototype:Enable(core)
	Runes.super.prototype.Enable(self, core)

	self:RegisterEvent("RUNE_POWER_UPDATE", "UpdateRunePower");
	self:RegisterEvent("RUNE_TYPE_UPDATE", "UpdateRuneType");

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

-- simply shows/hides the foreground rune when it becomes usable/unusable. this allows the background transparent rune to show only
function Runes.prototype:UpdateRunePower(rune, usable)
	if not rune or not self.frame.graphical or #self.frame.graphical < rune then
		return
	end

--	DEFAULT_CHAT_FRAME:AddMessage("Runes.prototype:UpdateRunePower: rune="..rune.." usable="..(usable and "yes" or "no").." GetRuneType(rune)="..GetRuneType(rune));

	if usable then
		self.frame.graphical[rune]:Show()
	else
		self.frame.graphical[rune]:Hide()
	end
end

function Runes.prototype:UpdateRuneType(rune)
--	DEFAULT_CHAT_FRAME:AddMessage("Runes.prototype:UpdateRuneType: rune="..rune.." GetRuneType(rune)="..GetRuneType(rune));

	if not rune or tonumber(rune) ~= rune or rune < 1 or rune > self.numRunes then
		return
	end

	local thisRuneName = self.runeNames[GetRuneType(rune)]

	self.frame.graphicalBG[rune]:SetStatusBarTexture(self:GetRuneTexture(thisRuneName))
	self.frame.graphicalBG[rune]:SetStatusBarColor(self:GetColor("Runes"..thisRuneName))

	self.frame.graphical[rune]:SetStatusBarTexture(self:GetRuneTexture(thisRuneName))
	self.frame.graphical[rune]:SetStatusBarColor(self:GetColor("Runes"..thisRuneName))
end

function Runes.prototype:GetRuneTexture(runeName)
	return "Interface\\PlayerFrame\\UI-PlayerFrame-DeathKnight-"..runeName
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

	self:Show(true)

	self:CreateRuneFrame()
end



function Runes.prototype:CreateRuneFrame()
	-- create numeric runes
	self.frame.numeric = self:FontFactory(self.moduleSettings.runeFontSize, nil, self.frame.numeric)

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	self.frame.numeric:Hide()

	if (not self.frame.graphicalBG) then
		self.frame.graphicalBG = {}
		self.frame.graphical = {}
	end

	for i=1, self.numRunes do
		self:CreateRune(i, GetRuneType(i), self.runeNames[GetRuneType(i)])
	end
end

function Runes.prototype:CreateRune(i, type, name)
	-- create backgrounds
	if (not self.frame.graphicalBG[i]) then
		self.frame.graphicalBG[i] = CreateFrame("StatusBar", nil, self.frame)

		self.frame.graphicalBG[i]:SetStatusBarTexture(self:GetRuneTexture(name))
	end

	self.frame.graphicalBG[i]:SetFrameStrata("BACKGROUND")
	self.frame.graphicalBG[i]:SetWidth(self.runeSize)
	self.frame.graphicalBG[i]:SetHeight(self.runeSize)
	-- hax for blizzard's swapping the unholy and frost rune placement on the default ui...
	local runeSwapI
	if i == 3 or i == 4 then
		runeSwapI = i + 2
	elseif i == 5 or i == 6 then
		runeSwapI = i - 2
	else
		runeSwapI = i
	end
	self.frame.graphicalBG[i]:SetPoint("TOPLEFT", (runeSwapI-1) * (self.runeSize-5) + (runeSwapI-1), 0)
	self.frame.graphicalBG[i]:SetAlpha(0.25)

	self.frame.graphicalBG[i]:SetStatusBarColor(self:GetColor("Runes"..name))

	-- create runes
	if (not self.frame.graphical[i]) then
		self.frame.graphical[i] = CreateFrame("StatusBar", nil, self.frame)

		self.frame.graphical[i]:SetStatusBarTexture(self:GetRuneTexture(name))
	end
	self.frame.graphical[i]:SetFrameStrata("BACKGROUND")
	self.frame.graphical[i]:SetAllPoints(self.frame.graphicalBG[i])

	self.frame.graphical[i]:SetStatusBarColor(self:GetColor("Runes"..name))

	self.frame.graphical[i]:Show()
end

function Runes.prototype:ShowBlizz()
	RuneFrame:Show()

	RuneFrame:RegisterEvent("RUNE_POWER_UPDATE");
	RuneFrame:RegisterEvent("RUNE_TYPE_UPDATE");
	RuneFrame:RegisterEvent("RUNE_REGEN_UPDATE");
	RuneFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
end


function Runes.prototype:HideBlizz()
	RuneFrame:Hide()

	RuneFrame:UnregisterAllEvents()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "DEATHKNIGHT") then
	IceHUD.Runes = Runes:new()
end