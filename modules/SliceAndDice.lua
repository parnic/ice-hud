local AceOO = AceLibrary("AceOO-2.0")

local SliceAndDice = AceOO.Class(IceUnitBar)

-- Constructor --
function SliceAndDice.prototype:init()
	SliceAndDice.super.prototype.init(self, "SliceAndDice", "player")

	self.moduleSettings = {}
	self.moduleSettings.desiredLerpTime = 0
	self.moduleSettings.shouldAnimate = false

	self:SetDefaultColor("SliceAndDice", 0.75, 1, 0.2)
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function SliceAndDice.prototype:Enable(core)
	SliceAndDice.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_AURAS_CHANGED", "UpdateSliceAndDice")

	self:ScheduleRepeatingEvent(self.elementName, self.UpdateSliceAndDice, 0.1, self)

	self:Show(false)
end

function SliceAndDice.prototype:Disable(core)
	SliceAndDice.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function SliceAndDice.prototype:GetDefaultSettings()
    local settings = SliceAndDice.super.prototype.GetDefaultSettings(self)

    settings["enabled"] = false
    settings["shouldAnimate"] = false
    settings["desiredLerpTime"] = nil
    settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 4
    settings["upperText"]="SnD:#"

    return settings
end

-- OVERRIDE
function SliceAndDice.prototype:GetOptions()
    local opts = SliceAndDice.super.prototype.GetOptions(self)
	
    opts["shouldAnimate"] = nil
    opts["desiredLerpTime"] = nil
    opts["lowThreshold"] = nil
    opts["textSettings"].args["lowerTextString"] = nil
    opts["textSettings"].args["lowerTextVisible"] = nil
    opts["textSettings"].args["upperTextString"]["desc"] = "The text to display under this bar. # will be replaced with the number of Slice and Dice seconds remaining."
    opts["textSettings"].args["lockLowerFontAlpha"] = nil
    
    return opts
end

-- 'Protected' methods --------------------------------------------------------

function _GetBuffDuration(unitName, buffName)
    local i = 1
    local buff, rank, texture, count, duration, remaining = UnitBuff(unitName, i)

    while buff do
        if (buff == buffName) then
            return duration, remaining
        end

        i = i + 1;

        buff, rank, texture, count, duration, remaining = UnitBuff(unitName, i)
    end

    return nil, nil
end

function SliceAndDice.prototype:UpdateSliceAndDice()
    local duration, remaining = _GetBuffDuration("player", "Slice and Dice")

    if (duration ~= nil) and (remaining ~= nil) then
        self:Show(true)
        self:UpdateBar(remaining / duration, "SliceAndDice")
        formatString = self.moduleSettings.upperText or ''
        self:SetBottomText1(string.gsub(formatString, "#", tostring(floor(remaining))))
    else
        self:Show(false)
    end
end

local _, unitClass = UnitClass("player")
-- Load us up
if unitClass == "ROGUE" then
    IceHUD.SliceAndDice = SliceAndDice:new()
end
