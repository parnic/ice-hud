local AceOO = AceLibrary("AceOO-2.0")

local PlayerMana = AceOO.Class(IceUnitBar)

PlayerMana.prototype.manaType = nil
PlayerMana.prototype.tickStart = nil

-- Constructor --
function PlayerMana.prototype:init()
	PlayerMana.super.prototype.init(self, "PlayerMana", "player")
	
	self:SetColor("playerMana", 62, 54, 152)
	self:SetColor("playerRage", 171, 59, 59)
	self:SetColor("playerEnergy", 218, 231, 31)
end


-- OVERRIDE
function PlayerMana.prototype:GetDefaultSettings()
	local settings = PlayerMana.super.prototype.GetDefaultSettings(self)
	settings["side"] = IceCore.Side.Right
	settings["offset"] = 1
	settings["tickerEnabled"] = true
	settings["tickerAlpha"] = 0.8
	return settings
end


-- OVERRIDE
function PlayerMana.prototype:GetOptions()
	local opts = PlayerMana.super.prototype.GetOptions(self)
	
	opts["tickerEnabled"] = {
		type = "toggle",
		name = "Show rogue/cat energy ticker",
		desc = "Show rogue/cat energy ticker",
		get = function()
			return self.moduleSettings.tickerEnabled
		end,
		set = function(value)
			self.moduleSettings.tickerEnabled = value
			self:ManaType(self.unit)
		end,
		order = 31
	}
	
	opts["tickerAlpha"] = 
	{
		type = 'range',
		name = 'Energy Ticker Alpha',
		desc = 'Energy Ticker Alpha',
		min = 0.1,
		max = 1,
		step = 0.05,
		get = function()
			return self.moduleSettings.tickerAlpha
		end,
		set = function(value)
			self.moduleSettings.tickerAlpha = value
			self.tickerFrame:SetStatusBarColor(self:GetColor("playerEnergy", self.moduleSettings.tickerAlpha))
		end,
		order = 32
	}
	
	return opts
end


function PlayerMana.prototype:Enable()
	PlayerMana.super.prototype.Enable(self)
	
	self:CreateTickerFrame()

	self:RegisterEvent("UNIT_MANA", "Update")
	self:RegisterEvent("UNIT_MAXMANA", "Update")
	self:RegisterEvent("UNIT_RAGE", "Update")
	self:RegisterEvent("UNIT_MAXRAGE", "Update")
	self:RegisterEvent("UNIT_ENERGY", "UpdateEnergy")
	self:RegisterEvent("UNIT_MAXENERGY", "Update")
	
	self:RegisterEvent("UNIT_DISPLAYPOWER", "ManaType")

	self:ManaType(self.unit)
end


function PlayerMana.prototype:ManaType(unit)
	if (unit ~= self.unit) then
		return
	end
	
	self.manaType = UnitPowerType(self.unit)
	
	-- register ticker for rogue energy
	if (self.moduleSettings.tickerEnabled and (self.manaType == 3) and self.alive) then
		self.tickerFrame:Show()
		self.tickerFrame:SetScript("OnUpdate", function() self:EnergyTick() end)
	else
		self.tickerFrame:Hide()
		self.tickerFrame:SetScript("OnUpdate", nil)
	end
	
	self:Update(self.unit)
end


function PlayerMana.prototype:Update(unit)
	PlayerMana.super.prototype.Update(self)
	if (unit and (unit ~= "player")) then
		return
	end
	
	if (self.manaType ~= 3) then
		self.tickerFrame:Hide()
	end
	
	local color = "playerMana"
	if not (self.alive) then
		color = "dead"
	else
		if (self.manaType == 1) then
			color = "playerRage"
		elseif (self.manaType == 3) then
			color = "playerEnergy"
		end
	end
	
	self:UpdateBar(self.mana/self.maxMana, color)
	self:SetBottomText1(self.manaPercentage)
	
	local amount = self:GetFormattedText(self.mana, self.maxMana)
	
	-- druids get a little shorted string to make room for druid mana in forms
	if (self.unitClass == "DRUID" and self.manaType ~= 0) then
		amount = self:GetFormattedText(self.mana)
	end
	self:SetBottomText2(amount, color)
end


function PlayerMana.prototype:UpdateEnergy(unit)
	if (unit and (unit ~= "player")) then
		return
	end
	
	self.tickStart = GetTime()
	self.tickerFrame:Show()
	self:Update(unit)
end


function PlayerMana.prototype:EnergyTick()
	if not (self.tickStart) then
		self.tickerFrame:Hide()
		return
	end
	
	local now = GetTime()
	local elapsed = now - self.tickStart
	
	if (elapsed > 2) then
		self.tickStart = now
	end
	
	local thisTick = elapsed / 2
	local x = (thisTick * (self.width - (self.width * IceBarElement.BarProportion))) + 4
	local y = thisTick * (self.height - 5)
	
	self.tickerFrame:ClearAllPoints()
	self.tickerFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", x, y)
end


function PlayerMana.prototype:CreateTickerFrame()
	if not (self.tickerFrame) then
		self.tickerFrame = CreateFrame("StatusBar", nil, self.barFrame)
	end
	
	self.tickerFrame:SetFrameStrata("BACKGROUND")
	self.tickerFrame:SetWidth(19)
	self.tickerFrame:SetHeight(1)
	
	if not (self.tickerFrame.spark) then
		self.tickerFrame.spark = self.tickerFrame:CreateTexture(nil, "BACKGROUND")
	end
	
	self.tickerFrame.spark:SetTexture(self:GetColor("playerEnergy", 1))
	self.tickerFrame.spark:SetBlendMode("ADD")
	self.tickerFrame.spark:ClearAllPoints()
	self.tickerFrame.spark:SetAllPoints(self.tickerFrame)
	
	self.tickerFrame:SetStatusBarTexture(self.tickerFrame.spark)
	self.tickerFrame:SetStatusBarColor(self:GetColor("playerEnergy", self.moduleSettings.tickerAlpha))
	
	self.tickerFrame:Hide()
end


-- Load us up
PlayerMana:new()
