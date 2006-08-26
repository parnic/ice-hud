local AceOO = AceLibrary("AceOO-2.0")

local TargetOfTarget = AceOO.Class(IceElement, "Metrognome-2.0")

TargetOfTarget.prototype.stackedDebuffs = nil
TargetOfTarget.prototype.buffSize = nil


-- Constructor --
function TargetOfTarget.prototype:init()
	TargetOfTarget.super.prototype.init(self, "TargetOfTarget")
	
	self:SetColor("totHostile", 0.8, 0.1, 0.1)
	self:SetColor("totFriendly", 0.2, 1, 0.2)
	self:SetColor("totNeutral", 0.9, 0.9, 0)
	
	self.buffSize = 15
	self.stackedDebuffs = {}

	self.scalingEnabled = true
end


-- OVERRIDE
function TargetOfTarget.prototype:GetOptions()
	local opts = TargetOfTarget.super.prototype.GetOptions(self)
	
	opts["vpos"] = {
		type = "range",
		name = "Vertical Position",
		desc = "Vertical Position",
		get = function()
			return self.moduleSettings.vpos
		end,
		set = function(v)
			self.moduleSettings.vpos = v
			self:Redraw()
		end,
		min = -300,
		max = 300,
		step = 10,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}

	opts["showDebuffs"] = {
		type = "toggle",
		name = "Show stacking debuffs",
		desc = "Show stacking debuffs in ToT info",
		get = function()
			return self.moduleSettings.showDebuffs
		end,
		set = function(value)
			self.moduleSettings.showDebuffs = value
			self:UpdateBuffs()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}
	
	opts["fontSize"] = {
		type = 'range',
		name = 'Font Size',
		desc = 'Font Size',
		get = function()
			return self.moduleSettings.fontSize
		end,
		set = function(v)
			self.moduleSettings.fontSize = v
			self:Redraw()
		end,
		min = 8,
		max = 20,
		step = 1,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 33
	}
	
	return opts
end


-- OVERRIDE
function TargetOfTarget.prototype:GetDefaultSettings()
	local defaults =  TargetOfTarget.super.prototype.GetDefaultSettings(self)
	defaults["vpos"] = -50
	defaults["showDebuffs"] = true
	defaults["fontSize"] = 13
	return defaults
end


-- OVERRIDE
function TargetOfTarget.prototype:Redraw()
	TargetOfTarget.super.prototype.Redraw(self)
	
	self:CreateFrame()
end


function TargetOfTarget.prototype:Enable(core)
	TargetOfTarget.super.prototype.Enable(self, core)
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "Update")
	
	self:RegisterMetro(self.name, self.Update, 0.33, self)
	self:StartMetro(self.name)
	
	self:Update()
end


function TargetOfTarget.prototype:Disable(core)
	TargetOfTarget.super.prototype.Disable(self, core)
	self:UnregisterMetro(self.name)
end


-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function TargetOfTarget.prototype:CreateFrame()
	TargetOfTarget.super.prototype.CreateFrame(self)
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(260)
	self.frame:SetHeight(50)
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", 0, self.moduleSettings.vpos)
	self.frame:SetScale(self.moduleSettings.scale)
	self.frame:Show()
	
	self:CreateToTFrame()
	self:CreateToTHPFrame()
	self:CreateDebuffFrame()
end


function TargetOfTarget.prototype:CreateToTFrame()
	self.frame.totName = self:FontFactory("Bold", self.moduleSettings.fontSize+1, nil, self.frame.totName)
	
	self.frame.totName:SetWidth(120)
	self.frame.totName:SetHeight(14)
	self.frame.totName:SetJustifyH("RIGHT")
	self.frame.totName:SetJustifyV("BOTTOM")
	
	self.frame.totName:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -2)
	self.frame.totName:Show()
end


function TargetOfTarget.prototype:CreateToTHPFrame()
	self.frame.totHealth = self:FontFactory(nil, self.moduleSettings.fontSize, nil, self.frame.totHealth)
	
	self.frame.totHealth:SetWidth(120)
	self.frame.totHealth:SetHeight(14)
	self.frame.totHealth:SetJustifyH("RIGHT")
	self.frame.totHealth:SetJustifyV("TOP")
	
	self.frame.totHealth:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -16)
	self.frame.totHealth:Show()
end


function TargetOfTarget.prototype:CreateDebuffFrame()
	if (self.frame.debuffFrame) then
		return
	end
	self.frame.debuffFrame = CreateFrame("Frame", nil, self.frame)

	self.frame.debuffFrame:SetFrameStrata("BACKGROUND")
	self.frame.debuffFrame:SetWidth(200)
	self.frame.debuffFrame:SetHeight(20)

	self.frame.debuffFrame:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
	self.frame.debuffFrame:Show()

	self.frame.debuffFrame.buffs = self:CreateIconFrames(self.frame.debuffFrame)
end


function TargetOfTarget.prototype:CreateIconFrames(parent)
	local buffs = {}
	
	for i = 1, 16 do
		buffs[i] = CreateFrame("Frame", nil, parent)
		buffs[i]:SetFrameStrata("BACKGROUND")
		buffs[i]:SetWidth(self.buffSize)
		buffs[i]:SetHeight(self.buffSize)
		buffs[i]:SetPoint("LEFT", (i-1) * self.buffSize + (i-1), 0)
		buffs[i]:Show()
		
		buffs[i].texture = buffs[i]:CreateTexture()
		buffs[i].texture:SetTexture(nil)
		buffs[i].texture:SetAllPoints(buffs[i])
		
		buffs[i].stack = self:FontFactory("Bold", 15, buffs[i])
		buffs[i].stack:SetPoint("BOTTOMRIGHT" , buffs[i], "BOTTOMRIGHT", 0, -1)
	end
	return buffs
end


function TargetOfTarget.prototype:UpdateBuffs()
	local debuffs = 0
	
	if (self.moduleSettings.showDebuffs) then
		for i = 1, 16 do
			local buffTexture, buffApplications = UnitDebuff("targettarget", i)
	
			if (buffApplications and (buffApplications > 1)) then
				debuffs = debuffs + 1
				
				if not (self.stackedDebuffs[debuffs]) then
					self.stackedDebuffs[debuffs] = {}
				end
				
				self.stackedDebuffs[debuffs].texture = buffTexture
				self.stackedDebuffs[debuffs].count = buffApplications
			end
		end
	end
	
	for i = 1, 16 do
		if (self.moduleSettings.showDebuffs and (i <= debuffs)) then
			self.frame.debuffFrame.buffs[i].texture:SetTexture(self.stackedDebuffs[i].texture)
			self.frame.debuffFrame.buffs[i].stack:SetText(self.stackedDebuffs[i].count)
		else
			self.frame.debuffFrame.buffs[i].texture:SetTexture(nil)
			self.frame.debuffFrame.buffs[i].stack:SetText(nil)
		end
	end
end


function TargetOfTarget.prototype:Update()
	self:UpdateBuffs()
	
	if not (UnitExists("targettarget")) then
		self.frame.totName:SetText()
		self.frame.totHealth:SetText()
		return
	end
	
	local _, unitClass = UnitClass("targettarget")
	local name = UnitName("targettarget")
	
	self.frame.totName:SetTextColor(self:GetColor(unitClass, 1))
	self.frame.totName:SetText(name)
	
	
	local color = "totFriendly" -- friendly > 4
	local reaction = UnitReaction("targettarget", "player")
	if (reaction and (reaction == 4)) then
		color = "totNeutral"
	elseif (reaction and (reaction < 4)) then
		color = "totHostile"
	end
	
	local health = UnitHealth("targettarget")
	local maxHealth = UnitHealthMax("targettarget")
	local healthPercentage = math.floor( (health/maxHealth)*100 )
	
	self.frame.totHealth:SetTextColor(self:GetColor(color, 1))
	self.frame.totHealth:SetText(healthPercentage .. "%")
end



-- load us up
TargetOfTarget:new()
