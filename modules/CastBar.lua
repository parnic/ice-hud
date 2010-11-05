local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local CastBar = IceCore_CreateClass(IceCastBar)

local IceHUD = _G.IceHUD

CastBar.prototype.lagBar = nil
CastBar.prototype.spellCastSent = nil


-- Constructor --
function CastBar.prototype:init()
	CastBar.super.prototype.init(self, "CastBar")

	self:SetDefaultColor("CastLag", 255, 0, 0)
	self:SetDefaultColor("CastNotInRange", 200, 200, 200)

	self.unit = "player"
end


-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function CastBar.prototype:GetDefaultSettings()
	local settings = CastBar.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 0
	settings["flashInstants"] = "Caster"
	settings["flashFailures"] = "Caster"
	settings["lagAlpha"] = 0.7
	settings["showBlizzCast"] = false
	settings["shouldAnimate"] = false
	settings["hideAnimationSettings"] = true
	settings["usesDogTagStrings"] = false
	settings["rangeColor"] = true
	settings["bAllowExpand"] = false

	return settings
end


-- OVERRIDE
function CastBar.prototype:GetOptions()
	local opts = CastBar.super.prototype.GetOptions(self)

	opts["flashInstants"] =
	{
		type = 'select',
		name = L["Flash Instant Spells"],
		desc = L["Defines when cast bar should flash on instant spells"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.flashInstants)
		end,
		set = function(info, value)
			self.moduleSettings.flashInstants = info.option.values[value]
		end,
		values = { "Always", "Caster", "Never" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40
	}

	opts["flashFailures"] =
	{
		type = 'select',
		name = L["Flash on Spell Failures"],
		desc = L["Defines when cast bar should flash on failed spells"],
		get = function(info)
			return IceHUD:GetSelectValue(info, self.moduleSettings.flashFailures)
		end,
		set = function(info, value)
			self.moduleSettings.flashFailures = info.option.values[value]
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		values = { "Always", "Caster", "Never" },
		order = 41
	}

	opts["lagAlpha"] =
	{
		type = 'range',
		name = L["Lag Indicator alpha"],
		desc = L["Lag indicator alpha (0 is disabled)"],
		min = 0,
		max = 1,
		step = 0.1,
		get = function()
			return self.moduleSettings.lagAlpha
		end,
		set = function(info, value)
			self.moduleSettings.lagAlpha = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 42
	}

	opts["showBlizzCast"] =
	{
		type = 'toggle',
		name = L["Show default cast bar"],
		desc = L["Whether or not to show the default cast bar."],
		get = function()
			return self.moduleSettings.showBlizzCast
		end,
		set = function(info, value)
			self.moduleSettings.showBlizzCast = value
			self:ToggleBlizzCast(self.moduleSettings.showBlizzCast)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 43
	}

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

	opts["rangeColor"] = {
		type = 'toggle',
		name = L["Change color when not in range"],
		desc = L["Changes the bar color to the CastNotInRange color when the target goes out of range for the current spell."],
		width = 'double',
		get = function()
			return self.moduleSettings.rangeColor
		end,
		set = function(info, v)
			self.moduleSettings.rangeColor = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30
	}

	opts["textSettings"] =
	{
		type = 'group',
		name = "|c"..self.configColor..L["Text Settings"].."|r",
		desc = L["Settings related to texts"],
		order = 32,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		args = {
			fontsize = {
				type = 'range',
				name = L["Bar Font Size"],
				desc = L["Bar Font Size"],
				get = function()
					return self.moduleSettings.barFontSize
				end,
				set = function(info, v)
					self.moduleSettings.barFontSize = v
					self:Redraw()
				end,
				min = 8,
				max = 20,
				step = 1,
				order = 11
			},

			lockFontAlpha = {
				type = "toggle",
				name = L["Lock Bar Text Alpha"],
				desc = L["Locks text alpha to 100%"],
				get = function()
					return self.moduleSettings.lockUpperTextAlpha
				end,
				set = function(info, v)
					self.moduleSettings.lockUpperTextAlpha = v
					self:Redraw()
				end,
				order = 13
			},

			upperTextVisible = {
				type = 'toggle',
				name = L["Spell cast text visible"],
				desc = L["Toggle spell cast text visibility"],
				get = function()
					return self.moduleSettings.textVisible['upper']
				end,
				set = function(info, v)
					self.moduleSettings.textVisible['upper'] = v
					self:Redraw()
				end,
				order = 14
			},

			textVerticalOffset = {
				type = 'range',
				name = L["Text Vertical Offset"],
				desc = L["Offset of the text from the bar vertically (negative is farther below)"],
				min = -250,
				max = 350,
				step = 1,
				get = function()
					return self.moduleSettings.textVerticalOffset
				end,
				set = function(info, v)
					self.moduleSettings.textVerticalOffset = v
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end
			},

			textHorizontalOffset = {
				type = 'range',
				name = L["Text Horizontal Offset"],
				desc = L["Offset of the text from the bar horizontally"],
				min = -350,
				max = 350,
				step = 1,
				get = function()
					return self.moduleSettings.textHorizontalOffset
				end,
				set = function(info, v)
					self.moduleSettings.textHorizontalOffset = v
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end
			},

			forceJustifyText = {
				type = 'select',
				name = L["Force Text Justification"],
				desc = L["This sets the alignment for the text on this bar"],
				get = function()
					return self.moduleSettings.forceJustifyText
				end,
				set = function(info, value)
					self.moduleSettings.forceJustifyText = value
					self:Redraw()
				end,
				values = { NONE = "None", LEFT = "Left", RIGHT = "Right" },
				disabled = function()
					return not self.moduleSettings.enabled
				end,
			}
		}
	}

	return opts
end

function CastBar.prototype:Enable(core)
	CastBar.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "EnteringVehicle")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "ExitingVehicle")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckVehicle")

	if self.moduleSettings.enabled and not self.moduleSettings.showBlizzCast then
		self:ToggleBlizzCast(false)
	end

	if self.moduleSettings.shouldAnimate then
		self.moduleSettings.shouldAnimate = false
	end
end


function CastBar.prototype:EnteringVehicle(event, unit, arg2)
	if (self.unit == "player" and IceHUD:ShouldSwapToVehicle(unit, arg2)) then
		self.unit = "vehicle"
		self:Update(self.unit)
	end
end


function CastBar.prototype:ExitingVehicle(event, unit)
	if (unit == "player" and self.unit == "vehicle") then
		self.unit = "player"
		self:Update(self.unit)
	end
end


function CastBar.prototype:CheckVehicle()
	if UnitHasVehicleUI("player") then
		self:EnteringVehicle(nil, "player", true)
	else
		self:ExitingVehicle(nil, "player")
	end
end


function CastBar.prototype:Disable(core)
	CastBar.super.prototype.Disable(self, core)

	if self.moduleSettings.showBlizzCast then
		self:ToggleBlizzCast(true)
	end
end

function CastBar.prototype:ToggleBlizzCast(on)
	if on then
		-- restore blizz cast bar
		CastingBarFrame:GetScript("OnLoad")(CastingBarFrame)
		PetCastingBarFrame:GetScript("OnLoad")(PetCastingBarFrame)
	else
		-- remove blizz cast bar
		CastingBarFrame:UnregisterAllEvents()
		PetCastingBarFrame:UnregisterAllEvents()
	end
end


-- OVERRIDE
function CastBar.prototype:CreateFrame()
	CastBar.super.prototype.CreateFrame(self)

	self:CreateLagBar()
end


function CastBar.prototype:CreateLagBar()
	self.lagBar = self:BarFactory(self.lagBar, "LOW","BACKGROUND")
	self:SetBarCoord(self.lagBar, 0 , true)

	local r, g, b = self:GetColor("CastLag")
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor("CastCasting")
	end
	self.lagBar.bar:SetVertexColor(r, g, b, self.moduleSettings.lagAlpha)

	self.lagBar.bar:Hide()
end


-- OVERRIDE
function CastBar.prototype:SpellCastSent(event, unit, spell, rank, target)
	CastBar.super.prototype.SpellCastSent(self, event, unit, spell, rank, target)
	if (unit ~= self.unit) then return end

	self.spellCastSent = GetTime()
end

-- OVERRIDE
function CastBar.prototype:SpellCastStart(event, unit, spell, rank)
	CastBar.super.prototype.SpellCastStart(self, event, unit, spell, rank)
	if (unit ~= self.unit) then return end

	if not self:IsVisible() or not self.actionDuration then
		return
	end

	local scale
	if self.unit == "vehicle" then
		scale = 0
	else
		local now = GetTime()
		local lag = now - (self.spellCastSent or now)
		scale = IceHUD:Clamp(lag / self.actionDuration, 0, 1)
	end

	self.lagBar:SetFrameStrata("BACKGROUND")
	self:SetBarCoord(self.lagBar, scale, true)

	self.spellCastSent = nil
end


-- OVERRIDE
function CastBar.prototype:SpellCastChannelStart(event, unit)
	CastBar.super.prototype.SpellCastChannelStart(self, event, unit)
	if (unit ~= self.unit) then return end

	if not self:IsVisible() or not self.actionDuration then
		return
	end

	local scale
	if self.unit == "vehicle" then
		scale = 0
	else
		local now = GetTime()
		local lag = now - (self.spellCastSent or now)
		scale = IceHUD:Clamp(lag / self.actionDuration, 0, 1)
	end

	local top = not self.moduleSettings.reverseChannel

	self.lagBar:SetFrameStrata("MEDIUM")
	self:SetBarCoord(self.lagBar, scale, top)

	self.spellCastSent = nil
end


function CastBar.prototype:UpdateBar(scale, color, alpha)
	local bCheckRange = true
	local inRange

	if not self.moduleSettings.rangeColor or not self.current or not self.action or not UnitExists("target") then
		bCheckRange = false
	else
		inRange = IsSpellInRange(self.current, "target")
		if inRange == nil then
			bCheckRange = false
		end
	end

	if bCheckRange and inRange == 0 then
		color = "CastNotInRange"
	end

	CastBar.super.prototype.UpdateBar(self, scale, color, alpha)
end

-------------------------------------------------------------------------------

-- Load us up
IceHUD.PlayerCast = CastBar:new()
