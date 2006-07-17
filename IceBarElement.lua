local AceOO = AceLibrary("AceOO-2.0")

IceBarElement = AceOO.Class(IceElement)
IceBarElement.virtual = true

IceBarElement.BackgroundAlpha = 0.25

IceBarElement.BarTexture = IceHUD.Location .. "\\textures\\HiBar"
IceBarElement.BackgroundTexture = IceHUD.Location .. "\\textures\\HiBarBG"
IceBarElement.BarProportion = 0.25 -- 0.18

IceBarElement.prototype.barFrame = nil
IceBarElement.prototype.side = nil
IceBarElement.prototype.offset = nil --offsets less than 0 should be reserved for pets etc
IceBarElement.prototype.width = nil
IceBarElement.prototype.height = nil
IceBarElement.prototype.backgroundAlpha = nil


-- Constructor --
function IceBarElement.prototype:init(name)
	IceBarElement.super.prototype.init(self, name)
	
	self.width = 77
	self.height = 154
	self.backgroundAlpha = IceBarElement.BackgroundAlpha
end




-- 'Public' methods -----------------------------------------------------------

function IceBarElement.prototype:SetPosition(side, offset)
	IceBarElement.prototype.side = side
	IceBarElement.prototype.offset = offset
end



-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:CreateFrame()
	-- don't call overridden method
	self:CreateBackground()
	self:CreateBar()
	self:CreateTexts()
end


-- Creates background for the bar
function IceBarElement.prototype:CreateBackground()
	self.frame = CreateFrame("StatusBar", nil, self.parent)
	
	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.width)
	self.frame:SetHeight(self.height)
	
	local bg = self.frame:CreateTexture(nil, "BACKGROUND")
	
	bg:SetTexture(IceBarElement.BackgroundTexture)
	bg:SetAllPoints(self.frame)
	
	if (self.side == IceCore.Side.Left) then
		bg:SetTexCoord(1, 0, 0, 1)
	end
	
	self.frame:SetStatusBarTexture(bg)
	self.frame:SetStatusBarColor(self:GetColor("undef", self.backgroundAlpha))
	
	local ownPoint = "LEFT"
	if (self.side == ownPoint) then
		ownPoint = "RIGHT"
	end
	
	-- ofxx = (bar width) + (extra space in between the bars)
	local offx = (IceBarElement.BarProportion * self.width * self.offset) + (self.offset * 10)
	if (self.side == IceCore.Side.Left) then
		offx = offx * -1
	end	
	
	self.frame:SetPoint("BOTTOM"..ownPoint, self.parent, "BOTTOM"..self.side, offx, 0)
end


-- Creates the actual bar
function IceBarElement.prototype:CreateBar()
	self.barFrame = CreateFrame("StatusBar", nil, self.frame)
	
	self.barFrame:SetFrameStrata("BACKGROUND")
	self.barFrame:SetWidth(self.width)
	self.barFrame:SetHeight(self.height)
	
	
	local bar = self.frame:CreateTexture(nil, "BACKGROUND")
	self.barFrame.texture = bar
	
	bar:SetTexture(IceBarElement.BarTexture)
	bar:SetAllPoints(self.frame)
	
	self.barFrame:SetStatusBarTexture(bar)
	
	self:UpdateBar(1, "undef")
	
	local point = "LEFT"
	if (self.side == point) then
		point = "RIGHT"
	end
	
	self.barFrame:SetPoint("BOTTOM"..point, self.frame, "BOTTOM"..self.side, 0, 0)
end


function IceBarElement.prototype:CreateTexts()
	self.frame.bottomUpperText = self:FontFactory(nil, 13)
	self.frame.bottomLowerText = self:FontFactory(nil, 13)

	self.frame.bottomUpperText:SetWidth(80)
	self.frame.bottomLowerText:SetWidth(120)

	local justify = "RIGHT"
	if ((self.side == "LEFT" and self.offset <= 1) or
		(self.side == "RIGHT" and self.offset > 1)) 
	then
		justify = "LEFT"
	end


	self.frame.bottomUpperText:SetJustifyH(justify)
	self.frame.bottomLowerText:SetJustifyH(justify)


	local ownPoint = self.side
	if (self.offset > 1) then
		ownPoint = self:Flip(ownPoint)
	end
	
	local parentPoint = self:Flip(self.side)
	
	
	local offx = 2
	-- adjust offset for bars where text is aligned to the outer side
	if (self.offset <= 1) then
		offx = IceBarElement.BarProportion * self.width + 6
	end


	if (self.side == IceCore.Side.Left) then
		offx = offx * -1
	end

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
	if (self.side == IceCore.Side.Left) then
		texture:SetTexCoord(1, 0, 1-scale, 1)
	else
		texture:SetTexCoord(0, 1, 1-scale, 1)
	end
end


function IceBarElement.prototype:UpdateBar(scale, color, alpha)
	alpha = alpha or 1
	self.frame:SetAlpha(alpha)
	
	self.frame:SetStatusBarColor(self:GetColor(color, self.backgroundAlpha))
	
	self.barFrame:SetStatusBarColor(self:GetColor(color))
	
	self:SetScale(self.barFrame.texture, scale)
end



-- Bottom line 1
function IceBarElement.prototype:SetBottomText1(text, color)
	if not (color) then
		color = "text"
	end
	self.frame.bottomUpperText:SetTextColor(self:GetColor(color, 1))
	self.frame.bottomUpperText:SetText(text)
end


-- Bottom line 2
function IceBarElement.prototype:SetBottomText2(text, color, alpha)
	if not (color) then
		color = "text"
	end
	if not (alpha) then
		alpha = self.alpha + 0.1
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

