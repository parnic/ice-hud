local LibDualSpec = LibStub('LibDualSpec-1.0', true)
local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local icon = LibStub("LibDBIcon-1.0", true)
local AceGUI = LibStub("AceGUI-3.0")
local AceSerializer = LibStub("AceSerializer-3.0", true)
local lastCustomModule = "Bar"

IceHUD_Options = {}

local options =
{
	type = 'group',
	name = L["IceHUD"],
	desc = L["IceHUD"],
	icon = "Interface\\Icons\\Spell_Frost_Frost",
	args =
	{
		headerGeneral = {
			type = 'header',
			name = L["General Settings"],
			order = 10
		},

		faq = {
			type = 'group',
			name = L["FAQs"],
			desc = L["Answers to questions that are frequently asked."],
			order = 1,
			args = {
				test = {
					type = 'description',
					fontSize = "medium",
					name = [[Thanks for using |cff9999ffIceHUD|r! Below you will find answers to all of the most commonly-asked questions. Be sure to check the addon's page on |cff33ff99GitHub|r and |cff33ff99curseforge.com|r as well for more discussion and updates! You can also email |cff33ff99icehud@parnic.com|r directly if you prefer.

|cff9999ffA Note on WoW Midnight|r
The 12.0 patch, for the Midnight expansion, made significant, sweeping changes to how addons work in the game. As a result, many features previously available are no longer allowed by the game. If IceHUD is no longer doing something it used to do, the most likely reason is that it's not possible (or much more difficult) in the new patch. Feel free to create a GitHub issue for any errors you find; it's expected that there will be some errors for a while due to the extent of changes required.

|cff9999ff1. How do I hide the default Blizzard player and target unit frames?|r
Expand the "|cffffdc42Module Settings|r" section, click "PlayerHealth" or "TargetHealth," and check "Hide Blizzard Frame"

|cff9999ff2. How do I turn off click-targeting and menus on the player bar?|r
Expand the "|cffffdc42Module Settings|r" section, click "PlayerHealth," un-check "Allow click-targeting." Note that as of v1.3, there is now an option to allow click-targeting out of combat, but turn it off while in combat.

|cff9999ff3. How do I hide the HUD or change its transparency based on combat, targeting, etc.?|r
Check the "Transparency Settings" section. Nearly any combination of states should be available for tweaking.

|cff9999ff4. Even if the rest of the HUD is transparent, the health percentages seem to show up. Why?|r
Expand the "|cffffdc42Module Settings|r" section, expand "PlayerHealth," click "Text Settings," look for options about keeping the lower/upper text blocks alpha locked. If the text is alpha locked, it will not drop below 100%, otherwise it respects its bar's transparency setting. PlayerHealth/Mana, TargetHealth/Mana, and pet bars should all have these options.

|cff9999ff5. Is there any way to see combo points for Rogues and Druids or sunder applications for Warriors?|r
Yes, check the "ComboPoints" and "Sunders" modules in the configuration panel. (Note that these modules may not show up if you're not of the appropriate class to see them. They should be present for their respective classes, however.)

|cff9999ff6. What's this thing at the top of the player's cast bar? It's darker than the rest of the bar.|r
That's the Cast Lag Indicator that shows you when you can start casting a new spell and still be able to finish the current one (based on your lag to the server). You can disable this in the Player Cast Bar module settings.

|cff9999ff7. Is there a bar that shows breath underwater, and if so how can I adjust it?|r
Yes, this is called the MirrorBarHandler in the |cffffdc42Module Settings|r. It's called that because it mirrors casting bar behavior, displays more than just breathing (fatigue is one example), and that's what Blizzard calls it. It can be moved/adjusted/resized/etc. as with any other module.

|cff9999ff8. There's a long green bar that sometimes shows up below everything else. What is it?|r
That would be the TargetOfTarget module. That module is available for people who don't want the full ToT health/mana bars, but do want some sort of ToT representation on the screen.

|cff9999ff9. IceHUD needs a bar or counter for buff/debuff X!|r
Good news: as of v1.5, you can create as many bars and counters for any buffs or debuffs you want! Select one of the custom module types above and press the Create button. This will create a custom module and automatically select it in the list. It is highly recommend that you rename the bar as soon as possible to avoid any confusion later.

|cff9999ff10. How do I turn off the resting/combat/PvP/etc. icons on the player or target?|r
Expand "|cffffdc42Module Settings|r", expand PlayerHealth (or TargetHealth for targets), click Icon Settings. You can control every aspect of the icons there including location, visibility, draw order, etc.

|cff9999ff11. How do I turn off buffs/debuffs on the player's or target's bar?|r
Expand "|cffffdc42Module Settings|r", expand PlayerInfo (or TargetInfo for targets), select Buff Settings or Debuff Settings, and un-check "show buffs" (or "show debuffs").

|cff9999ff12. How do I turn off these big huge bars that pulse whenever one of my abilities procs?|r
This isn't |cff9999ffIceHUD|r - it's Blizzard's Spell Alerts they added in 4.0.1. Interface options => Combat => "Spell Alert Opacity" to turn them off or search for a mod to tweak their positioning/size/etc.

|cff9999ff13. I don't like where some of the bars are placed. How do I put the health/mana on the left/right?|r
Expand "|cffffdc42Module Settings|r", expand whatever module you want to move (e.g. PlayerHealth, PlayerMana), and adjust the "Side" and "Offset" settings. "Side" controls whether it's on the left or the right and "Offset" controls how far from center it is.

|cff9999ff14. Which module displays Monk Chi power?|r
Prior to |cff9999ffIceHUD|r v1.11.2, this module was called |cffdcff42HarmonyPower|r. Harmony was the original name for Chi back when 5.0 was in beta, so I used Blizzard's name for it while I was developing for Cataclysm. |cff9999ffIceHUD|r v1.11.2 changed this module to be called |cffdcff42Chi|r.

|cff9999ff15. How do I add commas/periods into big numbers like health?|r
If you have |cff42ffffDogTags|r enabled, you can open the Text Settings for the module in question and add SeparateDigits() around the tag you're trying to split up. To display Health/MaxHealth with commas, use: [(SeparateDigits(HP):HPColor "/" SeparateDigits(MaxHP):HPColor):Bracket]. To use periods instead of commas, use: [(SeparateDigits(HP, "."):HPColor "/" SeparateDigits(MaxHP, "."):HPColor):Bracket]. Use the /dog help menu to build your own similar tags for Mana, etc.

|cff9999ff16. The countdown timers on buffs and debuffs completely obscure the icon. How do I disable the timer text?|r
|cff9999ffIceHUD|r is not responsible for this countdown text and cannot control it. The 6.0 patch added an option in the game client to display counts on top of cooldowns. Look at the Action Bars menu under the game's Interface options. You can turn the text on or off there. Mods like |cff42ffffOmniCC|r or |cff42ffffCooldownCount|r will generally give you the same feature but allow you to control when, where, and how the text shows up.

|cff9999ff17. When I rotate some modules 90 degrees, such as the castbar, the bar appears to wiggle up and down as it fills or empties. How do I fix this?|r
This is a side effect of the animation API that I'm co-opting to force a rotation without having to provide duplicates of every bar texture in the mod. Any bar moving sufficiently quickly and updating rapidly will cause this. |cff9999ffIceHUD|r is intended to be a vertically-oriented mod, so the rotation feature is there for people who are willing to accept the side effects that come with it. My suggestion is to use one of the many horizontally-oriented bar mods out there if you're wanting horizontal bars. |cff42ffffQuartz|r is a good castbar replacement that you can use and disable |cff9999ffIceHUD|r's built-in castbar, for example.

|cff9999ff18. How do I get rid of the bars that showed up beneath the player in the 7.0 patch?|r
Blizzard added a "Personal Resource Display" feature in the 7.0 game client. You can disable it in the Game options -> |cffffdc42Interface|r -> |cffffdc42Names|r -> |cffffdc42Personal Resource Display|r (or Options -> |cffffdc42Combat|r -> |cffffdc42Personal Resource Display|r, in 10.0+).

|cff9999ff19. Why is there no target castbar for Classic?|r
The Classic game client doesn't offer a reliable way to show castbars for anyone except the player. You can install the |cff42ffffLibCasterCasterino|r addon to enable support, but it's a best guess and not at all accurate.

|cff9999ff20. Why do buff/debuff timers not work in Classic?|r
The Classic game client doesn't provide this information to addons because it wasn't a feature when the game first released. You can install the |cff42ffffLibClassicDurations|r addon to enable support, but it's a best guess and not at all accurate.]]
				}
			}
		},

		positioningSettings = {
			type = 'group',
			name = L["Positioning Settings"],
			desc = L["Settings related to positioning and alpha"],
			order = 11,
			args = {
				vpos = {
					type = 'range',
					name = L["Vertical position"],
					desc = L["Vertical position"],
					get = function()
						return IceHUD.IceCore:GetVerticalPos()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetVerticalPos(v)
					end,
					min = -700,
					max = 700,
					step = 1,
					order = 11
				},

				hpos = {
					type = 'range',
					name = L["Horizontal position"],
					desc = L["Horizontal position (for you dual screen freaks)"],
					get = function()
						return IceHUD.IceCore:GetHorizontalPos()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetHorizontalPos(v)
					end,
					min = -2000,
					max = 2000,
					step = 1,
					order = 12
				},

				gap = {
					type = 'range',
					name = L["Gap"],
					desc = L["Distance between the left and right bars"],
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
					name = L["Scale"],
					desc = L["HUD scale"],
					get = function()
						return IceHUD.IceCore:GetScale()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetScale(v)
					end,
					min = 0.2,
					max = 4.0,
					step = 0.05,
					isPercent = true,
					order = 14,
				},
			}
		},


		alphaSettings = {
			type = 'group',
			name = L["Transparency Settings"],
			desc = L["Settings for bar transparencies"],
			order = 12,
			args = {
				headerAlpha = {
					type = 'header',
					name = L["Bar Alpha"],
					order = 10
				},

				alphaic = {
					type = 'range',
					name = L["Alpha in combat"],
					desc = L["Bar alpha In Combat"],
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
					name = L["Alpha out of combat"],
					desc = L["Bar alpha Out Of Combat without target"],
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
					name = L["Alpha OOC and Target"],
					desc = L["Bar alpha Out Of Combat with target accuired (takes precedence over Not Full)"],
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
					name = L["Alpha OOC and not full"],
					desc = L["Bar alpha Out Of Combat with target accuired or bar not full (Target takes precedence over this)"],
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
					name = L["Background Alpha"],
					order = 20
				},

				alphaicbg = {
					type = 'range',
					name = L["BG Alpha in combat"],
					desc = L["Background alpha for bars IC"],
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
					name = L["BG Alpha out of combat"],
					desc = L["Background alpha for bars OOC without target"],
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
					name = L["BG Alpha OOC and Target"],
					desc = L["Background alpha for bars OOC and target accuired (takes precedence over Not Full)"],
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
					name = L["BG Alpha OOC and not Full"],
					desc = L["Background alpha for bars OOC and bar not full (Target takes precedence over this)"],
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
					name = L["Other"],
					order = 30
				},

				backgroundToggle = {
					type = "toggle",
					name = L["Contextual Background"],
					desc = L["Toggles contextual background coloring"],
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
					name = L["Background Color"],
					desc = L["Background Color"],
					get = function()
						return IceHUD.IceCore:GetBackgroundColor()
					end,
					set = function(info, r, g, b)
						IceHUD.IceCore:SetBackgroundColor(r, g, b)
					end,
					order = 32,
				},

				bTreatFriendlyAsTarget = {
					type = 'toggle',
					name = L["Use 'Target' alpha for friendlies"],
					desc = L["If this is disabled, then targeting a friendly will use the 'Alpha out of combat' setting instead of 'Alpha OOC and Target'."],
					width = 'double',
					get = function()
						return IceHUD.IceCore.settings.bTreatFriendlyAsTarget
					end,
					set = function(info, value)
						IceHUD.IceCore.settings.bTreatFriendlyAsTarget = value
						IceHUD.IceCore:Redraw()
					end,
					order = 33,
				},

				bHideDuringPetBattles = {
					type = 'toggle',
					name = L["Hide during pet battles"],
					desc = L["This will hide the entire mod during pet battles."],
					width = 'double',
					get = function()
						return IceHUD.IceCore.settings.bHideDuringPetBattles
					end,
					set = function(info, value)
						IceHUD.IceCore.settings.bHideDuringPetBattles = value
						if not value then
							IceHUD.IceCore.IceHUDFrame:Show()
						end
					end,
					hidden = not UnitCanPetBattle,
					order = 34,
				},

				bHideInBarberShop = {
					type = 'toggle',
					name = L["Hide in barbershops"],
					desc = L["This will hide the entire mod when interacting with a barbershop."],
					width = 'double',
					get = function()
						return IceHUD.IceCore.settings.bHideInBarberShop
					end,
					set = function(info, value)
						IceHUD.IceCore.settings.bHideInBarberShop = value
						if not value then
							IceHUD.IceCore.IceHUDFrame:Show()
						end
					end,
					hidden = not GetBarberShopStyleInfo,
					order = 35,
				},

				bHideDuringShellGame = {
					type = 'toggle',
					name = L["Hide during shell game"],
					desc = L["This will hide the entire mod when playing the BfA Tortollan shell game world quest."],
					width = 'double',
					get = function()
						return IceHUD.IceCore.settings.bHideDuringShellGame
					end,
					set = function(info, value)
						IceHUD.IceCore.settings.bHideDuringShellGame = value
						if not value then
							IceHUD.IceCore.IceHUDFrame:Show()
						end
					end,
					hidden = not IceHUD.HasShellGame,
					order = 36,
				},

				bHideDuringCataloging = {
					type = 'toggle',
					name = L["Hide during cataloging"],
					desc = L["This will hide the entire mod when using the Dragonflight Cataloging camera."],
					width = 'double',
					get = function()
						return IceHUD.IceCore.settings.bHideDuringCataloging
					end,
					set = function(info, value)
						IceHUD.IceCore.settings.bHideDuringCataloging = value
						if not value then
							IceHUD.IceCore.IceHUDFrame:Show()
						end
					end,
					hidden = not IceHUD.HasCataloging,
					order = 36,
				},
				
				bIncreaseStrata = {
					type = 'range',
					name = L["Added strata"],
					desc = L["Push IceHUD modules to the foreground. Increase if other addons are covering IceHUD. Requires reload."],
					get = function()
						return IceHUD.IceCore:GetAddedStrata()
					end,
					set = function(info, v)
						IceHUD.IceCore:SetAddedStrata(v)
					end,
					min = 0,
					max = 2,
					step = 1,
					order = 37,
				},
			}
		},


		barSettings = {
			type = 'group',
			name = L["Bar Settings"],
			desc = L["Settings related to bars"],
			order = 20,
			args = {
				barPresets = {
					type = 'select',
					name = L["Presets"],
					desc = L["Predefined settings for different bars"],
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
					name = L["Advanced Bar Settings"],
					order = 10
				},

				barTexture = {
					type = 'select',
					name = L["Bar Texture"],
					desc = L["IceHUD Bar Texture"],
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
					name = L["Bar Width"],
					desc = L["Bar texture width (not the actual bar!)"],
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
					name = L["Bar Height"],
					desc = L["Bar texture height (not the actual bar!)"],
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
					name = L["Bar Proportion"],
					desc = L["Determines the bar width compared to the whole texture width"],
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
					name = L["Bar Space"],
					desc = L["Space between bars on the same side"],
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
					name = L["Bar Background Blend Mode"],
					desc = L["IceHUD Bar Background Blend mode"],
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
					name = L["Bar Blend Mode"],
					desc = L["IceHUD Bar Blend mode"],
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
			desc = L["Module configuration options"],
			name = L["Module Settings"],
			args = {},
			order = 41
		},

		colors = {
			type='group',
			desc = L["Module color configuration options"],
			name = L["Colors"],
			args = {},
			order = 42
		},

		enabled = {
			type = "toggle",
			name = L["Enabled"],
			desc = L["Enable/disable IceHUD"],
			get = function()
				return IceHUD.IceCore:IsEnabled()
			end,
			set = function(info, value)
				if (value) then
					IceHUD.IceCore:Enable(true)
				else
					IceHUD.IceCore:Disable(true)
				end
			end,
			order = 91
		},

		debug = {
			type = "toggle",
			name = L["Debugging"],
			desc = L["Enable/disable debug messages"],
			get = function()
				return IceHUD.IceCore:GetDebug()
			end,
			set = function(info, value)
				IceHUD.IceCore:SetDebug(value)
			end,
			hidden =
				--[===[@non-debug@
				true
				--@end-non-debug@]===]
				--@debug@
				false
				--@end-debug@
			,
			disabled =
				-- hello, snooper! this feature doesn't actually work yet, so enabling it won't help you much :)
				--[===[@non-debug@
				true
				--@end-non-debug@]===]
				--@debug@
				false
				--@end-debug@
			,
			order = 92
		},

		customModuleSelect = {
			type = "select",
			name = L["Create custom module"],
			desc = L["Select a custom module that you want to create here, then press the 'Create' button."],
			get = function(info)
				return lastCustomModule
			end,
			set = function(info, v)
				lastCustomModule = v
			end,
			values = IceHUD.validCustomModules,
			order = 94.5,
		},

		customModuleCreate = {
			type = "execute",
			name = L["Create"],
			desc = L["Creates the selected custom module"],
			func = function()
				IceHUD:CreateCustomModuleAndNotify(lastCustomModule)
			end,
			disabled = function()
				return not IceHUD.IceCore:IsEnabled()
			end,
			order = 94.6,
		},

		configMode = {
			type = 'toggle',
			name = L["Configuration Mode"],
			desc = L["Makes all modules visible so you can see where they're placed and find any that are overlapping."],
			get = function()
				return IceHUD.IceCore:IsInConfigMode()
			end,
			set = function(info, value)
				IceHUD.IceCore:ConfigModeToggle(value)
			end,
			disabled = function()
				return not IceHUD.IceCore:IsEnabled()
			end,
			order = 95
		},

		useDogTags = {
			type = 'toggle',
			name = L["Use Dog Tags"],
			desc = L["Whether or not the addon should use the DogTag library (this will increase the CPU usage of the mod). DogTag controls all text displayed around bars such as health or mana amounts. Type |cffffff78/dog|r to see all DogTag options.\n\nNOTE: after changing this option, you must reload the UI or else bad things happen"],
			get = function()
				return IceHUD.IceCore:ShouldUseDogTags()
			end,
			set = function(info, v)
				IceHUD.IceCore:SetShouldUseDogTags(v)
				StaticPopup_Show("ICEHUD_CHANGED_DOGTAG")
			end,
			hidden = function()
				return not LibStub("LibDogTag-3.0", true)
			end,
			order = 96
		},

		updatePeriod = {
			type = 'range',
			name = L["Update Period"],
			desc = L["Number of updates per second. The higher this number is, the smoother bars will animate. However, higher settings will also use more CPU, so balance it to your liking. 30 is the recommended setting."],
			get = function()
				return math.ceil(1/IceHUD.IceCore:UpdatePeriod())
			end,
			set = function(info, v)
				IceHUD.IceCore:SetUpdatePeriod(1/v)
			end,
			min = 15,
			max = 60,
			step = 1,
			order = 97
		},

		showMinimap = {
			type = 'toggle',
			name = L["Show Minimap Icon"],
			desc = L["Whether or not to show an IceHUD icon on the minimap."],
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
		},
	}
}

if AceGUIWidgetLSMlists then
	options.args.textSettings = {
		type = 'select',
		dialogControl = "LSM30_Font",
		name = L["Font"],
		desc = L["IceHUD Font"],
		get = function(info)
			return IceHUD.IceCore:GetFontFamily()
		end,
		set = function(info, value)
			IceHUD.IceCore:SetFontFamily(value)
		end,
		disabled = function()
			return not IceHUD.IceCore:IsEnabled()
		end,
		values = AceGUIWidgetLSMlists.font,
		order = 94.75,
	}
end

IceHUD_Options.options = options

function IceHUD_Options:GenerateModuleOptions(firstLoad)
	self.options.args.modules.args = IceHUD.IceCore:GetModuleOptions()
	if not firstLoad then
		IceHUD:NotifyOptionsChange()
	end
end

function IceHUD_Options:SetupProfileImportButtons()
	if AceSerializer then
		AceSerializer:Embed(self)
		self.options.args.profiles.args.export = {
			type = 'execute',
			name = L["Export profile"],
			desc = L["Exports your active profile to something you can copy and paste to another user or use on another account."],
			func = function()
				local frame = AceGUI:Create("Frame")
				frame:SetTitle("Profile data")
				frame:SetStatusText("Exported profile details")
				frame:SetLayout("Flow")
				frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
				local editbox = AceGUI:Create("MultiLineEditBox")
				editbox:SetLabel("Profile")
				editbox:SetFullWidth(true)
				editbox:SetFullHeight(true)
				local profileTable = IceHUD.deepcopy(IceHUD.db.profile)
				IceHUD:removeDefaults(profileTable, IceHUD.IceCore.defaults.profile)
				editbox:SetText(IceHUD.json.encode(profileTable))
				editbox:DisableButton(true)
				frame:AddChild(editbox)
			end,
			order = 98.1
		}

		self.options.args.profiles.args.import = {
			type = 'execute',
			name = L["Import profile"],
			desc = L["Imports a profile as exported from another user's IceHUD."],
			func = function()
				local frame = AceGUI:Create("Frame")
				frame:SetTitle("Profile data")
				frame:SetStatusText("Exported profile details")
				frame:SetLayout("Flow")
				frame:SetCallback("OnClose", function(widget)
					local newTable, err = IceHUD.json.decode(widget.children[1]:GetText())
					if err ~= nil then
						print("failed to import profile: "..err)
					else
						-- print("importing profile")
						IceHUD:PreProfileChanged()
						IceHUD:populateDefaults(newTable, IceHUD.IceCore.defaults.profile)
						IceHUD.db.profile = IceHUD.deepcopy(newTable)
						IceHUD.db.profiles[IceHUD.db:GetCurrentProfile()] = IceHUD.db.profile
						IceHUD:PostProfileChanged()
					end
					AceGUI:Release(widget)
				end)
				local editbox = AceGUI:Create("MultiLineEditBox")
				editbox:SetLabel("Profile")
				editbox:SetFullWidth(true)
				editbox:SetFullHeight(true)
				editbox:DisableButton(true)
				frame:AddChild(editbox)
			end,
			order = 98.2
		}
	end
end

function IceHUD_Options:OnLoad()
	self:GenerateModuleOptions(true)
	self.options.args.colors.args = IceHUD.IceCore:GetColorOptions()
	self.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(IceHUD.db)
	self:SetupProfileImportButtons()

	-- Add dual-spec support
	if IceHUD.db ~= nil and LibDualSpec then
		LibDualSpec:EnhanceOptions(IceHUD_Options.options.args.profiles, IceHUD.db)
	end

	LibStub("AceConfig-3.0"):RegisterOptionsTable("IceHUD", options, "icehudcl")
end

if IceHUD and IceHUD.IceCore then
	IceHUD_Options:OnLoad()
end
