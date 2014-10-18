local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local Vengeance = IceCore_CreateClass(IceUnitBar)

local VENGEANCE_SPELL_ID = 93098

Vengeance.prototype.current = nil
Vengeance.prototype.max = nil

-- constructor
function Vengeance.prototype:init()
	Vengeance.super.prototype.init(self, "Vengeance", "player")

	self.current = 0
	self:SetDefaultColor("Vengeance", 200, 45, 45)

	self.bTreatEmptyAsFull = true
end

-- default settings
function Vengeance.prototype:GetDefaultSettings()
	local defaults = Vengeance.super.prototype.GetDefaultSettings(self)
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
function Vengeance.prototype:Enable(core)
	Vengeance.super.prototype.Enable(self, core)

	-- Avoiding iteration where I can
	self:RegisterEvent("UNIT_AURA", "UpdateCurrent")
	self:RegisterEvent("UNIT_MAXHEALTH", "UpdateMax")

	self:UpdateMax()
end

-- disable plugin
function Vengeance.prototype:Disable(core)
	Vengeance.super.prototype.Disable(self, core)

	self:UnregisterAllEvents()
end

-- scan the tooltip and extract the vengeance value
do
	-- making these local as they're not used anywhere else
	local regions = {}
	local spellName = GetSpellInfo(VENGEANCE_SPELL_ID)
	local tooltipBuffer = CreateFrame("GameTooltip","tooltipBuffer",nil,"GameTooltipTemplate")
	tooltipBuffer:SetOwner(WorldFrame, "ANCHOR_NONE")

	-- suggested by Antiarc as a way to repopulate the same table instead of repeatedly creating a new one
	local function makeTable(t, ...)
		wipe(t)
		for i = 1, select("#", ...) do
			t[i] = select(i, ...)
		end
	end

	function Vengeance.prototype:UpdateCurrent(event, unit)
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

function Vengeance.prototype:UpdateMax(event, unit)
	if (unit and (unit ~= self.unit)) then
		return
	end

	local Stam, MaxHealth = UnitStat(self.unit, 3), UnitHealthMax(self.unit)
	self.max = floor(Stam + (MaxHealth - ((Stam - 19) * 14) - 6) / 10)
	self:Update()
end

function Vengeance.prototype:Update()
	Vengeance.super.prototype.Update(self)

	if self.current == 0 then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	self:UpdateBar(self.current / self.max, "Vengeance")
	self:SetBottomText1(floor((self.current / self.max) * 100) .. "%")
	self:SetBottomText2(tostring(self.current) .."/"..tostring(self.max))
end

-- Load for tanks only
local _, unitClass = UnitClass("player")
if ((unitClass == "DEATHKNIGHT" or unitClass == "DRUID" or unitClass == "PALADIN" or unitClass == "WARRIOR" or unitClass == "MONK")
	and IceHUD.WowVer >= 40000 and IceHUD.WowVer < 60000) then
  IceHUD.Vengeance = Vengeance:new()
end
