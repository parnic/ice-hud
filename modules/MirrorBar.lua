local AceOO = AceLibrary("AceOO-2.0")

-- 2 classes in the same file.. ugly but keeps the idea of
-- "1 module, 1 file" intact


-------------------------------------------------------------------------------
-- MirrorBar                                                                 --
-------------------------------------------------------------------------------

local MirrorBar = AceOO.Class(IceBarElement)

MirrorBar.prototype.timer = nil
MirrorBar.prototype.value = nil
MirrorBar.prototype.maxValue = nil
MirrorBar.prototype.scale = nil
MirrorBar.prototype.paused = nil
MirrorBar.prototype.label = nil


-- Constructor --
function MirrorBar.prototype:init(side, offset, name)
	MirrorBar.super.prototype.init(self, name)
	self.side = side
	self.offset = offset

	-- unregister the event superclass registered, we don't want to register
	-- this to the core
	self:UnregisterEvent(IceCore.Loaded)
end


function MirrorBar.prototype:Enable()
	MirrorBar.super.prototype.Enable(self)
	
	self.frame.bottomUpperText:SetWidth(200)
	self.frame.bottomLowerText:SetWidth(200)

	self.frame:Hide()
end


function MirrorBar.prototype:OnUpdate(elapsed)
	if (self.paused) then
		return
	end

	self.value = self.value + (self.scale * elapsed * 1000)
	
	scale = self.value / self.maxValue
	
	if (scale < 0) then -- lag compensation
		scale = 0
	end
	if (scale > 1) then -- lag compensation
		scale = 1
	end

	
	local timeRemaining = (self.maxValue - self.value) / 1000
	local remaining = string.format("%.1f", timeRemaining)
	
	if (timeRemaining < 0) then -- lag compensation
		remaining = 0
	end

	self:UpdateBar(scale, self.timer)
	
	local text = self.label .. " " .. remaining .. "s"
	
	if (math.mod(self.offset, 2) == 1) then
		self:SetBottomText1(text)
	else
		self:SetBottomText2(text, "text", 1)
	end
end


function MirrorBar.prototype:MirrorStart(timer, value, maxValue, scale, paused, label)
	self.timer = timer
	self.value = value
	self.maxValue = maxValue
	self.scale = scale
	self.paused = (paused > 0)
	self.label = label
	
	self.startTime = GetTime()

	self.frame:Show()
	self.frame:SetScript("OnUpdate", function() self:OnUpdate(arg1) end)
end


function MirrorBar.prototype:MirrorStop()
	self:CleanUp()
	self.frame:Hide()
	self.frame:SetScript("OnUpdate", nil)
end


function MirrorBar.prototype:MirrorPause(paused)
	if (paused > 0) then
		self.paused = true
	else
		self.paused = false
	end
end


function MirrorBar.prototype:CleanUp()
	self.timer = nil
	self.value = nil
	self.maxValue = nil
	self.scale = nil
	self.paused = nil
	self.label = nil
	self.startTime = nil
	self:SetBottomText1()
	self:SetBottomText2()
end





-------------------------------------------------------------------------------
-- MirrorBarHandler                                                          --
-------------------------------------------------------------------------------


local MirrorBarHandler = AceOO.Class(IceElement)

MirrorBarHandler.prototype.bars = nil


-- Constructor --
function MirrorBarHandler.prototype:init()
	MirrorBarHandler.super.prototype.init(self, "MirrorBarHandler")
	self.side = IceCore.Side.Left
	self.offset = 3
	
	self.bars = {}

	self:SetColor("EXHAUSTION", 1, 0.9, 0)
	self:SetColor("BREATH", 0, 0.5, 1)
	self:SetColor("DEATH", 1, 0.7, 0)
	self:SetColor("FEIGNDEATH", 1, 0.9, 0)
end


function MirrorBarHandler.prototype:Enable()
	MirrorBarHandler.super.prototype.Enable(self)
	self:RegisterEvent("MIRROR_TIMER_START", "MirrorStart")
	self:RegisterEvent("MIRROR_TIMER_STOP", "MirrorStop")
	self:RegisterEvent("MIRROR_TIMER_PAUSE", "MirrorPause")
	
	-- hide blizz mirror bar
	UIParent:UnregisterEvent("MIRROR_TIMER_START");
end


function MirrorBarHandler.prototype:Disable()
	MirrorBarHandler.super.prototype.Disable(self)
	
	UIParent:RegisterEvent("MIRROR_TIMER_START");
end


function MirrorBarHandler.prototype:MirrorStart(timer, value, maxValue, scale, paused, label)
	local done = nil
	
	-- check if we can find an already running timer to reverse it
	for i = 1, table.getn(self.bars) do
		if (self.bars[i].timer == timer) then
			done = true
			self.bars[i]:MirrorStart(timer, value, maxValue, scale, paused, label)
		end
	end
	
	-- check if there's a free instance in case we didn't find an already running bar
	if not (done) then
		for i = 1, table.getn(self.bars) do
			if not (self.bars[i].timer) and not (done) then
				done = true
				self.bars[i]:MirrorStart(timer, value, maxValue, scale, paused, label)
			end
		end
	end
	
	-- finally create a new instance if no available ones were found
	if not (done) then
		local count = table.getn(self.bars)
		self.bars[count + 1] = MirrorBar:new(self.side, self.offset + count, "MirrorBar" .. tostring(count+1))
		self.bars[count + 1]:Create(self.parent)
		self.bars[count + 1]:Enable()
		self.bars[count + 1]:MirrorStart(timer, value, maxValue, scale, paused, label)
	end
end


function MirrorBarHandler.prototype:MirrorStop(timer)
	for i = 1, table.getn(self.bars) do
		if (self.bars[i].timer == timer) then
			self.bars[i]:MirrorStop()
		end
	end
end


function MirrorBarHandler.prototype:MirrorPause(paused)
	for i = 1, table.getn(self.bars) do
		if (self.bars[i].timer ~= nil) then
			self.bars[i]:MirrorPause(paused > 0)
		end
	end
end



-- Load us up
MirrorBarHandler:new()


