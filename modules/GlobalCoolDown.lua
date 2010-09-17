local GlobalCoolDown = IceCore_CreateClass(IceBarElement)
GlobalCoolDown.prototype.scheduledEvent = nil

-- Constructor --
function GlobalCoolDown.prototype:init()
	GlobalCoolDown.super.prototype.init(self, "GlobalCoolDown", "player")

	self.moduleSettings = {}
	self.moduleSettings.barVisible = {bar = true, bg = false}
	self.moduleSettings.desiredLerpTime = 0
	self.moduleSettings.shouldAnimate = false

	self.unit = "player"
	self.startTime = nil
	self.duration = nil

	self:SetDefaultColor("GlobalCoolDown", 0.1, 0.1, 0.1)
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function GlobalCoolDown.prototype:Enable(core)
	GlobalCoolDown.super.prototype.Enable(self, core)

	self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN", "CooldownStateChanged")

	self:Show(false)
end

function GlobalCoolDown.prototype:Disable(core)
	GlobalCoolDown.super.prototype.Disable(self, core)

	self:CancelTimer(self.scheduledEvent, true)
end

function GlobalCoolDown.prototype:GetSpellId()
	local defaultSpells;
	if (IceHUD.WowVer >= 30000) then
		defaultSpells = {
			ROGUE=1752, -- sinister strike
			PRIEST=139, -- renew
			DRUID=774, -- rejuvenation
			WARRIOR=6673, -- battle shout
			MAGE=168, -- frost armor
			WARLOCK=1454, -- life tap
			PALADIN=1152, -- purify
			SHAMAN=324, -- lightning shield
			HUNTER=1978, -- serpent sting
			DEATHKNIGHT=47541 -- death coil
		}
	else
		defaultSpells = {
			ROGUE=1752, -- sinister strike
			PRIEST=139, -- renew
			DRUID=774, -- rejuvenation
			WARRIOR=6673, -- battle shout
			MAGE=168, -- frost armor
			WARLOCK=1454, -- life tap
			PALADIN=1152, -- purify
			SHAMAN=324, -- lightning shield
			HUNTER=1978 -- serpent sting
		}
	end
	local _, unitClass = UnitClass("player")
	return defaultSpells[unitClass]
end

-- OVERRIDE
function GlobalCoolDown.prototype:GetDefaultSettings()
	local settings = GlobalCoolDown.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 6
	settings["shouldAnimate"] = true
	settings["hideAnimationSettings"] = true
	settings["desiredLerpTime"] = 1
	settings["lowThreshold"] = 0
	settings["barVisible"]["bg"] = false
	settings["usesDogTagStrings"] = false
	settings["bHideMarkerSettings"] = true

	return settings
end

-- OVERRIDE
function GlobalCoolDown.prototype:GetOptions()
	local opts = GlobalCoolDown.super.prototype.GetOptions(self)

	opts["lowThreshold"] = nil
	opts["textSettings"] = nil

	return opts
end

-- 'Protected' methods --------------------------------------------------------

function GlobalCoolDown.prototype:CooldownStateChanged()
	local start, dur = GetSpellCooldown(self:GetSpellId())

	if dur ~= nil and dur > 0 and dur <= 1.5 then
		self.startTime = start
		self.duration = dur

		if self.CurrScale < 0.01 or self.CurrScale == 1 then
			self:SetScale(1, true)
			self.LastScale = 1
			self.DesiredScale = 0
			self.CurrLerpTime = 0
			self.moduleSettings.desiredLerpTime = dur or 1
		end
		self.frame:SetFrameStrata("TOOLTIP")
		self:Show(true)
		self.frame.bg:SetAlpha(0)
		self.barFrame.bar:SetVertexColor(self:GetColor("GlobalCoolDown", 0.8))
	else
		self.duration = nil
		self.startTime = nil

		self:Show(false)
	end
end

function GlobalCoolDown.prototype:UpdateGlobalCoolDown()
	if (self.duration ~= nil) and (self.startTime ~= nil) then
		remaining = GetTime() - self.startTime

		if (remaining > self.duration) then
			self.duration = nil
			self.startTime = nil

			self:Show(false)
		else
--			self:UpdateBar(1 - (self.duration ~= 0 and remaining / self.duration or 0), "GlobalCoolDown", 0.8)
		end
	else
		self:Show(false)
	end
end

-- Load us up
IceHUD.GlobalCoolDown = GlobalCoolDown:new()
