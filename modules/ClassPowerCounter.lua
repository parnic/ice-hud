local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceClassPowerCounter = IceCore_CreateClass(IceElement)

local IceHUD = _G.IceHUD

IceClassPowerCounter.prototype.runeHeight = 22
IceClassPowerCounter.prototype.runeWidth = 36
IceClassPowerCounter.prototype.numRunes = 3
IceClassPowerCounter.prototype.numConsideredFull = 99
IceClassPowerCounter.prototype.lastNumReady = 0
IceClassPowerCounter.prototype.runeCoords = {}
IceClassPowerCounter.prototype.runeShineFadeSpeed = 0.4
IceClassPowerCounter.prototype.minLevel = 9
IceClassPowerCounter.prototype.DesiredAnimDuration = 0.6
IceClassPowerCounter.prototype.DesiredScaleMod = .4
IceClassPowerCounter.prototype.DesiredAnimPause = 0.5
IceClassPowerCounter.prototype.requiredSpec = nil
IceClassPowerCounter.prototype.shouldShowUnmodified = false
IceClassPowerCounter.prototype.unmodifiedMaxPerRune = 10
IceClassPowerCounter.prototype.unit = "player"

IceClassPowerCounter.prototype.growModes = { width = 1, height = 2 }
IceClassPowerCounter.prototype.currentGrowMode = nil

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
		max = 700,
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

	opts["alsoShowNumeric"] = {
		type = 'toggle',
		name = L["Also show numeric"],
		desc = L["If this is set, the numeric value of the current rune count will show on top of the runes display."],
		get = function(info)
			return self.moduleSettings.alsoShowNumeric
		end,
		set = function(info, v)
			self.moduleSettings.alsoShowNumeric = v
			self:SetDisplayMode()
			self:UpdateRunePower()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric"
		end,
		order = 34.01,
	}

	opts["numericVerticalOffset"] = {
		type = 'range',
		min = -500,
		max = 500,
		step = 1,
		name = L["Numeric vertical offset"],
		desc = L["How far to offset the numeric display up or down."],
		get = function(info)
			return self.moduleSettings.numericVerticalOffset
		end,
		set = function(info, v)
			self.moduleSettings.numericVerticalOffset = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return self.moduleSettings.runeMode == "Numeric" or not self.moduleSettings.alsoShowNumeric
		end,
		order = 34.02,
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

	opts["pulseWhenFull"] = {
		type = "toggle",
		name = L["Pulse when full"],
		desc = L["If this is checked, then whenever the counter is maxed out it will gently pulsate to let you know it's ready to be used."],
		get = function()
			return self.moduleSettings.pulseWhenFull
		end,
		set = function(info, v)
			self.moduleSettings.pulseWhenFull = v
			if v and self.lastNumReady == self.numRunes then
				self:StartRunesFullAnimation()
			else
				self:StopRunesFullAnimation()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 41,
	}

	opts["hideFriendly"] = {
		type = "toggle",
		name = L["Friendly OOC alpha"],
		desc = L["If this is checked, then the counter will use your 'out of target' alpha when targeting someone who is friendly."],
		get = function()
			return self.moduleSettings.hideFriendly
		end,
		set = function(info, v)
			self.moduleSettings.hideFriendly = v
			self:Update(self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 42,
	}

	opts["overrideAlpha"] = {
		type = "toggle",
		name = L["Override alpha when not full"],
		desc = L["If your class power is not full (or not empty in the case of Holy Power) then the module will always be displayed on your screen using the In Combat alpha setting. Otherwise it will fade to the OOC alpha when you leave combat."],
		width = "double",
		get = function()
			return self.moduleSettings.overrideAlpha
		end,
		set = function(info, v)
			self.moduleSettings.overrideAlpha = v
			self:UpdateAlpha()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 43,
	}

	return opts
end


-- OVERRIDE
function IceClassPowerCounter.prototype:GetDefaultSettings()
	local defaults =  IceClassPowerCounter.super.prototype.GetDefaultSettings(self)

	defaults["vpos"] = 0
	defaults["hpos"] = 0
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
	defaults["hideFriendly"] = false
	defaults["pulseWhenFull"] = true
	defaults["overrideAlpha"] = true
	defaults["numericVerticalOffset"] = 0
	defaults["alwaysShowNumeric"] = false

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

	if IceHUD.WowVer >= 70000 then
		self.numRunes = UnitPowerMax(self.unit, self.unitPower)
	end
	self:CreateFrame()

	self:CheckValidLevel(nil, UnitLevel("player"))
end

function IceClassPowerCounter.prototype:CheckValidLevel(event, level)
	if not level then
		if event == "PLAYER_TALENT_UPDATE" then
			level = UnitLevel("player")
		else
			return
		end
	end

	if self.minLevel and level < self.minLevel then
		self:RegisterEvent("PLAYER_LEVEL_UP", "CheckValidLevel")
		self:Show(false)
	else
		self:CheckValidSpec()
	end
end

function IceClassPowerCounter.prototype:CheckValidSpec()
	if self.requiredSpec == nil then
		self:DisplayCounter()
		self:Show(true)
		return
	end

	self:RegisterEvent("PLAYER_TALENT_UPDATE", "CheckValidLevel")

	local spec = GetSpecialization()
	if spec == self.requiredSpec then
		self:DisplayCounter()
		self:Show(true)
	else
		self:Show(false)
	end
end

function IceClassPowerCounter.prototype:DisplayCounter()
	self:UnregisterEvent("PLAYER_LEVEL_UP")

	self:RegisterEvent("UNIT_POWER", "UpdateRunePower")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdateRunePower")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateRunePower")

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end

	self:UpdateRunePower()
end

function IceClassPowerCounter.prototype:Disable(core)
	IceClassPowerCounter.super.prototype.Disable(self, core)

	if self.moduleSettings.hideBlizz then
		self:ShowBlizz()
	end
end

function IceClassPowerCounter.prototype:UpdateRunePower(event, arg1, arg2)
	if event and (event == "UNIT_POWER" or event == "UNIT_POWER_FREQUENT") and arg1 ~= "player" and arg1 ~= "vehicle" then
		return
	end

	if IceHUD.WowVer >= 70000 then
		local numMax = UnitPowerMax(self.unit, self.unitPower)
		if numMax ~= self.numRunes then
			self.numRunes = numMax
			self:CreateFrame()
		end
	end

	local numReady = UnitPower("player", self.unitPower)
	local percentReady = self.shouldShowUnmodified and (UnitPower("player", self.unitPower, true) / self.unmodifiedMaxPerRune) or numReady

	if self:GetRuneMode() == "Numeric" or self.moduleSettings.alsoShowNumeric then
		self.frame.numeric:SetText(tostring(percentReady))
		self.frame.numeric:SetTextColor(self:GetColor(self.numericColor))
	end

	if self:GetRuneMode() ~= "Numeric" then
		for i=1, self.numRunes do
			if i <= ceil(percentReady) then
				if self:GetRuneMode() == "Graphical" then
					self.frame.graphical[i].rune:SetVertexColor(1, 1, 1)
				else
					self:SetCustomColor(i)
				end

				if self.moduleSettings.inactiveDisplayMode == "Hidden" then
					self.frame.graphical[i]:Show()
				end

				if i > numReady or self.numRunes == 1 then
					local left, right, top, bottom = 0, 1, 0, 1
					if self:GetRuneMode() == "Graphical" then
						left, right, top, bottom = unpack(self.runeCoords[i])
					end

					local currPercent = percentReady - numReady
					if self.numRunes == 1 then
						currPercent = numReady / UnitPowerMax("player", self.unitPower)
					end

					if self.currentGrowMode == self.growModes["height"] then
						top = bottom - (currPercent * (bottom - top))
						self.frame.graphical[i].rune:SetHeight(currPercent * self.runeHeight)
					elseif self.currentGrowMode == self.growModes["width"] then
						right = left + (currPercent * (right - left))
						self.frame.graphical[i].rune:SetWidth(currPercent * self.runeWidth)
					end
					self.frame.graphical[i].rune:SetTexCoord(left, right, top, bottom)
				elseif i > self.lastNumReady then
					if self.runeCoords ~= nil and #self.runeCoords >= i then
						local left, right, top, bottom = 0, 1, 0, 1
						if self:GetRuneMode() == "Graphical" then
							left, right, top, bottom = unpack(self.runeCoords[i])
						end
						self.frame.graphical[i].rune:SetTexCoord(left, right, top, bottom)
						self.frame.graphical[i].rune:SetHeight(self.runeHeight)
					end

					if self.moduleSettings.flashWhenBecomingReady then
						local fadeInfo={
							mode = "IN",
							timeToFade = self.runeShineFadeSpeed,
							finishedFunc = function() self:ShineFinished(i) end,
							finishedArg1 = i
						}
						UIFrameFade(self.frame.graphical[i].shine, fadeInfo);
					end
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

	if self.moduleSettings.pulseWhenFull then
		if numReady > self.lastNumReady and (numReady == self.numRunes or numReady >= self.numConsideredFull) then
			self:StartRunesFullAnimation()
		elseif numReady < self.numRunes and numReady < self.numConsideredFull then
			self:StopRunesFullAnimation()
		end
	end

	self.lastNumReady = numReady
	self:UpdateAlpha()

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end
end

function IceClassPowerCounter.prototype:StartRunesFullAnimation()
	if not self.AnimUpdate then
		self.AnimUpdate = function() self:UpdateRuneAnimation() end
	end

	self.AnimStartTime = GetTime()
	self.AnimDirection = 1
	self.frame:SetScript("OnUpdate", self.AnimUpdate)
end

function IceClassPowerCounter.prototype:UpdateRuneAnimation(frame, elapsed)
	local scale = self.frame:GetScale()
	local now = GetTime()
	local perc = IceHUD:Clamp((now - self.AnimStartTime) / self.DesiredAnimDuration, 0, 1)

	if self.AnimDirection > 0 then
		scale = 1 + (self.DesiredScaleMod * perc)

		if perc >= 1 then
			self.AnimDirection = -1
			self.AnimStartTime = now
		end
	elseif self.AnimDirection < 0 then
		scale = (1 + self.DesiredScaleMod) - (self.DesiredScaleMod * perc)

		if perc >= 1 then
			self.AnimDirection = 0
			self.AnimStartTime = now
		end
	else
		if now - self.AnimStartTime >= self.DesiredAnimPause then
			self.AnimDirection = 1
			self.AnimStartTime = now
		end
	end

	for i=1, #self.frame.graphical do
		self.frame.graphical[i]:SetScale(scale)
	end
	self.frame.numericParent:SetScale(scale)
end

function IceClassPowerCounter.prototype:StopRunesFullAnimation()
	self.frame:SetScript("OnUpdate", nil)
	for i=1, #self.frame.graphical do
		self.frame.graphical[i]:SetScale(1)
	end
	self.frame.numericParent:SetScale(1)
end

function IceClassPowerCounter.prototype:ShineFinished(rune)
	UIFrameFadeOut(self.frame.graphical[rune].shine, self.runeShineFadeSpeed);
end

function IceClassPowerCounter.prototype:GetRuneTexture(rune)
	return nil
end

function IceClassPowerCounter.prototype:GetRuneAtlas(rune)
	return nil
end

function IceClassPowerCounter.prototype:UseAtlasSize(rune)
	return false
end

function IceClassPowerCounter.prototype:GetShineAtlas(rune)
	return nil
end

function IceClassPowerCounter.prototype:CreateFrame()
	IceClassPowerCounter.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata("LOW")
	self.frame:SetHeight(self.runeHeight)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)

	self:CreateRuneFrame()

	self:SetDisplayMode()
end

function IceClassPowerCounter.prototype:GetRuneMode()
	return self.moduleSettings.runeMode
end

function IceClassPowerCounter.prototype:SetDisplayMode()
	if self:GetRuneMode() == "Numeric" or self.moduleSettings.alsoShowNumeric then
		self.frame.numeric:Show()
		for i=1, self.numRunes do
			self.frame.graphical[i]:Hide()
		end
	else
		self.frame.numeric:Hide()
	end

	if self:GetRuneMode() ~= "Numeric" then
		for i=1, self.numRunes do
			self:SetupRuneTexture(i)
			self.frame.graphical[i]:Show()
		end
	end
end

function IceClassPowerCounter.prototype:CreateRuneFrame()
	-- create numeric runes
	if self.frame.numericParent == nil then
		self.frame.numericParent = CreateFrame("Frame", nil, self.frame)
	end
	self.frame.numericParent:SetAllPoints(self.frame)
	self.frame.numeric = self:FontFactory(self.moduleSettings.runeFontSize, self.frame.numericParent, self.frame.numeric)

	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("CENTER", self.frame.numericParent, "CENTER", 0, self.moduleSettings.numericVerticalOffset)
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
		self.frame.graphical[i]:SetFrameStrata("BACKGROUND")

		self.frame.graphical[i].rune = self.frame.graphical[i]:CreateTexture(nil, "ARTWORK")
		self.frame.graphical[i].rune:SetVertexColor(0, 0, 0)
		self:SetupRuneTexture(i)

		self.frame.graphical[i].shine = self.frame.graphical[i]:CreateTexture(nil, "OVERLAY")
		if self:GetShineAtlas(i) then
			self.frame.graphical[i].shine:SetAtlas(self:GetShineAtlas(i))
		else
			self.frame.graphical[i].shine:SetTexture("Interface\\ComboFrame\\ComboPoint")
		self.frame.graphical[i].shine:SetTexCoord(0.5625, 1, 0, 1)
		end
		self.frame.graphical[i].shine:SetBlendMode("ADD")
		self.frame.graphical[i].shine:ClearAllPoints()
		self.frame.graphical[i].shine:SetPoint("CENTER", self.frame.graphical[i], "CENTER")

		self.frame.graphical[i].shine:SetWidth(self.runeWidth + 25)
		self.frame.graphical[i].shine:SetHeight(self.runeHeight + 10)
		self.frame.graphical[i].shine:Hide()

		self.frame.graphical[i]:Hide()
	end

	self.frame.graphical[i]:SetWidth(self.runeWidth)
	self.frame.graphical[i]:SetHeight(self.runeHeight)
	self.frame.graphical[i].rune:SetWidth(self.runeWidth)
	self.frame.graphical[i].rune:SetHeight(self.runeHeight)
	if self.currentGrowMode == self.growModes["width"] then
		self.frame.graphical[i].rune:SetPoint("LEFT", self.frame.graphical[i], "LEFT")
	else
		self.frame.graphical[i].rune:SetPoint("BOTTOM", self.frame.graphical[i], "BOTTOM")
	end
end

function IceClassPowerCounter.prototype:SetupRuneTexture(rune)
	if not rune or rune < 1 or rune > #self.runeCoords then
		return
	end

	local width = self.runeHeight
	local a,b,c,d = 0, 1, 0, 1
	if self:GetRuneMode() == "Graphical" then
		width = self.runeWidth
		a,b,c,d = unpack(self.runeCoords[rune])
	end

	-- make sure any texture aside from the special one is square and has the proper coordinates
	self.frame.graphical[rune].rune:SetTexCoord(a, b, c, d)
	self.frame.graphical[rune]:SetWidth(width)
	self.frame:SetWidth(width*self.numRunes)
	local runeAdjust = rune - (self.numRunes / 2) - 0.5
	if self.moduleSettings.displayMode == "Horizontal" then
		self.frame.graphical[rune]:SetPoint("CENTER", runeAdjust * (width-5) + runeAdjust + (runeAdjust * self.moduleSettings.runeGap), 0)
	else
		self.frame.graphical[rune]:SetPoint("CENTER", 0, -1 * (runeAdjust * (self.runeHeight-5) + runeAdjust + (runeAdjust * self.moduleSettings.runeGap)))
	end

	if self:GetRuneMode() == "Graphical" then
		local tex = self:GetRuneTexture(rune)
		if tex then
			self.frame.graphical[rune].rune:SetTexture(tex)
		else
			self.frame.graphical[rune].rune:SetAtlas(self:GetRuneAtlas(rune), self:UseAtlasSize(rune))
		end
	elseif self:GetRuneMode() == "Graphical Bar" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "Combo")
	elseif self:GetRuneMode() == "Graphical Circle" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "ComboRound")
	elseif self:GetRuneMode() == "Graphical Glow" then
		self.frame.graphical[rune].rune:SetTexture(IceElement.TexturePath .. "ComboGlow")
	elseif self:GetRuneMode() == "Graphical Clean Circle" then
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
	local scale = self.numRunes == 1 and 0 or ((curr-1)/(self.numRunes-1))

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

function IceClassPowerCounter.prototype:AlphaPassThroughTarget()
	return self.moduleSettings.hideFriendly and UnitIsFriend("player", "target")
end

function IceClassPowerCounter.prototype:HideBlizz()
	assert(false, "Must override HideBlizz in child classes.")
end

function IceClassPowerCounter.prototype:UseTargetAlpha()
	if not self.moduleSettings.overrideAlpha then
		return false
	end

	if self.bTreatEmptyAsFull then
		return self.lastNumReady > 0
	else
		return self.lastNumReady < self.numRunes
	end
end

