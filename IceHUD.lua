local L = LibStub("AceLocale-3.0"):GetLocale("IceHUD", false)
IceHUD = LibStub("AceAddon-3.0"):NewAddon("IceHUD", "AceConsole-3.0", "AceHook-3.0")

local IceHUD = IceHUD

local SML = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local ConfigDialog = LibStub("AceConfigDialog-3.0")
local icon = LibStub("LibDBIcon-1.0", true)

local pendingModuleLoads = {}
local bReadyToRegisterModules = false

local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn

IceHUD.UnitAura = UnitAura
if not IceHUD.UnitAura then
	IceHUD.UnitAura = function(unitToken, index, filter)
		local auraData = C_UnitAuras.GetAuraDataByIndex(unitToken, index, filter)
		if not auraData then
			return nil
		end

		return AuraUtil.UnpackAuraData(auraData)
	end
end

IceHUD.GetSpecialization = GetSpecialization
if not IceHUD.GetSpecialization then
	IceHUD.GetSpecialization = GetPrimaryTalentTree
end

IceHUD.CurrTagVersion = 3
IceHUD.debugging = false

IceHUD.WowVer = select(4, GetBuildInfo())
IceHUD.WowMain = not WOW_PROJECT_ID or WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
if GetClassicExpansionLevel then
	IceHUD.WowClassic = GetClassicExpansionLevel() == 0
	IceHUD.WowClassicBC = GetClassicExpansionLevel() == 1
	IceHUD.WowClassicWrath = GetClassicExpansionLevel() == 2
	IceHUD.WowClassicCataclysm = GetClassicExpansionLevel() == 3
	IceHUD.WowClassicMists = GetClassicExpansionLevel() == 4
else
	IceHUD.WowClassic = WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
	IceHUD.WowClassicBC = false
	IceHUD.WowClassicWrath = false
	IceHUD.WowClassicCataclysm = false
	IceHUD.WowClassicMists = false
	if WOW_PROJECT_ID and WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		if not LE_EXPANSION_LEVEL_CURRENT or LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
			IceHUD.WowClassicBC = true
		elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
			IceHUD.WowClassicWrath = true
		end
	elseif WOW_PROJECT_WRATH_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
		IceHUD.WowClassicWrath = true
	elseif WOW_PROJECT_CATACLYSM_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC then
		IceHUD.WowClassicCataclysm = true
	elseif WOW_PROJECT_MISTS_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC then
		IceHUD.WowClassicMists = true
	end
end

local GetSpellInfo = GetSpellInfo
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
	GetSpellInfo = function(spellID)
		if not spellID then
			return nil
		end

		local spellInfo = C_Spell.GetSpellInfo(spellID)
		if spellInfo then
			return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
		end
	end
end

local GetSpellName = GetSpellInfo
if C_Spell and C_Spell.GetSpellName then
	GetSpellName = C_Spell.GetSpellName
end

-- compatibility/feature flags
IceHUD.CanShowTargetCasting = not IceHUD.WowClassic or LibClassicCasterino or (IceHUD.WowClassic and IceHUD.WowVer >= 11500)
IceHUD.GetPlayerAuraBySpellID = _G["C_UnitAuras"] and C_UnitAuras.GetPlayerAuraBySpellID
IceHUD.SpellFunctionsReturnRank = IceHUD.WowMain and IceHUD.WowVer < 80000
IceHUD.EventExistsPlayerPetChanged = IceHUD.WowMain and IceHUD.WowVer < 80000
IceHUD.EventExistsPetBarChanged = IceHUD.WowMain and IceHUD.WowVer < 80000
IceHUD.EventExistsPlayerComboPoints = IceHUD.WowMain and IceHUD.WowVer < 30000
IceHUD.EventExistsUnitComboPoints = IceHUD.WowMain and IceHUD.WowVer < 70000
IceHUD.EventExistsUnitMaxPower = IceHUD.WowMain and IceHUD.WowVer >= 40000
IceHUD.EventExistsGroupRosterUpdate = IceHUD.WowVer >= 50000 or not IceHUD.WowMain
IceHUD.EventExistsUnitDynamicFlags = IceHUD.WowMain and IceHUD.WowVer < 80000
IceHUD.EventExistsUnitHealthFrequent = not IceHUD.WowMain or (IceHUD.WowVer >= 40000 and IceHUD.WowVer < 90000)
IceHUD.PerPowerEventsExist = IceHUD.WowMain and IceHUD.WowVer < 40000
IceHUD.PerTargetComboPoints = IceHUD.WowVer < 60000
IceHUD.CanTrackOtherUnitBuffs = not IceHUD.WowClassic or IceHUD.WowVer >= 11500
IceHUD.CanTrackGCD = not IceHUD.WowClassic or IceHUD.WowVer >= 11500
IceHUD.GetSpellInfoReturnsFunnel = IceHUD.WowMain and IceHUD.WowVer < 60000
IceHUD.CanHookDestroyTotem = IceHUD.WowClassic or IceHUD.WowClassicBC or IceHUD.WowClassicWrath or IceHUD.WowClassicCataclysm or IceHUD.WowClassicMists
IceHUD.ShouldUpdateTargetHealthEveryTick = (IceHUD.WowClassic or IceHUD.WowClassicBC) and GetCVarBool("predictedHealth")
IceHUD.UsesUIPanelButtonTemplate = IceHUD.WowVer >= 50000 or not IceHUD.WowMain
IceHUD.EventExistsSpellcastInterruptible = IceHUD.WowVer >= 30200 and not IceHUD.WowClassicWrath
IceHUD.DeathKnightUnholyFrostRunesSwapped = IceHUD.WowVer < 70300 and not IceHUD.WowClassicWrath and not IceHUD.WowClassicCataclysm and not IceHUD.WowClassicMists
IceHUD.SupportsHealPrediction = IceHUD.WowVer >= 40000 or IceHUD.WowClassicWrath
IceHUD.UnitGroupRolesReturnsRoleString = IceHUD.WowVer >= 40000 or IceHUD.WowClassicWrath
IceHUD.ShellGameSpellID = 271571
IceHUD.HasShellGame = GetSpellName(IceHUD.ShellGameSpellID)
IceHUD.CatalogingSpellIDs = {366290, 372817, 385025, 385635, 386070, 386504, 400043, 403115}
IceHUD.HasCataloging = GetSpellName(366290)

IceHUD.UnitPowerEvent = "UNIT_POWER_UPDATE"

IceHUD.validBarList = { "Bar", "HiBar", "RoundBar", "ColorBar", "RivetBar", "RivetBar2", "CleanCurves", "GlowArc",
	"BloodGlaives", "ArcHUD", "FangRune", "DHUD", "CleanCurvesOut", "CleanTank", "PillTank", "GemTank" }
IceHUD.validCustomModules = {Bar="Buff/Debuff watcher", Counter="Buff/Debuff stack counter", CD="Cooldown bar", Health="Health bar", Mana="Mana bar", CounterBar="Stack count bar"}

--@debug@
IceHUD.optionsLoaded = true
--@end-debug@

local function deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

IceHUD.deepcopy = deepcopy

function IceHUD:removeDefaults(db, defaults, blocker)
	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(db, nil)
	-- loop through the defaults and remove their content
	for k,v in pairs(defaults) do
		if type(v) == "table" and type(db[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			self:removeDefaults(db[k], v, blocker and blocker[k])
			if next(db[k]) == nil then
				db[k] = nil
			end
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if db[k] == defaults[k] and (not blocker or blocker[k] == nil) then
				db[k] = nil
			end
		end
	end
end

function IceHUD:populateDefaults(db, defaults, blocker)
	-- remove all metatables from the db, so we don't accidentally create new sub-tables through them
	setmetatable(db, nil)
	-- loop through the defaults and add their content
	for k,v in pairs(defaults) do
		if type(v) == "table" and type(db[k]) == "table" then
			-- if a blocker was set, dive into it, to allow multi-level defaults
			self:populateDefaults(db[k], v, blocker and blocker[k])
		else
			-- check if the current value matches the default, and that its not blocked by another defaults table
			if db[k] == nil then
				db[k] = defaults[k]
			end
		end
	end
end

IceHUD.Location = "Interface\\AddOns\\IceHUD"

StaticPopupDialogs["ICEHUD_CUSTOM_BAR_CREATED"] =
{
	text = L["A custom bar has been created and can be configured through Module Settings => MyCustomBar. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_CUSTOM_COUNTER_CREATED"] =
{
	text = L["A custom counter has been created and can be configured through Module Settings => MyCustomCounter. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_CUSTOM_COUNTER_BAR_CREATED"] =
{
	text = L["A custom counter bar has been created and can be configured through Module Settings => MyCustomCounterBar. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_CUSTOM_CD_CREATED"] =
{
	text = L["A custom cooldown bar has been created and can be configured through Module Settings => MyCustomCD. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_CUSTOM_HEALTH_CREATED"] =
{
	text = L["A custom health bar has been created and can be configured through Module Settings => MyCustomHealth. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_CUSTOM_MANA_CREATED"] =
{
	text = L["A custom mana bar has been created and can be configured through Module Settings => MyCustomMana. It is highly recommended that you change the bar name of this module so that it's easier to identify."],
	button1 = OKAY,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
}

StaticPopupDialogs["ICEHUD_DELETE_CUSTOM_MODULE"] =
{
	text = L["Are you sure you want to delete this module? This will remove all settings associated with it and cannot be un-done."],
	button1 = YES,
	button2 = NO,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
	OnAccept = function(self)
		IceHUD.IceCore:DeleteDynamicModule(self.data)
		self.data = nil
	end,
}

StaticPopupDialogs["ICEHUD_CHANGED_DOGTAG"] = {
	text = L["This option requires the UI to be reloaded. Do you wish to reload it now?"],
	button1 = YES,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
	OnAccept = function()
		ReloadUI()
	end,
	button2 = NO,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0
}

StaticPopupDialogs["ICEHUD_CHANGED_PROFILE_COMBAT"] = {
	text = L["You have changed IceHUD profiles while in combat. This can cause problems due to Blizzard's secure frame policy. You may need to reload your UI to repair IceHUD."],
	button1 = OKAY,
	OnShow = function(self)
		self:SetFrameStrata("TOOLTIP")
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 0
}

function IceHUD:OnInitialize()
	self:SetDebugging(false)
	self:Debug("IceHUD:OnInitialize()")

	self.IceCore = IceCore:new()
	self:RegisterPendingModules()
	self.IceCore:SetupDefaults()
	bReadyToRegisterModules = true

	self.db = LibStub("AceDB-3.0"):New("IceCoreDB", self.IceCore.defaults, true)
	if not self.db or not self.db.global or not self.db.profile then
		print(L["Error: IceHUD database not loaded correctly.  Please exit out of WoW and delete the database file (IceHUD.lua) found in: \\World of Warcraft\\WTF\\Account\\<Account Name>>\\SavedVariables\\"])
		return
	end

	self.db.RegisterCallback(self, "OnProfileShutdown", "PreProfileChanged")
	self.db.RegisterCallback(self, "OnProfileChanged", "PostProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "ProfileReset")
	self.db.RegisterCallback(self, "OnProfileCopied", "ProfileCopied")

	self:NotifyNewDb()

	ConfigDialog:SetDefaultSize("IceHUD", 750, 650)
	self:RegisterChatCommand("icehud", function()
			if not UnitAffectingCombat("player") then
				IceHUD:OpenConfig()
			else
				DEFAULT_CHAT_FRAME:AddMessage(L["|cff8888ffIceHUD|r: Combat lockdown restriction. Leave combat and try again."])
			end
		end)
	self:RegisterChatCommand("rl", function() ReloadUI() end)

	-- hack to allow /icehudcl to continue to function by loading the LoD options module and then re-calling the command
	--[===[@non-debug@
	self:RegisterChatCommand("icehudcl", function(arg)
		self:UnregisterChatCommand("icehudcl")
		self:LoadOptions()
		LibStub("AceConfigCmd-3.0"):HandleCommand("icehudcl", "IceHUD", arg)
		end)
	--@end-non-debug@]===]

	self:SyncSettingsVersions()

	self:InitLDB()
	if SML then
		SML.RegisterCallback(self, "LibSharedMedia_Registered", "UpdateMedia")
	end
end


function IceHUD:NotifyNewDb()
	self.IceCore.accountSettings = self.db.global
	self.IceCore.settings = self.db.profile
	self.IceCore:SetModuleDatabases()

	self.IceCore:CheckDisplayUpdateMessage()
end


function IceHUD:NotifyOptionsChange()
	if ACR then
		ACR:NotifyChange("IceHUD")
	end
end

function IceHUD:OnEnable(isFirst)
--	if isFirst then
		self:SetDebugging(self.IceCore:GetDebug())
		self.debugFrame = ChatFrame1
--	end
	self:Debug("IceHUD:OnEnable()")

	if self.db.profile.enable then
		self.IceCore:Enable()
	end

	-- Add dual-spec support
	local LibDualSpec = LibStub('LibDualSpec-1.0', true)
	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, "IceHUD")
	end

	--@debug@
	IceHUD_Options:OnLoad()
	--@end-debug@
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
			text = L["IceHUD"],
			label = L["IceHUD"],
			icon = "Interface\\Icons\\Spell_Frost_Frost",
			OnClick = function(button, msg)
				if not UnitAffectingCombat("player") then
					IceHUD:OpenConfig()
				else
					DEFAULT_CHAT_FRAME:AddMessage(L["|cff8888ffIceHUD|r: Combat lockdown restriction. Leave combat and try again."])
				end
			end,
		})

		if icon then
			icon:Register("IceHUD", ldbButton, self.db.profile.minimap)
		end

		if ldbButton then
			function ldbButton:OnTooltipShow()
				self:AddLine(L["IceHUD"] .. " @project-version@")
				self:AddLine(L["Click to open IceHUD options."], 1, 1, 1)
			end
		end
	end
end

-- blizzard interface options
local blizOptionsPanel = CreateFrame("FRAME", "IceHUDConfigPanel", UIParent)
blizOptionsPanel.name = "IceHUD"
blizOptionsPanel.button = CreateFrame("BUTTON", "IceHUDOpenConfigButton", blizOptionsPanel, IceHUD.UsesUIPanelButtonTemplate and "UIPanelButtonTemplate" or "UIPanelButtonTemplate2")
blizOptionsPanel.button:SetText("Open IceHUD configuration")
blizOptionsPanel.button:SetWidth(240)
blizOptionsPanel.button:SetHeight(30)
blizOptionsPanel.button:SetScript("OnClick", function(self) HideUIPanel(InterfaceOptionsFrame) HideUIPanel(GameMenuFrame) IceHUD:OpenConfig() end)
blizOptionsPanel.button:SetPoint('TOPLEFT', blizOptionsPanel, 'TOPLEFT', 20, -20)
if InterfaceOptions_AddCategory then
	InterfaceOptions_AddCategory(blizOptionsPanel)
elseif Settings then
	local category = Settings.RegisterCanvasLayoutCategory(blizOptionsPanel, "IceHUD")
	Settings.RegisterAddOnCategory(category)
end

function IceHUD:OpenConfig()
	if not ConfigDialog then return end

	if not self:LoadOptions() then
		return
	end

	if ConfigDialog.OpenFrames["IceHUD"] ~= nil then
		ConfigDialog:Close("IceHUD")
	else
		ConfigDialog:Open("IceHUD")
	end
end

function IceHUD:LoadOptions()
	if not self.optionsLoaded then
		local loaded, reason = LoadAddOn("IceHUD_Options")
		if not loaded then
			print("Failed to load options module. Reason: " .. reason)
			return false
		else
			self.optionsLoaded = true
		end
	end

	return true
end

function IceHUD:Debug(...)
	if self.debugging then
		local msg = ""
		for n=1,select('#', ...) do
			msg = msg .. tostring(select(n, ...)) .. " "
		end
		if self.debugFrame then
			self.debugFrame:AddMessage(msg)
		else
			print(msg)
		end
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
	if not unit or not ability then
		return 0, nil
	end

	if unit == "main hand weapon" or unit == "off hand weapon" then
		local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID
			= GetWeaponEnchantInfo()

		if unit == "main hand weapon" and hasMainHandEnchant then
			return mainHandCharges, nil
		elseif unit == "off hand weapon" and hasOffHandEnchant then
			return offHandCharges, nil
		end

		return 0, nil
	end

	-- Support for Spell IDs
	if (IceHUD.GetPlayerAuraBySpellID and tonumber(ability) ~= nil) then
		local aura = C_UnitAuras.GetPlayerAuraBySpellID(ability)
		if aura ~= nil then
			return aura.applications, nil
		else
			return 0, nil
		end
	end

	local i = 1
	local name, _, texture, applications
	if IceHUD.SpellFunctionsReturnRank then
		name, _, texture, applications = IceHUD.UnitAura(unit, i, auraType..(onlyMine and "|PLAYER" or ""))
	else
		name, texture, applications = IceHUD.UnitAura(unit, i, auraType..(onlyMine and "|PLAYER" or ""))
	end
	while name do
		if (not matchByName and string.match(texture:upper(), ability:upper()))
			or (matchByName and string.match(name:upper(), ability:upper())) then
			return applications, i
		end

		i = i + 1
		if IceHUD.SpellFunctionsReturnRank then
			name, _, texture, applications = IceHUD.UnitAura(unit, i, auraType..(onlyMine and "|PLAYER" or ""))
		else
			name, texture, applications = IceHUD.UnitAura(unit, i, auraType..(onlyMine and "|PLAYER" or ""))
		end
	end

	return 0, nil
end

do
	local retval = {}

	function IceHUD:HasBuffs(unit, spellIDs, filter)
		for i=1, #spellIDs do
			retval[i] = false
		end

		local i = 1
		local name, _, texture, applications, _, _, _, _, _, _, auraID
		if IceHUD.SpellFunctionsReturnRank then
			name, _, texture, applications, _, _, _, _, _, _, auraID = IceHUD.UnitAura(unit, i, filter)
		else
			name, texture, applications, _, _, _, _, _, _, auraID = IceHUD.UnitAura(unit, i, filter)
		end
		while name do
			for i=1, #spellIDs do
				if spellIDs[i] == auraID then
					retval[i] = applications == 0 and true or applications
					break
				end
			end

			i = i + 1
			if IceHUD.SpellFunctionsReturnRank then
				name, _, texture, applications, _, _, _, _, _, _, auraID = IceHUD.UnitAura(unit, i, filter)
			else
				name, texture, applications, _, _, _, _, _, _, auraID = IceHUD.UnitAura(unit, i, filter)
			end
		end

		return retval
	end

	function IceHUD:HasDebuffs(unit, spellIDs, filter)
		return IceHUD:HasBuffs(unit, spellIDs, filter and filter.."|HARMFUL" or "HARMFUL")
	end

	function IceHUD:HasAnyBuff(unit, spellIDs, filter)
		local buffs = IceHUD:HasBuffs(unit, spellIDs, filter)

		for i=1, #buffs do
			if buffs[i] then
				return true
			end
		end

		return false
	end

	function IceHUD:HasAnyDebuff(unit, spellIDs, filter)
		local debuffs = IceHUD:HasDebuffs(unit, spellIDs, filter)

		for i=1, #debuffs do
			if debuffs[i] then
				return true
			end
		end

		return false
	end
end

function IceHUD:OnDisable()
	IceHUD.IceCore:Disable()
end

function IceHUD:PreProfileChanged(db)
	if UnitAffectingCombat("player") then
		StaticPopup_Show("ICEHUD_CHANGED_PROFILE_COMBAT")
	end
	self.IceCore:Disable()
end

function IceHUD:PostProfileChanged(db, newProfile)
	self:NotifyNewDb()
	if self.db.profile.enable then
		self.IceCore:Enable()
	end
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

function IceHUD:Register(element)
	assert(element, "Trying to register a nil module")
	if not bReadyToRegisterModules then
		pendingModuleLoads[#pendingModuleLoads+1] = element
	else
		self.IceCore:Register(element)
	end
end

function IceHUD:RegisterPendingModules()
	for i=1, #pendingModuleLoads do
		self.IceCore:Register(pendingModuleLoads[i])
	end
	pendingModuleLoads = {}
end

function IceHUD:UpdateMedia(event, mediatype, key)
	if not self.db.profile or not self.IceCore.enabled then
		return
	end

	if mediatype == "font" then
		if key == self.db.profile.fontFamily then
			IceHUD.IceCore:SetFontFamily(key)
		end
	elseif mediatype == "statusbar" then
		if self.TargetOfTarget and self.TargetOfTarget.moduleSettings.enabled and key == self.TargetOfTarget.moduleSettings.texture then
			self.TargetOfTarget:Redraw()
		end
	end
end

function IceHUD:CreateCustomModuleAndNotify(moduleKey, settings)
	local newMod = nil
	local popupMsg
	if moduleKey == "Bar" then -- custom bar
		newMod = IceCustomBar:new()
		popupMsg = "ICEHUD_CUSTOM_BAR_CREATED"
	elseif moduleKey == "Counter" then -- custom counter
		newMod = IceCustomCount:new()
		popupMsg = "ICEHUD_CUSTOM_COUNTER_CREATED"
	elseif moduleKey == "CounterBar" then -- custom counter bar
		newMod = IceCustomCounterBar:new()
		popupMsg = "ICEHUD_CUSTOM_COUNTER_BAR_CREATED"
	elseif moduleKey == "CD" then -- cooldown bar
		newMod = IceCustomCDBar:new()
		popupMsg = "ICEHUD_CUSTOM_CD_CREATED"
	elseif moduleKey == "Health" then -- custom health bar
		newMod = IceCustomHealth:new()
		popupMsg = "ICEHUD_CUSTOM_HEALTH_CREATED"
	elseif moduleKey == "Mana" then -- custom mana bar
		newMod = IceCustomMana:new()
		popupMsg = "ICEHUD_CUSTOM_MANA_CREATED"
	end

	if newMod ~= nil then
		IceHUD.IceCore:AddNewDynamicModule(newMod, settings)
		ConfigDialog:SelectGroup("IceHUD", "modules", newMod.elementName)
		StaticPopup_Show(popupMsg)
	end
end

local function CheckLFGMode(mode)
	return (mode ~= nil and mode ~= "abandonedInDungeon" and mode ~= "queued")
end

function IceHUD:GetIsInLFGGroup()
	if not GetLFGMode then
		return false
	end

	local mode, submode
	if LE_LFG_CATEGORY_LFD then
		mode, submode = GetLFGMode(LE_LFG_CATEGORY_LFD)
	else
		mode, submode = GetLFGMode()
	end
	local IsInLFGGroup = CheckLFGMode(mode)

	if not LE_LFG_CATEGORY_LFD then
		return IsInLFGGroup
	end

	if not IsInLFGGroup then
		mode, submode = GetLFGMode(LE_LFG_CATEGORY_RF)
		IsInLFGGroup = CheckLFGMode(mode)
	end
	if not IsInLFGGroup then
		mode, submode = GetLFGMode(LE_LFG_CATEGORY_SCENARIO)
		IsInLFGGroup = CheckLFGMode(mode)
	end
	if not IsInLFGGroup then
		mode, submode = GetLFGMode(LE_LFG_CATEGORY_LFR)
		IsInLFGGroup = CheckLFGMode(mode)
	end

	return IsInLFGGroup
end

function IceHUD:OutOfCombatWrapper(func)
	return function(...)
		return IceHUD:RunOnLeaveCombat(func, ...)
	end
end

do
	local in_combat = false
	local in_lockdown = false
	local actions_to_perform = {}
	local pool = setmetatable({}, {__mode='k'})
	function IceHUD:PLAYER_REGEN_ENABLED()
		in_combat = false
		in_lockdown = false
		for i, t in ipairs(actions_to_perform) do
			t.f(unpack(t, 1, t.n))
			actions_to_perform[i] = nil
			wipe(t)
			pool[t] = true
		end
	end
	function IceHUD:PLAYER_REGEN_DISABLED()
		in_combat = true
	end
	function IceHUD:RunOnLeaveCombat(func, ...)
		if not in_combat then
			-- out of combat, call right away and return
			func(...)
			return
		end
		if not in_lockdown then
			in_lockdown = InCombatLockdown() -- still in PLAYER_REGEN_DISABLED
			if not in_lockdown then
				func(...)
				return
			end
		end
		local t = next(pool) or {}
		pool[t] = nil

		t.f = func
		local n = select('#', ...)
		t.n = n
		for i = 1, n do
			t[i] = select(i, ...)
		end
		actions_to_perform[#actions_to_perform+1] = t
	end
end
