# Commented / Removed Code Archive

This file preserves old code that was removed from active source. It is not loaded by ESO.

## Old `kelaAddInfoTooltip` implementation

```lua
function kelaAddInfoTooltip()

	-- enable isResearchable icon for itemslot in inventory
	--local OldZO_GamepadInventoryRefreshItemList = ZO_GamepadInventory.RefreshItemList
	--ZO_GamepadInventory.RefreshItemList = function(control, ...) 
	local function newRefreshItemList(control, ...)
		local function GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
			return function(itemData)
				if filteredEquipSlot then
					return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
				end
				if nonEquipableFilterType then
					return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
				end
				return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
			end
		end
		local function GetCategoryTypeFromWeaponType(bagId, slotIndex)
			local weaponType = GetItemWeaponType(bagId, slotIndex)
			if weaponType == WEAPONTYPE_AXE or weaponType == WEAPONTYPE_HAMMER or weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_DAGGER then
				return GAMEPAD_WEAPON_CATEGORY_ONE_HANDED_MELEE
			elseif weaponType == WEAPONTYPE_TWO_HANDED_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_AXE or weaponType == WEAPONTYPE_TWO_HANDED_HAMMER then
				return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE
			elseif weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_LIGHTNING_STAFF then
				return GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF
			elseif weaponType == WEAPONTYPE_HEALING_STAFF then
				return GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF
			elseif weaponType == WEAPONTYPE_BOW then
				return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
			elseif weaponType ~= WEAPONTYPE_NONE then
				return GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED
			end
		end
		local function GetBestQuestItemCategoryDescription(questItemData)
			local questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_NOT_SLOTTABLE
			if CanQuickslotQuestItemById(questItemData.questItemId) then
				questItemCategory = GAMEPAD_QUEST_ITEM_CATEGORY_SLOTTABLE
			end
			return GetString("SI_GAMEPADQUESTITEMCATEGORY", questItemCategory)
		end		
		local function GetBestItemCategoryDescription(itemData)
			if itemData.itemType == ITEMTYPE_FURNISHING then
				local furnitureDataId = GetItemFurnitureDataId(itemData.bagId, itemData.slotIndex)
				if furnitureDataId ~= 0 then
					local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(furnitureDataId)
					if categoryId then
						local categoryName = GetFurnitureCategoryInfo(categoryId)
						if categoryName ~= "" then
							return categoryName
						end
					end
				end
			end
			local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
			if categoryType ==  GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
				local weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
				return GetString("SI_WEAPONTYPE", weaponType)
			elseif categoryType then
				return GetString("SI_GAMEPADWEAPONCATEGORY", categoryType)
			end
			local armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
			if armorType ~= ARMORTYPE_NONE then
				return GetString("SI_ARMORTYPE", armorType)
			end
			return ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
		end

		control.itemList:Clear()
		if control.categoryList:IsEmpty() then return end

		local targetCategoryData = control.categoryList:GetTargetData()
		local filteredEquipSlot = targetCategoryData.equipSlot
		local nonEquipableFilterType = targetCategoryData.filterType
		local filteredDataTable

		local isQuestItemFilter = nonEquipableFilterType == ITEMFILTERTYPE_QUEST
		--special case for quest items
		if isQuestItemFilter then
			filteredDataTable = {}
			local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
			for _, questItems in pairs(questCache) do
				for _, questItem in pairs(questItems) do
					table.insert(filteredDataTable, questItem)
					questItem.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestQuestItemCategoryDescription(questItem))
				end
			end
			table.sort(filteredDataTable, ZO_GamepadInventory_QuestItemSortComparator)
		else
			local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)

			filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
			for _, itemData in pairs(filteredDataTable) do
				itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
			end
			table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)
		end

		local lastBestItemCategoryName
		for i, itemData in ipairs(filteredDataTable) do
			
			
			local CHECKED_ICON1 = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds"
			local CHECKED_ICON2 = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds"
			
			local nextItemData = filteredDataTable[i + 1]

			local entryData = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
			entryData:InitializeInventoryVisualData(itemData)

			if itemData.bagId == BAG_WORN then
				entryData.isEquippedInCurrentCategory = itemData.slotIndex == filteredEquipSlot
				entryData.isEquippedInAnotherCategory = itemData.slotIndex ~= filteredEquipSlot
				entryData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE)
			elseif isQuestItemFilter then
				local slotIndex = FindActionSlotMatchingSimpleAction(ACTION_TYPE_QUEST_ITEM, itemData.questItemId)
				entryData.isEquippedInCurrentCategory = slotIndex ~= nil
			else
				local slotIndex = FindActionSlotMatchingItem(itemData.bagId, itemData.slotIndex)
				entryData.isEquippedInCurrentCategory = slotIndex ~= nil
			end

			local remaining, duration
			if isQuestItemFilter then
				if itemData.toolIndex then
					remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
				elseif itemData.stepIndex and itemData.conditionIndex then
					remaining, duration = GetQuestItemCooldownInfo(itemData.questIndex, itemData.stepIndex, itemData.conditionIndex)
				end

				ZO_InventorySlot_SetType(entryData, SLOT_TYPE_QUEST_ITEM)
			else
				remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)

				ZO_InventorySlot_SetType(entryData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
			end
			if remaining > 0 and duration > 0 then
				entryData:SetCooldown(remaining, duration)
			end
			-- enable isresearchable icon for itemslot (ZO_SharedGamepadEntryStatusIndicatorSetup)
			--entryData:SetIgnoreTraitInformation(true)
			entryData:SetIgnoreTraitInformation(false)
			if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
				lastBestItemCategoryName = itemData.bestItemCategoryName

				entryData:SetHeader(lastBestItemCategoryName)
				control.itemList:AddEntry("ZO_GamepadItemSubEntryTemplateWithHeader", entryData)
			else
				control.itemList:AddEntry("ZO_GamepadItemSubEntryTemplate", entryData)
			end
		end
		control.itemList:Commit()
		
		
		
		-- local ret = OldZO_GamepadInventoryRefreshItemList(control, ...) 	
		-- return ret	
	end



	-- -- quest switching in the main menu
	-- local function moveToNextQuest (right)
	-- 	local questIndex = QUEST_JOURNAL_MANAGER:GetFocusedQuestIndex()
	-- 	local index
	-- 	if QUEST_JOURNAL_MANAGER.quests then
	-- 		for i, quest in ipairs(QUEST_JOURNAL_MANAGER.quests) do
	-- 			if quest.questIndex == questIndex then
	-- 				local nextQuest 
	-- 				if right then
	-- 					nextQuest = (i == #QUEST_JOURNAL_MANAGER.quests) and 1 or (i + 1)
	-- 				else
	-- 					nextQuest = (i == 1) and #QUEST_JOURNAL_MANAGER.quests or (i - 1)
	-- 				end
	-- 				index = QUEST_JOURNAL_MANAGER.quests[nextQuest].questIndex
	-- 				break
	-- 			end
	-- 		end
	-- 	end		
	-- 	QUEST_JOURNAL_GAMEPAD:FireCallbacks("QuestSelected", index)
	-- 	ZO_ZoneStories_Manager.StopZoneStoryTracking()
	-- 	FOCUSED_QUEST_TRACKER:ForceAssist(index)
	-- 	QUEST_JOURNAL_GAMEPAD:RefreshQuestList()
	-- end
	
	-- KelaPadUI.kelaMainMenuKeybindStripDescriptor =
	-- 	{
	-- 		{
	-- 			alignment = KEYBIND_STRIP_ALIGN_CENTER,	
	-- 			name = GetString(KELA_SETSKEY_VIEW),
	-- 			keybind = "UI_SHORTCUT_INPUT_LEFT",
	-- 			ethereal = true,
	-- 			visible = function()
	-- 					return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) and KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_QUEST) 
	-- 				end,
	-- 			callback = function()
	-- 					if KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) and KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_QUEST)  then 
	-- 						moveToNextQuest(false)
	-- 						kelaAddInfoTooltipMain()
	-- 					end
	-- 				end,
	-- 		},
	-- 		{
	-- 			alignment = KEYBIND_STRIP_ALIGN_CENTER,	
	-- 			name = GetString(KELA_SETSKEY_VIEW),
	-- 			keybind = "UI_SHORTCUT_INPUT_RIGHT",
	-- 			ethereal = true,
	-- 			visible = function()
	-- 					return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) and KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_QUEST) 
	-- 				end,
	-- 			callback = function()
	-- 					if KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) and KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_QUEST)  then 
	-- 						moveToNextQuest(true)
	-- 						kelaAddInfoTooltipMain()
	-- 					end
	-- 				end,
	-- 		},
	-- 		{
	-- 		alignment = function()		
	-- 					if KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) then
	-- 						return KEYBIND_STRIP_ALIGN_RIGHT
	-- 					else
	-- 						return KEYBIND_STRIP_ALIGN_CENTER
	-- 					end
	-- 			end,
	-- 		name = GetString(KELA_MAINMENU_QUICKACCESS),
	-- 		keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
	-- 			visible = function()
	-- 					return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_QUICKACCESS_ENABLED) and (KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_QUICKACCESS_QUEST) or KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_QUICKACCESS_MAIL))
	-- 				end,
	-- 		callback = function()		
	-- 					MAIN_MENU_GAMEPAD:ShowScene("kelaQuickAccess")
	-- 			end,
	-- 		},
			
	-- 		-- Achievement Tracker
	-- 		-- {
	-- 		-- 	alignment = KEYBIND_STRIP_ALIGN_CENTER,	
	-- 		-- 	name = GetString(KELA_SETSKEY_CLEARSEARCH),
	-- 		-- 	keybind = "UI_SHORTCUT_SECONDARY",
	-- 		-- 	visible = function()
	-- 		-- 			return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ACHIVTRACK) and ACHIEVEMENTS_GAMEPAD.visibleCategoryId ~= nil
	-- 		-- 		end,
	-- 		-- 	callback = function()
	-- 		-- 			CHAT_SYSTEM:AddMessage(GetString(KELA_SETSKEY_CLEARSEARCH))
	-- 		-- 		end,
	-- 		-- }
	-- 		-- table.insert(ACHIEVEMENTS_GAMEPAD.keybindStripDescriptor, keybind)
	-- 	}
 

	-- show the information window in the main menu root, add buttons
	-- local mainMenuGamepadScene = SCENE_MANAGER.scenes.mainMenuGamepad
	-- mainMenuGamepadScene:RegisterCallback("StateChange", function(oldState, newState) 
	-- 	-- states: hiding, showing, shown, hidden
	-- 	if(newState == "showing") then
	-- 		--buttons
	-- 		KEYBIND_STRIP:AddKeybindButtonGroup(KelaPadUI.kelaMainMenuKeybindStripDescriptor)
	-- 		if KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_MAININFO_ENABLED) then
	-- 			kelaAddInfoTooltipMain()
	-- 			--hide the progress bar at the bottom
	-- 			PLAYER_SUBMENU_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 			GAMEPAD_STATS_ROOT_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 			MAIN_MENU_GAMEPAD_SCENE:RemoveFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 		else
	-- 			--show the progress bar at the bottom
	-- 			PLAYER_SUBMENU_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 			GAMEPAD_STATS_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 			MAIN_MENU_GAMEPAD_SCENE:AddFragmentGroup(FRAGMENT_GROUP.PLAYER_PROGRESS_BAR_GAMEPAD_CURRENT)
	-- 		end
	-- 	elseif(newState == "hiding") then
	-- 		KEYBIND_STRIP:RemoveKeybindButtonGroup(KelaPadUI.kelaMainMenuKeybindStripDescriptor)
	-- 		KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_LEFT_TOOLTIP, false)
	-- 		KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_RIGHT_TOOLTIP, false)
	-- 		SCENE_MANAGER:RemoveFragment(KPUI_GAMEPAD_TOOLTIPS:GetTooltipFragment(KPUI_GAMEPAD_LEFT_TOOLTIP))
	-- 		SCENE_MANAGER:RemoveFragment(KPUI_GAMEPAD_TOOLTIPS:GetTooltipBgFragment(KPUI_GAMEPAD_LEFT_TOOLTIP))
	-- 		SCENE_MANAGER:RemoveFragment(KPUI_GAMEPAD_TOOLTIPS:GetTooltipFragment(KPUI_GAMEPAD_RIGHT_TOOLTIP))
	-- 		SCENE_MANAGER:RemoveFragment(KPUI_GAMEPAD_TOOLTIPS:GetTooltipBgFragment(KPUI_GAMEPAD_RIGHT_TOOLTIP))	
	-- 	end
	-- end) 

end
	
```

## Old `AddGamepadRallyPoint` experiment

```lua
local function AddGamepadRallyPoint()
	SecurePostHook(ZO_WorldMapManager, "InitializeKeybinds", function(self)
		CHAT_SYSTEM:AddMessage("Initializing Group Rally Point Map Option")
		self.keybindDescriptor_GroupRally = {
            name = function()
                if self.g_keybindStrips.gamepad:IsOverPinType(MAP_PIN_TYPE_RALLY_POINT) then
                    return GetString(SI_WORLD_MAP_ACTION_REMOVE_RALLY_POINT)
                else
                    return GetString(SI_TOOLTIP_UNIT_MAP_RALLY_POINT)
                end
            end,
            keybind = "UI_SHORTCUT_LEFT_SHOULDER", --"UI_SHORTCUT_QUINARY",
            -- visible = function()
            --     return not IsShowingCosmicMap() and IsMouseOverMap()
            -- end,
            callback = function()
                if self.g_keybindStrips.gamepad:IsOverPinType(MAP_PIN_TYPE_RALLY_POINT) then
                    RemoveRallyPoint()
                else
                    local x, y = NormalizePreferredMousePositionToMap()
                    if ZO_WorldMap_IsNormalizedPointInsideMapBounds(x, y) then
						PingMap(MAP_PIN_TYPE_RALLY_POINT, MAP_TYPE_LOCATION_CENTERED, x, y)
                        self.g_keybindStrips.gamepad:DoMouseEnterForPinType(MAP_PIN_TYPE_RALLY_POINT) -- this should have been called by the mouseover update, but it's not getting called
                    end
                end
            end,
        }

		local mapDescriptor = self.g_keybindStrips.gamepad.GetDescriptor()
		table.insert(mapDescriptor, self.keybindDescriptor_GroupRally)
		self.g_keybindStrips.gamepad = ZO_MapMouseoverKeybindStrip:New(self.control, mapDescriptor)

	end)
end

```

## Old commented core overrides at the end of KelaPadUI.lua

```lua
-- UPDATE: This was patched January 9th, 2023
-- Fixes Mail Link Tooltip bug for gear
-- ZO_GamepadLinks.Show = function (control)
--     local linkData = control:GetCurrentLink()
--     if linkData and linkData.linkType then
--         local previousLink = control.showingLinkData
--         local link = linkData.link
--         local useKeybindDescriptor = control.keybindStripDescriptor and control.keybindStripDescriptor[1] or nil
--         local actionName = useKeybindDescriptor and useKeybindDescriptor.keybind or nil

--         -- Show current link.
--         --if GAMEPAD_TOOLTIPS:LayoutLink(self.gamepadTooltip, link, actionName) then
-- 		if GAMEPAD_TOOLTIPS:LayoutLink(control.gamepadTooltip, link) then
--             control.showingLinkData = linkData
--             control:OnLinkShown(control.showingLinkData, previousLink)
--             return
--         end
--     end

--     control:Hide()
-- end

-- Fixes Mailbox Layout from shrinking too much when an item link is displayed
-- OLD_ZO_MailInbox_Gamepad_UpdateLinks = ZO_MailInbox_Gamepad.UpdateLinks
-- ZO_MailInbox_Gamepad.UpdateLinks = function (control, ...)
--     if control.inboxControl:IsHidden() then
--         control.activeLinks:Hide()
--         return
--     end

--     -- Extract and register any links found in the Guild's
--     -- Message of the Day and Description (About Us) text.
--     control.activeLinks:ResetLinks()

--     local bodyText = control.inbox.bodyEdit.edit:GetText()
--     if bodyText ~= "" then
--         control.activeLinks:AddLinksFromText(bodyText)
--     end

--     if control.activeLinks:HasLinks() then
--         --self.inboxRightPane:SetWidth(ZO_GAMEPAD_QUADRANT_2_3_WIDTH) -- ZO_GAMEPAD_QUADRANT_2_3_CONTAINER_WIDTH, ZO_GAMEPAD_QUADRANT_2_3_WIDTH
-- 		control.inboxRightPane:SetWidth(ZO_GAMEPAD_QUADRANT_2_3_4_WIDTH + ZO_GAMEPAD_QUADRANT_4_RIGHT_OFFSET * 2) -- ZO_GAMEPAD_QUADRANT_2_3_CONTAINER_WIDTH, ZO_GAMEPAD_QUADRANT_2_3_WIDTH
-- 		control.activeLinks:Show()
--     else
--         control.inboxRightPane:SetWidth(ZO_GAMEPAD_QUADRANT_2_3_4_WIDTH)
--         control.activeLinks:Hide()
--     end
-- end
```
