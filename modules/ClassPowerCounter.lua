local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceClassPowerCounter = IceCore_CreateClass(IceElement)

IceClassPowerCounter.prototype.runeHeight = 22
IceClassPowerCounter.prototype.runeWidth = 36
IceClassPowerCounter.prototype.numRunes = 3
IceClassPowerCounter.prototype.lastNumReady = 0
IceClassPowerCounter.prototype.runeCoords = {}
IceClassPowerCounter.prototype.runeShineFadeSpeed = 0.4

-- Constructor --
function IceClassPowerCounter.prototype:init(name)
	assert(name ~= nil, "ClassPowerCounter cannot be instantiated directly - supply a name from the child class and pass it up.")
	IceClassPowerCounter.super.prototype.init(self, name)

	self.scalingEnabled = true
end

-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function IceClassPowerCounter.prototype:GetOptions()
	local opts = IceClassPowerCounter.super.prototype.GetOptions(self)

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
		name = L["Display mode"],
		desc = L["Choose whether you'd like a graphical or numeric representation of the runes.\n\nNOTE: The color of 'Numeric' mode can be controlled by the HolyPowerNumeric color."],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.runeMode)
		end,
		set = function(info, v)
			self.moduleSettings.runeMode = info.option.values[v]
			self:SetDisplayMode()
			self:UpdateRunePower()
		end,
		values = { "Graphical", "Numeric", "Graphical Bar", "Graphical Circle", "Graphical Clean Circle", "Graphical Glow" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34
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
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric"
		end,
		order = 34.1
	}

	opts["runeOrientation"] = {
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
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric"
		end,
		order = 35
	}

	opts["inactiveDisplayMode"] = {
		type = 'select',
		name = L["Inactive mode"],
		desc = L["This controls what happens to runes that are inactive. Darkened means they are visible but colored black, Hidden means they are not displayed."],
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
			return self.moduleSettings.runeMode == "Numeric"
		end,
		order = 36
	}

	opts["flashWhenReady"] = {
		type = "toggle",
		name = L["Flash when ready"],
		desc = L["Shows a flash behind each holy rune when it becomes available."],
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
			return self.moduleSettings.runeMode == "Numeric"
		end,
		order = 37
	}

	opts["customColor"] = {
		type = 'color',
		name = L["Custom color"],
		desc = L["The color for this counter"],
		get = function()
			return self:GetCustomColor()
		end,
		set = function(info, r,g,b)
			self.moduleSettings.customColor.r = r
			self.moduleSettings.customColor.g = g
			self.moduleSettings.customColor.b = b
			self:UpdateRunePower()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric" or self.moduleSettings.runeMode == "Graphical"
		end,
		order = 38,
	}

	opts["customMinColor"] = {
		type = 'color',
		name = L["Custom minimum color"],
		desc = L["The minimum color for this counter (only used if Change Color is enabled)"],
		get = function()
			return self:GetCustomMinColor()
		end,
		set = function(info, r,g,b)
			self.moduleSettings.customMinColor.r = r
			self.moduleSettings.customMinColor.g = g
			self.moduleSettings.customMinColor.b = b
			self:UpdateRunePower()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.gradient
		end,
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric" or self.moduleSettings.runeMode == "Graphical"
		end,
		order = 39,
	}

	opts["gradient"] = {
		type = "toggle",
		name = L["Change color"],
		desc = L["This will fade the graphical representation from the min color specified to the regular color\n\n(e.g. if the min color is yellow, the color is red, and there are 3 total applications, then the first would be yellow, second orange, and third red)"],
		get = function()
			return self.moduleSettings.gradient
		end,
		set = function(info, v)
			self.moduleSettings.gradient = v
			self:UpdateRunePower()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric" or self.moduleSettings.runeMode == "Graphical"
		end,
		order = 40,
	}

	return opts
end


-- OVERRIDE
function IceClassPowerCounter.prototype:GetDefaultSettings()
	local defaults =  IceClassPowerCounter.super.prototype.GetDefaultSettings(self)

	defaults["vpos"] = 0
	defaults["hpos"] = 10
	defaults["runeFontSize"] = 20
	defaults["runeMode"] = "Graphical"
	defaults["usesDogTagStrings"] = false
	defaults["hideBlizz"] = false
	defaults["alwaysFullAlpha"] = false
	defaults["displayMode"] = "Horizontal"
	defaults["runeGap"] = 0
	defaults["flashWhenBecomingReady"] = true
	defaults["inactiveDisplayMode"] = "Darkened"
	defaults["gradient"] = true
	defaults["customMinColor"] = {r=1, g=1, b=0, a=1}
	defaults["customColor"] = {r=1, g=0, b=0, a=1}

	return defaults
end


-- OVERRIDE
function IceClassPowerCounter.prototype:Redraw()
	IceClassPowerCounter.super.prototype.Redraw(self)

	self:CreateFrame()
	self:UpdateRunePower()
end

function IceClassPowerCounter.prototype:GetCustomColor()
	return self.moduleSettings.customColor.r, self.moduleSettings.customColor.g, self.moduleSettings.customColor.b, self.alpha
end

function IceClassPowerCounter.prototype:GetCustomMinColor()
	return self.moduleSettings.customMinColor.r, self.moduleSettings.customMinColor.g, self.moduleSettings.customMinColor.b, self.alpha
end


-- OVERRIDE
function IceClassPowerCounter.prototype:Enable(core)
	IceClassPowerCounter.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_POWER", "UpdateRunePower")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdateRunePower")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRunePower")

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function IceClassPowerCounter.prototype:Disable(core)
	IceClassPowerCounter.super.prototype.Disable(self, core)

	if self.moduleSettings.hideBlizz then
		self:ShowBlizz()
	end
end

function IceClassPowerCounter.prototype:UpdateRunePower()
	local numReady = UnitPower("player", self.unitPower)

	if self.moduleSettings.runeMode == "Numeric" then
		self.frame.numeric:SetText(tostring(numReady))
		self.frame.numeric:SetTextColor(self:GetColor(self.numericColor))
	else
		for i=1, self.numRunes do
			if i <= numReady then
				if self.moduleSettings.runeMode == "Graphical" then
					self.frame.graphical[i].rune:SetVertexColor(1, 1, 1)
				else
					self:SetCustomColor(i)
				end

				if self.moduleSettings.inactiveDisplayMode == "Hidden" then
					self.frame.graphical[i]:Show()
				end

				if i > self.lastNumReady and self.moduleSettings.flashWhenBecomingReady then
					local fadeInfo={
						mode = "IN",
						timeToFade = self.runeShineFadeSpeed,
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
	end

	self.lastNumReady = numReady

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function IceClassPowerCounter.prototype:ShineFinished(rune)
	UIFrameFadeOut(self.frame.graphical[rune].shine, self.runeShineFadeSpeed);
end

function IceClassPowerCounter.prototype:GetRuneTexture(rune)
	assert(true, "Must override GetRuneTexture in child classes")
end


function IceClassPowerCounter.prototype:CreateFrame()
	IceClassPowerCounter.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetHeight(self.runeHeight)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)

	self:CreateRuneFrame()

	self:SetDisplayMode()
end

function IceClassPowerCounter.prototype:SetDisplayMode()
	if self.moduleSettings.runeMode == "Numeric" then
		self.frame.numeric:Show()
		for i=1, self.numRunes do
			self.frame.graphical[i]:Hide()
		end
	else
		self.frame.numeric:Hide()
		for i=1, self.numRunes do
			self:SetupRuneTexture(i)
			self.frame.graphical[i]:Show()
		end
	end
end

function IceClassPowerCounter.prototype:CreateRuneFrame()
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

function IceClassPowerCounter.prototype:CreateRune(i)
	-- create runes
	if (not self.frame.graphical[i]) then
		self.frame.graphical[i] = CreateFrame("Frame", nil, self.frame)
		self.frame.graphical[i].rune = self.frame.graphical[i]:CreateTexture(nil, "LOW")
		self.frame.graphical[i].rune:SetAllPoints(self.frame.graphical[i])
		self.frame.graphical[i].shine = self.frame.graphical[i]:CreateTexture(nil, "OVERLAY")

		self.frame.graphical[i]:SetWidth(self.runeWidth)
		self.frame.graphical[i]:SetHeight(self.runeHeight)

		self:SetupRuneTexture(i)
		self.frame.graphical[i].rune:SetVertexColor(0, 0, 0)
	end

	self.frame.graphical[i]:SetFrameStrata("BACKGROUND")

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

function IceClassPowerCounter.prototype:SetupRuneTexture(rune)
	if not rune or rune < 1 or rune > #self.runeCoords then
		return
	end

	local width = self.runeHeight
	local a,b,c,d = 0, 1, 0, 1
	if self.moduleSettings.runeMode == "Graphical" then
		width = self.runeWidth
		a,b,c,d = unpack(self.runeCoords[rune])
	end

	-- make sure any texture aside from the special one is square and has the proper coordinates
	self.frame.graphical[rune].rune:SetTexCoord(a, b, c, d)
	self.frame.graphical[rune]:SetWidth(width)
	self.frame:SetWidth(width*self.numRunes)
	if self.moduleSettings.displayMode == "Horizontal" then
		self.frame.graphical[rune]:SetPoint("TOPLEFT", (rune-1) * (width-5) + (rune-1) + ((rune-1) * self.moduleSettings.runeGap), 0)
	else
		self.frame.graphical[rune]:SetPoint("TOPLEFT", 0, -1 * ((rune-1) * (self.runeHeight-5) + (rune-1) + ((rune-1) * self.moduleSettings.runeGap)))
	end

	if self.moduleSettings.runeMode == "Graphical" then
		self.frame.graphical[rune].rune:SetTexture(self:GetRuneTexture(rune))
	elseif self.moduleSettings.runeMode == "Graphical Bar" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "Combo")
	elseif self.moduleSettings.runeMode == "Graphical Circle" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "ComboRound")
	elseif self.moduleSettings.runeMode == "Graphical Glow" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "ComboGlow")
	elseif self.moduleSettings.runeMode == "Graphical Clean Circle" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "ComboCleanCurves")
	end
end

function IceClassPowerCounter.prototype:GetAlphaAdd()
	return 0.15
end

function IceClassPowerCounter.prototype:SetCustomColor(i)
	local r, g, b = self:GetCustomColor()
	if (self.moduleSettings.gradient) then
		r,g,b = self:GetGradientColor(i)
	end
	self.frame.graphical[i].rune:SetVertexColor(r, g, b)
end

function IceClassPowerCounter.prototype:GetGradientColor(curr)
	local r, g, b = self:GetCustomColor()
	local mr, mg, mb = self:GetCustomMinColor()
	local scale = (curr-1)/(self.numRunes-1)

	if r < mr then
		r = ((r-mr)*scale) + mr
	else
		r = ((mr-r)*scale) + r
	end

	if g < mg then
		g = ((g-mg)*scale) + mg
	else
		g = ((mg-g)*scale) + g
	end

	if b < mb then
		b = ((b-mb)*scale) + mb
	else
		b = ((mb-b)*scale) + b
	end

	return r, g, b
end

function IceClassPowerCounter.prototype:TargetChanged()
	IceClassPowerCounter.super.prototype.TargetChanged(self)
	-- sort of a hack fix...if "ooc" alpha is set to 0, then the runes frame is all jacked up when the user spawns in
	-- need to re-run CreateFrame in order to setup the frame properly. not sure why :(
	self:Redraw()
end

function IceClassPowerCounter.prototype:InCombat()
	IceClassPowerCounter.super.prototype.InCombat(self)
	self:Redraw()
end

function IceClassPowerCounter.prototype:OutCombat()
	IceClassPowerCounter.super.prototype.OutCombat(self)
	self:Redraw()
end

function IceClassPowerCounter.prototype:CheckCombat()
	IceClassPowerCounter.super.prototype.CheckCombat(self)
	self:Redraw()
end

function IceClassPowerCounter.prototype:HideBlizz()
	assert(true, "Must override HideBlizz in child classes.")
end
