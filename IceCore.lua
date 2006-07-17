local AceOO = AceLibrary("AceOO-2.0")

IceCore = AceOO.Class("AceEvent-2.0")

IceCore.Side = { Left = "LEFT", Right = "RIGHT" }
IceCore.Width = 150

-- Events modules should register/trigger during load
IceCore.Loaded = "IceCore_Loaded"
IceCore.RegisterModule = "IceCore_RegisterModule"


-- 'Private' variables
IceCore.prototype.IceHUDFrame = nil
IceCore.prototype.elements = {}


function IceCore.prototype:init()
	IceCore.super.prototype.init(self)
	IceHUD:Debug("IceCore.prototype:init()")
	
	self:DrawFrame()
	
	-- We are ready to load modules
	self:RegisterEvent(IceCore.RegisterModule, "Register")
	self:TriggerEvent(IceCore.Loaded)
end


function IceCore.prototype:Enable()
	for i = 1, table.getn(self.elements) do
		self.elements[i]:Create(self.IceHUDFrame)
		self.elements[i]:Enable()
	end
end


function IceCore.prototype:DrawFrame()
	self.IceHUDFrame = CreateFrame("Frame","IceHUDFrame", UIParent)
	
	self.IceHUDFrame:SetFrameStrata("BACKGROUND")
	self.IceHUDFrame:SetWidth(IceCore.Width)
	self.IceHUDFrame:SetHeight(20)
	
	
	-- For debug purposes
	--[[
	self.IceHUDFrame:SetBackdrop(
	{
		bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
        edgeFile = "Interface/Tooltips/UI-ToolTip-Border", 
        tile = false,
		tileSize = 32,
		edgeSize = 14, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
	} )

	self.IceHUDFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.1)
	self.IceHUDFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.1)
	--]]
	
	self.IceHUDFrame:SetPoint("CENTER", 0, -150)
	self.IceHUDFrame:Show()
end





-- Method to handle module registration
function IceCore.prototype:Register(element)
	assert(element, "Trying to register a nil module")
	IceHUD:Debug("Registering: " .. element:ToString())
	table.insert(self.elements, element)
end

