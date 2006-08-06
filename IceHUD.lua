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
		
		positioningSettings = {
			type = 'group',
			name = 'Positioning Settings',
			desc = 'Settings related to positioning and alpha',
			order = 11,
			args = {
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
					isPercent = true,
					order = 13,
				},
			}
		},
		
		
		alphaSettings = {
			type = 'group',
			name = 'Transparency Settings',
			desc = 'Settings for bar transparencies',
			order = 12,
			args = {
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
					isPercent = true,
					order = 14,
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
					isPercent = true,
					order = 15,
				},
				
				alphabg = {
					type = 'range',
					name = 'Background Alpha',
					desc = 'Background alpha for bars',
					get = function()
						return IceHUD.IceCore:GetAlphaBG()
					end,
					set = function(v)
						IceHUD.IceCore:SetAlphaBG(v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 16,
				},
				
				backgroundColor = {
					type = 'color',
					name = 'Background Color',
					desc = 'Background Color',
					get = function()
						return IceHUD.IceCore:GetBackgroundColor()
					end,
					set = function(r, g, b)
						IceHUD.IceCore:SetBackgroundColor(r, g, b)
					end,
				},
			}
		},
		
		
		textSettings = {
			type = 'group',
			name = 'Text Settings',
			desc = 'Settings related to texts',
			order = 15,
			args = {
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
					order = 11
				},
				
				fontBold = {
					type = 'toggle',
					name = 'Bar Font Bold',
					desc = 'Bar Font Bold',
					get = function()
						return IceHUD.IceCore:GetBarFontBold()
					end,
					set = function(v)
						IceHUD.IceCore:SetBarFontBold(v)
					end,
					order = 12
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
					order = 13
				},
				
				upperTextVisible = {
					type = 'toggle',
					name = 'Upper text visible',
					desc = 'Toggle upper text visibility',
					get = function()
						return IceHUD.IceCore:GetTextVisibility("upper")
					end,
					set = function(v)
						IceHUD.IceCore:SetTextVisibility("upper", v)
					end,
					order = 14
				},
				
				lowerTextVisible = {
					type = 'toggle',
					name = 'Lower text visible',
					desc = 'Toggle lower text visibility',
					get = function()
						return IceHUD.IceCore:GetTextVisibility("lower")
					end,
					set = function(v)
						IceHUD.IceCore:SetTextVisibility("lower", v)
					end,
					order = 15
				},
			}
		},
				
		barSettings = {
			type = 'group',
			name = 'Bar Settings',
			desc = 'Settings related to bars',
			order = 20,
			args = {
				barPresets = {
					type = 'text',
					name = 'Presets',
					desc = 'Predefined settings for different bars',
					get = function()
						return IceHUD.IceCore:GetBarPreset()
					end,
					set = function(value)
						IceHUD.IceCore:SetBarPreset(value)
					end,
					validate = { "Bar", "HiBar", "RoundBar" },
					order = 9
				},
			
			
				headerBarAdvancedBlank = { type = 'header', name = " ", order = 10 },
				headerBarAdvanced = {
					type = 'header',
					name = "Advanced Bar Settings",
					order = 10
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
					validate = { "Bar", "HiBar", "RoundBar" },		
					order = 11
				},
				
				barWidth = {
					type = 'range',
					name = 'Bar Width',
					desc = 'Bar texture width (not the actual bar!)',
					get = function()
						return IceHUD.IceCore:GetBarWidth()
					end,
					set = function(v)
						IceHUD.IceCore:SetBarWidth(v)
					end,
					min = 20,
					max = 200,
					step = 1,
					order = 12
				},
				
				barHeight = {
					type = 'range',
					name = 'Bar Height',
					desc = 'Bar texture height (not the actual bar!)',
					get = function()
						return IceHUD.IceCore:GetBarHeight()
					end,
					set = function(v)
						IceHUD.IceCore:SetBarHeight(v)
					end,
					min = 100,
					max = 300,
					step = 1,
					order = 13
				},
				
				barProportion = {
					type = 'range',
					name = 'Bar Proportion',
					desc = 'Determines the bar width compared to the whole texture width',
					get = function()
						return IceHUD.IceCore:GetBarProportion()
					end,
					set = function(v)
						IceHUD.IceCore:SetBarProportion(v)
					end,
					min = 0.01,
					max = 0.5,
					step = 0.01,
					isPercent = true,
					order = 14
				},
				
				barSpace = {
					type = 'range',
					name = 'Bar Space',
					desc = 'Space between bars on the same side',
					get = function()
						return IceHUD.IceCore:GetBarSpace()
					end,
					set = function(v)
						IceHUD.IceCore:SetBarSpace(v)
					end,
					min = -10,
					max = 30,
					step = 1,
					order = 15
				},
			}
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
		
		debug = {
			type = "toggle",
			name = "Debugging",
			desc = "Enable/disable debug messages",
			get = function()
				return IceHUD.IceCore:GetDebug()
			end,
			set = function(value)
				IceHUD.IceCore:SetDebug(value)
			end,
			order = 93
		},
		
		about = {
			type = 'execute',
			name = 'About',
			desc = "Prints info about IceHUD",
			func = function()
				IceHUD:PrintAddonInfo()
			end,
			order = 94
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
	self:SetDebugging(self.IceCore:GetDebug())
end

