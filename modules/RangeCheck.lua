local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local RangeCheck = IceCore_CreateClass(IceElement)
RangeCheck.prototype.scheduledEvent = nil

local LibRange = nil
local DogTag = nil

-- Constructor --
function RangeCheck.prototype:init()
	RangeCheck.super.prototype.init(self, "RangeCheck")

	self.scalingEnabled = true

	LibRange = LibStub("LibRangeCheck-3.0", true)
end

function RangeCheck.prototype:Enable(core)
	RangeCheck.super.prototype.Enable(self, core)

	if IceHUD.IceCore:ShouldUseDogTags() then
		DogTag = LibStub("LibDogTag-3.0", true)
		self:RegisterFontStrings()
	else
		self.scheduledEvent = self:ScheduleRepeatingTimer("UpdateRange", 0.1)
	end
end

function RangeCheck.prototype:Disable(core)
	RangeCheck.super.prototype.Disable(self, core)

	if DogTag then
		self:UnregisterFontStrings()
	else
		self:CancelTimer(self.scheduledEvent, true)
	end
end

function RangeCheck.prototype:GetDefaultSettings()
	local defaults =  RangeCheck.super.prototype.GetDefaultSettings(self)

	defaults["rangeString"] = "Range: [HostileColor Range]"
	defaults["vpos"] = 220
	defaults["hpos"] = 0
	defaults["enabled"] = false

	return defaults
end

function RangeCheck.prototype:GetOptions()
	local opts = RangeCheck.super.prototype.GetOptions(self)

	self:AddDragMoveOption(opts, 30.91)

	opts["vpos"] = {
		type = "range",
		name = L["Vertical Position"],
		desc = L["Vertical Position"],
		get = function()
			return IceHUD:MathRound(self.moduleSettings.vpos)
		end,
		set = function(info, v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -300,
		max = 600,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["hpos"] = {
		type = "range",
		name = L["Horizontal Position"],
		desc = L["Horizontal Position"],
		get = function()
			return IceHUD:MathRound(self.moduleSettings.hpos)
		end,
		set = function(info, v)
			self.moduleSettings.hpos = v
			self:Redraw()
		end,
		min = -500,
		max = 500,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["rangeString"] = {
		type = 'input',
		name = L["Range string"],
		desc = L["DogTag-formatted string to use for the range display (only available if LibDogTag is being used)\n\nType /dogtag for a list of available tags"],
		get = function()
			return self.moduleSettings.rangeString
		end,
		set = function(info, v)
			---@diagnostic disable-next-line: need-check-nil, undefined-field
			v = DogTag:CleanCode(v)
			self.moduleSettings.rangeString = v
			self:RegisterFontStrings()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not DogTag or not LibRange
		end,
		usage = '',
		order = 33
	}

	return opts
end

function RangeCheck.prototype:Redraw()
	RangeCheck.super.prototype.Redraw(self)

	if (self.moduleSettings.enabled) then
		self:CreateFrame(true)
	end

	if self:IsInConfigMode() then
		self:UnregisterFontStrings()
		self:Update()
		self:UpdateRange()
	elseif DogTag then
		self:RegisterFontStrings()
	end
end

function RangeCheck.prototype:CreateFrame(redraw)
	if not (self.frame) then
		self.frame = CreateFrame("Frame", "IceHUD_"..self.elementName, self.parent)
	end

	self:CreateMoveHintFrame()

	self.frame:SetScale(self.moduleSettings.scale)
	self.frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata("BACKGROUND"))
	self.frame:SetWidth(200)
	self.frame:SetHeight(32)
	self.frame:ClearAllPoints()
	self:SetFramePosition()

	if not self.frame.rangeFontString then
		self.frame.rangeFontString = self:FontFactory(--[[self.moduleSettings.fontSize+1]] 13, self.frame, self.frame.rangeFontString)
	end
	self.frame.rangeFontString:SetJustifyH("CENTER")
	self.frame.rangeFontString:SetJustifyV("TOP")
	self.frame.rangeFontString:SetAllPoints(self.frame)
end

function RangeCheck.prototype:RegisterFontStrings()
	if DogTag and LibRange and not self.registered then
		DogTag:AddFontString(self.frame.rangeFontString, self.frame, self.moduleSettings.rangeString, "Unit", { unit = "target" })
		DogTag:UpdateAllForFrame(self.frame)
		self.registered = true
	end
end

function RangeCheck.prototype:UnregisterFontStrings()
	if DogTag and self.registered then
		DogTag:RemoveFontString(self.frame.rangeFontString)
		self.registered = false
	end
end

-- this function is called every 0.1 seconds only if LibDogTag is not being used
function RangeCheck.prototype:UpdateRange()
	local text
	if LibRange and UnitExists("target") then
		local min, max = LibRange:getRange("target")
		if min then
			if max then
				text = "Range: " .. min .. " - " .. max
			else
				text = "Range: " .. min .. "+"
			end
		else
			text = "Unknown"
		end

		self.frame.rangeFontString:SetWidth(0)
	end

	if not text and self:IsInConfigMode() then
		text = "RangeCheck"
	end

	self.frame.rangeFontString:SetText(text)
end

function RangeCheck.prototype:ToggleMoveHint()
	RangeCheck.super.prototype.ToggleMoveHint(self)
	self:UpdateRange()
end

IceHUD.RangeCheck = RangeCheck:new()
