IceHUD = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceDebug-2.0")

IceHUD.dewdrop = AceLibrary("Dewdrop-2.0")

IceHUD.Location = "Interface\\AddOns\\IceHUD"
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
			order = 16,
		},
		
		lockFontAlpha = {
			type = "toggle",
			name = "Lock Bar Text Alpha",
			desc = "Lock Bar Text Alpha",
			get = function()
				return IceHUD.IceCore:GetLockTextAlpha()
			end,
			set = function(value)
				IceHUD.IceCore:SetLockTextAlpha(value)
			end,
			order = 17
		},
		
		fontsize = {
			type = 'range',
			name = 'Bar Font Size',
			desc = 'Bar Font Size',
			get = function()
				return IceHUD.IceCore:GetBarFontSize()
			end,
			set = function(v)
				IceHUD.IceCore:SetBarFontSize(v)
			end,
			min = 8,
			max = 20,
			step = 1,
			order = 18
		},
		
		barTexture = {
			type = 'text',
			name = 'Bar Texture',
			desc = 'IceHUD Bar Texture',
			get = function()
				return IceHUD.IceCore:GetBarTexture()
			end,
			set = function(value)
				IceHUD.IceCore:SetBarTexture(value)
			end,
			validate = { "Bar", "HiBar" },		
			order = 19
		},
		
		
		
		headerModulesBlank = { type = 'header', name = ' ', order = 40 },
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
		
		
		headerOtherBlank = { type = 'header', name = ' ', order = 90 },
		headerOther = {
			type = 'header',
			name = 'Other',
			order = 90
		},
		
		enabled = {
			type = "toggle",
			name = "|cff8888ffEnabled|r",
			desc = "Enable/disable IceHUD",
			get = function()
				return IceHUD.IceCore:IsEnabled()
			end,
			set = function(value)
				if (value) then
					IceHUD.IceCore:Enable()
				else
					IceHUD.IceCore:Disable()
				end
			end,
			order = 91
		},
		
		reset = {
			type = 'execute',
			name = '|cffff0000Reset|r',
			desc = "Resets all IceHUD options - WARNING: Reloads UI",
			func = function()
				IceHUD.IceCore:ResetSettings()
			end,
			order = 92
		},
		
		about = {
			type = 'execute',
			name = 'About',
			desc = "Prints info about IceHUD",
			func = function()
				IceHUD:PrintAddonInfo()
			end,
			order = 93
		},
		
		endSpace = {
			type = 'header',
			name = ' ',
			order = 1000
		},

	}
}

IceHUD.slashMenu =
{
	type = 'execute',
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
	end
}



function IceHUD:OnInitialize()
	self:SetDebugging(false)
	self:Debug("IceHUD:OnInitialize()")
	
	self.IceCore = IceCore:new()
	
	self.options.args.modules.args = self.IceCore:GetModuleOptions()
	
	self:RegisterChatCommand({ "/icehud" }, IceHUD.slashMenu)
end


function IceHUD:OnEnable()
	self:Debug("IceHUD:OnEnable()")
	
	self.IceCore:Enable()
end

