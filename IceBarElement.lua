local AceOO = AceLibrary("AceOO-2.0")

local DogTag = nil

IceBarElement = AceOO.Class(IceElement)
IceBarElement.virtual = true

IceBarElement.BarTextureWidth = 128

IceBarElement.prototype.barFrame = nil
IceBarElement.prototype.backroundAlpha = nil

IceBarElement.prototype.combat = nil
IceBarElement.prototype.target = nil

IceBarElement.prototype.CurrLerpTime = 0
IceBarElement.prototype.LastScale = 1
IceBarElement.prototype.DesiredScale = 1
IceBarElement.prototype.CurrScale = 1


-- Constructor --
function IceBarElement.prototype:init(name)
	IceBarElement.super.prototype.init(self, name)

	if AceLibrary:HasInstance("LibDogTag-3.0") then
		DogTag = AceLibrary("LibDogTag-3.0")
		AceLibrary("LibDogTag-Unit-3.0")
	end
end



-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:Enable()
	IceBarElement.super.prototype.Enable(self)

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OutCombat")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckCombat")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")

	if self.moduleSettings.myTagVersion < IceHUD.CurrTagVersion then
		local origDefaults = self:GetDefaultSettings()

		self.moduleSettings.upperText = origDefaults["upperText"]
		self.moduleSettings.lowerText = origDefaults["lowerText"]
		self.moduleSettings.myTagVersion = IceHUD.CurrTagVersion
	end

	self:RegisterFontStrings()
end


function IceBarElement.prototype:RegisterFontStrings()
	if DogTag ~= nil and self.moduleSettings.usesDogTagStrings then
		if self.frame.bottomUpperText and self.moduleSettings.upperText then
			DogTag:AddFontString(self.frame.bottomUpperText, self.frame, self.moduleSettings.upperText, "Unit", { unit = self.unit })
		end
		if self.frame.bottomLowerText and self.moduleSettings.lowerText then
			DogTag:AddFontString(self.frame.bottomLowerText, self.frame, self.moduleSettings.lowerText, "Unit", {unit = self.unit })
		end
	end
end


-- OVERRIDE
function IceBarElement.prototype:GetDefaultSettings()
	local settings = IceBarElement.super.prototype.GetDefaultSettings(self)
	
	settings["side"] = IceCore.Side.Left
	settings["offset"] = 1
	settings["scale"] = 1
	settings["barFontSize"] = 12
	settings["lockUpperTextAlpha"] = true
	settings["lockLowerTextAlpha"] = false
	settings["textVisible"] = {upper = true, lower = true}
	settings["upperText"] = ''
	settings["lowerText"] = ''
	settings["textVerticalOffset"] = -1
	settings["textHorizontalOffset"] = 0
	settings["shouldAnimate"] = true
	settings["desiredLerpTime"] = 0.2
	settings["barVisible"] = {bg = true, bar = true}
	settings["myTagVersion"] = 2
	settings["widthModifier"] = 0
	settings["usesDogTagStrings"] = true
	settings["barVerticalOffset"] = 0

	return settings
end


-- OVERRIDE
function IceBarElement.prototype:GetOptions()
	local opts = IceBarElement.super.prototype.GetOptions(self)
	
	opts["side"] = 
	{
		type = 'text',
		name =  '|c' .. self.configColor .. 'Side|r',
		desc = 'Side of the HUD where the bar appears',
		get = function()
			if (self.moduleSettings.side == IceCore.Side.Right) then
				return "Right"
			else
				return "Left"
			end
		end,
		set = function(value)
			if (value == "Right") then
				self.moduleSettings.side = IceCore.Side.Right
			else
				self.moduleSettings.side = IceCore.Side.Left
			end
			self:Redraw()
		end,
		validate = { "Left", "Right" },
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 30
	}
	
	opts["offset"] = 
	{
		type = 'range',
		name = '|c' .. self.configColor .. 'Offset|r',
		desc = 'Offset of the bar',
		min = -10,
		max = 15,
		step = 1,
		get = function()
			return self.moduleSettings.offset
		end,
		set = function(value)
			self.moduleSettings.offset = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 31
	}
	
	opts["scale"] = 
	{
		type = 'range',
		name = '|c' .. self.configColor .. 'Scale|r',
		desc = 'Scale of the bar',
		min = 0.1,
		max = 2,
		step = 0.05,
		isPercent = true,
		get = function()
			return self.moduleSettings.scale
		end,
		set = function(value)
			self.moduleSettings.scale = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 32
	}

	opts["barVisible"] = {
		type = 'toggle',
		name = 'Bar visible',
		desc = 'Toggle bar visibility',
		get = function()
			return self.moduleSettings.barVisible['bar']
		end,
		set = function(v)
			self.moduleSettings.barVisible['bar'] = v
			if v then
				self.barFrame:Show()
			else
				self.barFrame:Hide()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 28
	}
			
	opts["bgVisible"] = {
		type = 'toggle',
		name = 'Bar background visible',
		desc = 'Toggle bar background visibility',
		get = function()
			return self.moduleSettings.barVisible['bg']
		end,
		set = function(v)
			self.moduleSettings.barVisible['bg'] = v
			if v then
				self.frame.bg:Show()
			else
				self.frame.bg:Hide()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 29
	}

	opts["shouldAnimate"] =
	{
		type = 'toggle',
		name = '|c' .. self.configColor .. 'Animate amount changes|r',
		desc = 'Whether or not to animate the bar falloffs/gains',
		get = function()
			return self.moduleSettings.shouldAnimate
		end,
		set = function(value)
			self.moduleSettings.shouldAnimate = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	opts["desiredLerpTime"] =
	{
		type = 'range',
		name = '|c' .. self.configColor .. 'Animation Duration|r',
		desc = 'How long the animation should take to play',
		min = 0,
		max = 2,
		step = 0.05,
		get = function()
			return self.moduleSettings.desiredLerpTime
		end,
		set = function(value)
			self.moduleSettings.desiredLerpTime = value
		end,
		disabled = function()
			return not self.moduleSettings.enabled or not self.moduleSettings.shouldAnimate
		end
	}

	opts["widthModifier"] = 
	{
		type = 'range',
		name = '|c' .. self.configColor .. 'Bar width modifier|r',
		desc = 'Make this bar wider or thinner than others',
		min = -80,
		max = 80,
		step = 1,
		get = function()
			return self.moduleSettings.widthModifier
		end,
		set = function(v)
			self.moduleSettings.widthModifier = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	opts["barVerticalOffset"] = 
	{
		type='range',
		name = '|c' .. self.configColor .. 'Bar vertical offset|r',
		desc = 'Adjust the vertical placement of this bar',
		min = -100,
		max = 100,
		step = 1,
		get = function()
			return self.moduleSettings.barVerticalOffset
		end,
		set = function(v)
			self.moduleSettings.barVerticalOffset = v
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end
	}

	opts["textSettings"] =
	{
		type = 'group',
		name = '|c' .. self.configColor .. 'Text Settings|r',
		desc = 'Settings related to texts',
		order = 32,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		args = {
			fontsize = {
				type = 'range',
				name = 'Bar Font Size',
				desc = 'Bar Font Size',
				get = function()
					return self.moduleSettings.barFontSize
				end,
				set = function(v)
					self.moduleSettings.barFontSize = v
					self:Redraw()
				end,
				min = 8,
				max = 20,
				step = 1,
				order = 11
			},

			lockUpperFontAlpha = {
				type = "toggle",
				name = "Lock Upper Text Alpha",
				desc = "Locks upper text alpha to 100%",
				get = function()
					return self.moduleSettings.lockUpperTextAlpha
				end,
				set = function(v)
					self.moduleSettings.lockUpperTextAlpha = v
					self:Redraw()
				end,
				order = 13
			},

			lockLowerFontAlpha = {
				type = "toggle",
				name = "Lock Lower Text Alpha",
				desc = "Locks lower text alpha to 100%",
				get = function()
					return self.moduleSettings.lockLowerTextAlpha
				end,
				set = function(v)
					self.moduleSettings.lockLowerTextAlpha = v
					self:Redraw()
				end,
				order = 13.1
			},

			upperTextVisible = {
				type = 'toggle',
				name = 'Upper text visible',
				desc = 'Toggle upper text visibility',
				get = function()
					return self.moduleSettings.textVisible['upper']
				end,
				set = function(v)
					self.moduleSettings.textVisible['upper'] = v
					self:Redraw()
				end,
				order = 14
			},
			
			lowerTextVisible = {
				type = 'toggle',
				name = 'Lower text visible',
				desc = 'Toggle lower text visibility',
				get = function()
					return self.moduleSettings.textVisible['lower']
				end,
				set = function(v)
					self.moduleSettings.textVisible['lower'] = v
					self:Redraw()
				end,
				order = 15
			},

			upperTextString = {
				type = 'text',
				name = 'Upper Text',
				desc = 'The upper text to display under this bar (accepts LibDogTag formatting)\n\nSee http://www.wowace.com/wiki/LibDogTag-2.0/ or type /dogtag for tag info',
				hidden = function()
					return DogTag == nil
				end,
				get = function()
					return self.moduleSettings.upperText
				end,
				set = function(v)
					if DogTag ~= nil and v ~= '' and v ~= nil then
						v = DogTag:CleanCode(v)
					end

					self.moduleSettings.upperText = v
					self:RegisterFontStrings()
					self:Redraw()
				end,
				usage = "<upper text to display>"
			},

			lowerTextString = {
				type = 'text',
				name = 'Lower Text',
				desc = 'The lower text to display under this bar (accepts LibDogTag formatting)\n\nSee http://www.wowace.com/wiki/LibDogTag-2.0/ or type /dogtag for tag info',
				hidden = function()
					return DogTag == nil
				end,
				get = function()
					return self.moduleSettings.lowerText
				end,
				set = function(v)
					if DogTag ~= nil and v ~= '' and v ~= nil then
						v = DogTag:CleanCode(v)
					end

					self.moduleSettings.lowerText = v
					self:RegisterFontStrings()
					self:Redraw()
				end,
				usage = "<lower text to display>"
			},

			textVerticalOffset = {
				type = 'range',
				name = '|c' .. self.configColor .. 'Text Vertical Offset|r',
				desc = 'Offset of the text from the bar vertically (negative is farther below)',
				min = -250,
				max = 350,
				step = 1,
				get = function()
					return self.moduleSettings.textVerticalOffset
				end,
				set = function(v)
					self.moduleSettings.textVerticalOffset = v
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end
			},

			textHorizontalOffset = {
				type = 'range',
				name = '|c' .. self.configColor .. 'Text Horizontal Offset|r',
				desc = 'Offset of the text from the bar horizontally',
				min = -50,
				max = 50,
				step = 1,
				get = function()
					return self.moduleSettings.textHorizontalOffset
				end,
				set = function(v)
					self.moduleSettings.textHorizontalOffset = v
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end
			}
		}
	}
	
	return opts
end



-- OVERRIDE
function IceBarElement.prototype:Redraw()
	IceBarElement.super.prototype.Redraw(self)

	if (not self.moduleSettings.enabled) then
		return
	end

	self.alpha = self.settings.alphaooc
	self:CreateFrame()
	self.frame:SetAlpha(self.alpha)
end



function IceBarElement.prototype:SetPosition(side, offset)
	IceBarElement.prototype.side = side
	IceBarElement.prototype.offset = offset
end


-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:CreateFrame()
	-- don't call overridden method
	self.alpha = self.settings.alphaooc

	self:CreateBackground()
	self:CreateBar()
	self:CreateTexts()
	
	self.frame:SetScale(self.moduleSettings.scale)
	-- never register the OnUpdate for the mirror bar since it's handled internally
	-- in addition, do not register OnUpdate if predictedPower is set and this is the player mana or target mana bar
	if not string.find(self.elementName, "MirrorBar")
		and ((IceHUD.WowVer < 30000 or not GetCVarBool("predictedPower")) or (not string.find(self.elementName, "PlayerMana") and not string.find(self.elementName, "TargetMana"))) then
		self.frame:SetScript("OnUpdate", function() self:MyOnUpdate() end)
	end
end


-- Creates background for the bar
function IceBarElement.prototype:CreateBackground()
	if not (self.frame) then
		self.frame = CreateFrame("StatusBar", "IceHUD_"..self.elementName, self.parent)
	end
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.frame:SetHeight(self.settings.barHeight)
	
	if not (self.frame.bg) then
		self.frame.bg = self.frame:CreateTexture(nil, "BACKGROUND")
	end
	
	self.frame.bg:SetTexture(IceElement.TexturePath .. self.settings.barTexture.."BG")
	self.frame.bg:SetBlendMode(self.settings.barBgBlendMode)
	self.frame.bg:ClearAllPoints()
	self.frame.bg:SetAllPoints(self.frame)
	
	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.frame.bg:SetTexCoord(1, 0, 0, 1)
	else
		self.frame.bg:SetTexCoord(0, 1, 0, 1)
	end
	
	self.frame:SetStatusBarTexture(self.frame.bg)
	self.frame:SetStatusBarColor(self:GetColor("undef", self.settings.alphabg))
	
	local ownPoint = "LEFT"
	if (self.moduleSettings.side == ownPoint) then
		ownPoint = "RIGHT"
	end
	
	-- ofxx = (bar width) + (extra space in between the bars)
	local offx = (self.settings.barProportion * self.settings.barWidth * self.moduleSettings.offset)
		+ (self.moduleSettings.offset * self.settings.barSpace)
	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end	
	
	self.frame:ClearAllPoints()
	self.frame:SetPoint("BOTTOM"..ownPoint, self.parent, "BOTTOM"..self.moduleSettings.side, offx, self.moduleSettings.barVerticalOffset)
end


-- Creates the actual bar
function IceBarElement.prototype:CreateBar()
	if not (self.barFrame) then
		self.barFrame = CreateFrame("StatusBar", nil, self.frame)
	end
	
	self.barFrame:SetFrameStrata("LOW")
	self.barFrame:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.barFrame:SetHeight(self.settings.barHeight)
	
	
	if not (self.barFrame.bar) then
		self.barFrame.bar = self.frame:CreateTexture(nil, "BACKGROUND")
	end
	
	self.barFrame.bar:SetTexture(IceElement.TexturePath .. self.settings.barTexture)
	self.barFrame.bar:SetBlendMode(self.settings.barBlendMode)
	self.barFrame.bar:SetAllPoints(self.frame)

	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.barFrame.bar:SetTexCoord(1, 0, 1-self.CurrScale, 1)
	else
		self.barFrame.bar:SetTexCoord(0, 1, 1-self.CurrScale, 1)
	end
	
	self.barFrame:SetStatusBarTexture(self.barFrame.bar)
	
	self:UpdateBar(1, "undef")
	
	self.barFrame:ClearAllPoints()
	self.barFrame:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 0)
end


function IceBarElement.prototype:CreateTexts()
	self.frame.bottomUpperText = self:FontFactory(self.moduleSettings.barFontSize, nil, self.frame.bottomUpperText)
	self.frame.bottomLowerText = self:FontFactory(self.moduleSettings.barFontSize, nil, self.frame.bottomLowerText)

-- Parnic - commented these out so that they conform to whatever width the string is set to
--	self.frame.bottomUpperText:SetWidth(80)
--	self.frame.bottomLowerText:SetWidth(120)
	
	self.frame.bottomUpperText:SetHeight(14)
	self.frame.bottomLowerText:SetHeight(14)

	local justify = "RIGHT"
	if ((self.moduleSettings.side == "LEFT" and self.moduleSettings.offset <= 1) or
		(self.moduleSettings.side == "RIGHT" and self.moduleSettings.offset > 1)) 
	then
		justify = "LEFT"
	end


	self.frame.bottomUpperText:SetJustifyH(justify)
	self.frame.bottomLowerText:SetJustifyH(justify)


	local ownPoint = self.moduleSettings.side
	if (self.moduleSettings.offset > 1) then
		ownPoint = self:Flip(ownPoint)
	end
	
	local parentPoint = self:Flip(self.moduleSettings.side)
	
	
	local offx = 0
	-- adjust offset for bars where text is aligned to the outer side
	if (self.moduleSettings.offset <= 1) then
		offx = self.settings.barProportion * self.settings.barWidth - offx
	end


	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end

	self.frame.bottomUpperText:ClearAllPoints()
	self.frame.bottomLowerText:ClearAllPoints()

	if self.moduleSettings.textHorizontalOffset ~= nil then
		offx = offx + self.moduleSettings.textHorizontalOffset
	end

	local offy = 0
	if self.moduleSettings.textVerticalOffset ~= nil then
		offy = self.moduleSettings.textVerticalOffset
	end

	self.frame.bottomUpperText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, offy)
	self.frame.bottomLowerText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, offy - 14)
	
	if (self.moduleSettings.textVisible["upper"]) then
		self.frame.bottomUpperText:Show()
	else
		self.frame.bottomUpperText:Hide()
	end
	
	if (self.moduleSettings.textVisible["lower"]) then
		self.frame.bottomLowerText:Show()
	else
		self.frame.bottomLowerText:Hide()
	end
end


function IceBarElement.prototype:Flip(side)
	if (side == IceCore.Side.Left) then
		return IceCore.Side.Right
	else
		return IceCore.Side.Left
	end
end


function IceBarElement.prototype:SetScale(texture, scale)
	local oldScale = self.CurrScale

	self.CurrScale = self:LerpScale(scale)

	if oldScale ~= self.CurrScale then
		if (self.moduleSettings.side == IceCore.Side.Left) then
			texture:SetTexCoord(1, 0, 1-self.CurrScale, 1)
		else
			texture:SetTexCoord(0, 1, 1-self.CurrScale, 1)
		end
	end
end


function IceBarElement.prototype:LerpScale(scale)
	if not self.moduleSettings.shouldAnimate then
		return scale
	end

	if self.CurrLerpTime < self.moduleSettings.desiredLerpTime then
		self.CurrLerpTime = self.CurrLerpTime + (1 / GetFramerate());
	end

	if self.CurrLerpTime > self.moduleSettings.desiredLerpTime then
		self.CurrLerpTime = self.moduleSettings.desiredLerpTime
	end

	if self.CurrLerpTime < self.moduleSettings.desiredLerpTime then
		return self.LastScale + ((self.DesiredScale - self.LastScale) * (self.CurrLerpTime / self.moduleSettings.desiredLerpTime))
	else
		return scale
	end
end


function IceBarElement.prototype:UpdateBar(scale, color, alpha)
	alpha = alpha or 1
	self.frame:SetAlpha(alpha)

	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor(color)
	end

	if (self.combat) then
		self.alpha = self.settings.alphaic
		self.backgroundAlpha = self.settings.alphaicbg
	elseif (self.target or self:UseTargetAlpha(scale)) then
		self.alpha = self.settings.alphaTarget
		self.backgroundAlpha = self.settings.alphaTargetbg
	else
		self.alpha = self.settings.alphaooc
		self.backgroundAlpha = self.settings.alphaoocbg
	end

	self.frame:SetStatusBarColor(r, g, b, self.backgroundAlpha)
	self.barFrame:SetStatusBarColor(self:GetColor(color))

	if self.DesiredScale ~= scale then
		self.DesiredScale = scale
		self.CurrLerpTime = 0
		self.LastScale = self.CurrScale
	end

	self:SetScale(self.barFrame.bar, self.DesiredScale)

	if not self.moduleSettings.barVisible['bg'] then
		self.frame.bg:Hide()
	else
		self.frame.bg:Show()
	end

	if not self.moduleSettings.barVisible['bar'] then
		self.barFrame:Hide()
	else
		self.barFrame:Show()
	end

	if DogTag ~= nil and self.moduleSettings.usesDogTagStrings then
		DogTag:UpdateAllForFrame(self.frame)
		self:SetTextAlpha()
	end
end


function IceBarElement.prototype:UseTargetAlpha(scale)
	return (scale and (scale < 1))
end


-- Bottom line 1
function IceBarElement.prototype:SetBottomText1(text, color)
	if not (self.moduleSettings.textVisible["upper"]) then
		return
	end

	if not (color) then
		color = "Text"
	end

	local alpha = self.alpha
	
	if (self.alpha > 0) then
		-- boost text alpha a bit to make it easier to see
		alpha = self.alpha + 0.1
			
		if (alpha > 1) then
			alpha = 1
		end
	end
	
	if (self.moduleSettings.lockUpperTextAlpha and (self.alpha > 0)) then
		alpha = 1
	end

	self.frame.bottomUpperText:SetText(text)
end


-- Bottom line 2
function IceBarElement.prototype:SetBottomText2(text, color, alpha)
	if not (self.moduleSettings.textVisible["lower"]) then
		return
	end
	
	if not (color) then
		color = "Text"
	end
	if not (alpha) then
		-- boost text alpha a bit to make it easier to see
		if (self.alpha > 0) then
			alpha = self.alpha + 0.1
			
			if (alpha > 1) then
				alpha = 1
			end
		end
	end

	if (self.moduleSettings.lockLowerTextAlpha and (self.alpha > 0)) then
		alpha = 1
	end

	self.frame.bottomLowerText:SetTextColor(self:GetColor(color, alpha))
	self.frame.bottomLowerText:SetText(text)
end


function IceBarElement.prototype:SetTextAlpha()
	if self.frame.bottomUpperText then
		self.frame.bottomUpperText:SetAlpha(self.moduleSettings.lockUpperTextAlpha and 1 or math.min(self.alpha > 0 and self.alpha + 0.1 or 0, 1))
	end
	if self.frame.bottomLowerText then
		self.frame.bottomLowerText:SetAlpha(self.moduleSettings.lockLowerTextAlpha and 1 or math.min(self.alpha > 0 and self.alpha + 0.1 or 0, 1))
	end
end


function IceBarElement.prototype:GetFormattedText(value1, value2)
	local color = "ffcccccc"
	
	local bLeft = ""
	local bRight = ""
	
	if (self.moduleSettings.brackets) then
		bLeft = "["
		bRight = "]"
	end
	
	
	if not (value2) then
		return string.format("|c%s%s|r%s|c%s%s|r", color, bLeft, value1, color, bRight)
	end
	return string.format("|c%s%s|r%s|c%s/|r%s|c%s%s|r", color, bLeft, value1, color, value2, color, bRight)
end


-- To be overridden
function IceBarElement.prototype:Update()
end

function IceBarElement.prototype:MyOnUpdate()
	self:SetScale(self.barFrame.bar, self.DesiredScale)
end


-- Combat event handlers ------------------------------------------------------

function IceBarElement.prototype:InCombat()
	self.combat = true
	self:Update(self.unit)
end


function IceBarElement.prototype:OutCombat()
	self.combat = false
	self:Update(self.unit)
end


function IceBarElement.prototype:CheckCombat()
	self.combat = UnitAffectingCombat("player")
	self.target = UnitExists("target")
	self:Update(self.unit)
end


function IceBarElement.prototype:TargetChanged()
	self.target = UnitExists("target")
	self:Update(self.unit)
end
