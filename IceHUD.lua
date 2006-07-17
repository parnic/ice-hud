IceHUD = AceLibrary("AceAddon-2.0"):new("AceDebug-2.0")
local AceOO = AceLibrary("AceOO-2.0")

IceHUD.Location = "Interface\\AddOns\\IceHUD"

function IceHUD:OnInitialize()
	self:SetDebugging(false)
	self:Debug("IceHUD:OnInitialize()")
	
	self.IceCore = IceCore:new()
end


function IceHUD:OnEnable()
	self:Debug("IceHUD:OnEnable()")
	
	self.IceCore:Enable()
end


