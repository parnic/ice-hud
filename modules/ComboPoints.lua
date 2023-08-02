local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local ComboPoints = IceCore_CreateClass(IceElement)

local IceHUD = _G.IceHUD

local AnticipationSpellId = 114015
local AnticipationExists = GetSpellInfo(AnticipationSpellId) and IceHUD.WowVer < 70000

ComboPoints.prototype.comboSize = 20

local SPELL_POWER_COMBO_POINTS = SPELL_POWER_COMBO_POINTS
if Enum and Enum.PowerType then
	SPELL_POWER_COMBO_POINTS = Enum.PowerType.ComboPoints
end

-- Constructor --
function ComboPoints.prototype:init()
	ComboPoints.super.prototype.init(self, "ComboPoints")

	self:SetDefaultColor("ComboPoints", 1, 1, 0)
	if AnticipationExists then
		self:SetDefaultColor("AnticipationPoints", 1, 0, 1)
	end
	self:SetDefaultColor("ChargedComboPoint", 0.3137254901960784, 0.3725490196078432, 1)
	self.scalingEnabled = true
end


function ComboPoints.prototype:GetMaxComboPoints()
	local retval = UnitPowerMax("player", SPELL_POWER_COMBO_POINTS)
	if retval == 0 then -- accommodate non-rogues who still need combo point displays for some specific encounters/quests
		retval = 5
	end

	return retval
end


-- 'Public' methods -----------------------------------------------------------


-- OVERRIDE
function ComboPoints.prototype:GetOptions()
	local opts = ComboPoints.super.prototype.GetOptions(self)

	opts["headerLookAndFeel"] = {
		type = 'header',
		name = L["Look and Feel"],
		order = 29.9
	}

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
		max = 200,
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
		min = -700,
		max = 700,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["comboFontSize"] = {
		type = "range",
		name = L["Combo Points Font Size"],
		desc = L["Combo Points Font Size"],
		get = function()
			return self.moduleSettings.comboFontSize
		end,
		set = function(info, v)
			self.moduleSettings.comboFontSize = v
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

	opts["comboMode"] = {
		type = 'select',
		name = L["Display Mode"],
		desc = L["Show graphical or numeric combo points"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.comboMode)
		end,
		set = function(info, v)
			self.moduleSettings.comboMode = info.option.values[v]
			self:CreateComboFrame(true)
			self:Redraw()
			IceHUD:NotifyOptionsChange()
		end,
		values = { "Numeric", "Graphical Bar", "Graphical Circle", "Graphical Glow", "Graphical Clean Circle" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 33
	}

	opts["graphicalLayout"] = {
		type = 'select',
		name = L["Layout"],
		desc = L["How the graphical combo points should be displayed"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.graphicalLayout)
		end,
		set = function(info, v)
			self.moduleSettings.graphicalLayout = info.option.values[v]
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or self.moduleSettings.comboMode == "Numeric"
		end,
		values = {"Horizontal", "Vertical"},
		order = 33.1
	}

	opts["comboGap"] = {
		type = 'range',
		name = L["Combo gap"],
		desc = L["Spacing between each combo point (only works for graphical mode)"],
		min = 0,
		max = 100,
		step = 1,
		get = function()
			return self.moduleSettings.comboGap
		end,
		set = function(info, v)
			self.moduleSettings.comboGap = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or self.moduleSettings.comboMode == "Numeric"
		end,
		order = 33.2
	}

	if AnticipationExists then
		opts["anticipation"] = {
			type = "toggle",
			name = L["Show Anticipation"],
			desc = L["Show points stored by the Anticipation talent"],
			get = function()
				return self.moduleSettings.showAnticipation
			end,
			set = function(info, v)
				self.moduleSettings.showAnticipation = v
				self:AddAnticipation() -- This will activate or deactivate as needed
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 33.3
		}
	end

	opts["gradient"] = {
		type = "toggle",
		name = L["Change color"],
		desc = L["1 combo point: yellow, max combo points: red"],
		get = function()
			return self.moduleSettings.gradient
		end,
		set = function(info, v)
			self.moduleSettings.gradient = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 34
	}

	opts["bShowWithNoTarget"] =
	{
		type = 'toggle',
		name = L["Show with no target"],
		desc = L["Whether or not to display when you have no target selected but have combo points available"],
		get = function()
			return self.moduleSettings.bShowWithNoTarget
		end,
		set = function(info, v)
			self.moduleSettings.bShowWithNoTarget = v
			self:UpdateComboPoints()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 35
	}

	opts["bShowCharged"] = {
		type = 'toggle',
		width = 'double',
		name = L["Show Charged points"],
		desc = L["Whether or not to color a charged combo point a separate color. Set the ChargedComboPoint color to the color you would like it to be."],
		get = function()
			return self.moduleSettings.bShowCharged
		end,
		set = function(info, v)
			self.moduleSettings.bShowCharged = v
			self:UpdateChargedComboPoints()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return not GetUnitChargedPowerPoints
		end,
		order = 36
	}

	return opts
end


-- OVERRIDE
function ComboPoints.prototype:GetDefaultSettings()
	local defaults =  ComboPoints.super.prototype.GetDefaultSettings(self)
	defaults["vpos"] = 0
	defaults["hpos"] = 0
	defaults["comboFontSize"] = 20
	defaults["comboMode"] = "Numeric"
	defaults["gradient"] = false
	defaults["usesDogTagStrings"] = false
	defaults["alwaysFullAlpha"] = true
	defaults["graphicalLayout"] = "Horizontal"
	defaults["comboGap"] = 0
	defaults["showAnticipation"] = true
	defaults["bShowWithNoTarget"] = true
	defaults["bShowCharged"] = true
	return defaults
end


-- OVERRIDE
function ComboPoints.prototype:Redraw()
	ComboPoints.super.prototype.Redraw(self)

	self:CreateFrame()
	self:UpdateComboPoints()
end


-- OVERRIDE
function ComboPoints.prototype:Enable(core)
	ComboPoints.super.prototype.Enable(self, core)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateComboPoints")
	if not IceHUD.EventExistsPlayerComboPoints then
		if IceHUD.EventExistsUnitComboPoints then
			self:RegisterEvent("UNIT_COMBO_POINTS", "UpdateComboPoints")
		else
			self:RegisterEvent(IceHUD.UnitPowerEvent, "UpdateComboPoints")
			if IceHUD.EventExistsUnitMaxPower then
				self:RegisterEvent("UNIT_MAXPOWER", "UpdateMaxComboPoints")
			end
		end
		if UnitHasVehicleUI then
			self:RegisterEvent("UNIT_ENTERED_VEHICLE", "UpdateComboPoints")
			self:RegisterEvent("UNIT_EXITED_VEHICLE", "UpdateComboPoints")
		end
		if AnticipationExists then
			self:RegisterEvent("PLAYER_TALENT_UPDATE", "AddAnticipation")
			self:AddAnticipation()
		end
	else
		self:RegisterEvent("PLAYER_COMBO_POINTS", "UpdateComboPoints")
	end

	if GetUnitChargedPowerPoints then
		self:RegisterEvent("UNIT_POWER_POINT_CHARGE", "UpdateChargedComboPoints")
	end

	if self.moduleSettings.comboMode == "Graphical" then
		self.moduleSettings.comboMode = "Graphical Bar"
	end

	self:CreateComboFrame(true)
	self:UpdateChargedComboPoints()
end

function ComboPoints.prototype:UpdateMaxComboPoints(event, unit, powerType)
	if unit == "player" and powerType == "COMBO_POINTS" then
		for i = 1, #self.frame.graphical do
			self.frame.graphicalBG[i]:Hide()
			self.frame.graphical[i]:Hide()
		end
		self:Redraw()
	end
end

function ComboPoints.prototype:UpdateChargedComboPoints()
	if GetUnitChargedPowerPoints then
		self.chargedPowerPoints = GetUnitChargedPowerPoints("player")
		self:CreateComboFrame()
		self:UpdateComboPoints()
	end
end

-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function ComboPoints.prototype:CreateFrame()
	ComboPoints.super.prototype.CreateFrame(self)

	self.frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata("BACKGROUND"))
	if self.moduleSettings.graphicalLayout == "Horizontal" then
		self.frame:SetWidth((self.comboSize - 5)*self:GetMaxComboPoints())
		self.frame:SetHeight(1)
	else
		self.frame:SetWidth(1)
		self.frame:SetHeight(self.comboSize*self:GetMaxComboPoints())
	end
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)

	self:Show(true)

	self:CreateComboFrame()
end



function ComboPoints.prototype:CreateComboFrame(forceTextureUpdate)
	-- create numeric combo points
	self.frame.numeric = self:FontFactory(self.moduleSettings.comboFontSize, nil, self.frame.numeric)

	self.frame.numeric:SetWidth(50)
	self.frame.numeric:SetJustifyH("CENTER")

	self.frame.numeric:SetPoint("TOP", self.frame, "TOP", 0, 0)
	self.frame.numeric:Show()

	if (not self.frame.graphicalBG) then
		self.frame.graphicalBG = {}
		self.frame.graphical = {}
		self.frame.graphicalAnt = {}
	end

	local i
	local maxComboPoints = self:GetMaxComboPoints()

	-- create backgrounds
	for i = 1, maxComboPoints do
		if (not self.frame.graphicalBG[i]) then
			local frame = CreateFrame("Frame", nil, self.frame)
			self.frame.graphicalBG[i] = frame
			frame.texture = frame:CreateTexture()
			frame.texture:SetAllPoints(frame)
			forceTextureUpdate = true
		end

		if forceTextureUpdate then
			if self.moduleSettings.comboMode == "Graphical Bar" then
				self.frame.graphicalBG[i].texture:SetTexture(IceElement.TexturePath .. "ComboBG")
			elseif self.moduleSettings.comboMode == "Graphical Circle" then
				self.frame.graphicalBG[i].texture:SetTexture(IceElement.TexturePath .. "ComboRoundBG")
			elseif self.moduleSettings.comboMode == "Graphical Glow" then
				self.frame.graphicalBG[i].texture:SetTexture(IceElement.TexturePath .. "ComboGlowBG")
			elseif self.moduleSettings.comboMode == "Graphical Clean Circle" then
				self.frame.graphicalBG[i].texture:SetTexture(IceElement.TexturePath .. "ComboCleanCurvesBG")
			end
		end

		self.frame.graphicalBG[i]:SetFrameStrata(IceHUD.IceCore:DetermineStrata("BACKGROUND"))
		self.frame.graphicalBG[i]:SetWidth(self.comboSize)
		self.frame.graphicalBG[i]:SetHeight(self.comboSize)
		if self.moduleSettings.graphicalLayout == "Horizontal" then
			self.frame.graphicalBG[i]:SetPoint("TOPLEFT", ((i-1) * (self.comboSize-5)) - 2.5 + ((i-1) * self.moduleSettings.comboGap), 0)
		else
			self.frame.graphicalBG[i]:SetPoint("TOPLEFT", 0, -1 * (((i-1) * (self.comboSize-5)) - 2.5 + ((i-1) * self.moduleSettings.comboGap)))
		end
		self.frame.graphicalBG[i]:SetAlpha(0.15)
		self.frame.graphicalBG[i].texture:SetVertexColor(self:GetColor("ComboPoints"))

		self.frame.graphicalBG[i]:Hide()
	end

	-- create combo points
	for i = 1, maxComboPoints do
		if (not self.frame.graphical[i]) then
			local frame = CreateFrame("Frame", nil, self.frame)
			self.frame.graphical[i] = frame
			frame.texture = frame:CreateTexture()
			frame.texture:SetAllPoints(frame)
			forceTextureUpdate = true
		end

		if forceTextureUpdate then
			if self.moduleSettings.comboMode == "Graphical Bar" then
				self.frame.graphical[i].texture:SetTexture(IceElement.TexturePath .. "Combo")
			elseif self.moduleSettings.comboMode == "Graphical Circle" then
				self.frame.graphical[i].texture:SetTexture(IceElement.TexturePath .. "ComboRound")
			elseif self.moduleSettings.comboMode == "Graphical Glow" then
				self.frame.graphical[i].texture:SetTexture(IceElement.TexturePath .. "ComboGlow")
			elseif self.moduleSettings.comboMode == "Graphical Clean Circle" then
				self.frame.graphical[i].texture:SetTexture(IceElement.TexturePath .. "ComboCleanCurves")
			end
		end

		self.frame.graphical[i]:SetFrameStrata(IceHUD.IceCore:DetermineStrata("LOW"))
		self.frame.graphical[i]:SetAllPoints(self.frame.graphicalBG[i])

		local r, g, b = self:GetColor("ComboPoints")
		if (self.moduleSettings.gradient) then
			g = g - ((1 / maxComboPoints)*i)
		end

		if self.moduleSettings.bShowCharged and self:IsChargedPoint(i) then
			self.frame.graphical[i].texture:SetVertexColor(self:GetColor("ChargedComboPoint"))
		else
			self.frame.graphical[i].texture:SetVertexColor(r, g, b)
		end

		self.frame.graphical[i]:Hide()
	end

	-- create Anticipation points
	if AnticipationExists then
		for i = 1, 5 do
			if (not self.frame.graphicalAnt[i]) then
				local frame = CreateFrame("Frame", nil, self.frame)
				self.frame.graphicalAnt[i] = frame
				frame.texture = frame:CreateTexture()
				frame.texture:SetAllPoints(frame)
			end

			if forceTextureUpdate then
				if self.moduleSettings.comboMode == "Graphical Bar" then
					self.frame.graphicalAnt[i].texture:SetTexture(IceElement.TexturePath .. "Combo")
				elseif self.moduleSettings.comboMode == "Graphical Circle" then
					self.frame.graphicalAnt[i].texture:SetTexture(IceElement.TexturePath .. "ComboRound")
				elseif self.moduleSettings.comboMode == "Graphical Glow" then
					self.frame.graphicalAnt[i].texture:SetTexture(IceElement.TexturePath .. "ComboGlow")
				elseif self.moduleSettings.comboMode == "Graphical Clean Circle" then
					self.frame.graphicalAnt[i].texture:SetTexture(IceElement.TexturePath .. "ComboCleanCurves")
				end
			end

			self.frame.graphicalAnt[i]:SetFrameStrata(IceHUD.IceCore:DetermineStrata("LOW"))
			self.frame.graphicalAnt[i]:SetFrameLevel(self.frame.graphical[i]:GetFrameLevel() + 1)
			self.frame.graphicalAnt[i]:SetWidth(math.floor(self.comboSize / 2))
			self.frame.graphicalAnt[i]:SetHeight(math.floor(self.comboSize / 2))

			self.frame.graphicalAnt[i]:SetPoint("CENTER", self.frame.graphical[i], "CENTER")

			local r, g, b = self:GetColor("AnticipationPoints")
			if (self.moduleSettings.gradient) then
				r = r - 0.25 * (i - 1) -- Go to straight blue, which is most visible against the redorange
			end
			self.frame.graphicalAnt[i].texture:SetVertexColor(r, g, b)

			self.frame.graphicalAnt[i]:Hide()
		end
	end
end

function ComboPoints.prototype:IsChargedPoint(point)
	if not self.chargedPowerPoints then
		return false
	end

	for i=1, #self.chargedPowerPoints do
		if self.chargedPowerPoints[i] == point then
			return true
		end
	end

	return false
end

function ComboPoints.prototype:UpdateComboPoints(...)
	if select('#', ...) >= 3 and select(1, ...) == IceHUD.UnitPowerEvent and select(3, ...) ~= "COMBO_POINTS" then
		return
	end

	local points, anticipate, _
	if IceHUD.IceCore:IsInConfigMode() then
		points = self:GetMaxComboPoints()
	elseif UnitHasVehicleUI then
		-- Parnic: apparently some fights have combo points while the player is in a vehicle?
		local isInVehicle = UnitHasVehicleUI and UnitHasVehicleUI("player")
		local checkUnit = isInVehicle and "vehicle" or "player"
		if IceHUD.PerTargetComboPoints then
			points = GetComboPoints(checkUnit, "target")
		else
			points = UnitPower(checkUnit, SPELL_POWER_COMBO_POINTS)
		end

		if AnticipationExists then
			_, _, _, anticipate = UnitAura("player", GetSpellInfo(AnticipationSpellId))
		else
			anticipate = 0
		end
	else
		points = GetComboPoints("player", "target")
	end

	points = points or 0
	anticipate = self.moduleSettings.showAnticipation and anticipate or 0

	if self:GetMaxComboPoints() > #self.frame.graphical then
		self:CreateComboFrame(true)
	end

	if (self.moduleSettings.comboMode == "Numeric") then
		local r, g, b = self:GetColor("ComboPoints")
		if (self.moduleSettings.gradient and points) then
			g = g - ((1 / self:GetMaxComboPoints())*points)
		end
		self.frame.numeric:SetTextColor(r, g, b, 0.7)

		local pointsText = tostring(points)
		if self.moduleSettings.bShowCharged and self:IsChargedPoint(points) then
			pointsText = pointsText.."@"
		end
		if anticipate > 0 then
			pointsText = pointsText.."+"..tostring(anticipate)
		end

		if (points == 0 and anticipate == 0) or (not UnitExists("target") and not self.moduleSettings.bShowWithNoTarget) then
			self.frame.numeric:SetText(nil)
		else
			self.frame.numeric:SetText(pointsText)
		end
	else
		self.frame.numeric:SetText()

		for i = 1, self:GetMaxComboPoints() do
			local hideIfNoTarget = not UnitExists("target") and not self.moduleSettings.bShowWithNoTarget

			if ((points > 0) or (anticipate > 0)) and not hideIfNoTarget then
				self.frame.graphicalBG[i]:Show()
			else
				self.frame.graphicalBG[i]:Hide()
			end

			if (i <= points) and not hideIfNoTarget then
				self.frame.graphical[i]:Show()
			else
				self.frame.graphical[i]:Hide()
			end

			if i <= #self.frame.graphicalAnt then
				if (i <= anticipate) and not hideIfNoTarget then
					self.frame.graphicalAnt[i]:Show()
				else
					self.frame.graphicalAnt[i]:Hide()
				end
			end
		end
	end
end

do
	local antStacks

	function ComboPoints.prototype:CheckAnticipation(e, unit) -- UNIT_AURA handler
		if UnitIsUnit(unit, "player") then
			local _, _, _, newAntStacks
			if IceHUD.SpellFunctionsReturnRank then
				_, _, _, newAntStacks = UnitAura("player", GetSpellInfo(AnticipationSpellId))
			else
				_, _, newAntStacks = UnitAura("player", GetSpellInfo(AnticipationSpellId))
			end
			if newAntStacks ~= antStacks then
				antStacks = newAntStacks
				self:UpdateComboPoints()
			end
		end
	end

	function ComboPoints.prototype:AddAnticipation() -- Handles both PLAYER_TALENT_CHANGED event and activation from options or initialization.
		if self.moduleSettings.showAnticipation and IsSpellKnown(AnticipationSpellId) then
			self:RegisterEvent("UNIT_AURA", "CheckAnticipation") -- CallbackHandler will just reassign if it's there, so no harm
		else
			self:UnregisterEvent("UNIT_AURA") -- Doesn't error if it wasn't there
		end
	end
end


-- Load us up
local _, class = UnitClass("player")
if (not IceHUD.WowClassic and not IceHUD.WowClassicBC) or class == "ROGUE" or class == "DRUID" then
	IceHUD.ComboPoints = ComboPoints:new()
end
