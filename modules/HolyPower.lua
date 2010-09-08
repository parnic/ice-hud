local AceOO = AceLibrary("AceOO-2.0")

local HolyPower = AceOO.Class(IceElement)

HolyPower.prototype.runeHeight = 22
HolyPower.prototype.runeWidth = 36
-- blizzard has hardcoded 3 runes right now, so i'll do the same...see PaladinPowerBar.lua
HolyPower.prototype.numRunes = 3
HolyPower.prototype.lastNumReady = 0

-- Constructor --
function HolyPower.prototype:init()
	HolyPower.super.prototype.init(self, "HolyPower")
	
	self:SetDefaultColor("HolyPowerNumeric", 218, 231, 31)

	self.scalingEnabled = true
end

-- pulled from PaladinPowerBar.xml in Blizzard's UI source
local runeCoords =
{
	{0.00390625, 0.14453125, 0.64843750, 0.82031250},
	{0.00390625, 0.12500000, 0.83593750, 0.96875000},
	{0.15234375, 0.25781250, 0.64843750, 0.81250000},
}

local HOLY_POWER_INDEX = 9
local runeShineFadeSpeed = 0.4

-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function HolyPower.prototype:GetOptions()
	local opts = HolyPower.super.prototype.GetOptions(self)

	opts["vpos"] = {
		type = "range",
		name = "Vertical Position",
		desc = "Vertical Position",
		get = function()
			return self.moduleSettings.vpos
		end,
		set = function(info, v)
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
		set = function(info, v)
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
		desc = "Hides Blizzard Holy Power frame and disables all events related to it.\n\nNOTE: Blizzard attaches the holy power UI to the player's unitframe, so if you have that hidden in PlayerHealth, then this won't do anything.",
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

	opts["runeMode"] = {
		type = 'select',
		name = 'Display mode',
		desc = "Choose whether you'd like a graphical or numeric representation of the runes.\n\nNOTE: The color of 'Numeric' mode can be controlled by the HolyPowerNumeric color.",
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.runeMode)
		end,
		set = function(info, v)
			self.moduleSettings.runeMode = info.option.values[v]
			self:SetDisplayMode()
			self:UpdateRunePower()
		end,
		values = { "Graphical", "Numeric" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34
	}

	opts["runeGap"] = {
		type = 'range',
		name = 'Rune gap',
		desc = 'Spacing between each rune (only works for graphical mode)',
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
		hidden = function()
			return self.moduleSettings.runeMode ~= "Graphical"
		end,
		order = 34.1
	}

	opts["displayMode"] = {
		type = 'select',
		name = 'Rune orientation',
		desc = 'Whether the runes should draw side-by-side or on top of one another',
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
		hidden = function()
			return self.moduleSettings.runeMode ~= "Graphical"
		end,
		order = 35
	}
	
	opts["inactiveDisplayMode"] = {
		type = 'select',
		name = 'Inactive mode',
		desc = "This controls what happens to runes that are inactive. Darkened means they are visible but colored black, Hidden means they are not displayed.",
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.inactiveDisplayMode)
		end,
		set = function(info, v)
			self.moduleSettings.inactiveDisplayMode = info.option.values[v]
			self:SetDisplayMode()
			self:UpdateRunePower()
		end,
		values = { "Darkened", "Hidden" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode ~= "Graphical"
		end,
		order = 36
	}

	opts["flashWhenReady"] = {
		type = "toggle",
		name = "Flash when ready",
		desc = "Shows a flash behind each holy rune when it becomes available.",
		get = function()
			return self.moduleSettings.flashWhenBecomingReady
		end,
		set = function(info, value)
			self.moduleSettings.flashWhenBecomingReady = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode ~= "Graphical"
		end,
		order = 37
	}

	return opts
end


-- OVERRIDE
function HolyPower.prototype:GetDefaultSettings()
	local defaults =  HolyPower.super.prototype.GetDefaultSettings(self)

	defaults["vpos"] = 0
	defaults["hpos"] = 10
	defaults["runeFontSize"] = 20
	defaults["runeMode"] = "Graphical"
	defaults["usesDogTagStrings"] = false
	defaults["hideBlizz"] = true
	defaults["alwaysFullAlpha"] = false
	defaults["displayMode"] = "Horizontal"
	defaults["runeGap"] = 0
	defaults["flashWhenBecomingReady"] = true
	defaults["inactiveDisplayMode"] = "Darkened"

	return defaults
end


-- OVERRIDE
function HolyPower.prototype:Redraw()
	HolyPower.super.prototype.Redraw(self)
	
	self:CreateFrame()
end


-- OVERRIDE
function HolyPower.prototype:Enable(core)
	HolyPower.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_POWER", "UpdateRunePower");
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdateRunePower");
	self:RegisterEvent("UNIT_AURA", "UpdateRunePower");
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRunePower");

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function HolyPower.prototype:UpdateRunePower()
	local numReady = UnitPower("player", HOLY_POWER_INDEX)
	
	if self.moduleSettings.runeMode == "Graphical" then
		for i=1, self.numRunes do
			if i <= numReady then
				self.frame.graphical[i].rune:SetVertexColor(1, 1, 1)

				if self.moduleSettings.inactiveDisplayMode == "Hidden" then
					self.frame.graphical[i]:Show()
				end

				if i > self.lastNumReady and self.moduleSettings.flashWhenBecomingReady then
					local fadeInfo={
						mode = "IN",
						timeToFade = runeShineFadeSpeed,
						finishedFunc = function() self:ShineFinished(i) end,
						finishedArg1 = i
					}
					UIFrameFade(self.frame.graphical[i].shine, fadeInfo);
				end
			else
				if self.moduleSettings.inactiveDisplayMode == "Darkened" then
					self.frame.graphical[i].rune:SetVertexColor(0, 0, 0)
				elseif self.moduleSettings.inactiveDisplayMode == "Hidden" then
					self.frame.graphical[i]:Hide()
				end
			end
		end
	elseif self.moduleSettings.runeMode == "Numeric" then
		self.frame.numeric:SetText(tostring(numReady))
		self.frame.numeric:SetTextColor(self:GetColor("HolyPowerNumeric"))
	end

	self.lastNumReady = numReady

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function HolyPower.prototype:ShineFinished(rune)
	UIFrameFadeOut(self.frame.graphical[rune].shine, runeShineFadeSpeed);
end

function HolyPower.prototype:GetRuneTexture(rune)
	if not rune or rune ~= tonumber(rune) then
		return
	end
	--return "Paladin-Rune0"..rune..".png"
	return "Interface\\PlayerFrame\\PaladinPowerTextures"
end


function HolyPower.prototype:CreateFrame()
	HolyPower.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.runeWidth*self.numRunes)
	self.frame:SetHeight(self.runeHeight)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)

	self:CreateRuneFrame()
	
	self:SetDisplayMode()
end

function HolyPower.prototype:SetDisplayMode()
	if self.moduleSettings.runeMode == "Graphical" then
		self.frame.numeric:Hide()
		for i=1, self.numRunes do
			self.frame.graphical[i]:Show()
		end
	elseif self.moduleSettings.runeMode == "Numeric" then
		self.frame.numeric:Show()
		for i=1, self.numRunes do
			self.frame.graphical[i]:Hide()
		end
	end
end

function HolyPower.prototype:CreateRuneFrame()
	-- create numeric runes
	self.frame.numeric = self:FontFactory(self.moduleSettings.runeFontSize, nil, self.frame.numeric)

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	self.frame.numeric:Hide()

	if (not self.frame.graphical) then
		self.frame.graphical = {}
	end

	for i=1, self.numRunes do
		self:CreateRune(i)
	end
end

function HolyPower.prototype:CreateRune(i)
	-- create runes
	if (not self.frame.graphical[i]) then
		self.frame.graphical[i] = CreateFrame("Frame", nil, self.frame)
		self.frame.graphical[i].rune = self.frame.graphical[i]:CreateTexture(nil, "LOW")
		self.frame.graphical[i].rune:SetAllPoints(self.frame.graphical[i])
		self.frame.graphical[i].shine = self.frame.graphical[i]:CreateTexture(nil, "OVERLAY")

		self:SetupRuneTexture(i)
		self.frame.graphical[i].rune:SetVertexColor(0, 0, 0)
	end

	self.frame.graphical[i]:SetFrameStrata("BACKGROUND")
	self.frame.graphical[i]:SetWidth(self.runeWidth)
	self.frame.graphical[i]:SetHeight(self.runeHeight)

	if self.moduleSettings.displayMode == "Horizontal" then
		self.frame.graphical[i]:SetPoint("TOPLEFT", (i-1) * (self.runeWidth-5) + (i-1) + ((i-1) * self.moduleSettings.runeGap), 0)
	else
		self.frame.graphical[i]:SetPoint("TOPLEFT", 0, -1 * ((i-1) * (self.runeHeight-5) + (i-1) + ((i-1) * self.moduleSettings.runeGap)))
	end

	self.frame.graphical[i]:Hide()

	self.frame.graphical[i].shine:SetTexture("Interface\\ComboFrame\\ComboPoint")
	self.frame.graphical[i].shine:SetBlendMode("ADD")
	self.frame.graphical[i].shine:SetTexCoord(0.5625, 1, 0, 1)
	self.frame.graphical[i].shine:ClearAllPoints()
	self.frame.graphical[i].shine:SetPoint("CENTER", self.frame.graphical[i], "CENTER")
	self.frame.graphical[i].shine:SetWidth(self.runeWidth + 25)
	self.frame.graphical[i].shine:SetHeight(self.runeHeight + 10)
	self.frame.graphical[i].shine:Hide()
end

function HolyPower.prototype:SetupRuneTexture(rune)
	if not rune or rune < 1 or rune > #runeCoords then
		return
	end

	self.frame.graphical[rune].rune:SetTexture(self:GetRuneTexture(rune))
	local a,b,c,d = unpack(runeCoords[rune])
	self.frame.graphical[rune].rune:SetTexCoord(a, b, c, d)
end

function HolyPower.prototype:GetAlphaAdd()
	return 0.15
end

function HolyPower.prototype:ShowBlizz()
	PaladinPowerBar:Show()

	PaladinPowerBar:RegisterEvent("UNIT_POWER");
	PaladinPowerBar:RegisterEvent("PLAYER_ENTERING_WORLD");
	PaladinPowerBar:RegisterEvent("UNIT_DISPLAYPOWER");
	PaladinPowerBar:RegisterEvent("UNIT_AURA");
end


function HolyPower.prototype:HideBlizz()
	PaladinPowerBar:Hide()

	PaladinPowerBar:UnregisterAllEvents()
end

function HolyPower.prototype:TargetChanged()
	HolyPower.super.prototype.TargetChanged(self)
	-- sort of a hack fix...if "ooc" alpha is set to 0, then the runes frame is all jacked up when the user spawns in
	-- need to re-run CreateFrame in order to setup the frame properly. not sure why :(
	self:Redraw()
end

function HolyPower.prototype:InCombat()
	HolyPower.super.prototype.InCombat(self)
	self:Redraw()
end

function HolyPower.prototype:OutCombat()
	HolyPower.super.prototype.OutCombat(self)
	self:Redraw()
end

function HolyPower.prototype:CheckCombat()
	HolyPower.super.prototype.CheckCombat(self)
	self:Redraw()
end

-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "PALADIN" and IceHUD.WowVer >= 40000) then
	IceHUD.HolyPower = HolyPower:new()
end
