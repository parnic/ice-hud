local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local DogTag = nil

local IceHUD = _G.IceHUD

IceBarElement = IceCore_CreateClass(IceElement)

IceBarElement.BarTextureWidth = 128

IceBarElement.prototype.barFrame = nil

IceBarElement.prototype.CurrLerpTime = 0
IceBarElement.prototype.LastScale = 1
IceBarElement.prototype.DesiredScale = 1
IceBarElement.prototype.CurrScale = 1
IceBarElement.prototype.Markers = {}
IceBarElement.prototype.IsBarElement = true -- cheating to avoid crawling up the 'super' references looking for this class. see IceCore.lua
IceBarElement.prototype.bTreatEmptyAsFull = false

local lastMarkerPosConfig = 50
local lastMarkerColorConfig = {r=1, b=0, g=0, a=1}
local lastMarkerHeightConfig = 6
local lastEditMarkerConfig = 1

-- Constructor --
function IceBarElement.prototype:init(name, ...)
	IceBarElement.super.prototype.init(self, name, ...)
end



-- 'Public' methods -----------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:Enable()
	IceBarElement.super.prototype.Enable(self)

	self:ConditionalSetupUpdate()

	if IceHUD.IceCore:ShouldUseDogTags() then
		DogTag = LibStub("LibDogTag-3.0", true)
		if DogTag then
			LibStub("LibDogTag-Unit-3.0", true)
		end
	end

	if self.moduleSettings.myTagVersion < IceHUD.CurrTagVersion then
		local origDefaults = self:GetDefaultSettings()

		self.moduleSettings.upperText = origDefaults["upperText"]
		self.moduleSettings.lowerText = origDefaults["lowerText"]
		self.moduleSettings.myTagVersion = IceHUD.CurrTagVersion
	end

	-- fixup for the old new 'invert' option. (This was here before I got here - Andre)
	if not self.moduleSettings.updatedReverseInverse then
		self.moduleSettings.updatedReverseInverse = true

		if self.moduleSettings.reverse then
			self.moduleSettings.reverse = false
			self.moduleSettings.inverse = "NORMAL"

			self:SetBarFramePoints(self.barFrame)
		end
	end

	-- fixup for the new new 'invert' option
	-- This is the new fixup code... Not sure if I'm doin' it right, or if the old and the new fixups can be merged.
	-- The way I figure it, someone who hasn't updated in like forever might not have had either fixup occur, and yet
	-- people who have been updating frequently will have already had the old fixup occur... DUN DUN DUN.
	-- Also... Setting the module default for moduleSettings.inverse seemed to automatically set all my characters
	-- to that default... So I'm not I can test whether or not my fixup does what I think it does. o.O
	if not self.moduleSettings.updatedInverseExpand then
		self.moduleSettings.updatedInverseExpand = true

		if self.moduleSettings.inverse == true then
			self.moduleSettings.inverse = "INVERSE"
		else
			self.moduleSettings.inverse = "NORMAL"
		end
		self:SetBarFramePoints(self.barFrame)
	end

	self:RegisterFontStrings()

	-- allows frames that show/hide via RegisterUnitWatch to not show text when they shouldn't
	if self.frame:GetScript("OnHide") == nil then
		self.frame:SetScript("OnHide", function()
			if self.moduleSettings.textVisible["upper"] then
				self.frame.bottomUpperText:Hide()
			end
			if self.moduleSettings.textVisible["lower"] then
				self.frame.bottomLowerText:Hide()
			end
			self:OnHide()
		end)
	end
	if self.frame:GetScript("OnShow") == nil then
		self.frame:SetScript("OnShow", function()
			if self.moduleSettings.textVisible["upper"] then
				self.frame.bottomUpperText:Show()
			end
			if self.moduleSettings.textVisible["lower"] then
				self.frame.bottomLowerText:Show()
			end
			self:OnShow()
		end)
	end

	self:Redraw()
end

function IceBarElement.prototype:OnHide()
	IceHUD.IceCore:RequestUpdates(self, nil)
end

function IceBarElement.prototype:OnShow()
	if not self:IsFull(self.CurrScale) then
		self:ConditionalSetupUpdate()
	end
end

function IceBarElement.prototype:Disable(core)
	IceBarElement.super.prototype.Disable(self, core)

	IceHUD.IceCore:RequestUpdates(self, nil)

	self:ClearMarkers()
end


function IceBarElement.prototype:RegisterFontStrings()
	if DogTag ~= nil and self.moduleSettings ~= nil and self.moduleSettings.usesDogTagStrings then
		if self.frame.bottomUpperText and self.moduleSettings.upperText then
			DogTag:AddFontString(self.frame.bottomUpperText, self.frame, self.moduleSettings.upperText, "Unit", { unit = self.unit })
		end
		if self.frame.bottomLowerText and self.moduleSettings.lowerText then
			DogTag:AddFontString(self.frame.bottomLowerText, self.frame, self.moduleSettings.lowerText, "Unit", {unit = self.unit })
		end
	end
end


-- OVERRIDE
function IceBarElement.prototype:GetDefaultSettings()
	local settings = IceBarElement.super.prototype.GetDefaultSettings(self)

	settings["side"] = IceCore.Side.Left
	settings["offset"] = 1
	settings["scale"] = 1
	settings["inverse"] = "NORMAL"
	settings["reverse"] = false
	settings["barFontSize"] = 12
	settings["lockUpperTextAlpha"] = true
	settings["lockLowerTextAlpha"] = false
	settings["textVisible"] = {upper = true, lower = true}
	settings["upperText"] = ''
	settings["lowerText"] = ''
	settings["textVerticalOffset"] = -1
	settings["textHorizontalOffset"] = 0
	settings["shouldAnimate"] = true
	settings["desiredLerpTime"] = 0.2
	settings["barVisible"] = {bg = true, bar = true}
	settings["myTagVersion"] = 2
	settings["widthModifier"] = 0
	settings["usesDogTagStrings"] = true
	settings["barVerticalOffset"] = 0
	settings["barHorizontalOffset"] = 0
	settings["forceJustifyText"] = "NONE"
	settings["shouldUseOverride"] = false
	settings["rotateBar"] = false
	settings["markers"] = {}
	settings["bAllowExpand"] = true

	return settings
end

do
	local function getFillOptions(self)
		local values = {
			["NORMAL"] = "Normal",
			["INVERSE"] = "Inverse",
		}
		if self.moduleSettings.bAllowExpand then
			values["EXPAND"] = "Expanding"
		end

		return values
	end

	-- OVERRIDE
	function IceBarElement.prototype:GetOptions()
		local opts = IceBarElement.super.prototype.GetOptions(self)

		opts["headerLookAndFeel"] = {
			type = 'header',
			name = L["Look and Feel"],
			order = 29.9
		}
		opts["side"] =
		{
			type = 'select',
			name = L["Side"],
			desc = L["Side of the HUD where the bar appears"],
			get = function(info)
				if (self.moduleSettings.side == IceCore.Side.Right) then
					return 2
				else
					return 1
				end
			end,
			set = function(info, value)
				if (value == 2) then
					self.moduleSettings.side = IceCore.Side.Right
				else
					self.moduleSettings.side = IceCore.Side.Left
				end
				self:Redraw()
			end,
			values = { "Left", "Right" },
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30
		}

		opts["offset"] =
		{
			type = 'range',
			name = L["Offset"],
			desc = L["Offset of the bar"],
			min = -10,
			max = 15,
			step = 1,
			get = function()
				return self.moduleSettings.offset
			end,
			set = function(info, value)
				self.moduleSettings.offset = value
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.01
		}

		opts["scale"] =
		{
			type = 'range',
			name = L["Scale"],
			desc = L["Scale of the bar"],
			min = 0.1,
			max = 2,
			step = 0.05,
			isPercent = true,
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
			order = 30.02
		}

		opts["inverse"] =
		{
			type = 'select',
			name = L["Invert bar"],
			desc = L["Controls what it means for the bar to be filled. A normal bar will grow larger as the value grows from 0% to 100%. A reversed bar will shrink as the value grows from 0% to 100%."],
			values = getFillOptions(self),
			get = function()
				return self.moduleSettings.inverse
			end,
			set = function(info, value)
				self.moduleSettings.inverse = value
				self:SetBarFramePoints(self.barFrame)
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.03
		}

		opts["reverse"] =
		{
			type = 'toggle',
			name = L["Reverse direction"],
			desc = L["Controls what it means for the bar to be filled. A normal bar will grow larger as the value grows from 0% to 100%. A reversed bar will shrink as the value grows from 0% to 100%."],
			get = function()
				return self.moduleSettings.reverse
			end,
			set = function(info, value)
				self.moduleSettings.reverse = value
				self:SetBarFramePoints(self.barFrame)
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.04
		}

		opts["barVisible"] = {
			type = 'toggle',
			name = L["Bar visible"],
			desc = L["Toggle bar visibility"],
			get = function()
				return self.moduleSettings.barVisible['bar']
			end,
			set = function(info, v)
				self.moduleSettings.barVisible['bar'] = v
				self:SetBarVisibility(v)
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 28
		}

		opts["bgVisible"] = {
			type = 'toggle',
			name = L["Bar background visible"],
			desc = L["Toggle bar background visibility"],
			get = function()
				return self.moduleSettings.barVisible['bg']
			end,
			set = function(info, v)
				self.moduleSettings.barVisible['bg'] = v
				if v then
					self.frame.bg:Show()
				else
					self.frame.bg:Hide()
				end
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 29
		}
		if not self.moduleSettings.hideAnimationSettings then
			opts["headerAnimation"] = {
				type = 'header',
				name = L["Animation Settings"],
				order = 110
			}
			opts["shouldAnimate"] =
			{
				type = 'toggle',
				name = L["Animate changes"],
				desc = L["Whether or not to animate the bar falloffs/gains"],
				get = function()
					return self.moduleSettings.shouldAnimate
				end,
				set = function(info, value)
					self.moduleSettings.shouldAnimate = value
					self:Redraw()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 111
			}

			opts["desiredLerpTime"] =
			{
				type = 'range',
				name = L["Animation Duration"],
				desc = L["How long the animation should take to play"],
				min = 0,
				max = 2,
				step = 0.05,
				get = function()
					return self.moduleSettings.desiredLerpTime
				end,
				set = function(info, value)
					self.moduleSettings.desiredLerpTime = value
				end,
				disabled = function()
					return not self.moduleSettings.enabled or not self.moduleSettings.shouldAnimate
				end,
				order = 112
			}
		end

		opts["widthModifier"] =
		{
			type = 'range',
			name = L["Bar width modifier"],
			desc = L["Make this bar wider or thinner than others"],
			min = -80,
			max = 80,
			step = 1,
			get = function()
				return self.moduleSettings.widthModifier
			end,
			set = function(info, v)
				self.moduleSettings.widthModifier = v
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.05
		}

		opts["barVerticalOffset"] =
		{
			type='range',
			name = L["Bar vertical offset"],
			desc = L["Adjust the vertical placement of this bar"],
			min = -400,
			max = 600,
			step = 1,
			get = function()
				return self.moduleSettings.barVerticalOffset
			end,
			set = function(info, v)
				self.moduleSettings.barVerticalOffset = v
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.06
		}

		opts["barHorizontalAdjust"] =
		{
			type='range',
			name = L["Bar horizontal adjust"],
			desc = L["This is a per-pixel horizontal adjustment. You should probably use the 'offset' setting above as it is designed to snap bars together. This may be used in the case of a horizontal bar needing to be positioned outside the normal bar locations."],
			min = -400,
			max = 600,
			step = 1,
			get = function()
				return self.moduleSettings.barHorizontalOffset
			end,
			set = function(info, v)
				self.moduleSettings.barHorizontalOffset = v
				self:Redraw()
			end,
			disabled = function()
				return not self.moduleSettings.enabled
			end,
			order = 30.06
		}

		opts["shouldUseOverride"] =
		{
			type = 'toggle',
			name = L["Override global texture"],
			desc = L["This will override the global bar texture setting for this bar with the one specified below."],
			get = function()
				return self.moduleSettings.shouldUseOverride
			end,
			set = function(info, value)
				self.moduleSettings.shouldUseOverride = value
				IceHUD:NotifyOptionsChange()

				self:NotifyBarOverrideChanged()
				self:Redraw()
			end,
			disabled = function()
				return not self:IsEnabled()
			end,
			order = 30.07
		}

		opts["barTextureOverride"] =
		{
			type = 'select',
			name = L["Bar Texture Override"],
			desc = L["This will override the global bar texture setting for this bar."],
			get = function(info)
				return IceHUD:GetSelectValue(info, self.moduleSettings.barTextureOverride)
			end,
			set = function(info, value)
				self.moduleSettings.barTextureOverride = info.option.values[value]
				self:NotifyBarOverrideChanged()
				self:Redraw()
			end,
			disabled = function()
				return not self:IsEnabled() or not self.moduleSettings.shouldUseOverride
			end,
			values = IceHUD.validBarList,
			order = 30.08
		}
		opts["barRotate"] =
		{
			type = 'toggle',
			name = L["Rotate 90 degrees"],
			desc = L["This will rotate this module by 90 degrees to give a horizontal orientation.\n\nWARNING: This feature is brand new and a bit rough around the edges. You will need to greatly adjust the vertical and horizontal offset of this bar plus move the text around in order for it to look correct.\n\nAnd I mean greatly."],
			get = function(info)
				return self.moduleSettings.rotateBar
			end,
			set = function(info, v)
				self.moduleSettings.rotateBar = v
				if v then
					self:RotateHorizontal()
				else
					self:ResetRotation()
				end
				self:Redraw()
			end,
			disabled = function()
				return not self:IsEnabled()
			end,
			order = 30.09
		}
		opts["textSettings"] =
		{
			type = 'group',
			name = "|c"..self.configColor..L["Text Settings"].."|r",
			desc = L["Settings related to texts"],
			order = 32,
			args = {
				fontsize = {
					type = 'range',
					name = L["Bar Font Size"],
					desc = L["Bar Font Size"],
					get = function()
						return self.moduleSettings.barFontSize
					end,
					set = function(info, v)
						self.moduleSettings.barFontSize = v
						self:Redraw()
					end,
					min = 8,
					max = 20,
					step = 1,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 11
				},

				lockUpperFontAlpha = {
					type = "toggle",
					name = L["Lock Upper Text Alpha"],
					desc = L["Locks upper text alpha to 100%"],
					get = function()
						return self.moduleSettings.lockUpperTextAlpha
					end,
					set = function(info, v)
						self.moduleSettings.lockUpperTextAlpha = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 13
				},

				lockLowerFontAlpha = {
					type = "toggle",
					name = L["Lock Lower Text Alpha"],
					desc = L["Locks lower text alpha to 100%"],
					get = function()
						return self.moduleSettings.lockLowerTextAlpha
					end,
					set = function(info, v)
						self.moduleSettings.lockLowerTextAlpha = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 14
				},

				upperTextVisible = {
					type = 'toggle',
					name = L["Upper text visible"],
					desc = L["Toggle upper text visibility"],
					get = function()
						return self.moduleSettings.textVisible['upper']
					end,
					set = function(info, v)
						self.moduleSettings.textVisible['upper'] = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 13.1,
				},

				lowerTextVisible = {
					type = 'toggle',
					name = L["Lower text visible"],
					desc = L["Toggle lower text visibility"],
					get = function()
						return self.moduleSettings.textVisible['lower']
					end,
					set = function(info, v)
						self.moduleSettings.textVisible['lower'] = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 14.1,
				},

				upperTextString = {
					type = 'input',
					name = L["Upper Text"],
					desc =
					self.moduleSettings.usesDogTagStrings and L["The upper text to display under this bar (accepts LibDogTag formatting)\n\nSee http://www.wowace.com/wiki/LibDogTag-2.0/ or type /dogtag for tag info.\n\nRemember to press ENTER after filling out this box or it will not save."]
						or L["The upper text to display under this bar.\n\nNOTE: this text block does NOT support DogTags.\n\nRemember to press ENTER/Accept after filling out this box or it will not save."],
					hidden = function()
						return DogTag == nil or not self.moduleSettings.usesDogTagStrings
					end,
					get = function()
						return self.moduleSettings.upperText
					end,
					set = function(info, v)
						if DogTag ~= nil and v ~= '' and v ~= nil then
							v = DogTag:CleanCode(v)
						end

						self.moduleSettings.upperText = v
						self:RegisterFontStrings()
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					multiline = self.moduleSettings.usesDogTagStrings,
					usage = "<upper text to display>",
					order = 13.2,
				},

				lowerTextString = {
					type = 'input',
					name = L["Lower Text"],
					desc =
					self.moduleSettings.usesDogTagStrings and L["The lower text to display under this bar (accepts LibDogTag formatting)\n\nSee http://www.wowace.com/wiki/LibDogTag-2.0/ or type /dogtag for tag info.\n\nRemember to press ENTER after filling out this box or it will not save."]
						or L["The lower text to display under this bar.\n\nNOTE: this text block does NOT support DogTags.\n\nRemember to press ENTER/Accept after filling out this box or it will not save."],
					hidden = function()
						return DogTag == nil or not self.moduleSettings.usesDogTagStrings
					end,
					get = function()
						return self.moduleSettings.lowerText
					end,
					set = function(info, v)
						if DogTag ~= nil and v ~= '' and v ~= nil then
							v = DogTag:CleanCode(v)
						end

						self.moduleSettings.lowerText = v
						self:RegisterFontStrings()
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					multiline = self.moduleSettings.usesDogTagStrings,
					usage = "<lower text to display>",
					order = 14.2,
				},

				forceJustifyText = {
					type = 'select',
					name = L["Force Text Justification"],
					desc = L["This sets the alignment for the text on this bar"],
					get = function(info)
						return self.moduleSettings.forceJustifyText
					end,
					set = function(info, value)
						self.moduleSettings.forceJustifyText = value
						self:Redraw()
					end,
					values = { NONE = "None", LEFT = "Left", RIGHT = "Right" },
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 11.1,
				},

				textVerticalOffset = {
					type = 'range',
					name = L["Text Vertical Offset"],
					desc = L["Offset of the text from the bar vertically (negative is farther below)"],
					min = -450,
					max = 350,
					step = 1,
					get = function()
						return self.moduleSettings.textVerticalOffset
					end,
					set = function(info, v)
						self.moduleSettings.textVerticalOffset = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 11.2,
				},

				textHorizontalOffset = {
					type = 'range',
					name = L["Text Horizontal Offset"],
					desc = L["Offset of the text from the bar horizontally"],
					min = -350,
					max = 350,
					step = 1,
					get = function()
						return self.moduleSettings.textHorizontalOffset
					end,
					set = function(info, v)
						self.moduleSettings.textHorizontalOffset = v
						self:Redraw()
					end,
					disabled = function()
						return not self.moduleSettings.enabled
					end,
					order = 11.3,
				},

				textHeader = {
					type = 'header',
					name = L["Upper Text"],
					order = 12,
				},
				textHeader2 = {
					type = 'header',
					name = L["Lower Text"],
					order = 13.999,
				},
			}
		}
		if not self.moduleSettings.bHideMarkerSettings then
			opts["markerSettings"] =
			{
				type = 'group',
				name = "|c"..self.configColor..L["Marker Settings"].."|r",
				desc = L["Create or remove markers at various points along the bar here"],
				order = 32,
				args = {
					markerPos = {
						type = "range",
						min = 0,
						max = 100,
						step = 1,
						name = L["Position (percent)"],
						desc = L["This specifies at what point along the bar this marker should be displayed. Remember to press ENTER when you are done typing.\n\nExample: if you wanted a marker at 40 energy and you have 100 total energy, then this would be 40. If you want it at 40 energy and you have 120 total energy, then this would be 33."],
						get = function()
							return lastMarkerPosConfig
						end,
						set = function(info, v)
							lastMarkerPosConfig = math.floor(v)
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 20,
					},
					markerColor = {
						type = "color",
						name = L["Color"],
						desc = L["The color this marker should be."],
						width = "half",
						get = function()
							return lastMarkerColorConfig.r, lastMarkerColorConfig.g, lastMarkerColorConfig.b, lastMarkerColorConfig.a
						end,
						set = function(info, r, g, b, a)
							lastMarkerColorConfig = {r=r, g=g, b=b, a=a}
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 30,
					},
					markerHeight = {
						type = "range",
						min = 1,
						step = 1,
						max = self.settings.barHeight,
						name = L["Height"],
						desc = L["The height of the marker on the bar."],
						get = function()
							return lastMarkerHeightConfig
						end,
						set = function(info, v)
							lastMarkerHeightConfig = v
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 40,
					},
					createMarker = {
						type = "execute",
						name = L["Create marker"],
						desc = L["Creates a new marker with the chosen settings."],
						width = "full",
						func = function()
							self:AddNewMarker(lastMarkerPosConfig / 100, lastMarkerColorConfig, lastMarkerHeightConfig)
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 10,
					},
					listMarkers = {
						type = "select",
						name = L["Edit Marker"],
						desc = L["Choose a marker to edit. This will place the marker's settings in the fields above here."],
						values = function()
							local retval = {}
							if self.moduleSettings.markers then
								for i=1, #self.moduleSettings.markers do
									retval[i] = ((self.moduleSettings.markers[i].position) * 100) .. "%"
								end
							end
							return retval
						end,
						get = function(info)
							return lastEditMarkerConfig
						end,
						set = function(info, v)
							lastEditMarkerConfig = v
							lastMarkerPosConfig = (self.moduleSettings.markers[v].position) * 100
							local color = self.moduleSettings.markers[v].color
							lastMarkerColorConfig = {r=color.r, g=color.g, b=color.b, a=color.a}
							lastMarkerHeightConfig = self.moduleSettings.markers[v].height
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 50,
					},
					editMarker = {
						type = "execute",
						name = L["Update"],
						desc = L["This will update the marker selected in the 'edit marker' box with the values specified."],
						func = function()
							if self.moduleSettings.markers and lastEditMarkerConfig <= #self.moduleSettings.markers then
								self:EditMarker(lastEditMarkerConfig, lastMarkerPosConfig / 100, lastMarkerColorConfig, lastMarkerHeightConfig)
							end
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 60,
					},
					deleteMarker = {
						type = "execute",
						name = L["Remove"],
						desc = L["This will remove the marker selected in the 'edit marker' box. This action is irreversible."],
						func = function()
							if self.moduleSettings.markers and lastEditMarkerConfig <= #self.moduleSettings.markers then
								self:RemoveMarker(lastEditMarkerConfig)
							end
						end,
						disabled = function()
							return not self.moduleSettings.enabled
						end,
						order = 70,
					},
				}
			}
		end
		return opts
	end
end

function IceBarElement.prototype:SetBarVisibility(visible)
	if visible then
		self.barFrame:Show()
	else
		self.barFrame:Hide()
	end
end

function IceBarElement.prototype:SetBarFramePoints(frame, offset_x, offset_y)
	local anchor

	frame:ClearAllPoints()
	if self.moduleSettings.inverse == "INVERSE" then
		anchor = "TOPLEFT"
	elseif self.moduleSettings.inverse == "EXPAND" then
		anchor = "LEFT"
	else
		anchor = "BOTTOMLEFT"
	end

	if self.moduleSettings.rotateBar then
		frame:SetPoint(anchor, self.frame, anchor, offset_y, offset_x)
	else
		frame:SetPoint(anchor, self.frame, anchor, offset_x, offset_y)
	end
end


-- OVERRIDE
function IceBarElement.prototype:Redraw()
	IceBarElement.super.prototype.Redraw(self)

	if (not self.moduleSettings.enabled) then
		return
	end

	self.alpha = self.settings.alphaooc
	self:CreateFrame()

	self.frame:SetAlpha(self.alpha)

	self:RepositionMarkers()
end



function IceBarElement.prototype:SetPosition(side, offset)
	IceBarElement.prototype.side = side
	IceBarElement.prototype.offset = offset
end


-- 'Protected' methods --------------------------------------------------------

-- OVERRIDE
function IceBarElement.prototype:CreateFrame()
	-- don't call overridden method
	self.alpha = self.settings.alphaooc

	self:CreateBackground()
	self:CreateBar()
	self:CreateTexts()
	if #self.Markers == 0 then
		self:LoadMarkers()
	else
		for i=1, #self.Markers do
			self:UpdateMarker(i)
		end
	end

	self.masterFrame:SetScale(self.moduleSettings.scale)

	if self.moduleSettings.rotateBar then
		self:RotateHorizontal()
	else
		self:ResetRotation()
	end
end

function IceBarElement.prototype:ConditionalSetupUpdate()
	if not self.MyOnUpdateFunc then
		self.MyOnUpdateFunc = function() self:MyOnUpdate() end
	end

	if IceHUD.IceCore:IsUpdateSubscribed(self) then
		return
	end

	if not self.moduleSettings.enabled then
		return
	end

	if not string.find(self.elementName, "MirrorBar") and not string.find(self.elementName, "PlayerMana") then
		IceHUD.IceCore:RequestUpdates(self, self.MyOnUpdateFunc)
	end
end

-- Creates background for the bar
function IceBarElement.prototype:CreateBackground()
	if not (self.frame) then
		self.frame = CreateFrame("Frame", "IceHUD_"..self.elementName, self.masterFrame)
	end

	self.frame:SetFrameStrata("BACKGROUND")
	self.frame:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.frame:SetHeight(self.settings.barHeight)

	if not (self.frame.bg) then
		self.frame.bg = self.frame:CreateTexture(nil, "BACKGROUND")
	end

	self.frame.bg:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture() .."BG")
	self.frame.bg:SetBlendMode(self.settings.barBgBlendMode)

	self.frame.bg:ClearAllPoints()
	self.frame.bg:SetPoint("BOTTOMLEFT",self.frame,"BOTTOMLEFT")
	self.frame.bg:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT")
	self.frame.bg:SetHeight(self.settings.barHeight)

	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.frame.bg:SetTexCoord(1, 0, 0, 1)
	else
		self.frame.bg:SetTexCoord(0, 1, 0, 1)
	end

	self.frame.bg:SetVertexColor(self:GetColor("undef", self.settings.alphabg))

	local ownPoint = "LEFT"
	if (self.moduleSettings.side == ownPoint) then
		ownPoint = "RIGHT"
	end

	-- ofxx = (bar width) + (extra space in between the bars)
	local offx = (self.settings.barProportion * self.settings.barWidth * self.moduleSettings.offset)
		+ (self.moduleSettings.offset * self.settings.barSpace)
	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end
	offx = offx + (self.moduleSettings.barHorizontalOffset or 0)

	self.frame:ClearAllPoints()
	self.frame:SetPoint("BOTTOM"..ownPoint, self.parent, "BOTTOM"..self.moduleSettings.side, offx, self.moduleSettings.barVerticalOffset)
end


-- Creates the actual bar
function IceBarElement.prototype:CreateBar()
	self.barFrame = self:BarFactory(self.barFrame, "LOW", "ARTWORK")
	self:SetBarCoord(self.barFrame)

	self.barFrame.bar:SetBlendMode(self.settings.barBlendMode)
	self:SetScale(self.CurrScale, true)
	self:UpdateBar(1, "undef")
end

-- Returns a barFrame & barFrame.bar
-- Rokiyo: Currently keeping old behaviour of running through bar creation on every Redraw, but I'm not convinced we need to.
function IceBarElement.prototype:BarFactory(barFrame, frameStrata, textureLayer)
	if not (barFrame) then
		barFrame = CreateFrame("Frame", nil, self.frame)
	end

	barFrame:SetFrameStrata(frameStrata and frameStrata or "LOW")
	barFrame:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	barFrame:SetHeight(self.settings.barHeight)
	self:SetBarFramePoints(barFrame)

	if not barFrame.bar then
		barFrame.bar = barFrame:CreateTexture(nil, (textureLayer and textureLayer or "ARTWORK"))
	end

	barFrame.bar:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture())
	barFrame.bar:SetAllPoints(barFrame)

	return barFrame
end

function IceBarElement.prototype:GetMyBarTexture()
	if self.moduleSettings.shouldUseOverride and self.moduleSettings.barTextureOverride then
		return self.moduleSettings.barTextureOverride
	else
		return self.settings.barTexture
	end
end


function IceBarElement.prototype:CreateTexts()
	self.frame.bottomUpperText = self:FontFactory(self.moduleSettings.barFontSize, nil, self.frame.bottomUpperText)
	self.frame.bottomLowerText = self:FontFactory(self.moduleSettings.barFontSize, nil, self.frame.bottomLowerText)

-- Parnic - commented these out so that they conform to whatever width the string is set to
--	self.frame.bottomUpperText:SetWidth(80)
--	self.frame.bottomLowerText:SetWidth(120)

	self.frame.bottomUpperText:SetHeight(14)
	self.frame.bottomLowerText:SetHeight(14)

	local ownPoint = self.moduleSettings.side
	if (self.moduleSettings.offset > 1) then
		ownPoint = self:Flip(ownPoint)
	end

	local justify = "RIGHT"
	if ((self.moduleSettings.side == "LEFT" and self.moduleSettings.offset <= 1) or
		(self.moduleSettings.side == "RIGHT" and self.moduleSettings.offset > 1))
	then
		justify = "LEFT"
	end

	if self.moduleSettings.forceJustifyText and self.moduleSettings.forceJustifyText ~= "NONE" then
		ownPoint = self.moduleSettings.forceJustifyText
		justify = self.moduleSettings.forceJustifyText
	end

	self.frame.bottomUpperText:SetJustifyH(justify)
	self.frame.bottomLowerText:SetJustifyH(justify)


	local parentPoint = self:Flip(self.moduleSettings.side)


	local offx = 0
	-- adjust offset for bars where text is aligned to the outer side
	if (self.moduleSettings.offset <= 1) then
		offx = self.settings.barProportion * self.settings.barWidth - offx
	end


	if (self.moduleSettings.side == IceCore.Side.Left) then
		offx = offx * -1
	end

	self.frame.bottomUpperText:ClearAllPoints()
	self.frame.bottomLowerText:ClearAllPoints()

	if self.moduleSettings.textHorizontalOffset ~= nil then
		offx = offx + self.moduleSettings.textHorizontalOffset
	end

	local offy = 0
	if self.moduleSettings.textVerticalOffset ~= nil then
		offy = self.moduleSettings.textVerticalOffset
	end

	self.frame.bottomUpperText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, offy)
	self.frame.bottomLowerText:SetPoint("TOP"..ownPoint , self.frame, "BOTTOM"..parentPoint, offx, offy - 14)

	if (self.moduleSettings.textVisible["upper"]) then
		self.frame.bottomUpperText:Show()
	else
		self.frame.bottomUpperText:Hide()
	end

	if (self.moduleSettings.textVisible["lower"]) then
		self.frame.bottomLowerText:Show()
	else
		self.frame.bottomLowerText:Hide()
	end
end


function IceBarElement.prototype:Flip(side)
	if (side == IceCore.Side.Left) then
		return IceCore.Side.Right
	else
		return IceCore.Side.Left
	end
end

-- Rokiyo: bar is the only required argument, scale & top are optional
function IceBarElement.prototype:SetBarCoord(barFrame, scale, top, overrideReverse)
	if not scale then scale = 0 end
	scale = IceHUD:Clamp(scale, 0, 1)

	if scale == 0 then
		barFrame.bar:Hide()
	else
		local min_y, max_y
		local offset_y = 0

		local reverse = self.moduleSettings.reverse
		if overrideReverse then
			reverse = false
		end

		if IceHUD:xor(reverse, top) then
			if self.moduleSettings.inverse == "INVERSE" then
				min_y = 1 - scale
				max_y = 1
				offset_y = 0 - (self.settings.barHeight * (1 - scale))
			elseif self.moduleSettings.inverse == "EXPAND" then
				min_y = 0.5 - (scale * 0.5);
				max_y = 0.5 + (scale * 0.5);
			else
				min_y = 0
				max_y = scale
				offset_y = (self.settings.barHeight * (1 - scale))
			end
		else
			if self.moduleSettings.inverse == "INVERSE" then
				min_y = 0;
				max_y = scale;
			elseif self.moduleSettings.inverse == "EXPAND" then
				min_y = 0.5 - (scale * 0.5);
				max_y = 0.5 + (scale * 0.5);
			else
				min_y = 1-scale;
				max_y = 1;
			end
		end

		if (self.moduleSettings.side == IceCore.Side.Left) then
			barFrame.bar:SetTexCoord(1, 0, min_y, max_y)
		else
			barFrame.bar:SetTexCoord(0, 1, min_y, max_y)
		end

		self:SetBarFramePoints(barFrame, 0, offset_y)
		barFrame:SetHeight(self.settings.barHeight * scale)
		barFrame.bar:Show()
	end
end

function IceBarElement.prototype:SetScale(inScale, force, skipLerp)
	local oldScale = self.CurrScale
	local min_y, max_y;

	if not skipLerp then
		self.CurrScale = self:LerpScale(inScale)
	else
		self.CurrScale = inScale
	end
	self.CurrScale = IceHUD:Clamp(self.CurrScale, 0, 1)

	if force or oldScale ~= self.CurrScale then
		local scale = self.CurrScale
		if self.moduleSettings.reverse then
			scale = 1 - scale
		end

		self:SetBarCoord(self.barFrame, scale)
	end

	if not self:IsFull(self.CurrScale) or not self:IsFull(inScale) then
		self:ConditionalSetupUpdate()
	else
		if self.CurrScale == self.DesiredScale then
			IceHUD.IceCore:RequestUpdates(self, nil)
		end
	end
end


function IceBarElement.prototype:LerpScale(scale)
	if not self.moduleSettings.shouldAnimate then
		return scale
	end

	local now = GetTime()

	if self.CurrLerpTime < self.moduleSettings.desiredLerpTime then
		self.CurrLerpTime = self.CurrLerpTime + (now - (self.lastLerpTime or now))
	end

	self.lastLerpTime = GetTime()

	if self.CurrLerpTime > self.moduleSettings.desiredLerpTime then
		self.CurrLerpTime = self.moduleSettings.desiredLerpTime
	elseif self.CurrLerpTime < self.moduleSettings.desiredLerpTime then
		return self.LastScale + ((self.DesiredScale - self.LastScale) * (self.CurrLerpTime / self.moduleSettings.desiredLerpTime))
	end

	return scale
end


function IceBarElement.prototype:UpdateBar(scale, color, alpha)
	alpha = alpha or 1
	self.frame:SetAlpha(alpha)

	local r, g, b = self.settings.backgroundColor.r, self.settings.backgroundColor.g, self.settings.backgroundColor.b
	if (self.settings.backgroundToggle) then
		r, g, b = self:GetColor(color)
	end

	if (self.combat) then
		self.alpha = self.settings.alphaic
		self.backgroundAlpha = self.settings.alphaicbg
	elseif (self.target and not self:AlphaPassThroughTarget()) then
		self.alpha = self.settings.alphaTarget
		self.backgroundAlpha = self.settings.alphaTargetbg
	elseif (self:UseTargetAlpha(scale)) then
		self.alpha = self.settings.alphaNotFull
		self.backgroundAlpha = self.settings.alphaNotFullbg
	else
		self.alpha = self.settings.alphaooc
		self.backgroundAlpha = self.settings.alphaoocbg
	end

	-- post-process override for the bar alpha to be 1 (ignoring BG alpha for now)
	if self.moduleSettings.alwaysFullAlpha then
		self.alpha = 1
	end

	self.frame.bg:SetVertexColor(r, g, b, self.backgroundAlpha)
	self.barFrame.bar:SetVertexColor(self:GetColor(color))
	if self.moduleSettings.markers then
		for i=1, #self.Markers do
			local color = self.moduleSettings.markers[i].color
			self.Markers[i].bar:SetVertexColor(color.r, color.g, color.b, self.alpha)
		end
	end

	if self.DesiredScale ~= scale then
		self.DesiredScale = scale
		self.CurrLerpTime = 0
		self.lastLerpTime = GetTime()
		self.LastScale = self.CurrScale
	end

	self:SetScale(self.DesiredScale)

	if not self.moduleSettings.barVisible['bg'] then
		self.frame.bg:Hide()
	else
		self.frame.bg:Show()
	end

	self:SetBarVisibility(self.moduleSettings.barVisible['bar'])

	if DogTag ~= nil and self.moduleSettings.usesDogTagStrings then
		DogTag:UpdateAllForFrame(self.frame)
	end

	self:SetTextAlpha()
end


function IceBarElement.prototype:UseTargetAlpha(scale)
	return not self:IsFull(scale)
end

function IceBarElement.prototype:IsFull(scale)
	if self.reverse then
		scale = 1 - scale
	end

	if not self.bTreatEmptyAsFull then
		return scale and scale == 1
	else
		return scale and scale == 0
	end
end


-- Bottom line 1
function IceBarElement.prototype:SetBottomText1(text, color)
	if not (self.moduleSettings.textVisible["upper"]) then
		return
	end

	if not (color) then
		color = "Text"
	end

	local alpha = self.alpha

	if (self.alpha > 0) then
		-- boost text alpha a bit to make it easier to see
		alpha = self.alpha + 0.1

		if (alpha > 1) then
			alpha = 1
		end
	end

	if (self.moduleSettings.lockUpperTextAlpha and (self.alpha > 0)) then
		alpha = 1
	end

	if not self.textColorOverride then
		self.frame.bottomUpperText:SetTextColor(self:GetColor(color, alpha))
	end
	self.frame.bottomUpperText:SetText(text)
	self.frame.bottomUpperText:SetWidth(0)
end


-- Bottom line 2
function IceBarElement.prototype:SetBottomText2(text, color, alpha)
	if not (self.moduleSettings.textVisible["lower"]) then
		return
	end

	if not (color) then
		color = "Text"
	end
	if not (alpha) then
		-- boost text alpha a bit to make it easier to see
		if (self.alpha > 0) then
			alpha = self.alpha + 0.1

			if (alpha > 1) then
				alpha = 1
			end
		end
	end

	if (self.moduleSettings.lockLowerTextAlpha and (self.alpha > 0)) then
		alpha = 1
	end

	if not self.textColorOverride then
		self.frame.bottomLowerText:SetTextColor(self:GetColor(color, alpha))
	end
	self.frame.bottomLowerText:SetText(text)
	self.frame.bottomLowerText:SetWidth(0)
end

function IceBarElement.prototype:SetCustomTextColor(fontInstance, colorTable)
	if not fontInstance or not colorTable or type(colorTable) ~= "table" then
		return
	end

	fontInstance:SetTextColor(colorTable.r, colorTable.g, colorTable.b)
end

function IceBarElement.prototype:SetTextAlpha()
	if self.frame.bottomUpperText then
		self.frame.bottomUpperText:SetAlpha(self.moduleSettings.lockUpperTextAlpha and 1 or math.min(self.alpha > 0 and self.alpha + 0.1 or 0, 1))
	end
	if self.frame.bottomLowerText then
		self.frame.bottomLowerText:SetAlpha(self.moduleSettings.lockLowerTextAlpha and 1 or math.min(self.alpha > 0 and self.alpha + 0.1 or 0, 1))
	end
end


function IceBarElement.prototype:GetFormattedText(value1, value2)
	local color = "ffcccccc"

	local bLeft = ""
	local bRight = ""

	if (self.moduleSettings.brackets) then
		bLeft = "["
		bRight = "]"
	end


	if not (value2) then
		return string.format("|c%s%s|r%s|c%s%s|r", color, bLeft, value1, color, bRight)
	end
	return string.format("|c%s%s|r%s|c%s/|r%s|c%s%s|r", color, bLeft, value1, color, value2, color, bRight)
end

function IceBarElement.prototype:SetScaledColor(colorVar, percent, maxColor, minColor)
	colorVar.r = ((maxColor.r - minColor.r) * percent) + minColor.r
	colorVar.g = ((maxColor.g - minColor.g) * percent) + minColor.g
	colorVar.b = ((maxColor.b - minColor.b) * percent) + minColor.b
end

-- To be overridden
function IceBarElement.prototype:Update()
end

function IceBarElement.prototype:MyOnUpdate()
	self:SetScale(self.DesiredScale)
end

function IceBarElement.prototype:RotateHorizontal()
	self:RotateFrame(self.frame)
end

function IceBarElement.prototype:ResetRotation()
	if self.frame.anim then
		self.frame.anim:Stop()
	end
	if self.barFrame.anim then
		self.barFrame.anim:Stop()
	end
	for i=1, #self.Markers do
		self.Markers[i]:Show()
	end
end

function IceBarElement.prototype:RotateFrame(frame)
	if not frame then
		return
	end

	if frame.anim == nil then
		local grp = frame:CreateAnimationGroup()
		local rot = grp:CreateAnimation("Rotation")
		rot:SetStartDelay(0)
		rot:SetEndDelay(5)
		rot:SetOrder(1)
		rot:SetDuration(0.001)
		rot:SetDegrees(-90)
		grp.rot = rot
		frame.anim = grp
	end

	local anchorPoint
	if self.moduleSettings.inverse == "INVERSE" then
		anchorPoint = "TOPLEFT"
	elseif self.moduleSettings.inverse == "EXPAND" then
		anchorPoint = "LEFT"
	else
		anchorPoint = "BOTTOMLEFT"
	end

	frame.anim.rot:SetOrigin(anchorPoint, 0, 0)
	frame.anim.rot:SetScript("OnUpdate", function(anim) if anim:GetProgress() >= 1 then anim:Pause() anim:SetScript("OnUpdate", nil) end end)
	frame.anim:Play()
end

function IceBarElement.prototype:NotifyBarOverrideChanged()
	for i=1, #self.Markers do
		self.Markers[i].bar:SetTexture(IceElement.TexturePath .. self:GetMyBarTexture())
	end
end

function IceBarElement.prototype:RepositionMarkers()
	for idx=1,#self.Markers do
		self:PositionMarker(idx, self.moduleSettings.markers[idx].position)
	end
end

function IceBarElement.prototype:ClearMarkers()
	for idx=#self.Markers,1,-1 do
		self:RemoveMarker(idx, true)
	end
end

function IceBarElement.prototype:AddNewMarker(inPosition, inColor, inHeight)
	if not self.moduleSettings.markers then
		self.moduleSettings.markers = {}
	end

	local idx = #self.moduleSettings.markers + 1
	self.moduleSettings.markers[idx] = {
		position = inPosition,
		color = {r=inColor.r, g=inColor.g, b=inColor.b, a=1},
		height = inHeight,
	}
	self:CreateMarker(idx)
end

function IceBarElement.prototype:EditMarker(idx, inPosition, inColor, inHeight)
	assert(idx > 0 and #self.Markers >= idx and self.Markers[idx] and self.Markers[idx].bar and #self.moduleSettings.markers >= idx,
		"Bad marker passed to EditMarker. idx="..idx..", #Markers="..#self.Markers..", #settings.markers="..#self.moduleSettings.markers)
	self.moduleSettings.markers[idx] = {
		position = inPosition,
		color = {r=inColor.r, g=inColor.g, b=inColor.b, a=1},
		height = inHeight,
	}
	self:CreateMarker(idx)
end

function IceBarElement.prototype:RemoveMarker(idx, bSkipSettings)
	assert(idx > 0 and #self.Markers >= idx and self.Markers[idx] and self.Markers[idx].bar and #self.moduleSettings.markers >= idx,
		"Bad marker passed to RemoveMarker. idx="..idx..", #Markers="..#self.Markers..", #settings.markers="..#self.moduleSettings.markers)
	self.Markers[idx]:Hide()
	table.remove(self.Markers, idx)
	if not bSkipSettings then
		table.remove(self.moduleSettings.markers, idx)
	end
end

function IceBarElement.prototype:CreateMarker(idx)
	if self.Markers[idx] ~= nil then
		self.Markers[idx]:Hide()
		self.Markers[idx].bar = nil
		self.Markers[idx] = nil
	end

	self.Markers[idx] = self:BarFactory(self.Markers[idx], "MEDIUM", "OVERLAY")

	local color = self.moduleSettings.markers[idx].color
	self.Markers[idx].bar:SetVertexColor(color.r, color.g, color.b, self.alpha)

	self:UpdateMarker(idx)
	self:PositionMarker(idx, self.moduleSettings.markers[idx].position)
end

function IceBarElement.prototype:UpdateMarker(idx)
	assert(idx > 0 and #self.Markers >= idx and self.Markers[idx] and self.Markers[idx].bar and #self.moduleSettings.markers >= idx,
		"Bad marker passed to UpdateMarker. idx="..idx..", #Markers="..#self.Markers..", #settings.markers="..#self.moduleSettings.markers)
	self.Markers[idx]:SetWidth(self.settings.barWidth + (self.moduleSettings.widthModifier or 0))
	self.Markers[idx]:SetHeight(self.moduleSettings.markers[idx].height)
end

function IceBarElement.prototype:PositionMarker(idx, pos)
	assert(idx > 0 and #self.Markers >= idx and self.Markers[idx] and self.Markers[idx].bar and #self.moduleSettings.markers >= idx,
		"Bad marker passed to PositionMarker. idx="..idx..", #Markers="..#self.Markers..", #settings.markers="..#self.moduleSettings.markers)

	local min_y, max_y, offset_y
	local heightScale = (self.moduleSettings.markers[idx].height / self.settings.barHeight)

	if (self.moduleSettings.inverse == "INVERSE") then
		offset_y = 0 - (self.settings.barHeight * pos)
		min_y = IceHUD:Clamp(pos, 0, 1)
		max_y = IceHUD:Clamp(pos+heightScale, 0, 1)
	elseif (self.moduleSettings.inverse == "EXPAND") then
		pos = pos + ((1-pos) * 0.5)
		heightScale = heightScale * 0.5
		offset_y = self.settings.barHeight * (pos - 0.5)
		min_y = IceHUD:Clamp(1-pos-(heightScale), 0, 1)
		max_y = IceHUD:Clamp(1-pos+(heightScale), 0, 1)
	else
		offset_y = (self.settings.barHeight * pos)
		min_y = IceHUD:Clamp(1-pos-heightScale, 0, 1)
		max_y = IceHUD:Clamp(1-pos, 0, 1)
	end

	if (self.moduleSettings.side == IceCore.Side.Left) then
		self.Markers[idx].bar:SetTexCoord(1, 0, min_y, max_y)
	else
		self.Markers[idx].bar:SetTexCoord(0, 1, min_y, max_y)
	end

	self:SetBarFramePoints(self.Markers[idx], 0, offset_y)
	self.Markers[idx].bar:Show()
end

function IceBarElement.prototype:LoadMarkers()
	self.Markers = {}

	if not self.moduleSettings.markers then
		return
	end

	for i=1, #self.moduleSettings.markers do
		self:CreateMarker(i)
	end
end
