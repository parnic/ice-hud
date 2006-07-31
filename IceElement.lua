local AceOO = AceLibrary("AceOO-2.0")

IceElement = AceOO.Class("AceEvent-2.0")
IceElement.virtual = true

-- Protected variables --
IceElement.prototype.name = nil
IceElement.prototype.parent = nil
IceElement.prototype.frame = nil

IceElement.prototype.colors = {} -- Shared table for all child classes to save some memory
IceElement.prototype.alpha = nil

IceElement.settings = nil
IceElement.moduleSettings = nil


-- Constructor --
-- IceElements are to be instantiated before IceCore is loaded.
-- Therefore we can wait for IceCore to load and then register our
-- module to the core with another event.
function IceElement.prototype:init(name)
	IceElement.super.prototype.init(self)
	assert(name, "IceElement must have a name")
	
	self.name = name
	self.alpha = 1
	
	-- Some common colors
	self:SetColor("text", 1, 1, 1)
	self:SetColor("undef", 0.7, 0.7, 0.7)
	
	self:RegisterEvent(IceCore.Loaded, "OnCoreLoad")
end


-- 'Public' methods -----------------------------------------------------------

function IceElement.prototype:ToString()
	return "IceElement('" .. self.name .. "')"
end


function IceElement.prototype:GetName()
	return self.name
end


function IceElement.prototype:Create(parent)
	assert(parent, "IceElement 'parent' can't be nil")
	
	self.parent = parent
	self:CreateFrame()
	self.frame:Hide()
end


function IceElement.prototype:SetDatabase(db)
	self.settings = db
	self.moduleSettings = db.modules[self.name]
end


function IceElement.prototype:IsEnabled()
	return self.moduleSettings.enabled
end


function IceElement.prototype:Enable()
	self.frame:Show()
end


function IceElement.prototype:Disable()
	self.frame:Hide()
	self:UnregisterAllEvents()
end


-- inherting classes should override this and provide
-- make sure they refresh any changes made to them
function IceElement.prototype:Redraw()
	
end


-- inheriting classes should override this and provide
-- AceOptions table for configuration
function IceElement.prototype:GetOptions()
	local opts = {}
	opts["enabled"] = {
		type = "toggle",
		name = "|cff8888ffEnabled|r",
		desc = "Enable/disable module",
		get = function()
			return self.moduleSettings.enabled
		end,
		set = function(value)
			self.moduleSettings.enabled = value
			if (value) then
				self:Enable()
			else
				self:Disable()
			end
		end,
		order = 20
	}
	return opts
end



-- inheriting classes should override this and provide
-- default settings to populate db
function IceElement.prototype:GetDefaultSettings()
	local defaults = {}
	defaults["enabled"] = true
	return defaults
end



-- 'Protected' methods --------------------------------------------------------

-- This should be overwritten by inheriting classes
function IceElement.prototype:CreateFrame()
	if not (self.frame) then
		self.frame = CreateFrame("Frame", "IceHUD_"..self.name, self.parent)
	end
end


function IceElement.prototype:GetColor(color, alpha)
	if not (color) then
		return 1, 1, 1, 1
	end

	if not (alpha) then
		alpha = self.alpha
	end
	
	if not (self.colors[color]) then
		local r, g, b = self:GetClassColor(color)
		return r, g, b, alpha
	end

	return self.colors[color].r, self.colors[color].g, self.colors[color].b, alpha
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
	self.colors[color] = {r = red, g = green, b = blue}
end


function IceElement.prototype:GetClassColor(class)
	class = string.upper(class)
	return RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b
end


function IceElement.prototype:FontFactory(weight, size, frame, font)
	weight = weight or ""
	local fontFile = IceHUD.Location .. "\\fonts\\Calibri" .. weight ..".ttf"
	
	if not (frame) then
		frame = self.frame
	end
	
	local fontString = nil
	if not (font) then
		fontString = frame:CreateFontString()
	else
		fontString = font
	end
	fontString:SetFont(fontFile, size)
	fontString:SetShadowColor(0, 0, 0, 1)
	fontString:SetShadowOffset(1, -1)
	
	return fontString
end



-- Event Handlers -------------------------------------------------------------

-- Register ourself to the core
function IceElement.prototype:OnCoreLoad()
	self:TriggerEvent(IceCore.RegisterModule, self)
end




-- Inherited classes should just instantiate themselves and let
-- superclass to handle registration to the core
-- IceInheritedClass:new()
