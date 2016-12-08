local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceCustomCounterBar = IceCore_CreateClass(IceBarElement)

IceCustomCounterBar.prototype.currColor = {}

local AuraIconWidth = 20
local AuraIconHeight = 20
local DefaultAuraIcon = "Interface\\Icons\\Spell_Frost_Frost"

function IceCustomCounterBar.prototype:init()
	IceCustomCounterBar.super.prototype.init(self, "CustomCounterBar")

	self.bTreatEmptyAsFull = true
end

function IceCustomCounterBar.prototype:GetOptions()
	local opts = IceCustomCounterBar.super.prototype.GetOptions(self)
	IceStackCounter_GetOptions(self, opts)

	opts["deleteme"] = {
		type = 'execute',
		name = L["Delete me"],
		desc = L["Deletes this custom module and all associated settings. Cannot be undone!"],
		func = function()
			local dialog = StaticPopup_Show("ICEHUD_DELETE_CUSTOM_MODULE")
			if dialog then
				dialog.data = self
			end
		end,
		order = 20.1,
	}

	opts["duplicateme"] = {
		type = 'execute',
		name = L["Duplicate me"],
		desc = L["Creates a new module of this same type and with all the same settings."],
		func = function()
			IceHUD:CreateCustomModuleAndNotify(self.moduleSettings.customBarType, self.moduleSettings)
		end,
		order = 20.2,
	}

	opts["type"] = {
		type = "description",
		name = string.format("%s %s", L["Module type:"], tostring(self:GetBarTypeDescription(self.moduleSettings.customBarType))),
		order = 21,
	}

	opts["name"] = {
		type = 'input',
		name = L["Counter name"],
		desc = L["The name of this counter (must be unique!). \n\nRemember to press ENTER after filling out this box with the name you want or it will not save."],
		get = function()
			return self.elementName
		end,
		set = function(info, v)
			if v ~= "" then
				IceHUD.IceCore:RenameDynamicModule(self, v)
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		usage = "<a name for this bar>",
		order = 29.91,
	}

	opts["countColor"] = {
		type = 'color',
		name = L["Count color"],
		desc = L["The color for this counter"],
		get = function()
			return self.moduleSettings.countColor.r, self.moduleSettings.countColor.g, self.moduleSettings.countColor.b, 1
		end,
		set = function(info, r,g,b)
			self.moduleSettings.countColor.r = r
			self.moduleSettings.countColor.g = g
			self.moduleSettings.countColor.b = b
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 29.95,
	}

	opts["countMinColor"] = {
		type = 'color',
		name = L["Count minimum color"],
		desc = L["The minimum color for this counter (only used if Change Color is enabled)"],
		get = function()
			return self.moduleSettings.countMinColor.r, self.moduleSettings.countMinColor.g,self.moduleSettings.countMinColor.b, 1
		end,
		set = function(info, r,g,b)
			self.moduleSettings.countMinColor.r = r
			self.moduleSettings.countMinColor.g = g
			self.moduleSettings.countMinColor.b = b
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.gradient
		end,
		order = 29.96,
	}

	opts["gradient"] = {
		type = "toggle",
		name = L["Change color"],
		desc = L["This will fade the graphical representation from the min color specified to the regular color\n\n(e.g. if the min color is yellow, the color is red, and there are 3 total applications, then the first would be yellow, second orange, and third red)"],
		get = function()
			return self.moduleSettings.gradient
		end,
		set = function(info, v)
			self.moduleSettings.gradient = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 29.97
	}

	opts["iconSettings"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Icon Settings"].."|r",
		args = {
			displayAuraIcon = {
				type = 'toggle',
				name = L["Display aura icon"],
				desc = L["Whether or not to display an icon for the aura that this bar is tracking"],
				get = function()
					return self.moduleSettings.displayAuraIcon
				end,
				set = function(info, v)
					self.moduleSettings.displayAuraIcon = v
					if self.barFrame.icon then
						if v then
							self.barFrame.icon:Show()
						else
							self.barFrame.icon:Hide()
						end
					end
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 40.1,
			},

			auraIconXOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon horizontal offset"],
				desc = L["Adjust the horizontal position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconXOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconXOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.2,
			},

			auraIconYOffset = {
				type = 'range',
				min = -250,
				max = 250,
				step = 1,
				name = L["Aura icon vertical offset"],
				desc = L["Adjust the vertical position of the aura icon"],
				get = function()
					return self.moduleSettings.auraIconYOffset
				end,
				set = function(info, v)
					self.moduleSettings.auraIconYOffset = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.3,
			},

			auraIconScale = {
				type = 'range',
				min = 0.1,
				max = 3.0,
				step = 0.05,
				name = L["Aura icon scale"],
				desc = L["Adjusts the size of the aura icon for this bar"],
				get = function()
					return self.moduleSettings.auraIconScale
				end,
				set = function(info, v)
					self.moduleSettings.auraIconScale = v
					self:PositionIcons()
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.displayAuraIcon
				end,
				order = 40.4,
			},
		},
	}

	return opts
end

function IceCustomCounterBar.prototype:GetDefaultSettings()
	local defaults = IceCustomCounterBar.super.prototype.GetDefaultSettings(self)
	IceStackCounter_GetDefaultSettings(defaults)

	defaults.textVisible['lower'] = false
	defaults.offset = 9
	defaults.desiredLerpTime = 0.1
	defaults.customBarType = "CounterBar"
	defaults.countMinColor = {r=1, g=1, b=0, a=1}
	defaults.countColor = {r=1, g=0, b=0, a=1}
	defaults.gradient = false
	defaults.usesDogTagStrings = false
	defaults.displayAuraIcon = false
	defaults.auraIconXOffset = 40
	defaults.auraIconYOffset = 0
	defaults.auraIconScale = 1

	return defaults
end

function IceCustomCounterBar.prototype:Enable(core)
	IceCustomCounterBar.super.prototype.Enable(self, core)

	if self.moduleSettings.auraIconScale == nil then
		self.moduleSettings.auraIconScale = 1
	end
	if self.moduleSettings.auraIconXOffset == nil then
		self.moduleSettings.auraIconXOffset = 40
	end
	if self.moduleSettings.auraIconYOffset == nil then
		self.moduleSettings.auraIconYOffset = 0
	end

	self:UpdateAuraIcon()

	IceStackCounter_Enable(self)
end

function IceCustomCounterBar.prototype:TargetChanged()
	IceCustomCount.super.prototype.TargetChanged(self)
	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:Redraw()
	IceCustomCounterBar.super.prototype.Redraw(self)

	self:UpdateAuraIcon()
	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:PositionIcons()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	self.barFrame.icon:ClearAllPoints()
	self.barFrame.icon:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self.moduleSettings.auraIconXOffset, self.moduleSettings.auraIconYOffset)
	self.barFrame.icon:SetWidth(AuraIconWidth * (self.moduleSettings.auraIconScale or 1))
	self.barFrame.icon:SetHeight(AuraIconHeight * (self.moduleSettings.auraIconScale or 1))
end

function IceCustomCounterBar.prototype:CreateFrame()
	IceCustomCounterBar.super.prototype.CreateFrame(self)

	if not self.barFrame.icon then
		self.barFrame.icon = self.masterFrame:CreateTexture(nil, "LOW")
		self.barFrame.icon:SetTexture(DefaultAuraIcon)
		self.barFrame.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		self.barFrame.icon:SetDrawLayer("OVERLAY")
		self.barFrame.icon:Hide()
	end
	self:PositionIcons()

	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:Show(bShouldShow)
	IceCustomCounterBar.super.prototype.Show(self, bShouldShow)

	if self.moduleSettings.displayAuraIcon then
		self.barFrame.icon:Show()
	else
		self.barFrame.icon:Hide()
	end
end

function IceCustomCounterBar.prototype:UpdateAuraIcon()
	if not self.barFrame or not self.barFrame.icon then
		return
	end

	local auraIcon, _
	_, _, auraIcon = GetSpellInfo(self.moduleSettings.auraName)

	if auraIcon == nil then
		auraIcon = "Interface\\Icons\\Spell_Frost_Frost"
	end

	self.barFrame.icon:SetTexture(auraIcon)
end

function IceCustomCounterBar.prototype:UpdateCustomCount()
	local points = IceStackCounter_GetCount(self) or 0
	local max = IceStackCounter_GetMaxCount(self) or 1
	local percent = IceHUD:Clamp(1.0 * points / (max > 0 and max or 1), 0, 1)

	if IceHUD.IceCore:IsInConfigMode() then
		points = IceStackCounter_GetMaxCount(self)
		percent = 1
		self.barFrame.icon:Show()
	end

	if (points == nil or points == 0) and self.moduleSettings.auraType ~= "charges" then
		self:Show(false)
		self:UpdateBar(0, "undef")
	else
		self:Show(true)

		self.currColor.r = self.moduleSettings.countColor.r
		self.currColor.g = self.moduleSettings.countColor.g
		self.currColor.b = self.moduleSettings.countColor.b

		if self.moduleSettings.gradient then
			self:SetScaledColor(self.currColor, percent, self.moduleSettings.countColor, self.moduleSettings.countMinColor)
		end

		self:UpdateBar(percent, "undef")
		self.barFrame.bar:SetVertexColor(self.currColor.r, self.currColor.g, self.currColor.b, self.alpha)
	end

	self:SetBottomText1(points or "0")
end

function IceCustomCounterBar.prototype:Update()
	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:UseTargetAlpha(scale)
	return IceStackCounter_UseTargetAlpha(self)
end
