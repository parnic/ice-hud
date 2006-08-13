local AceOO = AceLibrary("AceOO-2.0")

local TimerBar = AceOO.Class(IceBarElement, "AceHook-2.0", "Metrognome-2.0")


-- Constructor --
function TimerBar.prototype:init()
	TimerBar.super.prototype.init(self, "TimerBar")
	
	self:SetColor("timerFlight", 0.2, 0.7, 0.7)
end


-- 'Public' methods -----------------------------------------------------------

function TimerBar.prototype:GetDefaultSettings()
	local settings = TimerBar.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 3
	return settings
end


function TimerBar.prototype:Enable()
	TimerBar.super.prototype.Enable(self)
	
	self.frame.bottomUpperText:SetWidth(180)
	self.frame:Hide()
	
	self:Hook(ToFu, "OnUpdate")
end


function TimerBar.prototype:Disable()
	TimerBar.super.prototype.Disable(self)
	
	self:Unhook(ToFu, "OnUpdate")
end



-- 'Protected' methods --------------------------------------------------------

function TimerBar.prototype:OnUpdate(object, timeSinceLast)
	self.hooks[object].OnUpdate.orig(object, timeSinceLast)
	
	if (ToFu.inFlight) then
		local flightTime = ToFu.fullData.paths[ace.char.faction][ToFu.start][ToFu.destination].time
		
		if (flightTime ~= 0) then
			local timeRemaining = flightTime - ToFu.timeFlown
			
			self.frame:Show()
			self:UpdateBar(timeRemaining / flightTime, "timerFlight")
			--local text = string.format("%.1fs", timeRemaining)
			local text = FuBarUtils.FormatDurationCondensed(timeRemaining)
			self:SetBottomText1(text)
			
			return
		end
	end
	self.frame:Hide()
end




-- Load us up
if (IsAddOnLoaded("FuBar_ToFu")) then
	TimerBar:new()
end
