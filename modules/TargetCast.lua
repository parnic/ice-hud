local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local TargetCast = IceCore_CreateClass(IceCastBar)

TargetCast.prototype.notInterruptible = false

-- Constructor --
function TargetCast.prototype:init()
	TargetCast.super.prototype.init(self, "TargetCast")

	self:SetDefaultColor("CastNotInterruptible", 1, 0, 0)

	self.unit = "target"
end

function TargetCast.prototype:Enable(core)
	TargetCast.super.prototype.Enable(self, core)

	if IceHUD.EventExistsSpellcastInterruptible then
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "SpellCastInterruptible")
		self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "SpellCastNotInterruptible")
	end
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

function TargetCast.prototype:UpdateBar(scale, color, alpha)
	TargetCast.super.prototype.UpdateBar(self, scale, color, alpha)
	self:UpdateInterruptibleColor()
end

function TargetCast.prototype:UpdateInterruptibleColor()
	if self.moduleSettings.displayNonInterruptible then
		if self.notInterruptible then
			self.barFrame.bar:SetVertexColor(self:GetColor("CastNotInterruptible"))
		else
			self.barFrame.bar:SetVertexColor(self:GetColor(self:GetCurrentCastingColor()))
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

	if not (self.target) then
		self:StopBar()
		return
	end

	if UnitCastingInfo then
		local spell = UnitCastingInfo(self.unit)
		local notInterruptible = select(IceHUD.SpellFunctionsReturnRank and 9 or 8, UnitCastingInfo(self.unit))
		if spell then
			self.notInterruptible = notInterruptibleCast
			self:StartBar(IceCastBar.Actions.Cast)
			return
		end
	end

	if UnitChannelInfo then
		local channel = UnitChannelInfo(self.unit)
		notInterruptible = select(IceHUD.SpellFunctionsReturnRank and 8 or 7, UnitChannelInfo(self.unit))
		if channel then
			self.notInterruptible = notInterruptibleChannel
			self:StartBar(IceCastBar.Actions.Channel)
			return
		end
	end

	self:StopBar()
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

function TargetCast.prototype:StartBar(action, message)
	local spell, notInterruptible
	if UnitCastingInfo then
		spell = UnitCastingInfo(self.unit)
		notInterruptible = select(IceHUD.SpellFunctionsReturnRank and 9 or 8, UnitCastingInfo(self.unit))
	end
	if UnitChannelInfo and not spell then
		spell = UnitChannelInfo(self.unit)
		notInterruptible = select(IceHUD.SpellFunctionsReturnRank and 8 or 7, UnitChannelInfo(self.unit))

		if not spell then
			return
		end
	end

	self.notInterruptible = notInterruptible

	TargetCast.super.prototype.StartBar(self, action, message)
end

-------------------------------------------------------------------------------


-- Fulzamoth 2019-09-27 : load in Classic if LibClassicCasterino exists
-- Load us up
if not IceHUD.WowClassic or LibClassicCasterino then
	IceHUD.TargetCast = TargetCast:new()
end
