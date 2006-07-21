local AceOO = AceLibrary("AceOO-2.0")

IceCore = AceOO.Class("AceEvent-2.0", "AceDB-2.0")

IceCore.Side = { Left = "LEFT", Right = "RIGHT" }

-- Events modules should register/trigger during load
IceCore.Loaded = "IceCore_Loaded"
IceCore.RegisterModule = "IceCore_RegisterModule"


-- Private variables --
IceCore.prototype.settings = nil
IceCore.prototype.IceHUDFrame = nil
IceCore.prototype.elements = {}


-- Constructor --
function IceCore.prototype:init()
	IceCore.super.prototype.init(self)
	IceHUD:Debug("IceCore.prototype:init()")
	
	self:RegisterDB("IceCoreDB")
	
	self.IceHUDFrame = CreateFrame("Frame","IceHUDFrame", WorldFrame)
	
	
	-- We are ready to load modules
	self:RegisterEvent(IceCore.RegisterModule, "Register")
	self:TriggerEvent(IceCore.Loaded)
	
	
	-- DEFAULT SETTINGS
	local defaults = {
		gap = 150,
		verticalPos = -150,
		scale = 1,
		alphaooc = 0.3,
		alphaic = 0.6
	}
	

	-- get default settings from the modules
	defaults.modules = {}
	for i = 1, table.getn(self.elements) do
		local name = self.elements[i]:GetName()
		defaults.modules[name] = self.elements[i]:GetDefaultSettings()	
	end
	
	
	self:RegisterDefaults('account', defaults)
end


function IceCore.prototype:Enable()
	self.settings = self.db.account
	
	IceElement.Alpha = self.settings.bar
	self:DrawFrame()
	
	for i = 1, table.getn(self.elements) do
		self.elements[i]:SetDatabase(self.settings)
		self.elements[i]:Create(self.IceHUDFrame)
		if (self.elements[i]:IsEnabled()) then
			self.elements[i]:Enable()
		end
	end
end


function IceCore.prototype:DrawFrame()
	self.IceHUDFrame:SetFrameStrata("BACKGROUND")
	self.IceHUDFrame:SetWidth(self.settings.gap)
	self.IceHUDFrame:SetHeight(20)
	
	self:SetScale(self.settings.scale)
	
	self.IceHUDFrame:SetPoint("CENTER", 0, self.settings.verticalPos)
	self.IceHUDFrame:Show()
end


function IceCore.prototype:Redraw()
	for i = 1, table.getn(self.elements) do
		self.elements[i]:Redraw()
	end
end


function IceCore.prototype:GetModuleOptions()
	local options = {}
	for i = 1, table.getn(self.elements) do
		local modName = self.elements[i]:GetName()
		local opt = self.elements[i]:GetOptions()
		options[modName] =  {
			type = 'group',
			desc = 'Module options',
			name = modName,
			args = opt
		}
	end
	
	return options
end


-- Method to handle module registration
function IceCore.prototype:Register(element)
	assert(element, "Trying to register a nil module")
	IceHUD:Debug("Registering: " .. element:ToString())
	table.insert(self.elements, element)
end



-------------------------------------------------------------------------------
-- Configuration methods                                                     --
-------------------------------------------------------------------------------

function IceCore.prototype:ResetSettings()
	self:ResetDB()
	ReloadUI()
end

function IceCore.prototype:GetVerticalPos()
	return self.settings.verticalPos
end
function IceCore.prototype:SetVerticalPos(value)
	self.settings.verticalPos = value
	self.IceHUDFrame:ClearAllPoints()
	self.IceHUDFrame:SetPoint("CENTER", 0, self.settings.verticalPos)
end


function IceCore.prototype:GetGap()
	return self.settings.gap
end
function IceCore.prototype:SetGap(value)
	self.settings.gap = value
	self.IceHUDFrame:SetWidth(self.settings.gap)
end


function IceCore.prototype:GetScale()
	return self.settings.scale
end
function IceCore.prototype:SetScale(value)
	self.settings.scale = value
	
	local scale = UIParent:GetScale() * value
	self.IceHUDFrame:SetScale(scale)
end


function IceCore.prototype:GetAlphaOOC()
	return self.settings.alphaooc
end
function IceCore.prototype:SetAlphaOOC(value)
	self.settings.alphaooc = value
	self:Redraw()
end


function IceCore.prototype:GetAlphaIC()
	return self.settings.alphaic
end
function IceCore.prototype:SetAlphaIC(value)
	self.settings.alphaic = value
	self:Redraw()
end

