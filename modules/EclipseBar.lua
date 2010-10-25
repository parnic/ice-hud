local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local EclipseBar = IceCore_CreateClass(IceBarElement)

local IceHUD = _G.IceHUD

EclipseBar.prototype.barUpdateColor = "EclipseLunar"
EclipseBar.prototype.direction = "none"

local DirectionToColorMapping = {
	none = "Text",
	sun = "EclipseSolar",
	moon = "EclipseLunar",
}

function EclipseBar.prototype:init()
	EclipseBar.super.prototype.init(self, "EclipseBar")

	self:SetDefaultColor("EclipseLunar", 35, 104, 231)
	self:SetDefaultColor("EclipseLunarActive", 35, 104, 231)
	self:SetDefaultColor("EclipseSolar", 190, 210, 31)
	self:SetDefaultColor("EclipseSolarActive", 238, 251, 31)
end

function EclipseBar.prototype:GetOptions()
	local opts = EclipseBar.super.prototype.GetOptions(self)
	opts.reverse.hidden = true
	return opts
end

function EclipseBar.prototype:GetDefaultSettings()
	local defaults =  EclipseBar.super.prototype.GetDefaultSettings(self)

	defaults.textVisible.lower = false
	defaults.offset = -1
	defaults.enabled = true
	defaults.usesDogTagStrings = false
	defaults.textVerticalOffset = 13
	defaults.textHorizontalOffset = 12
	defaults.shouldAnimate = false
	defaults.hideAnimationSettings = true
	defaults.lockUpperTextAlpha = false
	defaults.bHideMarkerSettings = true
	defaults.markers[1] = {
		position = 0,
		color = {r=1, g=0, b=0, a=1},
		height = 6,
	}
	defaults.shouldHideBarRotation = true

	return defaults
end

function EclipseBar.prototype:Enable(core)
	if self.moduleSettings.rotateBar then
		self.moduleSettings.rotateBar = false
		self:ResetRotation()
	end

	EclipseBar.super.prototype.Enable(self, core)

	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "UpdateShown")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateShown")
	self:RegisterEvent("MASTERY_UPDATE", "UpdateShown")
	self:RegisterEvent("UNIT_AURA", "UpdateEclipseBuffs")
	self:RegisterEvent("ECLIPSE_DIRECTION_CHANGE", "UpdateEclipseDirection")

	self:UpdateEclipseDirection(nil, GetEclipseDirection() == "sun", GetEclipseDirection() == "none")
	self:UpdateEclipseBuffs()
	self:UpdateShown()
end

function EclipseBar.prototype:Disable(core)
	EclipseBar.super.prototype.Disable(self, core)
end

-- note that isNone is not passed by the ECLIPSE_DIRECTION_CHANGE event, only manually via :Enable
function EclipseBar.prototype:UpdateEclipseDirection(event, isLunar, isNone)
	self.direction = isLunar and "sun" or isNone and "none" or "moon"
	self:UpdateEclipsePower()
end

function EclipseBar.prototype:SetBarVisibility(visible)
	EclipseBar.super.prototype.SetBarVisibility(self, visible)

	if not self.solarBar then
		return
	end

	if visible then
		self.solarBar:Show()
	else
		self.solarBar:Hide()
	end
end

function EclipseBar.prototype:CreateFrame()
	EclipseBar.super.prototype.CreateFrame(self)

	self:CreateSolarBar()
	self:UpdateShown()
	self:UpdateAlpha()
end

function EclipseBar.prototype:ShouldRegisterOnUpdate()
	return false
end

function EclipseBar.prototype:CreateSolarBar()
	if not (self.solarBar) then
		self.solarBar = CreateFrame("Frame", nil, self.frame)
	end

	local solarTop = not IceHUD:xor(self.moduleSettings.reverse, self.moduleSettings.inverse)

	self.solarBar:SetFrameStrata("BACKGROUND")
	self.solarBar:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.solarBar:SetHeight(self.settings.barHeight)
	self.solarBar:ClearAllPoints()
	if solarTop then
		self.solarBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
	else
		self.solarBar:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT")
	end

	if not (self.solarBar.bar) then
		self.solarBar.bar = self.solarBar:CreateTexture(nil, "LOW")
	end

	self.solarBar.bar:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture())
	self.solarBar.bar:SetAllPoints(self.solarBar)

	self.solarBar.bar:SetVertexColor(self:GetColor("EclipseSolar", 1))

	local pos = 0.5
	local min_y = 0
	local max_y = pos
	if not solarTop then
		min_y = 1-pos
		max_y = 1
	end

	if self.moduleSettings.side == IceCore.Side.Left then
		self.solarBar.bar:SetTexCoord(1, 0, min_y, max_y)
	else
		self.solarBar.bar:SetTexCoord(0, 1, min_y, max_y)
	end

	self.solarBar.bar:Show()
	self.solarBar:SetHeight(self.settings.barHeight * pos)
end

function EclipseBar.prototype:UpdateShown()
	local form  = GetShapeshiftFormID()

	if form == MOONKIN_FORM or not form then
		if GetPrimaryTalentTree() == 1 then
			self:Show(true)
		else
			self:Show(false)
		end
	else
		self:Show(false)
	end
end

function EclipseBar.prototype:UseTargetAlpha(scale)
	return UnitPower("player", SPELL_POWER_ECLIPSE) ~= 0 and self.combat
end

function EclipseBar.prototype:UpdateEclipseBuffs()
	local buffStatus = IceHUD:HasBuffs("player", {ECLIPSE_BAR_SOLAR_BUFF_ID, ECLIPSE_BAR_LUNAR_BUFF_ID})
	local hasSolar = buffStatus[1]
	local hasLunar = buffStatus[2]

	if hasSolar then
		self.barUpdateColor = "EclipseSolarActive"
		self.solarBar.bar:SetVertexColor(self:GetColor("EclipseSolarActive", 1))
	elseif hasLunar then
		self.barUpdateColor = "EclipseLunarActive"
		self.solarBar.bar:SetVertexColor(self:GetColor("EclipseLunarActive", 1))
	else
		self.barUpdateColor = "EclipseLunar"
		self.solarBar.bar:SetVertexColor(self:GetColor("EclipseSolar", 1))
	end
end

function EclipseBar.prototype:UpdateEclipsePower()
	local power = UnitPower("player", SPELL_POWER_ECLIPSE)
	local maxPower = UnitPowerMax("player", SPELL_POWER_ECLIPSE)

	-- bad api, bad.
	if maxPower <= 0 or power > maxPower then
		return
	end

	self:SetBottomText1(abs((power/maxPower) * 100), DirectionToColorMapping[self.direction])

-- i'm rather fond of this solution so i'm keeping it around...the correct fix was in IceBarElement to set the upper text color
-- but hey, this would have been sweet.
--[[
	local r,g,b = self:GetColor(DirectionToColorMapping[self.direction])
	self:SetBottomText1(string.format("|c%x%x%x%x%d|r",
		self.alpha * 255,
		r * 255,
		g * 255,
		b * 255,
		abs((power/maxPower) * 100)))
]]
	local pos = (power/maxPower) / 2
	self:PositionMarker(1, pos)
end

function EclipseBar.prototype:MyOnUpdate()
	self:Update()

	self:UpdateEclipsePower()
	self:UpdateBar(0.5, self.barUpdateColor, 1)
	self:UpdateAlpha()
end

local _, unitClass = UnitClass("player")
if (unitClass == "DRUID" and IceHUD.WowVer >= 40000) then
	IceHUD.EclipseBar = EclipseBar:new()
end
