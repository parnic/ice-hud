local AceOO = AceLibrary("AceOO-2.0")

local SunderCount = AceOO.Class(IceElement)
local MAX_DEBUFF_COUNT = 40

SunderCount.prototype.sunderSize = 20

-- Constructor --
function SunderCount.prototype:init()
	SunderCount.super.prototype.init(self, "SunderCount")
	
	self:SetDefaultColor("SunderCount", 1, 1, 0)
	self.scalingEnabled = true
end



-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function SunderCount.prototype:GetOptions()
	local opts = SunderCount.super.prototype.GetOptions(self)

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
		max = 200,
		step = 10,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["sunderFontSize"] = {
		type = "range",
		name = "Sunder Count Font Size",
		desc = "Sunder Count Font Size",
		get = function()
			return self.moduleSettings.sunderFontSize
		end,
		set = function(v)
			self.moduleSettings.sunderFontSize = v
			self:Redraw()
		end,
		min = 10,
		max = 40,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["sunderMode"] = {
		type = "text",
		name = "Display Mode",
		desc = "Show graphical or numeric sunders",
		get = function()
			return self.moduleSettings.sunderMode
		end,
		set = function(v)
			self.moduleSettings.sunderMode = v
			self:CreateSunderFrame(true)
			self:Redraw()
		end,
		validate = { "Numeric", "Graphical Bar", "Graphical Circle", "Graphical Glow", "Graphical Clean Circle" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 33
	}

	opts["gradient"] = {
		type = "toggle",
		name = "Change color",
		desc = "1 compo point: yellow, 5 sunders: red",
		get = function()
			return self.moduleSettings.gradient
		end,
		set = function(v)
			self.moduleSettings.gradient = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34
	}

	return opts
end


-- OVERRIDE
function SunderCount.prototype:GetDefaultSettings()
	local defaults =  SunderCount.super.prototype.GetDefaultSettings(self)
	defaults["vpos"] = 0
	defaults["sunderFontSize"] = 20
	defaults["sunderMode"] = "Numeric"
	defaults["gradient"] = false
	defaults["usesDogTagStrings"] = false
	return defaults
end


-- OVERRIDE
function SunderCount.prototype:Redraw()
	SunderCount.super.prototype.Redraw(self)
	
	self:CreateFrame()
	self:UpdateSunderCount()
end


-- OVERRIDE
function SunderCount.prototype:Enable(core)
	SunderCount.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateSunderCount")
	self:RegisterEvent("UNIT_AURA", "UpdateSunderCount")

	if self.moduleSettings.sunderMode == "Graphical" then
		self.moduleSettings.sunderMode = "Graphical Bar"
	end

	self:CreateSunderFrame(true)
end



-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function SunderCount.prototype:CreateFrame()
	SunderCount.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.sunderSize*5)
	self.frame:SetHeight(1)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", 0, self.moduleSettings.vpos)
	
	self:Show(true)

	self:CreateSunderFrame()
end



function SunderCount.prototype:CreateSunderFrame(doTextureUpdate)

	-- create numeric sunders
	self.frame.numeric = self:FontFactory(self.moduleSettings.sunderFontSize, nil, self.frame.numeric)

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	self.frame.numeric:Show()

	if (not self.frame.graphicalBG) then
		self.frame.graphicalBG = {}
		self.frame.graphical = {}
	end

	-- create backgrounds
	for i = 1, 5 do
		if (not self.frame.graphicalBG[i]) then
			self.frame.graphicalBG[i] = CreateFrame("StatusBar", nil, self.frame)
		end

		if doTextureUpdate then
			if self.moduleSettings.sunderMode == "Graphical Bar" then
				self.frame.graphicalBG[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboBG")
			elseif self.moduleSettings.sunderMode == "Graphical Circle" then
				self.frame.graphicalBG[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboRoundBG")
			elseif self.moduleSettings.comboMode == "Graphical Glow" then
				self.frame.graphicalBG[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboGlowBG")
			elseif self.moduleSettings.comboMode == "Graphical Clean Circle" then
				self.frame.graphicalBG[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboCleanCurvesBG")
			end
		end

		self.frame.graphicalBG[i]:SetFrameStrata("BACKGROUND")
		self.frame.graphicalBG[i]:SetWidth(self.sunderSize)
		self.frame.graphicalBG[i]:SetHeight(self.sunderSize)
		self.frame.graphicalBG[i]:SetPoint("TOPLEFT", (i-1) * (self.sunderSize-5) + (i-1), 0)
		self.frame.graphicalBG[i]:SetAlpha(0.15)
		self.frame.graphicalBG[i]:SetStatusBarColor(self:GetColor("SunderCount"))

		self.frame.graphicalBG[i]:Hide()
	end

	-- create sunders
	for i = 1, 5 do
		if (not self.frame.graphical[i]) then
			self.frame.graphical[i] = CreateFrame("StatusBar", nil, self.frame)
		end

		if doTextureUpdate then
			if self.moduleSettings.sunderMode == "Graphical Bar" then
				self.frame.graphical[i]:SetStatusBarTexture(IceElement.TexturePath .. "Combo")
			elseif self.moduleSettings.sunderMode == "Graphical Circle" then
				self.frame.graphical[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboRound")
			elseif self.moduleSettings.comboMode == "Graphical Glow" then
				self.frame.graphical[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboGlow")
			elseif self.moduleSettings.comboMode == "Graphical Clean Circle" then
				self.frame.graphical[i]:SetStatusBarTexture(IceElement.TexturePath .. "ComboCleanCurves")
			end
		end

		self.frame.graphical[i]:SetFrameStrata("BACKGROUND")
		self.frame.graphical[i]:SetAllPoints(self.frame.graphicalBG[i])

		local r, g, b = self:GetColor("SunderCount")
		if (self.moduleSettings.gradient) then
			g = g - (0.15*i)
		end
		self.frame.graphical[i]:SetStatusBarColor(r, g, b)

		self.frame.graphical[i]:Hide()
	end
end


function SunderCount.prototype:GetDebuffCount(unit, ability, onlyMine)
	for i = 1, MAX_DEBUFF_COUNT do
		local name, texture, applications, duration
		if IceHUD.WowVer >= 30000 then
			name, _, texture, applications, _, _, duration = UnitDebuff(unit, i)
		else
			name, _, texture, applications, _, duration = UnitDebuff(unit, i)
		end

		if not texture then
			break
		end

		if string.match(texture, ability) and (not onlyMine or duration) then
			return applications
		end
	end

	return 0
end


function SunderCount.prototype:UpdateSunderCount()
	local points = self:GetDebuffCount("target", "Ability_Warrior_Sunder")

	if (points == 0) then
		points = nil
	end

	if (self.moduleSettings.sunderMode == "Numeric") then
		local r, g, b = self:GetColor("SunderCount")
		if (self.moduleSettings.gradient and points) then
			g = g - (0.15*points)
		end
		self.frame.numeric:SetTextColor(r, g, b, 0.7)

		self.frame.numeric:SetText(points)
	else
		self.frame.numeric:SetText()

		for i = 1, table.getn(self.frame.graphical) do
			if (points ~= nil) then
				self.frame.graphicalBG[i]:Show()
			else
				self.frame.graphicalBG[i]:Hide()
			end
			
			if (points ~= nil and i <= points) then
				self.frame.graphical[i]:Show()
			else
				self.frame.graphical[i]:Hide()
			end
		end
	end
end


-- Load us up
local _, unitClass = UnitClass("player")
if (unitClass == "WARRIOR") then
	IceHUD.SunderCount = SunderCount:new()
end
