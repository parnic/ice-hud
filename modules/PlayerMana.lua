local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerMana = IceCore_CreateClass(IceUnitBar)

local IceHUD = _G.IceHUD

PlayerMana.prototype.manaType = nil
PlayerMana.prototype.tickStart = nil
PlayerMana.prototype.previousEnergy = nil

-- Constructor --
function PlayerMana.prototype:init()
	PlayerMana.super.prototype.init(self, "PlayerMana", "player")

	self:SetDefaultColor("PlayerMana", 62, 54, 152)
	self:SetDefaultColor("PlayerRage", 171, 59, 59)
	self:SetDefaultColor("PlayerEnergy", 218, 231, 31)
	self:SetDefaultColor("PlayerFocus", 242, 149, 98)
	self:SetDefaultColor("PlayerRunicPower", 62, 54, 152)
	if IceHUD.WowVer >= 70000 then
		self:SetDefaultColor("PlayerInsanity", 150, 50, 255)
		self:SetDefaultColor("PlayerFury", 255, 50, 255)
		self:SetDefaultColor("PlayerMaelstrom", 62, 54, 152)
		self:SetDefaultColor("PlayerPain", 255, 50, 255)
	end
end


-- OVERRIDE
function PlayerMana.prototype:GetDefaultSettings()
	local settings = PlayerMana.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Right
	settings["offset"] = 1
	settings["tickerEnabled"] = true
	settings["tickerAlpha"] = 0.5
	settings["upperText"] = "[PercentMP:Round]"
	settings["lowerText"] = "[FractionalMP:Short:PowerColor]"

	return settings
end


-- OVERRIDE
function PlayerMana.prototype:GetOptions()
	local opts = PlayerMana.super.prototype.GetOptions(self)

if self:ShouldUseTicker() then
	opts["tickerEnabled"] = {
		type = "toggle",
		name = L["Show rogue/cat energy ticker"],
		desc = L["Show rogue/cat energy ticker"],
		get = function()
			return self.moduleSettings.tickerEnabled
		end,
		set = function(info, value)
			self.moduleSettings.tickerEnabled = value
			self:ManaType(nil, self.unit)
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 51
	}

	opts["tickerAlpha"] =
	{
		type = 'range',
		name = L["Energy Ticker Alpha"],
		desc = L["Energy Ticker Alpha"],
		min = 0.1,
		max = 1,
		step = 0.05,
		get = function()
			return self.moduleSettings.tickerAlpha
		end,
		set = function(info, value)
			self.moduleSettings.tickerAlpha = value
			self.tickerFrame.spark:SetVertexColor(self:GetColor("PlayerEnergy", self.moduleSettings.tickerAlpha))
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 52
	}
end
	opts["scaleManaColor"] = {
		type = "toggle",
		name = L["Color bar by mana %"],
		desc = L["Colors the mana bar from MaxManaColor to MinManaColor based on current mana %"],
		get = function()
			return self.moduleSettings.scaleManaColor
		end,
		set = function(info, value)
			self.moduleSettings.scaleManaColor = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 53
	}

	opts["scaleManaColorForAll"] = {
		type = "toggle",
		name = L["Scale for non-mana users"],
		desc = L["Uses the 'color bar by mana %' setting/colors even for classes that don't use Mana"],
		width = 'double',
		get = function()
			return self.moduleSettings.scaleManaColorForAll
		end,
		set = function(info, value)
			self.moduleSettings.scaleManaColorForAll = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		hidden = function()
			return not self.moduleSettings.scaleManaColor
		end,
		order = 53.1
	}

	return opts
end


function PlayerMana.prototype:Enable(core)
	PlayerMana.super.prototype.Enable(self, core)

	self:CreateTickerFrame()

	if IceHUD.WowVer >= 40000 then
		self:RegisterEvent("UNIT_POWER", "UpdateEvent")
		self:RegisterEvent("UNIT_MAXPOWER", "UpdateEvent")
	else
		self:RegisterEvent("UNIT_MAXMANA", "UpdateEvent")
		self:RegisterEvent("UNIT_MAXRAGE", "UpdateEvent")
		self:RegisterEvent("UNIT_MAXENERGY", "UpdateEvent")
		self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UpdateEvent")

		self:RegisterEvent("UNIT_MANA", "UpdateEvent")
		self:RegisterEvent("UNIT_RAGE", "UpdateEvent")
		self:RegisterEvent("UNIT_ENERGY", "UpdateEnergy")
		self:RegisterEvent("UNIT_RUNIC_POWER", "UpdateEvent")
	end

	self:RegisterEvent("UNIT_ENTERED_VEHICLE", "EnteringVehicle")
	self:RegisterEvent("UNIT_EXITED_VEHICLE", "ExitingVehicle")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "EnteringWorld")

	if not self.CustomOnUpdate then
		self.CustomOnUpdate = function() self:Update(self.unit) end
	end

	self:SetupOnUpdate(true)

	self:RegisterEvent("UNIT_DISPLAYPOWER", "ManaType")

	self:ManaType(nil, self.unit)
end

function PlayerMana.prototype:EnteringWorld()
	self:CheckVehicle()
	self:CheckCombat()
end

function PlayerMana.prototype:CheckVehicle()
	if UnitHasVehicleUI("player") then
		self:EnteringVehicle(nil, "player", true)
	else
		self:ExitingVehicle(nil, "player")
	end
end

function PlayerMana.prototype:ShouldUseTicker()
	return IceHUD.WowVer < 30000 or (IceHUD.WowVer < 70100 and not GetCVarBool("predictedPower"))
end

function PlayerMana.prototype:SetupOnUpdate(enable)
	if enable then
		IceHUD.IceCore:RequestUpdates(self, self.CustomOnUpdate)
	else
		-- make sure the animation has a chance to finish filling up the bar before we cut it off completely
		if self.CurrScale ~= self.DesiredScale then
			IceHUD.IceCore:RequestUpdates(self, self.MyOnUpdateFunc)
		else
			IceHUD.IceCore:RequestUpdates(self, nil)
		end
	end
end

function PlayerMana.prototype:OnShow()
	if not self:IsFull(self.CurrScale) then
		self:SetupOnUpdate(true)
	end
end

function PlayerMana.prototype:EnteringVehicle(event, unit, arg2)
	if (self.unit == "player") then
		if IceHUD:ShouldSwapToVehicle(unit, arg2) then
			self.unit = "vehicle"
			self:RegisterFontStrings()
		end
		self:ManaType(nil, self.unit)
	end
end


function PlayerMana.prototype:ExitingVehicle(event, unit)
	if (unit == "player") then
		if self.unit == "vehicle" then
			self.unit = "player"
			self:RegisterFontStrings()
		end
		self:ManaType(nil, self.unit)
	end
end


function PlayerMana.prototype:MyOnUpdate()
	PlayerMana.super.prototype.MyOnUpdate(self)

	if self.CurrScale == self.DesiredScale then
		self:SetupOnUpdate(false)
	end
end


-- OVERRIDE
function PlayerMana.prototype:Redraw()
	PlayerMana.super.prototype.Redraw(self)

	if (self.moduleSettings.enabled) then
		self:CreateTickerFrame()
	end
end

-- CheckCombat is hooked down in IceElement as PLAYER_ENTERING_WORLD, so hijack it for a mana check
function PlayerMana.prototype:CheckCombat()
	PlayerMana.super.prototype.CheckCombat(self)
	self:ManaType(nil, self.unit)
end

function PlayerMana.prototype:ManaType(event, unit)
	if (unit ~= self.unit) then
		return
	end

	self.manaType = UnitPowerType(self.unit)

	if self:ShouldUseTicker() then
		-- register ticker for rogue energy
		if (self.moduleSettings.tickerEnabled and (self.manaType == SPELL_POWER_ENERGY) and self.alive) then
			self.tickerFrame:Show()
			self.tickerFrame:SetScript("OnUpdate", function() self:EnergyTick() end)
		else
			self.tickerFrame:Hide()
			self.tickerFrame:SetScript("OnUpdate", nil)
		end
	end

	self.bTreatEmptyAsFull = self:TreatEmptyAsFull()

	self:Update(self.unit)
end

function PlayerMana.prototype:TreatEmptyAsFull()
	return self.manaType == SPELL_POWER_RAGE or self.manaType == SPELL_POWER_RUNIC_POWER
		or (IceHUD.WowVer >= 70000 and (self.manaType == SPELL_POWER_LUNAR_POWER or self.manaType == SPELL_POWER_INSANITY
		or self.manaType == SPELL_POWER_FURY or self.manaType == SPELL_POWER_PAIN or self.manaType == SPELL_POWER_MAELSTROM))
end

function PlayerMana.prototype:UpdateEvent(event, unit, powertype)
	self:Update(unit, powertype)
end

function PlayerMana.prototype:Update(unit, powertype)
	PlayerMana.super.prototype.Update(self)
	if (unit and (unit ~= self.unit)) then
		return
	end

	if powertype ~= nil and powertype == "ENERGY" then
		self:UpdateEnergy(nil, unit)
	end

	if self.unit == "vehicle" and ((not UnitExists(unit)) or (self.maxMana == 0)) then
		self:Show(false)
		return
	else
		self:Show(true)
	end

	local useTicker = self:ShouldUseTicker()
	-- the user can toggle the predictedPower cvar at any time and the addon will not get notified. handle it.
	if not self.tickerFrame and useTicker then
		self:CreateTickerFrame()
	end

	if (self.manaType ~= SPELL_POWER_ENERGY and useTicker) then
		self.tickerFrame:Hide()
	end

	local color = "PlayerMana"
	if not (self.alive) then
		color = "Dead"
	elseif (self.moduleSettings.scaleManaColor and (UnitPowerType(self.unit) == SPELL_POWER_MANA or self.moduleSettings.scaleManaColorForAll)) then
		color = "ScaledManaColor"
	else
		if (self.manaType == SPELL_POWER_RAGE) then
			color = "PlayerRage"
		elseif (self.manaType == SPELL_POWER_ENERGY) then
			color = "PlayerEnergy"
		elseif (self.manaType == SPELL_POWER_RUNIC_POWER) then
			color = "PlayerRunicPower"
		elseif (self.manaType == SPELL_POWER_FOCUS) then
			color = "PlayerFocus"
		elseif (IceHUD.WowVer >= 70000 and self.manaType == SPELL_POWER_INSANITY) then
			color = "PlayerInsanity"
		elseif (IceHUD.WowVer >= 70000 and self.manaType == SPELL_POWER_FURY) then
			color = "PlayerFury"
		elseif (IceHUD.WowVer >= 70000 and self.manaType == SPELL_POWER_MAELSTROM) then
			color = "PlayerMaelstrom"
		elseif (IceHUD.WowVer >= 70000 and self.manaType == SPELL_POWER_PAIN) then
			color = "PlayerPain"
		end
	end

	self:UpdateBar(self.manaPercentage, color)

	self:ConditionalUpdateFlash()

	if (self.manaPercentage == 1 and not self:TreatEmptyAsFull())
		or (self.manaPercentage == 0 and self:TreatEmptyAsFull()) then
		self:SetupOnUpdate(false)
	else
		self:SetupOnUpdate(true)
	end

	if useTicker then
		-- hide ticker if rest of the bar is not visible
		if (self.alpha == 0) then
	 		self.tickerFrame.spark:SetVertexColor(self:GetColor("PlayerEnergy", 0))
	 	else
	 		self.tickerFrame.spark:SetVertexColor(self:GetColor("PlayerEnergy", self.moduleSettings.tickerAlpha))
	 	end
	end

	if not IceHUD.IceCore:ShouldUseDogTags() then
		-- extra hack for whiny rogues (are there other kind?)
		local displayPercentage = self.manaPercentage
		if (self.manaType == SPELL_POWER_ENERGY) then
			displayPercentage = self.mana
		else
			displayPercentage = math.floor(displayPercentage * 100)
		end
		self:SetBottomText1(displayPercentage)


		local amount = self:GetFormattedText(self.mana, self.maxMana)

		-- druids get a little shorted string to make room for druid mana in forms
		if (self.unitClass == "DRUID" and self.manaType ~= SPELL_POWER_MANA) then
			amount = self:GetFormattedText(self.mana)
		end
		self:SetBottomText2(amount, color)
	end
end


-- OVERRIDE
function PlayerMana.prototype:UpdateBar(scale, color, alpha)
	self.noFlash = (self.manaType ~= SPELL_POWER_MANA)

	PlayerMana.super.prototype.UpdateBar(self, scale, color, alpha)
end


function PlayerMana.prototype:UpdateEnergy(event, unit)
	if (unit and (unit ~= self.unit)) then
		return
	end

	self.previousEnergy = UnitPower(self.unit, UnitPowerType(self.unit))
	if IceHUD.WowVer < 40000 then
		self:Update(unit)
	end

	if self:ShouldUseTicker() and
		((not (self.previousEnergy) or (self.previousEnergy <= UnitPower(self.unit, UnitPowerType(self.unit)))) and
		(self.moduleSettings.tickerEnabled) and self.manaType == SPELL_POWER_ENERGY) then
			self.tickStart = GetTime()
			self.tickerFrame:Show()
	end
end


function PlayerMana.prototype:EnergyTick()
	if not self:ShouldUseTicker() then
		return
	end

	if not (self.tickStart) then
		self.tickerFrame:Hide()
		return
	end

	local now = GetTime()
	local elapsed = now - self.tickStart

	if (elapsed > 2) then
		self.tickStart = now
	end

	local pos = elapsed / 2
	local y = pos * (self.settings.barHeight-2)

	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.tickerFrame.spark:SetTexCoord(1, 0, 1-pos-0.01, 1-pos)
	else
		self.tickerFrame.spark:SetTexCoord(0, 1, 1-pos-0.01, 1-pos)
	end
	self.tickerFrame.spark:SetHeight(self.settings.barHeight * 0.01)

	self.tickerFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, y)
end


function PlayerMana.prototype:CreateTickerFrame()
	if not self:ShouldUseTicker() then
		return
	end

	if not (self.tickerFrame) then
		self.tickerFrame = CreateFrame("Frame", nil, self.barFrame)
	end

	self.tickerFrame:SetFrameStrata("BACKGROUND")
	self.tickerFrame:SetWidth(self.settings.barWidth)
	self.tickerFrame:SetHeight(self.settings.barHeight)

	if not (self.tickerFrame.spark) then
		self.tickerFrame.spark = self.tickerFrame:CreateTexture(nil, "BACKGROUND")
		self.tickerFrame:Hide()
	end

	self.tickerFrame.spark:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture())
	self.tickerFrame.spark:SetBlendMode("ADD")
	self.tickerFrame.spark:ClearAllPoints()
	self.tickerFrame.spark:SetPoint("BOTTOMLEFT",self.tickerFrame,"BOTTOMLEFT")
	self.tickerFrame.spark:SetPoint("BOTTOMRIGHT",self.tickerFrame,"BOTTOMRIGHT")
	self.tickerFrame.spark:SetHeight(0)

	self.tickerFrame.spark:SetVertexColor(self:GetColor("PlayerEnergy", self.moduleSettings.tickerAlpha))

	self.tickerFrame:ClearAllPoints()
	self.tickerFrame:SetPoint("BOTTOMLEFT", self.frame, "BOTTOMLEFT", 0, 0)
end


-- Load us up
IceHUD.PlayerMana = PlayerMana:new()
