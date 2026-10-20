KelaPadUI = {
	name = "KelaPadUI",	
	displayName = "|cFF00FF" .. "KelaPadUI interface for Gamepad UI" .. "|r",
}

local _initialized = false

--KelaPadUI scenes
local kelaSetsScene = SCENE_MANAGER:GetScene("kelaSets")
GAMEPAD_SETS_LIST_FRAGMENT = ZO_FadeSceneFragment:New(Kela_Sets_List_Gamepad)
kelaSetsScene:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
kelaSetsScene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_RIGHT)
kelaSetsScene:AddFragment(GAMEPAD_SETS_LIST_FRAGMENT)
kelaSetsScene:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
kelaSetsScene:AddFragment(GAMEPAD_NAV_QUADRANT_2_3_4_BACKGROUND_FRAGMENT)
kelaSetsScene:AddFragment(MINIMIZE_CHAT_FRAGMENT)
kelaSetsScene:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
GAMEPAD_TOOLTIPS:AddTooltipInstantScene(GAMEPAD_RIGHT_TOOLTIP, kelaSetsScene)

-----------------------
--Options Root Scene
-----------------------
KELA_OPTIONS_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
KELA_OPTIONS_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
KELA_OPTIONS_ROOT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SYSTEM)
KELA_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
KELA_OPTIONS_ROOT_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
KELA_OPTIONS_ROOT_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
KELA_OPTIONS_ROOT_SCENE:AddFragment(KELA_OPTIONS_FRAGMENT)
KELA_OPTIONS_ROOT_SCENE:AddFragment(KELA_OPTIONS:GetHeaderFragment())

-----------------------
--Options Panel Scene
-----------------------
KELA_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
KELA_OPTIONS_PANEL_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD_OPTIONS)
KELA_OPTIONS_PANEL_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_SYSTEM)
KELA_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
KELA_OPTIONS_PANEL_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
KELA_OPTIONS_PANEL_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)
KELA_OPTIONS_PANEL_SCENE:AddFragment(KELA_OPTIONS_FRAGMENT)
KELA_OPTIONS_PANEL_SCENE:AddFragment(KELA_OPTIONS:GetHeaderFragment())

	-- show info tooltip

function KelaSetupTooltips()
	local tooltipLeft = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
	local tooltipRight = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP)	
	local tooltipQuad1 = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_QUAD1_TOOLTIP)	
	local tooltipMove = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP)
	local tooltipLeftDialog = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_DIALOG_TOOLTIP)	
	local tooltipQuad3 = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_QUAD3_TOOLTIP)		

	local tooltipChamp1 =  ZO_ChampionPerksChosenConstellationGamepadLeftTooltipContainerTipScrollScrollChildTooltip
	local tooltipChamp2 =  ZO_ChampionPerksChosenConstellationGamepadRightTooltipContainerTipScrollScrollChildTooltip

	kelaTotalRedefineStyles()

	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_LEFT_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)	
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_WIDE_SETS_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDE_WIDTH)
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_WIDE_CRAFTING_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDE_WIDTH)
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_WIDE_RESEARCH_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDE_WIDTH)
		
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:ClearAnchors()
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 535, 53) 
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 535, -125) 
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)

	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control:ClearAnchors()
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -10, 53) 
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -10, -125) 
	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)
	
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_RIGHT_TOOLTIP.control:ClearAnchors()
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_RIGHT_TOOLTIP.control:SetAnchor(TOPRIGHT, GuiRoot, TOPRIGHT, -10, 53) 
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_RIGHT_TOOLTIP.control:SetAnchor(BOTTOMRIGHT, GuiRoot, BOTTOMRIGHT, -10, -125) 		
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_RIGHT_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)		
	
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_MAIN_TOOLTIP.control:ClearAnchors()
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_MAIN_TOOLTIP.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 56, 53) 
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_MAIN_TOOLTIP.control:SetAnchor(BOTTOMLEFT, GuiRoot, BOTTOMLEFT, 56, -125) 		
	KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_MAIN_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)		

	-- GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_MOVABLE_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)
	-- GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_DIALOG_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)
	-- GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_QUAD3_TOOLTIP.control:SetWidth(KELA_TOOLTIPS_WIDTH)	

	LOOT_WINDOW_GAMEPAD.control:ClearAnchors()
	LOOT_WINDOW_GAMEPAD.control:SetAnchor(TOPRIGHT, GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control, TOPLEFT, -5, 0) 
	LOOT_WINDOW_GAMEPAD.control:SetAnchor(BOTTOMRIGHT, GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_RIGHT_TOOLTIP.control, BOTTOMLEFT, -5, 0) 
	LOOT_WINDOW_GAMEPAD.control:SetWidth(520)		
	


	kelaReplaceTooltips (tooltipLeft)
	kelaReplaceTooltips (tooltipRight)
	kelaReplaceTooltipQuad1 (tooltipQuad1)
	-- kelaReplaceTooltipChamps (tooltipChamp1)
	-- kelaReplaceTooltipChamps (tooltipChamp2)
	-- kelaReplaceTooltips (GAMEPAD_QUAD3_TOOLTIP)


	ZO_CRAFTING_TOOLTIP_STYLES = ZO_DeepTableCopy(ZO_TOOLTIP_STYLES)
	for key,value in pairs(ZO_CRAFTING_TOOLTIP_STYLES) do
		value["horizontalAlignment"] = TEXT_ALIGN_CENTER

		if key ~= "topSection" then
			value["layoutPrimaryDirectionCentered"] = true
		end
	end

end



local function KelaPadUI_OnLoaded(eventType, addonName)
	if _initialized then return end
	if addonName ~= "KelaPadUI" then return end
	EVENT_MANAGER:UnregisterForEvent("KelaPadUI", EVENT_ADD_ON_LOADED)

	KelaPadUI.unitName = zo_strformat("<<1>>", GetUnitName("player"))
	KelaInitializeSettings()

	local function IsFeatureEnabled(settingId)
		return KelaGetSetting_Bool(SETTING_TYPE_KELA, settingId)
	end

	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_ANTIQUITY_FILTERS) then
		KelaSetupAntiquityFilters()
	end
	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_ANTIQUITY_LEADS) then
		KelaSetupAntiquityLeadInfo()
	end

	KELA_SETS_LIST:SetMasterSetsList()

	local hasTradingDependencies = TamrielTradeCentre ~= nil and ArkadiusTradeTools ~= nil
	if hasTradingDependencies and IsFeatureEnabled(KELA_SETTING_PANEL_TRADE_ENABLED) then
		KelaInitializeTradingHistory()
		KelaSetupTradingHouse()
		KelaSetupCraftingStation()
	elseif not hasTradingDependencies then
		KelaSetSetting(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED, false)
	end

	-- Extra functions added
	KelaSetupTooltips()
	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_COMPANION) then
		KelaSetupCompanionInfo()
	end
	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_DUNGEON_FINDER) then
		KelaSetupDungeonFinder()
	end
	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_CHAT_TOOLS) then
		KelaSetupChatTools()
	end
	if IsFeatureEnabled(KELA_SETTING_PANEL_FEATURES_MAP_RALLY) then
		KelaSetupMapRally()
	end

	_initialized = true

end


local function OnGamepadPreferredModeChanged(eventType, addonName)
	--_initialized = false
	if IsInGamepadPreferredMode() then
		KelaPadUI_OnLoaded (eventType, addonName)
	end		
end

EVENT_MANAGER:RegisterForEvent("KelaPadUI", EVENT_ADD_ON_LOADED, KelaPadUI_OnLoaded)
EVENT_MANAGER:RegisterForEvent("KelaPadUI", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(code, inGamepad)  OnGamepadPreferredModeChanged(EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, KelaPadUI.name) end)


-- EVENT_MANAGER:RegisterForEvent("testtest", EVENT_ACTION_LAYER_POPPED, testtest)



