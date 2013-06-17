local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local SliceAndDice = IceCore_CreateClass(IceUnitBar)

local IceHUD = _G.IceHUD

local NetherbladeItemIdList = {29044, 29045, 29046, 29047, 29048}
local NineTailedItemIdList = {96679, 96680, 96681, 96682, 96683, 95305, 95306, 95307, 95308, 95309, 95935, 95936, 95937, 95938, 95939}
-- Parnic - bah, have to abandon the more robust string representation of each slot because of loc issues...
local NetherbladeEquipLocList = {1, 3, 5, 7, 10} --"HeadSlot", "ShoulderSlot", "ChestSlot", "LegsSlot", "HandsSlot"}

local GlyphSpellId = 56810

local baseTime = 9
local gapPerComboPoint = 3
local netherbladeBonus = 3
local glyphBonusSec = 6
local impSndTalentPage = 2
local impSndTalentIdx = 4
local impSndBonusPerRank = 0.25
local maxComboPoints = 5
local sndEndTime = 0
local sndDuration = 0

local CurrMaxSnDDuration = 0
local PotentialSnDDuration = 0

if IceHUD.WowVer >= 50000 then
	baseTime = 12
	gapPerComboPoint = 6
end

-- Constructor --
function SliceAndDice.prototype:init()
	SliceAndDice.super.prototype.init(self, "SliceAndDice", "player")

	self.moduleSettings = {}
	self.moduleSettings.desiredLerpTime = 0
	self.moduleSettings.shouldAnimate = false

	self:SetDefaultColor("SliceAndDice", 0.75, 1, 0.2)
	self:SetDefaultColor("SliceAndDicePotential", 1, 1, 1)

	self.bTreatEmptyAsFull = true
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function SliceAndDice.prototype:Enable(core)
	SliceAndDice.super.prototype.Enable(self, core)

	self:RegisterEvent("UNIT_AURA", "UpdateSliceAndDice")
	self:RegisterEvent("UNIT_COMBO_POINTS", "UpdateDurationBar")

	if not self.moduleSettings.alwaysFullAlpha then
		self:Show(false)
	else
		self:UpdateSliceAndDice()
	end

	self:SetBottomText1("")
end

function SliceAndDice.prototype:TargetChanged()
	SliceAndDice.super.prototype.TargetChanged(self)
	self:UpdateDurationBar()
	self:UpdateSliceAndDice()
end

function SliceAndDice.prototype:Disable(core)
	SliceAndDice.super.prototype.Disable(self, core)
end

-- OVERRIDE
function SliceAndDice.prototype:GetDefaultSettings()
	local settings = SliceAndDice.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["shouldAnimate"] = false
	settings["desiredLerpTime"] = nil
	settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 6
	settings["upperText"]="SnD:"
	settings["showAsPercentOfMax"] = true
	settings["durationAlpha"] = 0.6
	settings["usesDogTagStrings"] = false
	settings["lockLowerFontAlpha"] = false
	settings["lowerTextString"] = ""
	settings["lowerTextVisible"] = false
	settings["hideAnimationSettings"] = true
	settings["bAllowExpand"] = true

	return settings
end

-- OVERRIDE
function SliceAndDice.prototype:GetOptions()
	local opts = SliceAndDice.super.prototype.GetOptions(self)

	opts["textSettings"].args["upperTextString"]["desc"] = "The text to display under this bar. # will be replaced with the number of Slice and Dice seconds remaining."
	opts["textSettings"].args["upperTextString"].hidden = false

	opts["showAsPercentOfMax"] =
	{
		type = 'toggle',
		name = L["Show bar as % of maximum"],
		desc = L["If this is checked, then the SnD buff time shows as a percent of the maximum attainable (taking set bonuses and talents into account). Otherwise, the bar always goes from full to empty when applying SnD no matter the duration."],
		get = function()
			return self.moduleSettings.showAsPercentOfMax
		end,
		set = function(info, v)
			self.moduleSettings.showAsPercentOfMax = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	opts["durationAlpha"] =
	{
		type = "range",
		name = L["Potential SnD time bar alpha"],
		desc = L["What alpha value to use for the bar that displays how long your SnD will last if you activate it. (This gets multiplied by the bar's current alpha to stay in line with the bar on top of it)"],
		min = 0,
		max = 100,
		step = 5,
		get = function()
			return self.moduleSettings.durationAlpha * 100
		end,
		set = function(info, v)
			self.moduleSettings.durationAlpha = v / 100.0
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	return opts
end

function SliceAndDice.prototype:CreateFrame()
	SliceAndDice.super.prototype.CreateFrame(self)

	self:CreateDurationBar()
end

function SliceAndDice.prototype:CreateDurationBar()
	self.durationFrame = self:BarFactory(self.durationFrame, "BACKGROUND","ARTWORK")

	-- Rokiyo: Do we need to call this here?
	self.CurrScale = 0

	self.durationFrame.bar:SetVertexColor(self:GetColor("SliceAndDicePotential", self.moduleSettings.durationAlpha))
	self.durationFrame.bar:SetHeight(0)

	self:UpdateBar(1, "undef")

	-- force update the bar...if we're in here, then either the UI was just loaded or the player is jacking with the options.
	-- either way, make sure the duration bar matches accordingly
	self:UpdateDurationBar()
end

function SliceAndDice.prototype:RotateHorizontal()
	SliceAndDice.super.prototype.RotateHorizontal(self)

	self:RotateFrame(self.durationFrame)
end

function SliceAndDice.prototype:ResetRotation()
	SliceAndDice.super.prototype.ResetRotation(self)

	if self.durationFrame.anim then
		self.durationFrame.anim:Stop()
	end
end

-- 'Protected' methods --------------------------------------------------------

function SliceAndDice.prototype:GetBuffDuration(unitName, buffName)
	local i = 1
	local buff, rank, texture, count, type, duration, endTime, remaining
	if IceHUD.WowVer >= 30000 then
		buff, rank, texture, count, type, duration, endTime = UnitBuff(unitName, i)
	else
		buff, rank, texture, count, duration, remaining = UnitBuff(unitName, i)
	end

	while buff do
		if (texture and string.match(texture, buffName)) then
			if endTime and not remaining then
				remaining = endTime - GetTime()
			end
			return duration, remaining
		end

		i = i + 1;

		if IceHUD.WowVer >= 30000 then
			buff, rank, texture, count, type, duration, endTime = UnitBuff(unitName, i)
		else
			buff, rank, texture, count, duration, remaining = UnitBuff(unitName, i)
		end
	end

	return nil, nil
end

function SliceAndDice.prototype:MyOnUpdate()
	SliceAndDice.super.prototype.MyOnUpdate(self)
	if self.bUpdateSnd then
		self:UpdateSliceAndDice(nil, self.unit, true)
	end
	if self.target then
		self:UpdateDurationBar()
	end
end

function SliceAndDice.prototype:UpdateSliceAndDice(event, unit, fromUpdate)
	if unit and unit ~= self.unit then
		return
	end

	local now = GetTime()
	local remaining = nil

	if not fromUpdate or IceHUD.WowVer < 30000 then
		sndDuration, remaining = self:GetBuffDuration(self.unit, "Ability_Rogue_SliceDice")

		if not remaining then
			sndEndTime = 0
		else
			sndEndTime = remaining + now
		end
	end

	if sndEndTime and sndEndTime >= now then
		if not fromUpdate then
			self.bUpdateSnd = true
		end

		self:Show(true)
		if not remaining then
			remaining = sndEndTime - now
		end
		local denominator = (self.moduleSettings.showAsPercentOfMax and CurrMaxSnDDuration or sndDuration)
		self:UpdateBar(denominator ~= 0 and remaining / denominator or 0, "SliceAndDice")
	else
		self:UpdateBar(0, "SliceAndDice")

		if ((IceHUD.WowVer >= 30000 and GetComboPoints(self.unit, "target") == 0) or (IceHUD.WowVer < 30000 and GetComboPoints() == 0)) or not UnitExists("target") then
			if self.bIsVisible then
				self.bUpdateSnd = nil
			end

			if not self.moduleSettings.alwaysFullAlpha then
				self:Show(false)
			end
		end
	end

	-- somewhat redundant, but we also need to check potential remaining time
	if (remaining ~= nil) or PotentialSnDDuration > 0 then
		local potText = " (" .. PotentialSnDDuration .. ")"
		self:SetBottomText1(self.moduleSettings.upperText .. tostring(floor(remaining or 0)) .. (self.moduleSettings.durationAlpha ~= 0 and potText or ""))
	end
end

function SliceAndDice.prototype:UpdateDurationBar(event, unit)
	if unit and unit ~= self.unit then
		return
	end

	local points
	if IceHUD.WowVer >= 30000 then
		points = GetComboPoints(self.unit, "target")
	else
		points = GetComboPoints("target")
	end
	local scale

	-- first, set the cached upper limit of SnD duration
	CurrMaxSnDDuration = self:GetMaxBuffTime(maxComboPoints)

	if event then
		self:UpdateSliceAndDice()
	end

	-- player doesn't want to show the percent of max or the alpha is zeroed out, so don't bother with the duration bar
	if not self.moduleSettings.showAsPercentOfMax or self.moduleSettings.durationAlpha == 0 or (points == 0 and not self:IsVisible()) then
		self.durationFrame:Hide()
		return
	end
	self.durationFrame:Show()

	-- if we have combo points and a target selected, go ahead and show the bar so the duration bar can be seen
	if points > 0 and UnitExists("target") then
		self:Show(true)
	end

	if self.moduleSettings.durationAlpha > 0 then
		PotentialSnDDuration = self:GetMaxBuffTime(points)

		-- compute the scale from the current number of combo points
		scale = IceHUD:Clamp(PotentialSnDDuration / CurrMaxSnDDuration, 0, 1)

		-- sadly, animation uses bar-local variables so we can't use the animation for 2 bar textures on the same bar element
		if (self.moduleSettings.reverse) then
			scale = 1 - scale
		end

		self.durationFrame.bar:SetVertexColor(self:GetColor("SliceAndDicePotential", self.moduleSettings.durationAlpha))
		self:SetBarCoord(self.durationFrame, scale)
	end

	if sndEndTime < GetTime() then
		local potText = " (" .. PotentialSnDDuration .. ")"
		self:SetBottomText1(self.moduleSettings.upperText .. "0" .. (self.moduleSettings.durationAlpha > 0 and potText or ""))
	end
end

function SliceAndDice.prototype:GetMaxBuffTime(numComboPoints)
	local maxduration

	if numComboPoints == 0 then
		return 0
	end

	maxduration = baseTime + ((numComboPoints - 1) * gapPerComboPoint)

	if self:HasNetherbladeBonus() then
		maxduration = maxduration + netherbladeBonus
	end

	if self:HasNineTailedBonus() then
		maxduration = maxduration + gapPerComboPoint
	end

	if IceHUD.WowVer < 50000 then
		if self:HasGlyphBonus() then
			maxduration = maxduration + glyphBonusSec
		end

		local rank = 0
		local _
		_, _, _, _, rank = GetTalentInfo(impSndTalentPage, impSndTalentIdx)

		maxduration = maxduration * (1 + (rank * impSndBonusPerRank))
	end

	return maxduration
end

function SliceAndDice.prototype:HasNetherbladeBonus()
	local numPieces
	local linkStr, itemId

	numPieces = 0

	-- run through all the possible equip locations of a netherblade piece
	for i=1,#NetherbladeEquipLocList do
		-- pull the link string for the item in this equip loc
		linkStr = GetInventoryItemLink(self.unit, NetherbladeEquipLocList[i])
		-- get the item id out of that link string
		itemId = self:GetItemIdFromItemLink(linkStr)

		-- check if the item id in that slot is part of the netherblade item id list
		if self:IsItemIdInList(itemId, NetherbladeItemIdList) then
			-- increment the fact that we have this piece of netherblade
			numPieces = numPieces + 1

			-- check if we've met the set bonus for slice and dice
			if numPieces >= 2 then
				return true
			end
		end
	end
end

function SliceAndDice.prototype:HasNineTailedBonus()
	local numPieces
	local linkStr, itemId

	numPieces = 0

	-- run through all the possible equip locations of a nine-tailed piece
	for i=1,#NetherbladeEquipLocList do
		-- pull the link string for the item in this equip loc
		linkStr = GetInventoryItemLink(self.unit, NetherbladeEquipLocList[i])
		-- get the item id out of that link string
		itemId = self:GetItemIdFromItemLink(linkStr)

		-- check if the item id in that slot is part of the nine-tailed item id list
		if self:IsItemIdInList(itemId, NineTailedItemIdList) then
			-- increment the fact that we have this piece of nine-tailed
			numPieces = numPieces + 1

			-- check if we've met the set bonus for slice and dice
			if numPieces >= 2 then
				return true
			end
		end
	end
end

function SliceAndDice.prototype:HasGlyphBonus()
	for i=1,GetNumGlyphSockets() do
		local enabled, _, _, spell = GetGlyphSocketInfo(i)

		if enabled and spell == GlyphSpellId then
			return true
		end
	end

	return false
end

function SliceAndDice.prototype:GetItemIdFromItemLink(linkStr)
	local itemId
	local _

	if linkStr then
		_, itemId, _, _, _, _, _, _, _ = strsplit(":", linkStr)
	end

	return itemId or 0
end

function SliceAndDice.prototype:IsItemIdInList(itemId, list)
	for i=1,#list do
		if string.match(itemId, list[i]) then
			return true
		end
	end

	return false
end

function SliceAndDice.prototype:OutCombat()
	SliceAndDice.super.prototype.OutCombat(self)

	self:UpdateSliceAndDice()
end

local _, unitClass = UnitClass("player")
-- Load us up
if unitClass == "ROGUE" then
	IceHUD.SliceAndDice = SliceAndDice:new()
end
