local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)

local validUnits = {"player", "target", "focus", "pet", "vehicle", "targettarget", "main hand weapon", "off hand weapon"}
local buffOrDebuff = {"buff", "debuff", "charges", "spell count"}

-- OVERRIDE
function IceStackCounter_GetOptions(frame, opts)
	opts["customHeader"] = {
		type = 'header',
		name = L["Aura settings"],
		order = 30.1,
	}

	opts["auraTarget"] = {
		type = 'select',
		values = validUnits,
		name = L["Unit to track"],
		desc = L["Select which unit that this bar should be looking for buffs/debuffs on"],
		get = function(info)
			return IceHUD:GetSelectValue(info, frame.moduleSettings.auraTarget)
		end,
		set = function(info, v)
			frame.moduleSettings.auraTarget = info.option.values[v]
			frame.unit = info.option.values[v]
			frame:Redraw()
			IceHUD:NotifyOptionsChange()
		end,
		disabled = function()
			return not frame.moduleSettings.enabled or frame.moduleSettings.auraType == "charges" or frame.moduleSettings.auraType == "spell count"
		end,
		order = 30.4,
	}

	opts["auraType"] = {
		type = 'select',
		values = buffOrDebuff,
		name = L["Buff or debuff?"],
		desc = L["Whether we are tracking a buff or debuff"],
		get = function(info)
			return IceHUD:GetSelectValue(info, frame.moduleSettings.auraType)
		end,
		set = function(info, v)
			frame.moduleSettings.auraType = info.option.values[v]
			frame:Redraw()
		end,
		disabled = function()
			return not frame.moduleSettings.enabled or frame.unit == "main hand weapon" or frame.unit == "off hand weapon"
		end,
		order = 30.5,
	}

	opts["auraName"] = {
		type = 'input',
		name = L["Aura to track"],
		desc = L["Which buff/debuff this counter will be tracking. \n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return frame.moduleSettings.auraName
		end,
		set = function(info, v)
			frame.moduleSettings.auraName = v
			frame:Redraw()
		end,
		disabled = function()
			return not frame.moduleSettings.enabled or frame.unit == "main hand weapon" or frame.unit == "off hand weapon"
		end,
		usage = "<which aura to track>",
		order = 30.6,
	}

	opts["trackOnlyMine"] = {
		type = 'toggle',
		name = L["Only track auras by me"],
		desc = L["Checking this means that only buffs or debuffs that the player applied will trigger this bar"],
		get = function()
			return frame.moduleSettings.onlyMine
		end,
		set = function(info, v)
			frame.moduleSettings.onlyMine = v
			frame:Redraw()
		end,
		disabled = function()
			return not frame.moduleSettings.enabled or frame.unit == "main hand weapon" or frame.unit == "off hand weapon"
				or frame.moduleSettings.auraType == "charges" or frame.moduleSettings.auraType == "spell count"
		end,
		order = 30.7,
	}

	opts["maxCount"] = {
		type = 'input',
		name = L["Maximum applications"],
		desc = L["How many total applications of this buff/debuff can be applied. For example, only 5 sunders can ever be on a target, so this would be set to 5 for tracking Sunder.\n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return tostring(frame.moduleSettings.maxCount)
		end,
		set = function(info, v)
			if not v or not tonumber(v) or tonumber(v) <= 0 then
				v = 5
			end
			frame.moduleSettings.maxCount = tonumber(v)
			frame:Redraw()
		end,
		disabled = function()
			return not frame.moduleSettings.enabled or frame.moduleSettings.auraType == "charges"
		end,
		usage = "<the maximum number of valid applications>",
		order = 30.9,
	}
end

function IceStackCounter_GetMaxCount(frame)
	if frame.moduleSettings.auraType == "charges" then
		local _, max = GetSpellCharges(frame.moduleSettings.auraName)
		return max or 1
	else
		return tonumber(frame.moduleSettings.maxCount)
	end
end

function IceStackCounter_GetDefaultSettings(defaults)
	defaults["maxCount"] = 5
	defaults["auraTarget"] = "player"
	defaults["auraName"] = ""
	defaults["onlyMine"] = true
	defaults["auraType"] = "buff"
end


function IceStackCounter_Enable(frame)
	frame:RegisterEvent("UNIT_AURA", "UpdateCustomCount")
	frame:RegisterEvent("UNIT_PET", "UpdateCustomCount")
	frame:RegisterEvent("PLAYER_PET_CHANGED", "UpdateCustomCount")
	frame:RegisterEvent("PLAYER_FOCUS_CHANGED", "UpdateCustomCount")
	frame:RegisterEvent("PLAYER_DEAD", "UpdateCustomCount")
	frame:RegisterEvent("SPELL_UPDATE_CHARGES", "UpdateCustomCount")

	frame.unit = frame.moduleSettings.auraTarget or "player"

	if not tonumber(frame.moduleSettings.maxCount) or tonumber(frame.moduleSettings.maxCount) <= 0 then
		frame.moduleSettings.maxCount = 5
		frame:Redraw()
	end
end

function IceStackCounter_GetCount(frame)
	if not frame.moduleSettings.auraName then
		return
	end

	local points
	if IceHUD.IceCore:IsInConfigMode() then
		points = tonumber(frame.moduleSettings.maxCount)
	else
		if frame.moduleSettings.auraType == "charges" then
			points = GetSpellCharges(frame.moduleSettings.auraName) or 0
		elseif frame.moduleSettings.auraType == "spell count" then
			points = GetSpellCount(frame.moduleSettings.auraName) or 0
		else
			points = IceHUD:GetAuraCount(frame.moduleSettings.auraType == "buff" and "HELPFUL" or "HARMFUL",
				frame.unit, frame.moduleSettings.auraName, frame.moduleSettings.onlyMine, true)
		end
	end

	frame.lastPoints = points

	if (points == 0) then
		points = nil
	end

	return points
end

function IceStackCounter_UseTargetAlpha(frame)
	if frame.moduleSettings.auraType == "charges" then
		return IceStackCounter_GetCount(frame) ~= IceStackCounter_GetMaxCount(frame) or frame.target or frame.combat
	else
		return frame.lastPoints ~= nil and frame.lastPoints > 0
	end
end
