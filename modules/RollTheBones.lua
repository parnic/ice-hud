local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local RollTheBones = IceCore_CreateClass(IceUnitBar)

local IceHUD = _G.IceHUD

local baseTime = 12
local gapPerComboPoint = 6
local maxComboPoints = 5
local rtbEndTime = 0
local rtbDuration = 0
local rtbCount = 0

local CurrMaxRtBDuration = 0
local PotentialRtBDuration = 0

local RtBBuffs = {199603, 193358, 193357, 193359, 199600, 193356}
local RtBSet = {}
for _, v in ipairs(RtBBuffs) do
  RtBSet[v] = true
end

-- Constructor --
function RollTheBones.prototype:init()
  RollTheBones.super.prototype.init(self, "RollTheBones", "player")

  self.moduleSettings = {}
  self.moduleSettings.desiredLerpTime = 0
  self.moduleSettings.shouldAnimate = false

  self:SetDefaultColor("RollTheBones", 1, 0.6, 0.2)
  self:SetDefaultColor("RollTheBones2", 0.75, 1, 0.2)
  self:SetDefaultColor("RollTheBones3", 0.4, 1, 0.2)
  self:SetDefaultColor("RollTheBones6", 0.1, 1, 0.7)
  self:SetDefaultColor("RollTheBonesPotential", 1, 1, 1)

  self.bTreatEmptyAsFull = true
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function RollTheBones.prototype:Enable(core)
  RollTheBones.super.prototype.Enable(self, core)

  self:RegisterEvent("UNIT_AURA", "UpdateRollTheBones")
  self:RegisterEvent("UNIT_POWER", "ComboPointsChanged")

  if not self.moduleSettings.alwaysFullAlpha then
    self:Show(false)
  else
    self:UpdateRollTheBones()
  end

  self:SetBottomText1("")
end

function RollTheBones.prototype:Disable(core)
  RollTheBones.super.prototype.Disable(self, core)
end

function RollTheBones.prototype:ComboPointsChanged(...)
  if select('#', ...) >= 3 and select(1, ...) == "UNIT_POWER" and select(3, ...) ~= "COMBO_POINTS" then
    return
  end

  self:TargetChanged()
  self:UpdateDurationBar()
end

-- OVERRIDE
function RollTheBones.prototype:GetDefaultSettings()
  local settings = RollTheBones.super.prototype.GetDefaultSettings(self)

  settings["enabled"] = false
  settings["shouldAnimate"] = false
  settings["desiredLerpTime"] = nil
  settings["lowThreshold"] = 0
  settings["side"] = IceCore.Side.Right
  settings["offset"] = 6
  settings["upperText"]="RtB:"
  settings["showAsPercentOfMax"] = true
  settings["durationAlpha"] = 0.6
  settings["usesDogTagStrings"] = false
  settings["lockLowerFontAlpha"] = false
  settings["lowerTextString"] = ""
  settings["lowerTextVisible"] = false
  settings["hideAnimationSettings"] = true
  settings["bAllowExpand"] = true
  settings["bShowWithNoTarget"] = true
  settings["bUseMultipleBuffColors"] = true

  return settings
end

-- OVERRIDE
function RollTheBones.prototype:GetOptions()
  local opts = RollTheBones.super.prototype.GetOptions(self)

  opts["textSettings"].args["upperTextString"]["desc"] = "The text to display under this bar. # will be replaced with the number of Roll the Bones seconds remaining."
  opts["textSettings"].args["upperTextString"].hidden = false

  opts["showAsPercentOfMax"] =
  {
    type = 'toggle',
    name = L["Show bar as % of maximum"],
    desc = L["If this is checked, then the RtB buff time shows as a percent of the maximum attainable (taking set bonuses and talents into account). Otherwise, the bar always goes from full to empty when applying RtB no matter the duration."],
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
    name = L["Potential RtB time bar alpha"],
    desc = L["What alpha value to use for the bar that displays how long your RtB will last if you activate it. (This gets multiplied by the bar's current alpha to stay in line with the bar on top of it)"],
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

  opts["bShowWithNoTarget"] =
  {
    type = 'toggle',
    name = L["Show with no target"],
    desc = L["Whether or not to display when you have no target selected but have combo points available"],
    get = function()
      return self.moduleSettings.bShowWithNoTarget
    end,
    set = function(info, v)
      self.moduleSettings.bShowWithNoTarget = v
      self:ComboPointsChanged()
    end,
    disabled = function()
      return not self.moduleSettings.enabled
    end,
  }

  opts["bUseMultipleBuffColors"] =
  {
    type = 'toggle',
    name = L["Use multiple buff colors"],
    desc = L["If this is checked, then the bar uses different colors depending on how many RtB buffs you have"],
    get = function()
      return self.moduleSettings.bUseMultipleBuffColors
    end,
    set = function(info, v)
      self.moduleSettings.bUseMultipleBuffColors = v
      self:Redraw()
    end,
    disabled = function()
      return not self.moduleSettings.enabled
    end,
  }

  return opts
end

function RollTheBones.prototype:CreateFrame()
  RollTheBones.super.prototype.CreateFrame(self)

  self:CreateDurationBar()
end

function RollTheBones.prototype:CreateDurationBar()
  self.durationFrame = self:BarFactory(self.durationFrame, "BACKGROUND","ARTWORK")

  -- Rokiyo: Do we need to call this here?
  self.CurrScale = 0

  self.durationFrame.bar:SetVertexColor(self:GetColor("RollTheBonesPotential", self.moduleSettings.durationAlpha))
  self.durationFrame.bar:SetHeight(0)

  self:UpdateBar(1, "undef")

  -- force update the bar...if we're in here, then either the UI was just loaded or the player is jacking with the options.
  -- either way, make sure the duration bar matches accordingly
  self:UpdateDurationBar()
end

function RollTheBones.prototype:RotateHorizontal()
  RollTheBones.super.prototype.RotateHorizontal(self)

  self:RotateFrame(self.durationFrame)
end

function RollTheBones.prototype:ResetRotation()
  RollTheBones.super.prototype.ResetRotation(self)

  if self.durationFrame and self.durationFrame.anim then
    self.durationFrame.anim:Stop()
  end
end

-- 'Protected' methods --------------------------------------------------------

function RollTheBones.prototype:GetBuffDuration(unitName, ids)
  local i = 1
  local buff, rank, texture, type, duration, endTime, remaining, spellId
  buff, _, _, _, type, duration, endTime, _, _, _, spellId = UnitBuff(unitName, i)

  local realDuration, remaining, count
  local now = GetTime()

  count = 0
  while buff do
    if (spellId and ids[spellId]) then
      if endTime then
        realDuration = duration
        remaining = endTime - now
        count = count + 1
      end
    end

    i = i + 1;

    buff, _, _, _, type, duration, endTime, _, _, _, spellId = UnitBuff(unitName, i)

  end

  if count > 0 then
    return realDuration, remaining, count
  else
    return nil, nil, 0
  end
end

function RollTheBones.prototype:MyOnUpdate()
  RollTheBones.super.prototype.MyOnUpdate(self)
  if self.bUpdateRtb then
    self:UpdateRollTheBones(nil, self.unit, true)
  end
  if self.target or self.moduleSettings.bShowWithNoTarget then
    self:UpdateDurationBar()
  end
end

local function RTBGetComboPoints(unit)
  return UnitPower(unit, SPELL_POWER_COMBO_POINTS)
end

-- use this to figure out if Roll the Bones is available or not. neither IsSpellKnown nor IsPlayerSpell are correct for it
-- when SnD is known, but this is.
local function HasSpell(id)
    local spell = GetSpellInfo(id)
    return spell == GetSpellInfo(spell)
end

local function ShouldHide()
  return not HasSpell(193316)
end

function RollTheBones.prototype:UpdateRollTheBones(event, unit, fromUpdate)
  if unit and unit ~= self.unit then
    return
  end

  local now = GetTime()
  local remaining = nil

  if not fromUpdate then
    rtbDuration, remaining, rtbCount = self:GetBuffDuration(self.unit, RtBSet)

    if not remaining then
      rtbEndTime = 0
    else
      rtbEndTime = remaining + now
    end
  end

  if rtbEndTime and rtbEndTime >= now then
    if not fromUpdate then
      self.bUpdateRtb = true
    end

    self:Show(true)
    if not remaining then
      remaining = rtbEndTime - now
    end
    local denominator = (self.moduleSettings.showAsPercentOfMax and CurrMaxRtBDuration or rtbDuration)
    self:UpdateBar(denominator ~= 0 and remaining / denominator or 0, self:GetColorName(rtbCount))
  else
    self:UpdateBar(0, "RollTheBones")

    if RTBGetComboPoints(self.unit) == 0 or (not UnitExists("target") and not self.moduleSettings.bShowWithNoTarget) or ShouldHide() then
      if self.bIsVisible then
        self.bUpdateRtb = nil
      end

      if not self.moduleSettings.alwaysFullAlpha or ShouldHide() then
        self:Show(false)
      end
    end
  end

  -- somewhat redundant, but we also need to check potential remaining time
  if (remaining ~= nil) or PotentialRtBDuration > 0 then
    local potText = " (" .. PotentialRtBDuration .. ")"
    self:SetBottomText1(self.moduleSettings.upperText .. tostring(floor(remaining or 0)) .. (self.moduleSettings.durationAlpha ~= 0 and potText or ""))
  end
end

function RollTheBones.prototype:GetColorName(count)
  if self.moduleSettings.bUseMultipleBuffColors and count >= 2 then
    return "RollTheBones"..count
  else
    return "RollTheBones"
  end
end

function RollTheBones.prototype:TargetChanged()
  if self.moduleSettings.bShowWithNoTarget and RTBGetComboPoints(self.unit) > 0 then
    self.target = true
  else
    self.target = UnitExists("target")
  end
  self:Update(self.unit)

  self:UpdateDurationBar()
  self:UpdateRollTheBones()
end

function RollTheBones.prototype:UpdateDurationBar(event, unit)
  if unit and unit ~= self.unit then
    return
  end

  local points = RTBGetComboPoints(self.unit)
  -- check for Deeper Stratagem
  local _, _, _, DeeperStratagem = GetTalentInfo(3, 1, 1)

  if DeeperStratagem then
    -- first, set the cached upper limit of RtB duration
    CurrMaxRtBDuration = self:GetMaxBuffTime(maxComboPoints + 1)
  else
    CurrMaxRtBDuration = self:GetMaxBuffTime(maxComboPoints)
  end

  if event then
    self:UpdateRollTheBones()
  end

  -- player doesn't want to show the percent of max or the alpha is zeroed out, so don't bother with the duration bar
  if not self.moduleSettings.showAsPercentOfMax or self.moduleSettings.durationAlpha == 0 or (points == 0 and not self:IsVisible())
    or ShouldHide() then
    self.durationFrame:Hide()
    return
  end
  self.durationFrame:Show()

  -- if we have combo points and a target selected, go ahead and show the bar so the duration bar can be seen
  if points > 0 and (UnitExists("target") or self.moduleSettings.bShowWithNoTarget) then
    self:Show(true)
  end

  if self.moduleSettings.durationAlpha > 0 then
    PotentialRtBDuration = self:GetMaxBuffTime(points)

    -- compute the scale from the current number of combo points
    local scale = IceHUD:Clamp(PotentialRtBDuration / CurrMaxRtBDuration, 0, 1)

    -- sadly, animation uses bar-local variables so we can't use the animation for 2 bar textures on the same bar element
    if (self.moduleSettings.reverse) then
      scale = 1 - scale
    end

    self.durationFrame.bar:SetVertexColor(self:GetColor("RollTheBonesPotential", self.moduleSettings.durationAlpha))
    self:SetBarCoord(self.durationFrame, scale)
  end

  if rtbEndTime < GetTime() then
    local potText = " (" .. PotentialRtBDuration .. ")"
    self:SetBottomText1(self.moduleSettings.upperText .. "0" .. (self.moduleSettings.durationAlpha > 0 and potText or ""))
  end
end

function RollTheBones.prototype:GetMaxBuffTime(numComboPoints)
  local maxduration

  if numComboPoints == 0 then
    return 0
  end

  maxduration = baseTime + ((numComboPoints - 1) * gapPerComboPoint)

  return maxduration
end

function RollTheBones.prototype:GetItemIdFromItemLink(linkStr)
  local itemId
  local _

  if linkStr then
    _, itemId, _, _, _, _, _, _, _ = strsplit(":", linkStr)
  end

  return itemId or 0
end

function RollTheBones.prototype:IsItemIdInList(itemId, list)
  for i=1,#list do
    if string.match(itemId, list[i]) then
      return true
    end
  end

  return false
end

function RollTheBones.prototype:OutCombat()
  RollTheBones.super.prototype.OutCombat(self)

  self:UpdateRollTheBones()
end

local _, unitClass = UnitClass("player")
-- Load us up
if unitClass == "ROGUE" and IceHUD.WowVer >= 70000 then
  IceHUD.RollTheBones = RollTheBones:new()
end
