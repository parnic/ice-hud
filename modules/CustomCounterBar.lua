local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceCustomCounterBar = IceCore_CreateClass(IceBarElement)

IceCustomCounterBar.prototype.currColor = {}

function IceCustomCounterBar.prototype:init()
	IceCustomCounterBar.super.prototype.init(self, "CustomCounterBar")

	self.bTreatEmptyAsFull = true
end

function IceCustomCounterBar.prototype:GetOptions()
	local opts = IceCustomCounterBar.super.prototype.GetOptions(self)

	for k,v in pairs(IceStackCounter_GetOptions(self)) do
		opts[k] = v
	end

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

	return opts
end

function IceCustomCounterBar.prototype:GetDefaultSettings()
	local defaults =  IceCustomCounterBar.super.prototype.GetDefaultSettings(self)

	for k,v in pairs(IceStackCounter_GetDefaultSettings(self)) do
		defaults[k] = v
	end

	defaults.textVisible['lower'] = false
	defaults.offset = 9
	defaults.desiredLerpTime = 0.1
	defaults.customBarType = "CounterBar"
	defaults.countMinColor = {r=1, g=1, b=0, a=1}
	defaults.countColor = {r=1, g=0, b=0, a=1}
	defaults.gradient = false
	defaults.usesDogTagStrings = false

	return defaults
end

function IceCustomCounterBar.prototype:Enable(core)
	IceCustomCounterBar.super.prototype.Enable(self, core)

	IceStackCounter_Enable(self)
end

function IceCustomCounterBar.prototype:Redraw()
	IceCustomCounterBar.super.prototype.Redraw(self)

	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:CreateFrame()
	IceCustomCounterBar.super.prototype.CreateFrame(self)

	self:UpdateCustomCount()
end

function IceCustomCounterBar.prototype:UpdateCustomCount()
	local points = IceStackCounter_GetCount(self) or 0
	local max = IceStackCounter_GetMaxCount(self) or 1
	local percent = IceHUD:Clamp(1.0 * points / (max > 0 and max or 1), 0, 1)

	if IceHUD.IceCore:IsInConfigMode() then
		points = IceStackCounter_GetMaxCount(self)
		percent = 1
	end

	if points == nil or points == 0 then
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
