local AceOO = AceLibrary("AceOO-2.0")

local TargetCC = AceOO.Class(IceUnitBar)

-- Constructor --
function TargetCC.prototype:init()
    TargetCC.super.prototype.init(self, "TargetCC", "target")

    self.unit = "target"

    self.moduleSettings = {}
    self.moduleSettings.desiredLerpTime = 0
--    self.moduleSettings.shouldAnimate = false

    self:SetDefaultColor("CC:Stun", 0.85, 0.55, 0.2)
    self:SetDefaultColor("CC:Incapacitate", 0.90, 0.6, 0.2)
    self:SetDefaultColor("CC:Fear", 0.85, 0.2, 0.65)

    self.debuffList = {}
    self.debuffList["Kidney Shot"] = "Stun"
    self.debuffList["Cheap Shot"] = "Stun"
    self.debuffList["Mace Stun Effect"] = "Stun"
    self.debuffList["Shadowfury"] = "Stun"
    self.debuffList["Hammer of Justice"] = "Stun"
    self.debuffList["Impact"] = "Stun"
    self.debuffList["Blackout"] = "Stun"
    self.debuffList["Intimidation"] = "Stun"
    self.debuffList["Charge Stun"] = "Stun"
    self.debuffList["Intercept Stun"] = "Stun"
    self.debuffList["Revenge Stun"] = "Stun"
    self.debuffList["Concussion Blow"] = "Stun"
    self.debuffList["Bash"] = "Stun"
    self.debuffList["Pounce"] = "Stun"
    self.debuffList["Improved Concussive Shot"] = "Stun"
    self.debuffList["Starfire Stun"] = "Stun"
    self.debuffList["War Stomp"] = "Stun"

    self.debuffList["Repentance"] = "Incapacitate"
    self.debuffList["Sap"] = "Incapacitate"
    self.debuffList["Gouge"] = "Incapacitate"
    self.debuffList["Blind"] = "Incapacitate"
    self.debuffList["Wyvern Sting"] = "Incapacitate"
    self.debuffList["Scatter Shot"] = "Incapacitate"
    self.debuffList["Sleep"] = "Incapacitate"
    self.debuffList["Polymorph"] = "Incapacitate"
    self.debuffList["Polymorph: Pig"] = "Incapacitate"
    self.debuffList["Polymorph: Turtle"] = "Incapacitate"
    self.debuffList["Hibernate"] = "Incapacitate"
    self.debuffList["Freezing Trap Effect"] = "Incapacitate"
    self.debuffList["Chastize"] = "Incapacitate"
    self.debuffList["Maim"] = "Incapacitate"

    self.debuffList["Psychic Scream"] = "Fear"
    self.debuffList["Fear"] = "Fear"
    self.debuffList["Howl of Terror"] = "Fear"

    self.previousDebuff = nil
    self.previousDebuffTarget = nil
    self.previousDebuffTime = nil
end

-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function TargetCC.prototype:Enable(core)
    TargetCC.super.prototype.Enable(self, core)

    self:RegisterEvent("UNIT_AURA", "UpdateTargetDebuffs")

    self:ScheduleRepeatingEvent(self.elementName, self.UpdateTargetDebuffs, 0.1, self)

    self:Show(false)
end

function TargetCC.prototype:Disable(core)
	TargetCC.super.prototype.Disable(self, core)

	self:CancelScheduledEvent(self.elementName)
end

-- OVERRIDE
function TargetCC.prototype:GetDefaultSettings()
    local settings = TargetCC.super.prototype.GetDefaultSettings(self)

    settings["enabled"] = false
    settings["shouldAnimate"] = false
    settings["desiredLerpTime"] = nil
    settings["lowThreshold"] = 0
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 3

    return settings
end

-- OVERRIDE
function TargetCC.prototype:GetOptions()
	local opts = TargetCC.super.prototype.GetOptions(self)

	opts["shouldAnimate"] = nil
	opts["desiredLerpTime"] = nil
	opts["lowThreshold"] = nil
	opts["textSettings"].args["upperTextString"] = nil
	opts["textSettings"].args["lowerTextString"] = nil

	opts["alertParty"] = {
		type = "toggle",
		name = "Alert Party",
		desc = "Broadcasts crowd control effects you apply to your target via the party chat channel",
		get = function()
			return self.moduleSettings.alertParty
		end,
		set = function(v)
			self.moduleSettings.alertParty = v
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
	}

	return opts    
end
    
-- 'Protected' methods --------------------------------------------------------

function _GetMaxDebuffDuration(unitName, debuffNames)
    local i = 1
    local debuff, rank, texture, count, debuffType, duration, remaining = UnitDebuff(unitName, i)
    local result = {nil, nil, nil}

    while debuff do
        if debuffNames[debuff] then
            if result[0] then
                if result[2] < remaining then
                    result = {debuff, duration, remaining}
                end
            else
                result = {debuff, duration, remaining}
            end
        end

        i = i + 1;

        debuff, rank, texture, count, debuffType, duration, remaining = UnitDebuff(unitName, i)
    end

    return unpack(result)
end

function TargetCC.prototype:UpdateTargetDebuffs()
    local name, duration, remaining = _GetMaxDebuffDuration(self.unit, self.debuffList)
    local targetName = UnitName(self.unit)

    if (name ~= nil) and (self.previousDebuff == nil) and (duration ~= nil) and (remaining ~= nil) then
        if (duration > 1) and (self.moduleSettings.alertParty) and ((GetNumPartyMembers() >= 1) or (GetNumRaidMembers() >= 1)) then
            SendChatMessage(targetName .. ": " .. name .. " (" .. tostring(floor(remaining * 10) / 10) .. "/" .. tostring(duration) .. "s)", "PARTY")
        end

        self.previousDebuff = name
        self.previousDebuffTarget = targetName
        self.previousDebuffTime = GetTime() + duration
	-- Parnic: Force the CurrScale to 1 so that the lerping doesn't make it animate up and back down
	self.CurrScale = 1.0
    elseif (self.previousDebuff ~= nil) then
        if (targetName ~= self.previousDebuffTarget) then
            self.previousDebuff = nil
            self.previousDebuffTarget = nil
            self.previousDebuffTime = nil
        elseif (GetTime() > self.previousDebuffTime) then
            self.previousDebuff = nil
            self.previousDebuffTarget = nil
            self.previousDebuffTime = nil
        end
    end

    if (name ~= nil) then
        self:Show(true)

        if (duration ~= nil) then
            self:UpdateBar(remaining / duration, "CC:" .. self.debuffList[name])
            self:SetBottomText2(floor(remaining * 10) / 10)
        else
            self:UpdateBar(0, "CC:" .. self.debuffList[name])
            self:SetBottomText2("")
        end

        self:SetBottomText1(name)
    else
        self:Show(false)
    end
end

-- Load us up
IceHUD.TargetCC = TargetCC:new()
