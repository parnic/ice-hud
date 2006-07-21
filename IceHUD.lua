IceHUD = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDebug-2.0")

IceHUD.dewdrop = AceLibrary("Dewdrop-2.0")

IceHUD.Location = "Interface\\AddOns\\IceHUD"
IceHUD.temp = nil
IceHUD.options =
{
	type = 'group',
	args = 
	{
		headerGeneral = {
			type = 'header',
			name = "General Settings",
			order = 10
		},
		vpos = {
			type = 'range',
			name = 'Vertical position',
			desc = 'Vertical position',
			get = function()
				return IceHUD.IceCore:GetVerticalPos()
			end,
			set = function(v)
				IceHUD.IceCore:SetVerticalPos(v)
			end,
			min = -300,
			max = 300,
			step = 10,
			order = 11
		},
		
		gap = {
			type = 'range',
			name = 'Gap',
			desc = 'Distance between the left and right bars',
			get = function()
				return IceHUD.IceCore:GetGap()
			end,
			set = function(v)
				IceHUD.IceCore:SetGap(v)
			end,
			min = 50,
			max = 300,
			step = 5,
			order = 12,
		},
		
		scale = {
			type = 'range',
			name = 'Scale',
			desc = 'HUD scale',
			get = function()
				return IceHUD.IceCore:GetScale()
			end,
			set = function(v)
				IceHUD.IceCore:SetScale(v)
			end,
			min = 0.5,
			max = 1.5,
			step = 0.05,
			order = 13,
		},
		
		alphaooc = {
			type = 'range',
			name = 'Alpha OOC',
			desc = 'Bar alpha Out Of Combat',
			get = function()
				return IceHUD.IceCore:GetAlphaOOC()
			end,
			set = function(v)
				IceHUD.IceCore:SetAlphaOOC(v)
			end,
			min = 0,
			max = 1,
			step = 0.05,
			order = 14,
		},
		
		alphaic = {
			type = 'range',
			name = 'Alpha IC',
			desc = 'Bar alpha In Combat',
			get = function()
				return IceHUD.IceCore:GetAlphaIC()
			end,
			set = function(v)
				IceHUD.IceCore:SetAlphaIC(v)
			end,
			min = 0,
			max = 1,
			step = 0.05,
			order = 15
		},
		
		
		headerModules = {
			type = 'header',
			name = 'Module Settings',
			order = 40
		},
		
		modules = {
			type='group',
			desc = 'Module configuration options',
			name = 'Modules',
			args = {},
			order = 41
		},
		
		
		
		headerOther = {
			type = 'header',
			name = 'Other Settings',
			order = 90
		},
		
		reset = {
			type = 'execute',
			name = '|cffff0000Reset|r',
			desc = "Resets all IceHUD options - WARNING: Reloads UI",
			func = function()
				IceHUD.IceCore:ResetSettings()
			end,
			order = 91
		},
		
		dewdrop = {
			type = 'execute',
			name = 'dewdrop',
			desc = 'Open Dewdrop menu for commands',
			func = function()
				if not (IceHUD.dewdrop:IsRegistered(IceHUD.IceCore.IceHUDFrame)) then
					IceHUD.dewdrop:Register(IceHUD.IceCore.IceHUDFrame, 
						'children', IceHUD.options,
						'point', "BOTTOMLEFT",
						'relativePoint', "TOPLEFT",
						'dontHook', true
					)
				end
				IceHUD.dewdrop:Open(IceHUD.IceCore.IceHUDFrame)
			end,
			order = 92
		}
	}
}


function IceHUD:OnInitialize()
	self:SetDebugging(false)
	self:Debug("IceHUD:OnInitialize()")
	
	self.IceCore = IceCore:new()
	
	self.options.args.modules.args = self.IceCore:GetModuleOptions()
	
	self:RegisterChatCommand({ "/icehud" }, IceHUD.options)
end


function IceHUD:OnEnable()
	self:Debug("IceHUD:OnEnable()")
	
	self.IceCore:Enable()
end


