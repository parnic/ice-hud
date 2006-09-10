local AceOO = AceLibrary("AceOO-2.0")

local TargetOfTarget = AceOO.Class(IceElement, "Metrognome-2.0")

TargetOfTarget.prototype.stackedDebuffs = nil
TargetOfTarget.prototype.buffSize = nil
TargetOfTarget.prototype.height = nil
TargetOfTarget.prototype.unit = nil


-- Constructor --
function TargetOfTarget.prototype:init()
	TargetOfTarget.super.prototype.init(self, "TargetOfTarget")
	
	self:SetColor("totHostile", 0.8, 0.1, 0.1)
	self:SetColor("totFriendly", 0.2, 1, 0.2)
	self:SetColor("totNeutral", 0.9, 0.9, 0)

	self.buffSize = 12
	self.height = 12
	self.stackedDebuffs = {}
	self.unit = "targettarget"

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

	if (self.moduleSettings.enabled) then
		self:CreateFrame()
	end
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
	if not (self.frame) then
		self.frame = CreateFrame("Button", "IceHUD_"..self.name, self.parent)
	end

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.settings.gap)
	self.frame:SetHeight(self.height)
	self.frame:SetPoint("TOP", self.parent, "TOP", 0, self.moduleSettings.vpos)
	self.frame:SetScale(self.moduleSettings.scale)

	if (not self.frame.texture) then
		self.frame.texture = self.frame:CreateTexture()
		self.frame.texture:SetTexture(IceElement.TexturePath .. "smooth")
		self.frame.texture:SetVertexColor(0.2, 0.2, 0.2, 0.3)
		self.frame.texture:SetAllPoints(self.frame)
	end
	
	self.frame.unit = self.unit -- for blizz default tooltip handling
	self.frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self.frame:SetScript("OnClick", function() self:OnClick(arg1) end)
	self.frame:SetScript("OnEnter", function() UnitFrame_OnEnter() end)
	self.frame:SetScript("OnLeave", function() UnitFrame_OnLeave() end)

	self:CreateBarFrame()
	self:CreateToTFrame()
	self:CreateToTHPFrame()
	self:CreateDebuffFrame()
end


function TargetOfTarget.prototype:CreateBarFrame()
	if (not self.frame.bar) then
		self.frame.bar = CreateFrame("StatusBar", nil, self.frame)
	end

	self.frame.bar:SetFrameStrata("BACKGROUND")
	self.frame.bar:SetWidth(self.settings.gap)
	self.frame.bar:SetHeight(self.height)

	self.frame.bar:SetPoint("LEFT", self.frame, "LEFT", 0, 0)

	if (not self.frame.bar.texture) then
		self.frame.bar.texture = self.frame.bar:CreateTexture()
		self.frame.bar.texture:SetTexture(IceElement.TexturePath .. "smooth")
		self.frame.bar.texture:SetAllPoints(self.frame.bar)
		self.frame.bar:SetStatusBarTexture(self.frame.bar.texture)
	end

	self.frame.bar:Show()
end


function TargetOfTarget.prototype:CreateToTFrame()
	self.frame.totName = self:FontFactory("Bold", self.moduleSettings.fontSize, self.frame.bar, self.frame.totName)
	
	self.frame.totName:SetWidth(self.settings.gap-40)
	self.frame.totName:SetHeight(self.height)
	self.frame.totName:SetJustifyH("LEFT")
	self.frame.totName:SetJustifyV("TOP")

	self.frame.totName:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
	self.frame.totName:Show()
end


function TargetOfTarget.prototype:CreateToTHPFrame()
	self.frame.totHealth = self:FontFactory("Bold", self.moduleSettings.fontSize, self.frame.bar, self.frame.totHealth)

	self.frame.totHealth:SetWidth(40)
	self.frame.totHealth:SetHeight(self.height)
	self.frame.totHealth:SetJustifyH("RIGHT")
	self.frame.totHealth:SetJustifyV("TOP")

	self.frame.totHealth:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
	self.frame.totHealth:Show()
end


function TargetOfTarget.prototype:CreateDebuffFrame()
	if (self.frame.debuffFrame) then
		return
	end
	self.frame.debuffFrame = CreateFrame("Frame", nil, self.frame)

	self.frame.debuffFrame:SetFrameStrata("BACKGROUND")
	self.frame.debuffFrame:SetWidth(10)
	self.frame.debuffFrame:SetHeight(self.height)

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
		
		buffs[i].stack = self:FontFactory("Bold", 11, buffs[i])
		buffs[i].stack:SetPoint("BOTTOMRIGHT" , buffs[i], "BOTTOMRIGHT", 0, -1)
	end
	return buffs
end


function TargetOfTarget.prototype:UpdateBuffs()
	local debuffs = 0
	
	if (self.moduleSettings.showDebuffs) then
		for i = 1, 16 do
			local buffTexture, buffApplications = UnitDebuff(self.unit, i)

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
	
	if not (UnitExists(self.unit)) then
		self.frame.totName:SetText()
		self.frame.totHealth:SetText()
		self.frame:Hide()
		return
	end

	self.frame:Show()

	local _, unitClass = UnitClass(self.unit)
	local name = UnitName(self.unit)
	local reaction = UnitReaction(self.unit, "player")

	local health = UnitHealth(self.unit)
	local maxHealth = UnitHealthMax(self.unit)
	local healthPercentage = math.floor( (health/maxHealth)*100 )
	
	local rColor = UnitReactionColor[reaction or 5]

	self.frame.totName:SetTextColor(rColor.r, rColor.g, rColor.b, 0.9)
	self.frame.totName:SetText(name)

	self.frame.totHealth:SetTextColor(rColor.r, rColor.g, rColor.b, 0.9)
	self.frame.totHealth:SetText(healthPercentage .. "%")

	self.frame.bar.texture:SetVertexColor(self:GetColor(unitClass, 0.7))
	self.frame.bar:SetMinMaxValues(0, maxHealth)
	self.frame.bar:SetValue(health)
end



function TargetOfTarget.prototype:OnClick(button)
	-- copy&paste from blizz code, it better work ;)
	if (SpellIsTargeting() and button == "RightButton") then
		SpellStopTargeting()
		return
	end

	if (button == "LeftButton") then
		if (SpellIsTargeting()) then
			SpellTargetUnit(self.unit)
		elseif (CursorHasItem()) then
			DropItemOnUnit(self.unit)
		else
			TargetUnit(self.unit)
		end
	else
		ToggleDropDownMenu(1, nil, TargetFrameDropDown, "cursor")
	end
end


-- load us up
TargetOfTarget:new()
