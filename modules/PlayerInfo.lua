local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
local PlayerInfo = IceCore_CreateClass(IceTargetInfo)

local EPSILON = 0.5

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
            CancelItemTempEnchantment(1)
        elseif this.type == "oh" then
            CancelItemTempEnchantment(2)
        else
            CancelUnitBuff(self.unit, this.id)
        end
	end
end

function PlayerInfo.prototype:CreateIconFrames(parent, direction, buffs, type)
	local buffs = PlayerInfo.super.prototype.CreateIconFrames(self, parent, direction, buffs, type)

    if not self.MyOnClickBuffFunc then
        self.MyOnClickBuffFunc = function(this,event) self:BuffClick(this,event) end
    end

	for i = 1, IceCore.BuffLimit do
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
	TemporaryEnchantFrame:Show()

	BuffFrame:GetScript("OnLoad")(BuffFrame)
end


function PlayerInfo.prototype:HideBlizz()
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()

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

	local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
		= GetWeaponEnchantInfo()

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
					GetInventoryItemTexture(self.unit, GetInventorySlotInfo("MainHandSlot")),
					self.mainHandEnchantEndTime,
					CurrTime + (mainHandExpiration/1000),
					true,
					mainHandCharges,
					nil,
					"mh")
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
					GetInventoryItemTexture(self.unit, GetInventorySlotInfo("SecondaryHandSlot")),
					self.offHandEnchantEndTime,
					CurrTime + (offHandExpiration/1000),
					true,
					offHandCharges,
					nil,
					"oh")
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

-- Load us up
IceHUD.PlayerInfo = PlayerInfo:new()
