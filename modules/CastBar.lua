local AceOO = AceLibrary("AceOO-2.0")

local CastBar = AceOO.Class(IceCastBar)

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
		validate = { "Always", "Caster", "Never" },
		order = 41
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


-------------------------------------------------------------------------------


-- Load us up
CastBar:new()
