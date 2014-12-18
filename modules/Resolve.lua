local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Resolve = IceCore_CreateClass(IceUnitBar)

local RESOLVE_SPELL_ID = 158298
local RESOLVE_MAX = 240

Resolve.prototype.current = nil
Resolve.prototype.max = RESOLVE_MAX

-- constructor
function Resolve.prototype:init()
	Resolve.super.prototype.init(self, "Resolve", "player")

	self.current = 0
	self:SetDefaultColor("Resolve", 200, 45, 45)

	self.bTreatEmptyAsFull = true
end

-- default settings
function Resolve.prototype:GetDefaultSettings()
	local defaults = Resolve.super.prototype.GetDefaultSettings(self)
	defaults.enabled = false
	defaults.usesDogTagStrings = false
	defaults.lockUpperTextAlpha = false
	defaults.shouldAnimate = false
	defaults.hideAnimationSettings = true
	defaults.offset = 5
	defaults.side = IceCore.Side.Left
	return defaults
end

-- enable plugin
function Resolve.prototype:Enable(core)
	Resolve.super.prototype.Enable(self, core)

	-- Avoiding iteration where I can
	self:RegisterEvent("UNIT_AURA", "UpdateCurrent")

	self:Update()
end

-- disable plugin
function Resolve.prototype:Disable(core)
	Resolve.super.prototype.Disable(self, core)

	self:UnregisterAllEvents()
end

-- scan the tooltip and extract the Resolve value
do
	-- making these local as they're not used anywhere else
	local regions = {}
	local spellName = GetSpellInfo(RESOLVE_SPELL_ID)
	local tooltipBuffer = CreateFrame("GameTooltip","tooltipBuffer",nil,"GameTooltipTemplate")
	tooltipBuffer:SetOwner(WorldFrame, "ANCHOR_NONE")

	-- suggested by Antiarc as a way to repopulate the same table instead of repeatedly creating a new one
	local function makeTable(t, ...)
		wipe(t)
		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
	end

	function Resolve.prototype:UpdateCurrent(event, unit)
		if (unit and (unit ~= self.unit)) then
			return
		end

		local name = UnitAura(self.unit, spellName)
		if name then
			-- Buff found, copy it into the buffer for scanning
			tooltipBuffer:ClearLines()
			tooltipBuffer:SetUnitBuff(self.unit, name)

			-- Grab all regions, stuff em into our table
			makeTable(regions, tooltipBuffer:GetRegions())

			-- Convert FontStrings to strings, replace anything else with ""
			for i=1, #regions do
				local region = regions[i]
				regions[i] = region:GetObjectType() == "FontString" and region:GetText() or ""
			end

			-- Find the number, save it
			self.current = tonumber(string.match(table.concat(regions),"%d+")) or 0
		else
			self.current = 0
		end

		self:Update()
	end
end

function Resolve.prototype:Update()
	Resolve.super.prototype.Update(self)

	if self.current == 0 then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.current / self.max, "Resolve")
	self:SetBottomText1(floor((self.current / self.max) * 100) .. "%")
	self:SetBottomText2(tostring(self.current) .."/"..tostring(self.max))
end

-- Load for tanks only
local _, unitClass = UnitClass("player")
if ((unitClass == "DEATHKNIGHT" or unitClass == "DRUID" or unitClass == "PALADIN" or unitClass == "WARRIOR" or unitClass == "MONK")
	and IceHUD.WowVer >= 60000) then
  IceHUD.Resolve = Resolve:new()
end
