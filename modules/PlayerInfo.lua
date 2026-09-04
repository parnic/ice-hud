local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerInfo = IceCore_CreateClass(IceTargetInfo)

local EPSILON = 0.5
local ValidAnchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER" }

-- Aura containers create and own their buttons, so weapon enchants can't be appended to
-- the buff display anymore. They get their own small strip of icon frames instead.
local WeaponEnchantSlots = {
	{type = "mh", inventorySlot = "MAINHANDSLOT", endTimeKey = "mainHandEnchantEndTime", timeSetKey = "mainHandEnchantTimeSet"},
	{type = "oh", inventorySlot = "SECONDARYHANDSLOT", endTimeKey = "offHandEnchantEndTime", timeSetKey = "offHandEnchantTimeSet"},
}

PlayerInfo.prototype.mainHandEnchantTimeSet = 0
PlayerInfo.prototype.mainHandEnchantEndTime = 0
PlayerInfo.prototype.offHandEnchantTimeSet = 0
PlayerInfo.prototype.offHandEnchantEndTime = 0
PlayerInfo.prototype.scheduledEvent = nil

-- Constructor --
function PlayerInfo.prototype:init()
	PlayerInfo.super.prototype.init(self, "PlayerInfo", "player")
end

function PlayerInfo.prototype:GetDefaultSettings()
	local settings = PlayerInfo.super.prototype.GetDefaultSettings(self)

	settings["enabled"] = false
	settings["vpos"] = -100
	settings["hideBlizz"] = false

	-- The strip is positioned on its own because the aura container's coordinates are
	-- secret: we can't read where the buffs ended up and line up with them. Default it to
	-- a row above the buff anchor, which is the one spot buffs can't grow into.
	settings["weaponEnchants"] = {
		show = true,
		anchorTo = settings.auras.buff.anchorTo,
		offsetX = settings.auras.buff.offsetX,
		offsetY = settings.auras.buff.offsetY + settings.auras.buff.size + settings.spaceBetweenBuffs,
		growDirection = settings.auras.buff.growDirection,
	}

	return settings
end

function PlayerInfo.prototype:GetOptions()
	local opts = PlayerInfo.super.prototype.GetOptions(self)

	opts["hideBlizz"] = {
		type = "toggle",
		name = L["Hide Blizzard Buffs"],
		desc = L["Hides Blizzard's default buffs frame and disables all events related to it"],
		get = function()
			return self.moduleSettings.hideBlizz
		end,
		set = function(info, value)
			self.moduleSettings.hideBlizz = value
			if (value) then
				self:HideBlizz()
			else
				self:ShowBlizz()
			end
		end,
		disabled = function()
			return not self.moduleSettings.enabled
		end,
		order = 33.1,
	}

	local function EnchantsDisabled()
		return not self.moduleSettings.enabled or not self.moduleSettings.weaponEnchants.show
	end

	opts["weaponEnchants"] = {
		type = 'group',
		name = "|c"..self.configColor..L["Weapon Enchant Settings"].."|r",
		desc = L["Weapon Enchant Settings"],
		-- Only the aura container path uses this strip; everywhere else weapon enchants are
		-- still appended to the buff display and follow its settings.
		hidden = function()
			return not IceHUD.CanUseAuraContainer()
		end,
		args = {
			show = {
				type = 'toggle',
				name = L["Show weapon enchants"],
				desc = L["Toggles whether or not temporary weapon enchants are displayed"],
				get = function()
					return self.moduleSettings.weaponEnchants.show
				end,
				set = function(info, v)
					self.moduleSettings.weaponEnchants.show = v
					self:CreateWeaponEnchantFrame(false)
					self:UpdateWeaponEnchants()
				end,
				disabled = function()
					return not self.moduleSettings.enabled
				end,
				order = 41.1,
			},
			growDirection = {
				type = 'select',
				name = L["Grow direction"],
				desc = L["Which direction the weapon enchants should grow from the anchor point"],
				values = { "Left", "Right" },
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.weaponEnchants.growDirection)
				end,
				set = function(info, v)
					self.moduleSettings.weaponEnchants.growDirection = info.option.values[v]
					self:CreateWeaponEnchantFrame(false)
					self:UpdateWeaponEnchants()
				end,
				disabled = EnchantsDisabled,
				order = 41.2,
			},
			anchorTo = {
				type = 'select',
				name = L["Anchor to"],
				desc = L["The point on the PlayerInfo frame that the weapon enchant frame gets connected to"],
				values = ValidAnchors,
				get = function(info)
					return IceHUD:GetSelectValue(info, self.moduleSettings.weaponEnchants.anchorTo)
				end,
				set = function(info, v)
					self.moduleSettings.weaponEnchants.anchorTo = info.option.values[v]
					self:PositionWeaponEnchantFrame()
				end,
				disabled = EnchantsDisabled,
				order = 41.3,
			},
			offsetX = {
				type = 'range',
				name = L["Horizontal offset"],
				desc = L["How far horizontally the weapon enchant frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.weaponEnchants.offsetX
				end,
				set = function(info, v)
					self.moduleSettings.weaponEnchants.offsetX = v
					self:PositionWeaponEnchantFrame()
				end,
				disabled = EnchantsDisabled,
				order = 41.4,
			},
			offsetY = {
				type = 'range',
				name = L["Vertical offset"],
				desc = L["How far vertically the weapon enchant frame should be offset from the anchor"],
				min = -500,
				max = 500,
				step = 1,
				get = function()
					return self.moduleSettings.weaponEnchants.offsetY
				end,
				set = function(info, v)
					self.moduleSettings.weaponEnchants.offsetY = v
					self:PositionWeaponEnchantFrame()
				end,
				disabled = EnchantsDisabled,
				order = 41.5,
			},
		},
		order = 41,
	}

	return opts
end

StaticPopupDialogs["ICEHUD_BUFF_DISMISS_UNAVAILABLE"] =
{
	text = "Sorry, but there is currently no simple way for custom mods to cancel buffs while retaining flexibility in how buffs are displayed. This will be fixed whenever the API is more accessible and I get some free time.",
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
}

-- playerinfo buffclick event handle
function PlayerInfo.prototype:BuffClick(this,event)
	if not self:AllowMouseBuffInteraction(this) then
		return
	end

    -- We want to catch the rightbutton click.
    -- We also need to check for combat lockdown. The api won't allow cancelling during combat lockdown.
    if( event == "RightButton" ) and not InCombatLockdown() then
        if this.type == "mh" then
            IceHUD.CancelItemTempEnchantment(1)
        elseif this.type == "oh" then
            IceHUD.CancelItemTempEnchantment(2)
        else
            CancelUnitBuff(self.unit, this.id)
        end
	end
end

function PlayerInfo.prototype:CreateIconFrames(parent, direction, buffs, type, count)
	local buffs = PlayerInfo.super.prototype.CreateIconFrames(self, parent, direction, buffs, type, count)

    if not self.MyOnClickBuffFunc then
        self.MyOnClickBuffFunc = function(this,event) self:BuffClick(this,event) end
    end

	for i = 1, #buffs do
		if (self.moduleSettings.mouseBuff) then
			buffs[i]:SetScript("OnMouseUp", self.MyOnClickBuffFunc)
		else
			buffs[i]:SetScript("OnMouseUp", nil)
		end
	end

	return buffs
end

function PlayerInfo.prototype:Enable(core)
	PlayerInfo.super.prototype.Enable(self, core)

	if (self.moduleSettings.hideBlizz) then
		self:HideBlizz()
	end

	self.scheduledEvent = self:ScheduleRepeatingTimer("RepeatingUpdateBuffs", 1)
end

function PlayerInfo.prototype:Disable(core)
	PlayerInfo.super.prototype.Disable(self, core)

	self:CancelTimer(self.scheduledEvent, true)
end

function PlayerInfo.prototype:ShowBlizz()
	BuffFrame:Show()
	if DebuffFrame then
		DebuffFrame:Show()
		DebuffFrame:GetScript("OnLoad")(DebuffFrame)
		if DebuffFrame.Update then
			DebuffFrame:Update()
		end
	end
	if TemporaryEnchantFrame then
		TemporaryEnchantFrame:Show()
	end

	BuffFrame:GetScript("OnLoad")(BuffFrame)
	if BuffFrame.Update then
		BuffFrame:Update()
	end
end


function PlayerInfo.prototype:HideBlizz()
	BuffFrame:Hide()
	if DebuffFrame then
		DebuffFrame:Hide()
		DebuffFrame:UnregisterAllEvents()
	end
	if TemporaryEnchantFrame then
		TemporaryEnchantFrame:Hide()
	end

	BuffFrame:UnregisterAllEvents()
end

function PlayerInfo.prototype:RepeatingUpdateBuffs()
	self:UpdateBuffs(self.unit, true)
end

function PlayerInfo.prototype:UpdateBuffs(unit, fromRepeated)
	if unit and unit ~= self.unit then
		return
	end

	if not fromRepeated then
		PlayerInfo.super.prototype.UpdateBuffs(self)
	end

	-- The container path has no icon frames of ours to append to, so weapon enchants live
	-- in a separate strip there. The buff frame is missing entirely when buffs are hidden,
	-- since the container isn't built until something wants to show one.
	if IceHUD.CanUseAuraContainer() then
		self:UpdateWeaponEnchants()
		return
	end

	if not self.frame.buffFrame or not self.frame.buffFrame.iconFrames then
		return
	end

	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
		= IceHUD.GetWeaponEnchantInfo()

	local startingNum = 0

	for i=1, IceCore.BuffLimit do
		if not self.frame.buffFrame.iconFrames[i]:IsVisible()
			or self.frame.buffFrame.iconFrames[i].type == "mh"
			or self.frame.buffFrame.iconFrames[i].type == "oh" then
			if startingNum == 0 then
				startingNum = i
			end
		end

		if self.frame.buffFrame.iconFrames[i]:IsVisible() then
			if (self.frame.buffFrame.iconFrames[i].type == "mh" and not hasMainHandEnchant)
				or (self.frame.buffFrame.iconFrames[i].type == "oh" and not hasOffHandEnchant) then
				self.frame.buffFrame.iconFrames[i]:Hide()
			end
		end
	end

	-- no acceptable space found to append weapon buffs, so don't.
	-- either the player already has 40 buffs on him or he's in configuration mode
	if startingNum == 0 then
		return
	end

	if hasMainHandEnchant or hasOffHandEnchant then
		local CurrTime = GetTime()

		if hasMainHandEnchant and startingNum <= IceCore.BuffLimit then
			if self.mainHandEnchantEndTime == 0 or
				abs(self.mainHandEnchantEndTime - (mainHandExpiration/1000)) > CurrTime - self.mainHandEnchantTimeSet + EPSILON then
				self.mainHandEnchantEndTime = mainHandExpiration/1000
				self.mainHandEnchantTimeSet = CurrTime
			end

			if not self.frame.buffFrame.iconFrames[startingNum]:IsVisible() or self.frame.buffFrame.iconFrames[startingNum].type ~= "mh" then
				self:SetupAura("buff",
					startingNum,
					GetInventoryItemTexture(self.unit, GetInventorySlotInfo("MAINHANDSLOT")),
					self.mainHandEnchantEndTime,
					CurrTime + (mainHandExpiration/1000),
					true,
					mainHandCharges,
					nil,
					"mh",
					nil,
					true)
			end

			startingNum = startingNum + 1
		end

		if hasOffHandEnchant and startingNum <= IceCore.BuffLimit then
			if self.offHandEnchantEndTime == 0 or
				abs(self.offHandEnchantEndTime - (offHandExpiration/1000)) > abs(CurrTime - self.offHandEnchantTimeSet) + EPSILON then
				self.offHandEnchantEndTime = offHandExpiration/1000
				self.offHandEnchantTimeSet = CurrTime
			end

			if not self.frame.buffFrame.iconFrames[startingNum]:IsVisible() or self.frame.buffFrame.iconFrames[startingNum].type ~= "oh" then
				self:SetupAura("buff",
					startingNum,
					GetInventoryItemTexture(self.unit, GetInventorySlotInfo("SECONDARYHANDSLOT")),
					self.offHandEnchantEndTime,
					CurrTime + (offHandExpiration/1000),
					true,
					offHandCharges,
					nil,
					"oh",
					nil,
					true)
			end

			startingNum = startingNum + 1
		end

		for i=startingNum, IceCore.BuffLimit do
			if self.frame.buffFrame.iconFrames[i]:IsVisible() then
				self.frame.buffFrame.iconFrames[i]:Hide()
			end
		end

		self.frame.buffFrame.iconFrames = self:CreateIconFrames(self.frame.buffFrame,
			self.moduleSettings.auras["buff"].growDirection,
			self.frame.buffFrame.iconFrames, "buff")
	end
end

-- OVERRIDE
function PlayerInfo.prototype:CreateFrame(redraw)
	PlayerInfo.super.prototype.CreateFrame(self, redraw)

	self:CreateWeaponEnchantFrame(redraw)
end

function PlayerInfo.prototype:Redraw()
	PlayerInfo.super.prototype.Redraw(self)

	self:ReapplyWeaponEnchantSettings()
end

-- OVERRIDE
function PlayerInfo.prototype:RedrawBuffs()
	PlayerInfo.super.prototype.RedrawBuffs(self)

	if self.moduleSettings.enabled then
		self:CreateWeaponEnchantFrame(false)
		self:UpdateWeaponEnchants()
	end
end

-- OVERRIDE
function PlayerInfo.prototype:UpdateAlpha()
	PlayerInfo.super.prototype.UpdateAlpha(self)

	self:UpdateAuraCooldownAlpha("weaponEnchantFrame")
end

function PlayerInfo.prototype:ReapplyWeaponEnchantSettings()
	if not self.frame.weaponEnchantFrame then
		return
	end
	for i=1,#self.frame.weaponEnchantFrame.iconFrames do
		if self.frame.weaponEnchantFrame.iconFrames[i].cd.SetHideCountdownNumbers then
			self.frame.weaponEnchantFrame.iconFrames[i].cd:SetHideCountdownNumbers(self.moduleSettings.forceHideCooldownNumbers)
		end
	end
end

function PlayerInfo.prototype:CreateWeaponEnchantFrame(redraw)
	if not IceHUD.CanUseAuraContainer() then
		return
	end

	local settings = self.moduleSettings.weaponEnchants

	if not self.frame.weaponEnchantFrame then
		self.frame.weaponEnchantFrame = CreateFrame("Frame", nil, self.frame)
		self.frame.weaponEnchantFrame:SetWidth(1)
		self.frame.weaponEnchantFrame:SetHeight(1)
		self.frame.weaponEnchantFrame.iconFrames = {}
	end

	local frame = self.frame.weaponEnchantFrame

	frame:SetFrameStrata(IceHUD.IceCore:DetermineStrata(IceElement.defaultStrata))
	self:PositionWeaponEnchantFrame()

	if not redraw then
		frame.iconFrames = self:CreateIconFrames(frame, settings.growDirection, frame.iconFrames, "buff", #WeaponEnchantSlots)
	end

	if settings.show then
		frame:Show()
	else
		frame:Hide()
	end
end

-- The strip can't be anchored to the aura container - it's restricted, so anything hung off
-- it inherits UntrustedLayoutScriptExecution and the SetPoint is refused - and the
-- container's coordinates are secret, so they can't be read and reused either. That leaves
-- positioning it against our own frame from its own settings.
function PlayerInfo.prototype:PositionWeaponEnchantFrame()
	local frame = self.frame and self.frame.weaponEnchantFrame

	if not frame then
		return
	end

	local settings = self.moduleSettings.weaponEnchants

	frame:ClearAllPoints()
	frame:SetPoint(settings.growDirection == "Left" and "TOPRIGHT" or "TOPLEFT", self.frame,
		settings.anchorTo, settings.offsetX, settings.offsetY)
end

function PlayerInfo.prototype:UpdateWeaponEnchants()
	if not self.frame then
		return
	end

	-- The container globals can show up after we've already built our frames, so make the
	-- strip on first use rather than only at creation time.
	if not self.frame.weaponEnchantFrame then
		self:CreateWeaponEnchantFrame(false)
	end

	local frame = self.frame.weaponEnchantFrame

	if not frame or not frame.iconFrames then
		return
	end

	if not self.moduleSettings.weaponEnchants.show then
		frame:Hide()
		return
	end

	frame:Show()

	-- Nothing may actually be enchanted while the strip is being positioned, so config mode
	-- fills every slot the same way the buff placeholders do.
	if self:IsInConfigMode() then
		local currTime = GetTime()

		for i = 1, #frame.iconFrames do
			self:SetupAura("weaponEnchant", i, GetInventoryItemTexture(self.unit,
				GetInventorySlotInfo(WeaponEnchantSlots[i].inventorySlot)) or [[Interface\Icons\Spell_Frost_Frost]],
				60, currTime + 59, true, math.random(5), nil, WeaponEnchantSlots[i].type, nil, true)
		end

		return
	end

	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, _, hasOffHandEnchant, offHandExpiration, offHandCharges
		= IceHUD.GetWeaponEnchantInfo()
	local currTime = GetTime()
	local shown = 0

	-- Icon frames keep the position they were laid out at, so an inactive slot would leave
	-- a hole. Active enchants get packed into the frames from the front instead.
	if hasMainHandEnchant then
		shown = shown + 1
		self:SetupWeaponEnchant(shown, 1, mainHandExpiration, mainHandCharges, currTime)
	else
		self:ClearWeaponEnchantState(1)
	end

	if hasOffHandEnchant then
		shown = shown + 1
		self:SetupWeaponEnchant(shown, 2, offHandExpiration, offHandCharges, currTime)
	else
		self:ClearWeaponEnchantState(2)
	end

	for i = shown + 1, #WeaponEnchantSlots do
		frame.iconFrames[i]:Hide()
	end
end

function PlayerInfo.prototype:ClearWeaponEnchantState(slotIndex)
	local slot = WeaponEnchantSlots[slotIndex]

	self[slot.endTimeKey] = 0
	self[slot.timeSetKey] = 0
end

function PlayerInfo.prototype:SetupWeaponEnchant(index, slotIndex, expiration, charges, currTime)
	local slot = WeaponEnchantSlots[slotIndex]

	-- The remaining time shrinks on every update, so only re-base the duration when it
	-- moves by more than the elapsed time - otherwise the cooldown swipe restarts each tick.
	if self[slot.endTimeKey] == 0
		or abs(self[slot.endTimeKey] - (expiration/1000)) > currTime - self[slot.timeSetKey] + EPSILON then
		self[slot.endTimeKey] = expiration/1000
		self[slot.timeSetKey] = currTime
	end

	self:SetupAura("weaponEnchant",
		index,
		GetInventoryItemTexture(self.unit, GetInventorySlotInfo(slot.inventorySlot)),
		self[slot.endTimeKey],
		currTime + (expiration/1000),
		true,
		charges,
		nil,
		slot.type,
		nil,
		true)
end

-- Load us up
IceHUD.PlayerInfo = PlayerInfo:new()
