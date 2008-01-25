local AceOO = AceLibrary("AceOO-2.0")

local CastBar = AceOO.Class(IceCastBar)

CastBar.prototype.lagBar = nil
CastBar.prototype.spellCastSent = nil


-- Constructor --
function CastBar.prototype:init()
	CastBar.super.prototype.init(self, "CastBar")

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
	return settings
end


-- OVERRIDE
function CastBar.prototype:GetOptions()
	local opts = CastBar.super.prototype.GetOptions(self)

	opts["flashInstants"] =
	{
		type = 'text',
		name =  "Flash Instant Spells",
		desc = "Defines when cast bar should flash on instant spells",
		get = function()
			return self.moduleSettings.flashInstants
		end,
		set = function(value)
			self.moduleSettings.flashInstants = value
		end,
		validate = { "Always", "Caster", "Never" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 40
	}

	opts["flashFailures"] =
	{
		type = "text",
		name = "Flash on Spell Failures",
		desc = "Defines when cast bar should flash on failed spells",
		get = function()
			return self.moduleSettings.flashFailures
		end,
		set = function(value)
			self.moduleSettings.flashFailures = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		validate = { "Always", "Caster", "Never" },
		order = 41
	}
	
	opts["lagAlpha"] = 
	{
		type = 'range',
		name = 'Lag Indicator',
		desc = 'Lag indicator alpha (0 is disabled)',
		min = 0,
		max = 1,
		step = 0.1,
		get = function()
			return self.moduleSettings.lagAlpha
		end,
		set = function(value)
			self.moduleSettings.lagAlpha = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 42
	}

	opts["textSettings"] =
	{
		type = 'group',
		name = '|c' .. self.configColor .. 'Text Settings|r',
		desc = 'Settings related to texts',
		order = 32,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		args = {
			fontsize = {
				type = 'range',
				name = 'Bar Font Size',
				desc = 'Bar Font Size',
				get = function()
					return self.moduleSettings.barFontSize
				end,
				set = function(v)
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
				name = "Lock Bar Text Alpha",
				desc = "Locks text alpha to 100%",
				get = function()
					return self.moduleSettings.lockTextAlpha
				end,
				set = function(v)
					self.moduleSettings.lockTextAlpha = v
					self:Redraw()
				end,
				order = 13
			},

			upperTextVisible = {
				type = 'toggle',
				name = 'Spell cast text visible',
				desc = 'Toggle spell cast text visibility',
				get = function()
					return self.moduleSettings.textVisible['upper']
				end,
				set = function(v)
					self.moduleSettings.textVisible['upper'] = v
					self:Redraw()
				end,
				order = 14
			}
		}
	}

	return opts
end


function CastBar.prototype:Enable(core)
	CastBar.super.prototype.Enable(self, core)
	
	-- remove blizz cast bar
	CastingBarFrame:UnregisterAllEvents()
end


function CastBar.prototype:Disable(core)
	CastBar.super.prototype.Disable(self, core)
	
	-- restore blizz cast bar
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_SENT");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_START");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_STOP");
	
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_FAILED");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	CastingBarFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
end


-- OVERRIDE
function CastBar.prototype:CreateFrame()
	CastBar.super.prototype.CreateFrame(self)
	
	self:CreateLagBar()
end


function CastBar.prototype:CreateLagBar()
	if not (self.lagBar) then
		self.lagBar = CreateFrame("StatusBar", nil, self.frame)
	end
	
	self.lagBar:SetFrameStrata("BACKGROUND")
	self.lagBar:SetWidth(self.settings.barWidth)
	self.lagBar:SetHeight(self.settings.barHeight)
	
	
	if not (self.lagBar.bar) then
		self.lagBar.bar = self.lagBar:CreateTexture(nil, "BACKGROUND")
	end
	
	self.lagBar.bar:SetTexture(IceElement.TexturePath .. self.settings.barTexture .. "BG")
	self.lagBar.bar:SetAllPoints(self.lagBar)
	
	self.lagBar:SetStatusBarTexture(self.lagBar.bar)
	
	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor("CastCasting")
	end
	self.lagBar:SetStatusBarColor(r, g, b, self.moduleSettings.lagAlpha)
	

	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.lagBar.bar:SetTexCoord(1, 0, 0, 0)
	else
		self.lagBar.bar:SetTexCoord(0, 1, 0, 0)
	end
	
	self.lagBar:ClearAllPoints()
	self.lagBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
end


-- OVERRIDE
function CastBar.prototype:SpellCastSent(unit, spell, rank, target)
	CastBar.super.prototype.SpellCastSent(self, unit, spell, rank, target)
	if (unit ~= self.unit) then return end

	self.spellCastSent = GetTime()
end


-- OVERRIDE
function CastBar.prototype:SpellCastStart(unit, spell, rank)
	CastBar.super.prototype.SpellCastStart(self, unit, spell, rank)
	if (unit ~= self.unit) then return end

	local lag = GetTime() - self.spellCastSent
	
	local pos = lag / self.actionDuration
	local y = self.settings.barHeight - (pos * self.settings.barHeight)
	
	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.lagBar.bar:SetTexCoord(1, 0, 0, pos)
	else
		self.lagBar.bar:SetTexCoord(0, 1, 0, pos)
	end
	
	self.lagBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, y)
end


-- OVERRIDE
function CastBar.prototype:SpellCastChannelStart(unit)
	CastBar.super.prototype.SpellCastChannelStart(self, unit)
	if (unit ~= self.unit) then return end
	
	local lag = GetTime() - self.spellCastSent
	
	local pos = lag / self.actionDuration
	local y = self.settings.barHeight - (pos * self.settings.barHeight)
	
	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.lagBar.bar:SetTexCoord(1, 0, 1-pos, 1)
	else
		self.lagBar.bar:SetTexCoord(0, 1, 1-pos, 1)
	end
	
	self.lagBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
end

-------------------------------------------------------------------------------

-- Load us up
CastBar:new()
