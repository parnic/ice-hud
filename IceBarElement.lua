local AceOO = AceLibrary("AceOO-2.0")

IceBarElement = AceOO.Class(IceElement)
IceBarElement.virtual = true

IceBarElement.BackgroundAlpha = 0.25

IceBarElement.TexturePath = IceHUD.Location .. "\\textures\\"
IceBarElement.BackgroundTexture = IceHUD.Location .. "\\textures\\HiBarBG"
IceBarElement.BarProportion = 0.36
IceBarElement.BarTextureWidth = 128

IceBarElement.prototype.barFrame = nil
IceBarElement.prototype.width = nil
IceBarElement.prototype.height = nil
IceBarElement.prototype.backgroundAlpha = nil

IceBarElement.prototype.combat = nil



-- Constructor --
function IceBarElement.prototype:init(name)
	IceBarElement.super.prototype.init(self, name)
	
	self.width = 77
	self.height = 154
	
	self.backgroundAlpha = IceBarElement.BackgroundAlpha
end




-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:Enable()
	IceBarElement.super.prototype.Enable(self)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OutCombat")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckCombat")
end


-- OVERRIDE
function IceBarElement.prototype:GetOptions()
	local opts = IceBarElement.super.prototype.GetOptions(self)
	
	opts["side"] = 
	{
		type = 'text',
		name = 'Side',
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
		order = 30
	}
	
	opts["offset"] = 
	{
		type = 'range',
		name = 'Offset',
		desc = 'Offset of the bar',
		min = -1,
		max = 10,
		step = 1,
		get = function()
			return self.moduleSettings.offset
		end,
		set = function(value)
			self.moduleSettings.offset = value
			self:Redraw()
		end,
		order = 31
	}
	
	return opts
end



-- OVERRIDE
function IceBarElement.prototype:Redraw()
	IceBarElement.super.prototype.Redraw(self)
	
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
end


-- Creates background for the bar
function IceBarElement.prototype:CreateBackground()
	if not (self.frame) then
		self.frame = CreateFrame("StatusBar", "IceHUD_"..self.name, self.parent)
	end
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.width)
	self.frame:SetHeight(self.height)
	
	if not (self.frame.bg) then
		self.frame.bg = self.frame:CreateTexture(nil, "BACKGROUND")
	end
	
	self.frame.bg:SetTexture(IceBarElement.BackgroundTexture)
	self.frame.bg:ClearAllPoints()
	self.frame.bg:SetAllPoints(self.frame)
	
	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.frame.bg:SetTexCoord(1, 0, 0, 1)
	else
		self.frame.bg:SetTexCoord(1, 0, 1, 0)
	end
	
	self.frame:SetStatusBarTexture(self.frame.bg)
	self.frame:SetStatusBarColor(self:GetColor("undef", self.backgroundAlpha))
	
	local ownPoint = "LEFT"
	if (self.moduleSettings.side == ownPoint) then
		ownPoint = "RIGHT"
	end
	
	-- ofxx = (bar width) + (extra space in between the bars)
	local offx = (IceBarElement.BarProportion * self.width * self.moduleSettings.offset)
		+ (self.moduleSettings.offset * 5)
	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end	
	
	self.frame:ClearAllPoints()
	self.frame:SetPoint("BOTTOM"..ownPoint, self.parent, "BOTTOM"..self.moduleSettings.side, offx, 0)
end


-- Creates the actual bar
function IceBarElement.prototype:CreateBar()
	if not (self.barFrame) then
		self.barFrame = CreateFrame("StatusBar", nil, self.frame)
	end
	
	self.barFrame:SetFrameStrata("BACKGROUND")
	self.barFrame:SetWidth(self.width)
	self.barFrame:SetHeight(self.height)
	
	
	if not (self.barFrame.bar) then
		self.barFrame.bar = self.frame:CreateTexture(nil, "BACKGROUND")
	end
	
	self.barFrame.bar:SetTexture(IceBarElement.TexturePath .. self.settings.barTexture)
	self.barFrame.bar:SetAllPoints(self.frame)
	
	self.barFrame:SetStatusBarTexture(self.barFrame.bar)
	
	self:UpdateBar(1, "undef")
	
	local point = "LEFT"
	if (self.moduleSettings.side == point) then
		point = "RIGHT"
	end
	
	self.barFrame:ClearAllPoints()
	self.barFrame:SetPoint("BOTTOM"..point, self.frame, "BOTTOM"..self.moduleSettings.side, 0, 0)
end


function IceBarElement.prototype:CreateTexts()
	self.frame.bottomUpperText = self:FontFactory(nil, self.settings.barFontSize, nil, self.frame.bottomUpperText)
	self.frame.bottomLowerText = self:FontFactory(nil, self.settings.barFontSize, nil, self.frame.bottomLowerText)

	self.frame.bottomUpperText:SetWidth(80)
	self.frame.bottomLowerText:SetWidth(120)
	
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
	
	
	local offx = 2
	-- adjust offset for bars where text is aligned to the outer side
	if (self.moduleSettings.offset <= 1) then
		offx = IceBarElement.BarProportion * self.width - offx
	end


	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end

	self.frame.bottomUpperText:ClearAllPoints()
	self.frame.bottomLowerText:ClearAllPoints()

	self.frame.bottomUpperText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, -1)
	self.frame.bottomLowerText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, -15)
end


function IceBarElement.prototype:Flip(side)
	if (side == IceCore.Side.Left) then
		return IceCore.Side.Right
	else
		return IceCore.Side.Left
	end
end


function IceBarElement.prototype:SetScale(texture, scale)
	if (self.moduleSettings.side == IceCore.Side.Left) then
		texture:SetTexCoord(1, 0, 1-scale, 1)
	else
		texture:SetTexCoord(0, 1, 1-scale, 1)
	end
end


function IceBarElement.prototype:UpdateBar(scale, color, alpha)
	alpha = alpha or 1
	self.frame:SetAlpha(alpha)
	
	self.frame:SetStatusBarColor(self:GetColor(color, self.alpha))
	
	self.barFrame:SetStatusBarColor(self:GetColor(color))
	
	self:SetScale(self.barFrame.bar, scale)
end



-- Bottom line 1
function IceBarElement.prototype:SetBottomText1(text, color)
	if not (color) then
		color = "text"
	end
	
	local alpha = 1
	if not (self.settings.lockTextAlpha) then
		-- boost text alpha a bit to make it easier to see
		if (self.alpha > 0) then
			alpha = self.alpha + 0.1
			
			if (alpha > 1) then
				alpha = 1
			end
		else
			alpha = 0
		end
	end
	
	self.frame.bottomUpperText:SetTextColor(self:GetColor(color, alpha))
	self.frame.bottomUpperText:SetText(text)
end


-- Bottom line 2
function IceBarElement.prototype:SetBottomText2(text, color, alpha)
	if not (color) then
		color = "text"
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
	self.frame.bottomLowerText:SetTextColor(self:GetColor(color, alpha))
	self.frame.bottomLowerText:SetText(text)
end


function IceBarElement.prototype:GetFormattedText(value1, value2)
	local color = "ffcccccc"
	if not (value2) then
		return string.format("|c%s[|r%s|c%s]|r", color, value1, color)
	end
	return string.format("|c%s[|r%s|c%s/|r%s|c%s]|r", color, value1, color, value2, color)
end


-- To be overridden
function IceBarElement.prototype:Update()
	if (self.combat) then
		self.alpha = self.settings.alphaic
		self.backgroundAlpha = IceBarElement.BackgroundAlpha
	else
		self.alpha = self.settings.alphaooc
		self.backgroundAlpha = IceBarElement.BackgroundAlpha
	end
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
	self:Update(self.unit)
end
