IceHUD = LibStub("AceAddon-3.0"):NewAddon("IceHUD", "AceConsole-3.0")

local SML = AceLibrary("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local ConfigDialog = LibStub("AceConfigDialog-3.0")
local icon = LibStub("LibDBIcon-1.0")

IceHUD.CurrTagVersion = 3
IceHUD.debugging = false

IceHUD.WowVer = select(4, GetBuildInfo())

IceHUD.validBarList = { "Bar", "HiBar", "RoundBar", "ColorBar", "RivetBar", "RivetBar2", "CleanCurves", "GlowArc", "BloodGlaives", "ArcHUD", "FangRune" }

IceHUD.Location = "Interface\\AddOns\\IceHUD"
IceHUD.options =
{
	type = 'group',
	name = "IceHUD",
	desc = "IceHUD",
	icon = "Interface\\Icons\\Spell_Frost_Frost",
	args = 
	{
		headerGeneral = {
			type = 'header',
			name = "General Settings",
			order = 10
		},
		
		faq = {
			type = 'group',
			name = 'FAQs',
			desc = 'Answers to questions that are frequently asked.',
			order = 1,
			args = {
				test = {
					type = 'description',
					fontSize = "medium",
					name = [[Thanks for using IceHUD! Below you will find answers to all of the most commonly-asked questions. Be sure to check the addon's page on curse.com and wowinterface.com as well for more discussion and updates!


1. How do I hide the default Blizzard player and target unit frames?
Expand the "Module Settings" section, click "Player Health" or "Target Health," and check "Hide Blizzard Frame"

2. How do I turn off click-targeting and menus on the player bar?
Expand the "Module Settings" section, click "Player Health," un-check "Allow click-targeting." Note that as of v1.3, there is now an option to allow click-targeting out of combat, but turn it off while in combat.

3. How do I hide the HUD or change its transparency based on combat, targeting, etc.?
Check the "Transparency Settings" section. Nearly any combination of states should be available for tweaking.

4. Even if the rest of the HUD is transparent, the health percentages seem to show up. Why?
Expand the "Module Settings" section, expand "Player Health," click "Text Settings," look for options about keeping the lower/upper text blocks alpha locked. If the text is alpha locked, it will not drop below 100%, otherwise it respects its bar's transparency setting. Player Health/Mana, Target Health/Mana, and pet bars should all have these options.

5. Is there any way to see combo points for Rogues and Druids or sunder applications for Warriors?
Yes, check the "combo points" and "sunder count" modules in the configuration panel. (Note that these modules may not show up if you're not of the appropriate class to see them. They should be present for their respective classes, however.)

6. What's this thing at the top of the player's cast bar? It's darker than the rest of the bar.
That's the Cast Lag Indicator that shows you when you can start casting a new spell and still be able to finish the current one (based on your lag to the server). You can disable this in the Player Cast Bar module settings.

7. Is there a bar that shows breath underwater and if so, how can I adjust it?
Yes, this is called the MirrorBarHandler in the module settings. It's called that because it mirrors casting bar behavior, displays more than just breathing (fatigue is one example), and that's what Blizzard calls it. It can be moved/adjusted/resized/etc. as with any other module.

8. There's a long green bar that sometimes shows up below everything else. What is it?
That would be the TargetOfTarget module. That module is available for people who don't want the full ToT health/mana bars, but do want some sort of ToT representation on the screen.

9. IceHUD needs a bar or counter for buff/debuff X!
Good news: as of v1.5, you can create as many bars and counters for any buffs or debuffs you want! Click one of the "Create custom ..." buttons above. This will create a module named MyCustomBar# (where # is a number based on how many custom bars you've made so far) or MyCustomCounter#. You can then expand the Module Settings group and modify all sorts of settings on the new custom module. It is highly recommend that you rename the bar as soon as possible to avoid any confusion later. These custom modules are full-featured enough to replace some of the class-specific ones that are already there, but I will leave them so as not to upset people who are already using them.

10. How do I turn off the resting/combat/PvP/etc. icons on the player or target?
Expand Module Settings, expand PlayerHealth (or TargetHealth for targets), click Icon Settings. You can control every aspect of the icons there including location, visibility, draw order, etc.

11. How do I turn off buffs/debuffs on the player's or target's bar?
Expand Module Settings, expand PlayerInfo (or TargetInfo for targets), and set the number of buffs per row to be 0. These cannot be controlled independently (e.g. you can turn off buffs and debuffs, but not just one or the other).]]
				}
			}
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
					set = function(info, v)
						IceHUD.IceCore:SetVerticalPos(v)
					end,
					min = -700,
					max = 700,
					step = 10,
					order = 11
				},

				hpos = {
					type = 'range',
					name = 'Horizontal position',
					desc = 'Horizontal position (for you dual screen freaks)',
					get = function()
						return IceHUD.IceCore:GetHorizontalPos()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetHorizontalPos(v)
					end,
					min = -2000,
					max = 2000,
					step = 10,
					order = 12
				},

				gap = {
					type = 'range',
					name = 'Gap',
					desc = 'Distance between the left and right bars',
					get = function()
						return IceHUD.IceCore:GetGap()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetGap(v)
					end,
					min = 50,
					max = 700,
					step = 5,
					order = 13,
				},

				scale = {
					type = 'range',
					name = 'Scale',
					desc = 'HUD scale',
					get = function()
						return IceHUD.IceCore:GetScale()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetScale(v)
					end,
					min = 0.5,
					max = 1.5,
					step = 0.05,
					isPercent = true,
					order = 14,
				},
			}
		},


		alphaSettings = {
			type = 'group',
			name = 'Transparency Settings',
			desc = 'Settings for bar transparencies',
			order = 12,
			args = {
				headerAlpha = {
					type = 'header',
					name = "Bar Alpha",
					order = 10
				},

				alphaic = {
					type = 'range',
					name = 'Alpha in combat',
					desc = 'Bar alpha In Combat',
					get = function()
						return IceHUD.IceCore:GetAlpha("IC")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlpha("IC", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 11,
				},

				alphaooc = {
					type = 'range',
					name = 'Alpha out of combat',
					desc = 'Bar alpha Out Of Combat without target',
					get = function()
						return IceHUD.IceCore:GetAlpha("OOC")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlpha("OOC", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 12,
				},

				alphaTarget = {
					type = 'range',
					name = 'Alpha OOC and Target',
					desc = 'Bar alpha Out Of Combat with target accuired (takes precedence over Not Full)',
					get = function()
						return IceHUD.IceCore:GetAlpha("Target")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlpha("Target", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 13,
				},

				alphaNotFull = {
					type = 'range',
					name = 'Alpha OOC and not full',
					desc = 'Bar alpha Out Of Combat with target accuired or bar not full (Target takes precedence over this)',
					get = function()
						return IceHUD.IceCore:GetAlpha("NotFull")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlpha("NotFull", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 14,
				},


				headerAlphaBackground = {
					type = 'header',
					name = "Background Alpha",
					order = 20
				},

				alphaicbg = {
					type = 'range',
					name = 'BG Alpha in combat',
					desc = 'Background alpha for bars IC',
					get = function()
						return IceHUD.IceCore:GetAlphaBG("IC")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlphaBG("IC", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 21,
				},

				alphaoocbg = {
					type = 'range',
					name = 'BG Alpha out of combat',
					desc = 'Background alpha for bars OOC without target',
					get = function()
						return IceHUD.IceCore:GetAlphaBG("OOC")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlphaBG("OOC", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 22,
				},

				alphaTargetbg = {
					type = 'range',
					name = 'BG Alpha OOC and Target',
					desc = 'Background alpha for bars OOC and target accuired (takes precedence over Not Full)',
					get = function()
						return IceHUD.IceCore:GetAlphaBG("Target")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlphaBG("Target", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 23,
				},

				alphaNotFullbg = {
					type = 'range',
					name = 'BG Alpha OOC and not Full',
					desc = 'Background alpha for bars OOC and bar not full (Target takes precedence over this)',
					get = function()
						return IceHUD.IceCore:GetAlphaBG("NotFull")
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAlphaBG("NotFull", v)
					end,
					min = 0,
					max = 1,
					step = 0.05,
					isPercent = true,
					order = 24,
				},


				headerBarAdvanced = {
					type = 'header',
					name = "Other",
					order = 30
				},

				backgroundToggle = {
					type = "toggle",
					name = "Contextual Background",
					desc = "Toggles contextual background coloring",
					get = function()
						return IceHUD.IceCore:GetBackgroundToggle()
					end,
					set = function(info, value)
						IceHUD.IceCore:SetBackgroundToggle(value)
					end,
					order = 31
				},

				backgroundColor = {
					type = 'color',
					name = 'Background Color',
					desc = 'Background Color',
					get = function()
						return IceHUD.IceCore:GetBackgroundColor()
					end,
					set = function(info, r, g, b)
						IceHUD.IceCore:SetBackgroundColor(r, g, b)
					end,
					order = 32,
				},
			}
		},


		textSettings = {
			type = 'select',
			name =  'Font',
			desc = 'IceHUD Font',
			order = 19,
			get = function(info)
				return IceHUD:GetSelectValue(info, IceHUD.IceCore:GetFontFamily())
			end,
			set = function(info, value)
				IceHUD.IceCore:SetFontFamily(info.option.values[value])
			end,
			values = SML:List('font'),	
		},

		barSettings = {
			type = 'group',
			name = 'Bar Settings',
			desc = 'Settings related to bars',
			order = 20,
			args = {
				barPresets = {
					type = 'select',
					name = 'Presets',
					desc = 'Predefined settings for different bars',
					get = function(info)
						return IceHUD:GetSelectValue(info, IceHUD.IceCore:GetBarPreset())
					end,
					set = function(info, value)
						IceHUD.IceCore:SetBarPreset(info.option.values[value])
					end,
					values = IceHUD.validBarList,
					order = 9
				},


				headerBarAdvanced = {
					type = 'header',
					name = "Advanced Bar Settings",
					order = 10
				},

				barTexture = {
					type = 'select',
					name = 'Bar Texture',
					desc = 'IceHUD Bar Texture',
					get = function(info)
						return IceHUD:GetSelectValue(info, IceHUD.IceCore:GetBarTexture())
					end,
					set = function(info, value)
						IceHUD.IceCore:SetBarTexture(IceHUD.validBarList[value])
					end,
					values = IceHUD.validBarList,
					order = 11
				},

				barWidth = {
					type = 'range',
					name = 'Bar Width',
					desc = 'Bar texture width (not the actual bar!)',
					get = function()
						return IceHUD.IceCore:GetBarWidth()
					end,
					set = function(info, v)
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
					set = function(info, v)
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
					set = function(info, v)
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
					set = function(info, v)
						IceHUD.IceCore:SetBarSpace(v)
					end,
					min = -10,
					max = 30,
					step = 1,
					order = 15
				},

				bgBlendMode = {
					type = 'select',
					name = 'Bar Background Blend Mode',
					desc = 'IceHUD Bar Background Blend mode',
					get = function(info)
						return IceHUD.IceCore:GetBarBgBlendMode()
					end,
					set = function(info, value)
						IceHUD.IceCore:SetBarBgBlendMode(value)
					end,
					values = { BLEND = "Blend", ADD = "Additive" }, --"Disable", "Alphakey", "Mod" },		
					order = 16
				},

				barBlendMode = {
					type = 'select',
					name = 'Bar Blend Mode',
					desc = 'IceHUD Bar Blend mode',
					get = function(info)
						return IceHUD.IceCore:GetBarBlendMode()
					end,
					set = function(info, value)
						IceHUD.IceCore:SetBarBlendMode(value)
					end,
					values = { BLEND = "Blend", ADD = "Additive" }, --"Disable", "Alphakey", "Mod" },		
					order = 17
				},
			}
		},


		modules = {
			type='group',
			desc = 'Module configuration options',
			name = 'Module Settings',
			args = {},
			order = 41
		},
		
		colors = {
			type='group',
			desc = 'Module color configuration options',
			name = 'Colors',
			args = {},
			order = 42
		},

		headerOther = {
			type = 'header',
			name = 'Other',
			order = 90
		},
--[[
		enabled = {
			type = "toggle",
			name = "|cff11aa11Enabled|r",
			desc = "Enable/disable IceHUD",
			get = function()
				return IceHUD.IceCore:IsEnabled()
			end,
			set = function(info, value)
				if (value) then
					IceHUD.IceCore:Enable()
				else
					IceHUD.IceCore:Disable()
				end
			end,
			order = 91
		},
]]
		debug = {
			type = "toggle",
			name = "Debugging",
			desc = "Enable/disable debug messages",
			get = function()
				return IceHUD.IceCore:GetDebug()
			end,
			set = function(info, value)
				IceHUD.IceCore:SetDebug(value)
			end,
			order = 92
		},
		
		reset = {
			type = 'execute',
			name = '|cffff0000Reset|r',
			desc = "Resets all IceHUD options - WARNING: Reloads UI",
			func = function()
				StaticPopup_Show("ICEHUD_RESET")
			end,
			order = 93
		},

		customBar = {
			type = 'execute',
			name = 'Create custom bar',
			desc = 'Creates a new customized bar. This bar allows you to specify a buff or debuff to track on a variety of targets. Once that buff/debuff is applied, you will be able to watch it count down on the bar. You can create as many of these as you like.',
			func = function()
				IceHUD.IceCore:AddNewDynamicModule(IceCustomBar:new())
				StaticPopup_Show("ICEHUD_CUSTOM_BAR_CREATED")
			end,
			order = 94.5
		},

		customCount = {
			type = 'execute',
			name = 'Create custom counter',
			desc = 'Creates a new customized counter. This counter allows you to specify a stacking buff or debuff to track on a variety of targets. A number or graphic (whichever you choose) will count the number of applications of the specified buff/debuff. You can create as many of these as you like.',
			func = function()
				IceHUD.IceCore:AddNewDynamicModule(IceCustomCount:new())
				StaticPopup_Show("ICEHUD_CUSTOM_COUNTER_CREATED")
			end,
			order = 94.6
		},

		customCD = {
			type = 'execute',
			name = 'Create cooldown bar',
			desc = 'Creates a new customized ability cooldown bar. This bar will monitor the cooldown of the specified skill/spell so you know when it is available to be used again. You can create as many of these as you like.',
			func = function()
				IceHUD.IceCore:AddNewDynamicModule(IceCustomCDBar:new())
				StaticPopup_Show("ICEHUD_CUSTOM_CD_CREATED")
			end,
			order = 94.7
		},

		customHealth = {
			type = 'execute',
			name = 'Custom health bar',
			desc = 'Creates a new customized health bar. This bar monitors the health of whatever unit you specify. You can create as many of these as you like.',
			func = function()
				IceHUD.IceCore:AddNewDynamicModule(IceCustomHealth:new())
				StaticPopup_Show("ICEHUD_CUSTOM_HEALTH_CREATED")
			end,
			hidden = function()
				return IceCustomHealth == nil
			end,
			order = 94.8
		},

		customMana = {
			type = 'execute',
			name = 'Custom mana bar',
			desc = 'Creates a new customized mana bar. This bar monitors the mana of whatever unit you specify. You can create as many of these as you like.',
			func = function()
				IceHUD.IceCore:AddNewDynamicModule(IceCustomMana:new())
				StaticPopup_Show("ICEHUD_CUSTOM_MANA_CREATED")
			end,
			hidden = function()
				return IceCustomMana == nil
			end,
			order = 94.8
		},

		configMode = {
			type = 'toggle',
			name = '|cffff0000Configuration Mode|r',
			desc = 'Puts IceHUD into configuration mode so bars can be placed more easily',
			get = function()
				return IceHUD.IceCore:IsInConfigMode()
			end,
			set = function(info, value)
				IceHUD.IceCore:ConfigModeToggle(value)
			end,
			order = 95
		},

		useDogTags = {
			type = 'toggle',
			name = 'Use Dog Tags',
			desc = 'Whether or not the addon should use the DogTag library (this will increase the CPU usage of the mod)\n\nNOTE: after changing this option, you must reload the UI or else bad things happen',
			get = function()
				return IceHUD.IceCore:ShouldUseDogTags()
			end,
			set = function(info, v)
				StaticPopupDialogs["ICEHUD_CHANGED_DOGTAG"] = {
					text = "This option requires the UI to be reloaded. Do you wish to reload it now?",
					button1 = "Yes",
					OnAccept = function()
						ReloadUI()
					end,
					button2 = "No",
					timeout = 0,
					whileDead = 1,
					hideOnEscape = 1
				};
				IceHUD.IceCore:SetShouldUseDogTags(v)
				StaticPopup_Show("ICEHUD_CHANGED_DOGTAG")
			end,
			hidden = function()
				return not AceLibrary:HasInstance("LibDogTag-3.0")
			end,
			order = 96
		},

		updatePeriod = {
			type = 'range',
			name = 'Update Period',
			desc = 'Time between display updates in seconds',
			get = function()
				return IceHUD.IceCore:UpdatePeriod()
			end,
			set = function(info, v)
				IceHUD.IceCore:SetUpdatePeriod(v)
			end,
			min = 0.01,
			max = 1.0,
			step = 0.01,
			order = 97
		},

		showMinimap = {
			type = 'toggle',
			name = "Show Minimap Icon",
			desc = "Whether or not to show an IceHUD icon on the minimap.",
			get = function(info)
				return not IceHUD.db.profile.minimap.hide
			end,
			set = function(info, v)
				IceHUD.db.profile.minimap.hide = not v
				if v then
					icon:Show("IceHUD")
				else
					icon:Hide("IceHUD")
				end
			end,
			hidden = function() return not icon end,
			order = 98
		}
	}
}


StaticPopupDialogs["ICEHUD_RESET"] = 
{
	text = "Are you sure you want to reset IceHUD settings?",
	button1 = OKAY,
	button2 = CANCEL,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	OnAccept = function()
		IceHUD:ResetSettings()
	end
}

StaticPopupDialogs["ICEHUD_CUSTOM_BAR_CREATED"] =
{
	text = "A custom bar has been created and can be configured through Module Settings => MyCustomBar. It is highly recommended that you change the bar name of this module so that it's easier to identify.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

StaticPopupDialogs["ICEHUD_CUSTOM_COUNTER_CREATED"] =
{
	text = "A custom counter has been created and can be configured through Module Settings => MyCustomCounter. It is highly recommended that you change the bar name of this module so that it's easier to identify.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

StaticPopupDialogs["ICEHUD_CUSTOM_CD_CREATED"] =
{
	text = "A custom cooldown bar has been created and can be configured through Module Settings => MyCustomCD. It is highly recommended that you change the bar name of this module so that it's easier to identify.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

StaticPopupDialogs["ICEHUD_CUSTOM_HEALTH_CREATED"] =
{
	text = "A custom health bar has been created and can be configured through Module Settings => MyCustomHealth. It is highly recommended that you change the bar name of this module so that it's easier to identify.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

StaticPopupDialogs["ICEHUD_CUSTOM_MANA_CREATED"] =
{
	text = "A custom mana bar has been created and can be configured through Module Settings => MyCustomMana. It is highly recommended that you change the bar name of this module so that it's easier to identify.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

StaticPopupDialogs["ICEHUD_DELETE_CUSTOM_MODULE"] =
{
	text = "Are you sure you want to delete this module? This will remove all settings associated with it and cannot be un-done.",
	button1 = "Yes",
	button2 = "No",
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnAccept = function(self)
		IceHUD.IceCore:DeleteDynamicModule(self.data)
	end,
}


function IceHUD:OnInitialize()
	self:SetDebugging(false)
	self:Debug("IceHUD:OnInitialize()")

	self.IceCore = IceCore:new()

	self.db = LibStub("AceDB-3.0"):New("IceCoreDB", self.IceCore.defaults, "Default")
	self.db.RegisterCallback(self, "OnProfileShutdown", "PreProfileChanged")
	self.db.RegisterCallback(self, "OnProfileChanged", "PostProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "ProfileReset")
	self.db.RegisterCallback(self, "OnProfileCopied", "ProfileCopied")

	self:NotifyNewDb()
	self:GenerateModuleOptions(true)
	self.options.args.colors.args = self.IceCore:GetColorOptions()
	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	LibStub("AceConfig-3.0"):RegisterOptionsTable("IceHUD", self.options, "/icehudcl")

	ConfigDialog:SetDefaultSize("IceHUD", 750, 650)
	self:RegisterChatCommand("icehud", function() IceHUD:OpenConfig() end)
	self:RegisterChatCommand("rl", function() ReloadUI() end)

	self:SyncSettingsVersions()

	self:InitLDB()
end


function IceHUD:NotifyNewDb()
	self.IceCore.accountSettings = self.db.global
	self.IceCore.settings = self.db.profile
	self.IceCore:SetModuleDatabases()
	
	self.IceCore:CheckDisplayUpdateMessage()
end


function IceHUD:GenerateModuleOptions(firstLoad)
	self.options.args.modules.args = self.IceCore:GetModuleOptions()
	if not firstLoad and ACR ~= nil then
		IceHUD:NotifyOptionsChange()
	end
end

function IceHUD:NotifyOptionsChange()
	ACR:NotifyChange("IceHUD")
end


function IceHUD:OnEnable(isFirst)
	self:Debug("IceHUD:OnEnable()")

	self.IceCore:Enable()

	if isFirst then
		self:SetDebugging(self.IceCore:GetDebug())
		self.debugFrame = ChatFrame2
	end
end

-- add settings changes/updates here so that existing users don't lose their settings
function IceHUD:SyncSettingsVersions()
	if not self.IceCore.settings.updatedOocNotFull then
		self.IceCore.settings.updatedOocNotFull = true
		self.IceCore.settings.alphaNotFull = self.IceCore.settings.alphaTarget
		self.IceCore.settings.alphaNotFullbg = self.IceCore.settings.alphaTargetbg
	end
end


function IceHUD:InitLDB()
	local LDB = LibStub and LibStub("LibDataBroker-1.1", true)

	if (LDB) then
		local ldbButton = LDB:NewDataObject("IceHUD", {
			type = "launcher",
			text = "IceHUD",
			icon = "Interface\\Icons\\Spell_Frost_Frost",
			OnClick = function(_, msg)
				if not (UnitAffectingCombat("player")) then
					IceHUD:OpenConfig()
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cff8888ffIceHUD|r: Combat lockdown restriction. Leave combat and try again.")
				end
			end,
		})

		if icon then
			icon:Register("IceHUD", ldbButton, self.db.profile.minimap)
		end
	end
end

-- blizzard interface options
local blizOptionsPanel = CreateFrame("FRAME", "IceHUDConfigPanel", UIParent)
blizOptionsPanel.name = "IceHUD"
blizOptionsPanel.button = CreateFrame("BUTTON", "IceHUDOpenConfigButton", blizOptionsPanel, "UIPanelButtonTemplate2")
blizOptionsPanel.button:SetText("Open IceHUD configuration")
blizOptionsPanel.button:SetWidth(240)
blizOptionsPanel.button:SetHeight(30)
blizOptionsPanel.button:SetScript("OnClick", function(self) HideUIPanel(InterfaceOptionsFrame) HideUIPanel(GameMenuFrame) IceHUD:OpenConfig() end)
blizOptionsPanel.button:SetPoint('TOPLEFT', blizOptionsPanel, 'TOPLEFT', 20, -20)
InterfaceOptions_AddCategory(blizOptionsPanel)

function IceHUD:OpenConfig()
	if not ConfigDialog then return end
	ConfigDialog:Open("IceHUD")
end

function IceHUD:Debug(msg)
	if self.debugging then
		self.debugFrame:AddMessage(msg)
	end
end

function IceHUD:SetDebugging(bIsDebugging)
	self.debugging = bIsDebugging
end

-- rounding stuff
function IceHUD:MathRound(num, idp)
	if not num then
		return nil
	end

	local mult = 10^(idp or 0)
	return math.floor(num  * mult + 0.5) / mult
end

function IceHUD:GetBuffCount(unit, ability, onlyMine, matchByName)
	return IceHUD:GetAuraCount("HELPFUL", unit, ability, onlyMine, matchByName)
end

function IceHUD:GetDebuffCount(unit, ability, onlyMine, matchByName)
	return IceHUD:GetAuraCount("HARMFUL", unit, ability, onlyMine, matchByName)
end

function IceHUD:GetAuraCount(auraType, unit, ability, onlyMine, matchByName)
	if unit == "main hand weapon" or unit == "off hand weapon" then
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, hasOffHandEnchant, offHandExpiration, offHandCharges
			= GetWeaponEnchantInfo()

		if unit == "main hand weapon" and hasMainHandEnchant then
			return mainHandCharges
		elseif unit == "off hand weapon" and hasOffHandEnchant then
			return offHandCharges
		end

		return 0
	end

	for i = 1, 40 do
		local name, _, texture, applications = UnitAura(unit, i, auraType..(onlyMine and "|PLAYER" or ""))

		if (not matchByName and not texture) or (matchByName and not name) then
			break
		end

		if (not matchByName and string.match(texture:upper(), ability:upper())) or (matchByName and string.match(name:upper(), ability:upper())) then
			return applications
		end
	end

	return 0
end

function IceHUD:OnDisable()
	IceHUD.IceCore:Disable()
end

function IceHUD:PreProfileChanged(db)
	self.IceCore:Disable()
end

function IceHUD:PostProfileChanged(db, newProfile)
	self:NotifyNewDb()
	self.IceCore:Enable()
end

function IceHUD:ProfileReset()
	ReloadUI()
end
function IceHUD:ProfileCopied()
	ReloadUI()
end

function IceHUD:Clamp(value, min, max)
	if value < min then
		value = min
	elseif value > max then
		value = max
	elseif value ~= value or not (value >= min and value <= max) then -- check for nan...
		value = min
	end

	return value
end

function IceHUD:ShouldSwapToVehicle(...)
	local arg1, arg2 = ...

	if (arg1 == "player") then
		if (arg2) then
			return true
		end
	end

	if (UnitHasVehicleUI("player")) then
		return true
	end
end

function IceHUD:xor(val1, val2)
	return val1 and not val2 or val2 and not val1
end

function IceHUD:GetSelectValue(info, val)
	for k,v in pairs(info.option.values) do
		if v == val then
			return k
		end
	end

	return 1
end
