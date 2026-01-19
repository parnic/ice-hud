local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local SML = LibStub("LibSharedMedia-3.0")

local IceHUD = _G.IceHUD

IceElement = IceCore_CreateClass()

IceElement.TexturePath = IceHUD.Location .. "\\textures\\"

-- Protected variables --
IceElement.prototype.elementName = nil
IceElement.prototype.parent = nil
IceElement.prototype.frame = nil
IceElement.prototype.masterFrame = nil

IceElement.prototype.defaultColors = {} -- Shared table for all child classes to save some memory
IceElement.prototype.alpha = nil
IceElement.prototype.backroundAlpha = nil

IceElement.prototype.combat = nil
IceElement.prototype.target = nil

IceElement.settings = nil
IceElement.moduleSettings = nil

IceElement.prototype.configColor = "ff8888ff"
IceElement.prototype.scalingEnabled = nil

IceElement.prototype.bIsVisible = true

-- Constructor --
-- IceElements are to be instantiated before IceCore is loaded.
-- Therefore we can wait for IceCore to load and then register our
-- module to the core with another event.
function IceElement.prototype:init(name, skipRegister)
	assert(name, "IceElement must have a name")

	self.elementName = name
	self.alpha = 1
	self.scalingEnabled = false

	-- Some common colors
	self:SetDefaultColor("Text", 1, 1, 1)
	self:SetDefaultColor("undef", 0.7, 0.7, 0.7)

	LibStub("AceEvent-3.0"):Embed(self)
	LibStub("AceTimer-3.0"):Embed(self)

	if skipRegister ~= true then
		IceHUD:Register(self)
	end
end


-- 'Public' methods -----------------------------------------------------------

function IceElement.prototype:ToString()
	return "IceElement('" .. self.elementName .. "')"
end


function IceElement.prototype:GetElementName()
	return self.elementName
end

function IceElement.prototype:GetElementDescription()
	return L["Module options"]
end


function IceElement.prototype:Create(parent)
	assert(parent, "IceElement 'parent' can't be nil")

	self.parent = parent
	if not self.masterFrame then
		self.masterFrame = CreateFrame("Frame", "IceHUD_Element_"..self.elementName, self.parent)
		self.masterFrame:SetFrameStrata(IceHUD.IceCore:DetermineStrata("MEDIUM"))
	end
	self:CreateFrame()
	self:Show(false)
end


function IceElement.prototype:SetDatabase(db)
	self.settings = db
	self.moduleSettings = db.modules[self.elementName]
end


function IceElement.prototype:IsEnabled()
	return self.moduleSettings.enabled
end


function IceElement.prototype:Enable(core)
	if (not core) then
		self.moduleSettings.enabled = true
	end

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "InCombat")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OutCombat")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "CheckCombat")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "TargetChanged")

	self:Show(true)
end


function IceElement.prototype:Disable(core)
	if (not core) then
		self.moduleSettings.enabled = false
	end
	self:Show(false)
	self:UnregisterAllEvents()
end



-- inherting classes should override this and provide
-- make sure they refresh any changes made to them
function IceElement.prototype:Redraw()

end


function IceElement.prototype:GetBarTypeDescription(barType)
	local pre = "|cff00ff00"
	local post = "|r"
	local retval = ""

	if barType == "CD" then
		retval = L["Cooldown"]
	elseif barType == "Bar" then
		retval = L["(De)Buff watcher"]
	elseif barType == "Counter" then
		retval = L["Counter"]
	elseif barType == "CounterBar" then
		retval = L["CounterBar"]
	elseif barType == "Health" then
		retval = HEALTH
	elseif barType == "Mana" then
		retval = MANA
	end

	return string.format("%s%s%s", pre, retval, post)
end


-- inheriting classes should override this and provide
-- AceOptions table for configuration
function IceElement.prototype:GetOptions()
	local opts = {}

	opts["enabled"] = {
		type = "toggle",
		name = L["Enabled"],
		desc = L["Enable/disable module"],
		get = function()
			return self.moduleSettings.enabled
		end,
		set = function(info, value)
			self.moduleSettings.enabled = value
			if (value) then
				self:Enable(true)
			else
				self:Disable()
			end
		end,
		order = 20
	}

	opts["headerVisibility"] = {
		type = 'header',
		name = L["Visibility Settings"],
		order = 27
	}

	opts["scale"] =
	{
		type = 'range',
		name = L["Scale"],
		desc = L["Scale of the element"],
		min = 0.2,
		max = 2,
		step = 0.1,
		isPercent = true,
		hidden = not self.scalingEnabled,
		get = function()
			return self.moduleSettings.scale
		end,
		set = function(info, value)
			self.moduleSettings.scale = value
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.1
	}

	opts["alwaysFullAlpha"] =
	{
		type = 'toggle',
		name = L["Always show at 100% alpha"],
		desc = L["Whether to always show this module at 100% alpha or not"],
		width = 'double',
		get = function()
			return self.moduleSettings.alwaysFullAlpha
		end,
		set = function(info, value)
			self.moduleSettings.alwaysFullAlpha = value
			self:Update()
			self:Redraw()
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 27.5
	}

	return opts
end



-- inheriting classes should override this and provide
-- default settings to populate db
function IceElement.prototype:GetDefaultSettings()
	local defaults = {}
	defaults["enabled"] = true
	defaults["scale"] = 1
	defaults["alwaysFullAlpha"] = false
	return defaults
end



-- 'Protected' methods --------------------------------------------------------

-- This should be overwritten by inheriting classes
function IceElement.prototype:CreateFrame()
	if not (self.frame) then
		self.frame = CreateFrame("Frame", "IceHUD_"..self.elementName, self.masterFrame)
	end
	self.masterFrame:SetAllPoints(self.frame)

	self.masterFrame:SetScale(self.moduleSettings.scale)

	self:UpdateAlpha()
end

function IceElement.prototype:SetFramePosition()
	self.frame:SetPoint("TOP", self.parent, "BOTTOM", self.moduleSettings.hpos, self.moduleSettings.vpos)
end

function IceElement.prototype:CreateMoveHintFrame()
	if not self.frame then
		self:CreateFrame()
	end

	self.frame:SetClampedToScreen(true)

	if not self.moveHint then
		self.moveHint = CreateFrame("Frame", "IceHUD_"..self.elementName.."_move", self.frame)

		self.moveHint.texture = self.moveHint:CreateTexture(nil, "ARTWORK")
		self.moveHint.texture:SetTexture("Interface/Tooltips/UI-Tooltip-Background")
		self.moveHint.texture:SetBlendMode("ADD")
		self.moveHint.texture:SetVertexColor(0.2, 0.8, 0.2, 0.75)
		self.moveHint.texture:SetAllPoints(self.moveHint)

		self.moveHint:SetScript("OnMouseDown", function() self:MoveHintMouseDown() end)
		self.moveHint:SetScript("OnMouseUp", function() self:MoveHintMouseUp() end)
		self.moveHint:SetScript("OnEnter", function() self:MoveHintEnter() end)
		self.moveHint:SetScript("OnLeave", function() self:MoveHintLeave() end)
		self.moveHint:Hide()
	end

	self.moveHint:SetAllPoints(self.frame)
end

function IceElement.prototype:AddDragMoveOption(opts, order)
	opts.dragMove = {
		type = "execute",
		name = L["Toggle interactive placement mode"],
		desc = L["Toggles the ability to drag this module to the desired location instead of adjusting Position sliders."],
		width = "full",
		func = function() self:ToggleMoveHint() end,
		hidden =
			--[===[@non-debug@
			true
			--@end-non-debug@]===]
			--@debug@
			false
			--@end-debug@
		,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = order,
	}

	return opts
end

function IceElement.prototype:IsInConfigMode()
	return IceHUD.IceCore:IsInConfigMode() or self.inMoveMode
end

function IceElement.prototype:MoveHintMouseDown()
	if IsMouseButtonDown("RightButton") then
		self:ToggleMoveHint()
		self:MoveHintMouseUp()
		return
	elseif IsMouseButtonDown("MiddleButton") then
		if self.moveHintOrigX and self.moveHintOrigY then
			self:MoveHintMoveTo(self.moveHintOrigX, self.moveHintOrigY)
		end

		self:SetFramePosition()
		IceHUD:NotifyOptionsChange()
		return
	elseif not IsMouseButtonDown("LeftButton") then
		return
	end

	self.moveHintOrigX, self.moveHintOrigY = self:MoveHintGetOffsets()
	self:SetMoveHintLast()
	self.moveHintScale = UIParent:GetEffectiveScale()
	self.moveHint:SetScript("OnUpdate", function() self:MoveHintUpdate() end)
end

function IceElement.prototype:SetMoveHintLast()
	self.moveHintLastX, self.moveHintLastY = GetCursorPosition()
	self.moveHintLastLeft, self.moveHintLastTop = self.frame:GetLeft(), self.frame:GetTop()
end

function IceElement.prototype:MoveHintUpdate()
	local currLeft, currTop = self.frame:GetLeft(), self.frame:GetTop()
	local lastX, lastY = self.moveHintLastX, self.moveHintLastY
	local currX, currY = GetCursorPosition()
	local dx, dy = (currX - lastX) / self.moveHintScale / IceHUD.IceCore:GetScale(), (currY - lastY) / self.moveHintScale / IceHUD.IceCore:GetScale()
	if IsShiftKeyDown() then
		dy = 0
	end
	if IsControlKeyDown() then
		dx = 0
	end

	self:MoveHintMoveBy(dx, dy)

	self:SetFramePosition()
	IceHUD:NotifyOptionsChange()
	self:SetMoveHintLast()

	-- if the frame clamping caused the frame to not move in a given direction, un-apply our delta to respect the clamp
	if not IsShiftKeyDown() and currTop == self.moveHintLastTop then
		self:MoveHintMoveBy(0, -dy)
	end
	if not IsControlKeyDown() and currLeft == self.moveHintLastLeft then
		self:MoveHintMoveBy(-dx, 0)
	end
end

function IceElement.prototype:MoveHintGetOffsets()
	return self.moduleSettings.hpos, self.moduleSettings.vpos
end

function IceElement.prototype:MoveHintMoveBy(dx, dy)
	self:MoveHintMoveTo(self.moduleSettings.hpos + dx, self.moduleSettings.vpos + dy)
end

function IceElement.prototype:MoveHintMoveTo(x, y)
	self.moduleSettings.hpos = x
	self.moduleSettings.vpos = y
end

function IceElement.prototype:MoveHintMouseUp()
	self.moveHint:SetScript("OnUpdate", nil)
end

function IceElement.prototype:MoveHintEnter()
	GameTooltip:SetOwner(self.moveHint, "ANCHOR_TOPLEFT")
	GameTooltip:SetText(self:MoveHintGetTooltip())
end

function IceElement.prototype:MoveHintGetTooltip()
	if not self.moveHintTooltip then
		self.moveHintTooltip = "|cffffffff"..self.elementName.."|r\n"..L["|cff9999ffLeft click|r and drag to move. Hold |cff9999ffShift|r to lock vertical position, hold |cff9999ffControl|r to lock horizontal position.\n\n|cff9999ffMiddle click|r to reset to previous position.\n\n|cff9999ffRight click|r to lock in place."]
	end
	return self.moveHintTooltip
end

function IceElement.prototype:MoveHintLeave()
	GameTooltip:Hide()
end

function IceElement.prototype:ToggleMoveHint()
	if not self.moveHint then
		self:CreateMoveHintFrame()
	end

	local wasInMoveMode = self.inMoveMode
	if wasInMoveMode then
		self.inMoveMode = false
		self.moveHint:Hide()
		self:Redraw()
	else
		self.inMoveMode = true
		self.moveHint:Show()
		self:Redraw()
	end

	return not wasInMoveMode
end


function IceElement.prototype:UpdateAlpha()
	if self:IsInConfigMode() or self.moduleSettings.alwaysFullAlpha then
		self.alpha = 1
		self.backgroundAlpha = 1
	else
		self.alpha = self.settings.alphaooc
		if (self.combat) then
			self.alpha = self.settings.alphaic
			self.backgroundAlpha = self.settings.alphaicbg
		elseif (self.target and not self:AlphaPassThroughTarget()) then
			self.alpha = self.settings.alphaTarget
			self.backgroundAlpha = self.settings.alphaTargetbg
		elseif (self:UseTargetAlpha(self.CurrScale)) then
			self.alpha = self.settings.alphaNotFull
			self.backgroundAlpha = self.settings.alphaNotFullbg
		else
			self.alpha = self.settings.alphaooc
			self.backgroundAlpha = self.settings.alphaoocbg
		end

		if IceHUD.CanAccessValue(self.alpha) and self.alpha ~= 0 then
			self.alpha = math.min(1, self.alpha + self:GetAlphaAdd())
		end
	end

	self.frame:SetAlpha(self.alpha)
end

function IceElement.prototype:AlphaPassThroughTarget()
	return not self.settings.bTreatFriendlyAsTarget and UnitIsFriend("target", "player")
end

-- use this to add some value to alpha every time. if you always want an element to be slightly brighter than the actual alpha for visibility
function IceElement.prototype:GetAlphaAdd()
	return 0
end


function IceElement.prototype:GetColors()
	return self.settings.colors
end


function IceElement.prototype:GetColor(color, alpha)
	if not (color) then
		return 1, 1, 1, 1
	end

	if not (alpha) then
		alpha = self.alpha
	end

	if not (self.settings.colors[color]) then
		local r, g, b = self:GetClassColor(color)
		return r, g, b, alpha
	end

	return self.settings.colors[color].r, self.settings.colors[color].g, self.settings.colors[color].b, alpha
end


function IceElement.prototype:GetHexColor(color, alpha)
	local r, g, b, a = self:GetColor(color)
	return string.format("%02x%02x%02x%02x", a * 255, r * 255, g * 255, b * 255)
end


function IceElement.prototype:SetColor(color, red, green, blue)
	if (red > 1) then
		red = red / 255
	end
	if (green > 1) then
		green = green / 255
	end
	if (blue > 1) then
		blue = blue / 255
	end
	self.settings.colors[color] = {r = red, g = green, b = blue}
end


function IceElement.prototype:SetDefaultColor(color, red, green, blue)
	if (red > 1) then
		red = red / 255
	end
	if (green > 1) then
		green = green / 255
	end
	if (blue > 1) then
		blue = blue / 255
	end

	self.defaultColors[color] = {r = red, g = green, b = blue}
end


function IceElement.prototype:GetClassColor(class)
	if type(class) == "table" then
		---@diagnostic disable-next-line: unbalanced-assignments
		local r,g,b = class
		if r and g and b then
			return r, g, b
		else
			return CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS["WARRIOR"] or RAID_CLASS_COLORS["WARRIOR"]
		end
	elseif type(class) == "function" then
		return
	end

	class = class:upper()
	if CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] then
		return CUSTOM_CLASS_COLORS[class].r, CUSTOM_CLASS_COLORS[class].g, CUSTOM_CLASS_COLORS[class].b
	elseif RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] then
		return RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
	else
		-- crazy talk...who the crap wouldn't have a blizzard-defined global defined?
		return 1,1,1
	end
end


function IceElement.prototype:ConvertToHex(color)
	return string.format("ff%02x%02x%02x", color.r*255, color.g*255, color.b*255)
end


function IceElement.prototype:FontFactory(size, frame, font, flags)
	if not (frame) then
		frame = self.masterFrame
	end

	local fontString = nil
	if not (font) then
		fontString = frame:CreateFontString()
	else
		fontString = font
	end

	if not flags then
		if self.settings.TextDecoration == "Outline" then
			flags = "OUTLINE"
		elseif self.settings.TextDecoration == "ThickOutline" then
			flags = "THICKOUTLINE"
		end
	end

	if not fontString:SetFont(SML:Fetch('font', self.settings.fontFamily), size, flags) then
		fontString:SetFont("Fonts\\FRIZQT__.TTF", size, flags)
	end

	if not (flags) then
		if self.settings.TextDecoration == "Shadow" then
			fontString:SetShadowColor(0, 0, 0, 1)
			fontString:SetShadowOffset(1, -1)
		end
	end

	return fontString
end


function IceElement.prototype:UseTargetAlpha(scale)
	return false
end


function IceElement.prototype:Update()
	self:UpdateAlpha()
end


function IceElement.prototype:IsVisible()
	return self.bIsVisible
end

function IceElement.prototype:Show(bShouldShow)
	if self.bIsVisible == bShouldShow or not self.masterFrame or not self.frame then
		return nil
	end

	self.bIsVisible = bShouldShow

	if not bShouldShow then
		self.masterFrame:Hide()
		self.frame:Hide()
	else
		self.masterFrame:Show()
		self.frame:Show()
	end

	return true
end


-- Combat event handlers ------------------------------------------------------

function IceElement.prototype:InCombat()
	self.combat = true
	self:Update()
end


function IceElement.prototype:OutCombat()
	self.combat = false
	self:Update()
end


function IceElement.prototype:CheckCombat()
	self.combat = UnitAffectingCombat("player")
	self.target = UnitExists("target")
	self:Update()
end


function IceElement.prototype:TargetChanged()
	self.target = UnitExists("target")
	self:Update()
end



-- Inherited classes should just instantiate themselves and let
-- superclass to handle registration to the core
-- IceInheritedClass:new()
