local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local TargetCast = IceCore_CreateClass(IceCastBar)

TargetCast.prototype.notInterruptible = false
TargetCast.prototype.notInterruptibleColorRGBA = {r = 0, g = 0, b = 0, a = 0}
TargetCast.prototype.interruptibleColorRGBA = {r = 0, g = 0, b = 0, a = 0}

-- Constructor --
function TargetCast.prototype:init()
	TargetCast.super.prototype.init(self, "TargetCast")

	self:SetDefaultColor("CastNotInterruptible", 1, 0, 0)

	self.unit = "target"
	self.skipSetColorOnFlash = true
end

function TargetCast.prototype:Enable(core)
	TargetCast.super.prototype.Enable(self, core)

	if IceHUD.EventExistsSpellcastInterruptible then
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "SpellCastInterruptible")
		self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "SpellCastNotInterruptible")
	end
end

function TargetCast.prototype:Redraw()
	TargetCast.super.prototype.Redraw(self)

	self.notInterruptibleColorRGBA.r, self.notInterruptibleColorRGBA.g, self.notInterruptibleColorRGBA.b = self:GetColor("CastNotInterruptible")
	self.interruptibleColorRGBA.r, self.interruptibleColorRGBA.g, self.interruptibleColorRGBA.b = self:GetColor(self:GetCurrentCastingColor())
end


function TargetCast.prototype:SpellCastInterruptible(event, unit)
	if unit and unit ~= self.unit then
		return
	end

	self.notInterruptible = false
	self:UpdateInterruptibleColor()
end

function TargetCast.prototype:SpellCastNotInterruptible(event, unit)
	if unit and unit ~= self.unit then
		return
	end

	self.notInterruptible = true
	self:UpdateInterruptibleColor()
end

function TargetCast.prototype:UpdateBar(scale, color)
	TargetCast.super.prototype.UpdateBar(self, scale, color)
	self:UpdateInterruptibleColor()
end

function TargetCast.prototype:UpdateInterruptibleColor()
	if self.moduleSettings.displayNonInterruptible then
		if not IceHUD.CanAccessValue(self.notInterruptible) then
			self.notInterruptibleColorRGBA.a = self.alpha
			self.interruptibleColorRGBA.a = self.alpha
			self:GetBarTexture():SetVertexColorFromBoolean(self.notInterruptible, self.notInterruptibleColorRGBA, self.interruptibleColorRGBA)
		else
			local color = self.notInterruptible and self.notInterruptibleColorRGBA or self.interruptibleColorRGBA
			self:SetBarColorRGBA(color.r, color.g, color.b, self.alpha)
		end
	end
end


-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetCast.prototype:GetDefaultSettings()
	local settings = TargetCast.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 3
	settings["flashInstants"] = "Never"
	-- Fulzamoth 2019-09-27 : let the flash handler work if in Classic and LibClassicCasterino exists
	if LibClassicCasterino then
		settings["flashFailures"] = ""
	else
		settings["flashFailures"] = "Never"
	end 
	settings["shouldAnimate"] = false
	settings["hideAnimationSettings"] = true
	settings["usesDogTagStrings"] = false
	settings["displayNonInterruptible"] = true

	return settings
end


-- OVERRIDE
function TargetCast.prototype:TargetChanged(unit)
	TargetCast.super.prototype.TargetChanged(self, unit)

	if not self.target then
		self:StopBar()
		return
	end

	local spell, notInterruptible, isCast = self:GetCastSpellAndInterruptible()
	if spell then
		self.notInterruptible = notInterruptible
		self:StartBar(isCast and IceCastBar.Actions.Cast or IceCastBar.Actions.Channel)
	else
		self:StopBar()
	end
end


function TargetCast.prototype:GetOptions()
	local opts = TargetCast.super.prototype.GetOptions(self)

	opts["barVisible"] = {
		type = 'toggle',
		name = L["Bar visible"],
		desc = L["Toggle bar visibility"],
		get = function()
			return self.moduleSettings.barVisible['bar']
		end,
		set = function(info, v)
			self.moduleSettings.barVisible['bar'] = v
			if v then
				self.barFrame:Show()
			else
				self.barFrame:Hide()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 28
	}

	opts["bgVisible"] = {
		type = 'toggle',
		name = L["Bar background visible"],
		desc = L["Toggle bar background visibility"],
		get = function()
			return self.moduleSettings.barVisible['bg']
		end,
		set = function(info, v)
			self.moduleSettings.barVisible['bg'] = v
			if v then
				self.frame.bg:Show()
			else
				self.frame.bg:Hide()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 29
	}

	opts["displayNonInterruptible"] = {
		type = 'toggle',
		name = L["Display non-interruptible color"],
		desc = L["Toggles whether or not to show the CastNonInterruptible color for this bar when a cast is non-interruptible"],
		width = 'double',
		get = function()
			return self.moduleSettings.displayNonInterruptible
		end,
		set = function(info, v)
			self.moduleSettings.displayNonInterruptible = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30
	}

	return opts
end

function TargetCast.prototype:StartBar(action, message, spellId)
	if self:IsCastOrChannel(action) then
		local spell, notInterruptible = self:GetCastSpellAndInterruptible()
		if not spell then
			return
		end

		self.notInterruptible = notInterruptible
	end

	TargetCast.super.prototype.StartBar(self, action, message, spellId)

	self:UpdateInterruptibleColor()
end

function TargetCast.prototype:GetCastSpellAndInterruptible()
	local spell, arg7, arg8, arg9, _, notInterruptible, isSpellCast
	if UnitCastingInfo then
		spell, _, _, _, _, _, _, arg8, arg9 = UnitCastingInfo(self.unit)
		notInterruptible = IceHUD.SpellFunctionsReturnRank and arg9 or arg8
		isSpellCast = true
	end
	if UnitChannelInfo and not spell then
		spell, _, _, _, _, _, arg7, arg8 = UnitChannelInfo(self.unit)
		notInterruptible = IceHUD.SpellFunctionsReturnRank and arg8 or arg7
		isSpellCast = false
	end

	return spell, notInterruptible, isSpellCast
end

-------------------------------------------------------------------------------


-- Fulzamoth 2019-09-27 : load in Classic if LibClassicCasterino exists
-- Load us up
if IceHUD.CanShowTargetCasting then
	IceHUD.TargetCast = TargetCast:new()
end
