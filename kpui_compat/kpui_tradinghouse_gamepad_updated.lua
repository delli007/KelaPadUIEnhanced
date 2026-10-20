-- COMPATIBILITY COPY: This is the copied trading-house implementation retained
-- for the cautious refactor phase. Rebuild it with core hooks and small custom
-- controls in a future pass. See OPTIMIZATION_TODO.md before changing it.


local lib = LIB_ITEM_LINK
local colors = kpuiConst.Colors	
-- KPUI_ATTGraph = nil

KELA_KNOWN_ITEM_FILTER = "ALL"
KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX = 1

KELA_TRADINGHOUSE_CURRENTSCENE = ""
KELA_TRADINGHOUSE_CURRENT_SELECTEDDATA = {}

local hookCraftingStationAlready = false
local hookCraftingStationKeybindAlready = false
local hookProvisionerTooltipAlready = false
local hookCreationTooltipAlready = false
local hookDeconstructTooltipAlready = false
local hookRefineTooltipAlready = false
local hookAlchemyTooltipAlready = false
local hookEnchantingTooltipAlready = false

				
local hookTradingHouseAlready = false
local hookBankingAlready = false
local hookStoregAlready = false
local hookATTAlready = false

-- local KELA_QUALITY_NORMAL = 366
-- local KELA_QUALITY_FINE = 367
-- local KELA_QUALITY_SUPERIOR = 368
-- local KELA_QUALITY_EPIC = 369
-- local KELA_QUALITY_LEGENDARY = 370

KELA_TRADING_TOOLTIP_TYPE_SMITHING = 1
KELA_TRADING_TOOLTIP_TYPE_TRADINGHOUSE = 2

KELA_SMITHING_IMPROVED_TOOLTIP_TYPE = 0

local function KelaCreateColorizedResumePrice(index)
	local label = GetString("KELA_TRADING_RESUMEPRICE", index)
	if index == 5 then 
		color = colors.COLOR_DEALGREAT
	elseif index == 4 then 
		color = colors.COLOR_DEALGOOD
	elseif index == 3 then 
		color = colors.COLOR_DEALNORMAL
	elseif index == 2 then 
		color = colors.COLOR_WHITE
	elseif index == 1 then 
		return label
	end
	return color:Colorize(label)
end	


function KelaIsSceneTradingHouse(currentScene)
	return (currentScene == "TRADING_HOUSE_CREATE_LISTING_GAMEPAD" or currentScene == "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS" or currentScene == "GAMEPAD_TRADING_HOUSE_LISTINGS" or currentScene == "GAMEPAD_TRADING_HOUSE_SELL")
end




-- local subIdToQuality = { }
local function GetItemLinks(itemLink)

	local function GetQualityItemLink(itemId, itemQuality, itemLevel, itemChampionPoints, enchantId)
		if itemId == nil or itemId == 0 then return end
		-- LibItemLink
		-- Generates an item link
		--- itemId = any itemId of a valid item
		--- itemQuality = number - any valid quality type like ITEM_QUALITY_NORMAL (optional)
		--- itemLevel = number 1-50 - if it's not a champion item, define the level (optional)
		--- itemChampionPoints = number 0-160 - if you want to create a cp item (optional)
		--- itemStyle = number - choose a motif style (optional)
		--- isCrafted = boolean - if it's a crafted item (optional)
		--- enchantId = number 1-unknown - if you want to add any enchantment to your item (optional)
		--- enchantQuality = number - any valid quality type like ITEM_QUALITY_LEGENDARY (optional)
		--- linkStyle = if you want some brackets or not (optional)
		--CHAT_SYSTEM:AddMessage("Getting item link for "..itemId.." "..itemQuality.." "..itemLevel.." "..itemChampionPoints.." "..enchantId)
		tlink = lib:BuildItemLink(tonumber(itemId), tonumber(itemQuality), tonumber(itemLevel), tonumber(itemChampionPoints), nil, nil, tonumber(enchantId))	
		--CHAT_SYSTEM:AddMessage(tlink.." "..GetItemLinkQuality(tlink))
		return tlink
	end
	
	local resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink
	local minLevel, minChampionPoints
	local referenceEnchantID
	local itemType = GetItemLinkItemType(itemLink) 
	local itemId = GetItemLinkItemId(itemLink)
	local referenceQuality = GetItemLinkQuality(itemLink)
	
	--CHAT_SYSTEM:AddMessage(GetString("SI_ITEMTYPE", itemType))
	
	-- if itemType == ITEMTYPE_RECIPE or itemType == ITEMTYPE_BLACKSMITHING_RAW_MATERIAL or itemType == ITEMTYPE_CLOTHIER_RAW_MATERIAL or itemType == ITEMTYPE_WOODWORKING_RAW_MATERIAL or itemType == ITEMTYPE_JEWELRYCRAFTING_RAW_MATERIAL then
		if itemType == ITEMTYPE_RECIPE then
			resultItemLink = GetItemLinkRecipeResultItemLink(itemLink)
		else
			resultItemLink = GetItemLinkRefinedMaterialItemLink(itemLink)
		end
	-- end

	
	if itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON then
		minLevel, minChampionPoints = GetItemLinkGlyphMinLevels(itemLink)
		referenceEnchantID = GetItemLinkFinalEnchantId(itemLink)
	elseif itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
		minLevel = GetItemLinkRequiredLevel(itemLink)
		minChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
		referenceEnchantID = GetItemLinkFinalEnchantId(itemLink)
	end

	if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON or itemType == ITEMTYPE_WEAPON then		
		if referenceQuality ~= ITEM_QUALITY_NORMAL then normalItemLink = GetQualityItemLink(itemId, ITEM_QUALITY_NORMAL, minLevel, minChampionPoints, referenceEnchantID) end
		if referenceQuality ~= ITEM_QUALITY_MAGIC then fineItemLink = GetQualityItemLink(itemId, ITEM_QUALITY_MAGIC, minLevel, minChampionPoints, referenceEnchantID) end
		if referenceQuality ~= ITEM_QUALITY_ARCANE then superiorItemLink = GetQualityItemLink(itemId, ITEM_QUALITY_ARCANE, minLevel, minChampionPoints, referenceEnchantID) end
		if referenceQuality ~= ITEM_QUALITY_ARTIFACT then epicItemLink = GetQualityItemLink(itemId, ITEM_QUALITY_ARTIFACT, minLevel, minChampionPoints, referenceEnchantID) end
		if referenceQuality ~= ITEM_QUALITY_LEGENDARY then legendaryItemLink = GetQualityItemLink(itemId, ITEM_QUALITY_LEGENDARY, minLevel, minChampionPoints, referenceEnchantID) end
	
		-- Additional check to make sure the item link returned is the quality we're looking for
		if normalItemLink and GetItemLinkQuality(normalItemLink) ~= ITEM_QUALITY_NORMAL then normalItemLink = nil end
		if fineItemLink and GetItemLinkQuality(fineItemLink) ~= ITEM_QUALITY_MAGIC then fineItemLink = nil end
		if superiorItemLink and GetItemLinkQuality(superiorItemLink) ~= ITEM_QUALITY_ARCANE then superiorItemLink = nil end
		if epicItemLink and GetItemLinkQuality(epicItemLink) ~= ITEM_QUALITY_ARTIFACT then epicItemLink = nil end
		if legendaryItemLink and GetItemLinkQuality(legendaryItemLink) ~= ITEM_QUALITY_LEGENDARY then legendaryItemLink = nil end
		
	end	

	return resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink

end
local function GetBuyInfo(tblBuyingItems, itemUID)
	local strBuyInfo = ""
	local guildName = tblBuyingItems[itemUID]["guildName"]
	local buyingTime = colors.COLOR_WHITE:Colorize(KelaTimeStampToDateTimeString(tblBuyingItems[itemUID]["buyingTimeStamp"]))
	local buyPrice = tblBuyingItems[itemUID]["buyPrice"]
	local buyPricePerUnit = tblBuyingItems[itemUID]["buyPricePerUnit"]
	local buyStackCount = KelaLocalizedFormatNumber(buyPrice/buyPricePerUnit)
	local iconCoin = zo_iconFormat(GetCurrencyGamepadIcon(CURT_MONEY), 20, 20)
	strBuyInfo = "* "..GetString(KELA_TRADING_BOUGHT)..buyingTime..GetString(KELA_TRADING_BOUGHT_FOR)..colors.COLOR_WHITE:Colorize(KelaLocalizedFormatNumber(buyPrice)..iconCoin)
	-- if buyPrice ~= buyPricePerUnit then
		strBuyInfo = strBuyInfo.." ("..buyStackCount.."*"..KelaLocalizedFormatNumber(buyPricePerUnit)..")"
	-- end					
	if guildName ~= "" then
		local guildColor = colors.COLOR_WHITE
		if ArkadiusTradeTools ~= nil then
			guildColor = ArkadiusTradeTools:GetGuildColor(guildName)
		end
		guildName = guildColor:Colorize(guildName)					
		strBuyInfo = strBuyInfo.." in guild "..guildName
	end

	local colorQuality
	local strQuality = ""
	local displayQuality = tblBuyingItems[itemUID]["displayQuality"]
	local itemType = GetItemLinkItemType(itemLink)
	if displayQuality and (itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON) then 
		colorQuality = GetItemQualityColor(displayQuality) 
		strBuyInfo = strBuyInfo.." ("..colorQuality:Colorize(GetString("SI_ITEMDISPLAYQUALITY", displayQuality))..")"
	end	
	return strBuyInfo
end
local function HideTradingTooltipControls()
	if ctlItemTypeGuildStat then ctlItemTypeGuildStat:SetHidden(true) end	
	if ctlTradingInfo then ctlTradingInfo:SetHidden(true) end						
	if KPUI_ATTGraph then KPUI_ATTGraph:SetHidden(true) end	
	if ctlPreviousListings then ctlPreviousListings:SetHidden(true) end		
	if ctlOtherQualityInfo then ctlOtherQualityInfo:SetHidden(true) end				
	if ctlProductMaterialInfoRow then ctlProductMaterialInfoRow:SetHidden(true) end	
	if ctlCraftingInfo then ctlCraftingInfo:SetHidden(true) end			
end
local function HideImprovementTooltipControls(hide)
	local function hideSource()
		if ctlSourceInfo then ctlSourceInfo:SetHidden(true) end	
		if ctlSourceGraph then ctlSourceGraph:SetHidden(true) end					
		if ctlSourceNotes then ctlSourceNotes:SetHidden(true) end
		if ctlSourceListings then ctlSourceListings:SetHidden(true) end	
		if ctlSourceOther then ctlSourceOther:SetHidden(true) end	
	end
	local function hideResult()
		if ctlResultInfo then ctlResultInfo:SetHidden(true) end						
		if ctlResultGraph then ctlResultGraph:SetHidden(true) end	
		if ctlResultNotes then ctlResultNotes:SetHidden(true) end
		if ctlResultListings then ctlResultListings:SetHidden(true) end	
		if ctlResultOther then ctlResultOther:SetHidden(true) end	
	end
	if hide == "source" then
		hideSource()
	elseif hide == "result" then
		hideResult()
	else
		hideSource()
		hideResult()
	end
end
local function HideProvisionerTooltipControls()
	if ctlProvisionerInfo then ctlProvisionerInfo:SetHidden(true) end	
	if ctlProvisionerGraph then ctlProvisionerGraph:SetHidden(true) end						
	if ctlProvisionerListings then ctlProvisionerListings:SetHidden(true) end				
end
local function HideCreationTooltipControls()
	if ctlCreationInfo then ctlCreationInfo:SetHidden(true) end	
	if ctlCreationGraph then ctlCreationGraph:SetHidden(true) end						
	if ctlCreationListings then ctlCreationListings:SetHidden(true) end					
	if ctlCreationOther then ctlCreationOther:SetHidden(true) end				
end
local function HideAlchemyTooltipControls()
	if ctlAlchemyInfo then ctlAlchemyInfo:SetHidden(true) end	
	if ctlAlchemyGraph then ctlAlchemyGraph:SetHidden(true) end						
	if ctlAlchemyListings then ctlAlchemyListings:SetHidden(true) end					
end
local function HideEnchantingTooltipControls()
	if ctlEnchantingInfo then ctlEnchantingInfo:SetHidden(true) end	
	if ctlEnchantingGraph then ctlEnchantingGraph:SetHidden(true) end						
	if ctlEnchantingListings then ctlEnchantingListings:SetHidden(true) end	
	if ctlEnchantingOther then ctlEnchantingOther:SetHidden(true) end		
end

-- functions that add modules to the information window
local function AddClearLine(tooltip, lastControl, x, y)
	-- empty line
	if not x then x = 0 end
	if not y then y = 0 end
	local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
	bodySection:AddLine(" ")
	-- bodySection:AddLine(" ")
	tooltip:AddSection(bodySection)
	bodySection:ClearAnchors()
	bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, x, y)
	bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, x, y)					
	return bodySection
end
local function SetSmithTradingInfo (ctlSmithTradingInfo, lastControl, priceInfoTTC, priceInfoATT, currentScene, selectedData, stackCount)
	ctlSmithTradingInfo:ClearAnchors()
	ctlSmithTradingInfo:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 15)
	ctlSmithTradingInfo:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 15)
	ctlSmithTradingInfo:SetHidden(false)
	return ctlSmithTradingInfo.SetItemInfo(priceInfoTTC, priceInfoATT, currentScene, selectedData, stackCount)
end
local function SetSmithGraph (ctlSmithGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, stackCount)
	ctlSmithGraph:ClearAnchors()
	ctlSmithGraph:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 10, 0)
	ctlSmithGraph:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, -10, 0)
	KelaUpdateATTGraph(itemLink, ctlSmithGraph, priceInfoATT.SuggestedPrice, priceInfoTTC.SuggestedPrice)
	ctlSmithGraph:SetHidden(false)
	local stackCountGuild
	if priceInfoATT.Vouchers ~= 0 then
		stackCountGuild = priceInfoATT.Vouchers
	else
		stackCountGuild = stackCount
	end
	return ctlSmithGraph.SetGuildSalesInfo(priceInfoATT.GuildsInfo, priceInfoATT.GuildsPrice, stackCountGuild, ctlSmithGraph)	
end
local function SetSmithNotes (tooltip, lastControl, strBuyInfo, ModFontSize)
	if not ModFontSize then ModFontSize = 20 end
	local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
	bodySection:AddLine(strBuyInfo, {fontSize = ModFontSize})
	tooltip:AddSection(bodySection)
	bodySection:ClearAnchors()
	bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
	bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
	return bodySection
end
local function SetSmithListings (ctlSmithListings, lastControl, listingItemsTable)
	ctlSmithListings:SetHidden(false)					
	return ctlSmithListings.SetPreviousListings(listingItemsTable, lastControl)
end
local function SetSmithQualityPrices(tooltip, ctlSmithOQInfo, lastControl, itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink) --, traitInformation, tooltip)
	lastControl = AddClearLine(tooltip, lastControl, 0, 15)
	ctlSmithOQInfo:SetHidden(false)	
	return ctlSmithOQInfo.SetOtherQualityPrices(itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink, lastControl)
end
local function SetProductionPrices(ctlProductionInfo, lastControl, resultItemLink, priceInfoTTC, priceInfoATT)
	ctlProductionInfo:SetHidden(false)	
	return ctlProductionInfo.SetRawProductPrices(resultItemLink, priceInfoTTC, priceInfoATT, lastControl)
end
local function SetCraftingComponents(ctlCraftingInfo, lastControl, craftingComponentPrices)
	ctlCraftingInfo:SetHidden(false)	
	return ctlCraftingInfo.SetItemPrices(craftingComponentPrices, lastControl)
end

--check the setting and the trading module
local function IsKPUITradingHouseSettingEnabled(setting)
	if setting then 
		return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED)	and KelaGetSetting_Bool(SETTING_TYPE_KELA, setting)		
	else
		return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED)
	end
end
function KelaSetupCraftingStation()

	if not hookCraftingStationAlready then

		-- alchemy crafting
		ZO_PreHook(ZO_GamepadAlchemy, "UpdateTooltip", function(control, ...)
				local ingredientsBar = control.control:GetNamedChild("SlotContainer")
				-- setting
				if not hookAlchemyTooltipAlready then
					control.tooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
					control.tooltip.tip:SetStyles(control.tooltip.tip:GetStyle("tooltip"))
					ingredientsBar:ClearAnchors()
					ingredientsBar:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, ZO_GAMEPAD_PROVISIONER_INGREDIENTS_BAR_OFFSET_X, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET + 30)
					control.tooltip:ClearAnchors()
					control.tooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -25)	
					if not ctlAlchemyTooltip then ctlAlchemyTooltip = CreateControlFromVirtual("$(parent)TradingTip", control.tooltip, "KPUI_CraftingTooltip") end
					ctlAlchemyTooltip:ClearAnchors()
					ctlAlchemyTooltip:SetAnchor(BOTTOMLEFT, control.tooltip, BOTTOMRIGHT, 38)
					ctlAlchemyTooltip:SetHidden(true)
					GAMEPAD_ALCHEMY_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
						if newState == SCENE_HIDDEN then
							if ctlAlchemyTooltip then 
								ctlAlchemyTooltip.tip:ClearLines()
								ctlAlchemyTooltip:SetHidden(true) 
							end
							HideAlchemyTooltipControls() -- fixes "too many achors processed" error
							
						end
					end)
					hookAlchemyTooltipAlready = true
				end	
			-- if KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED) then
				if control:IsCraftable() then
					control.tooltip:SetHidden(false)
					control.tooltip.tip:ClearLines()
					local solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex = control:GetAllCraftingBagAndSlots()
					local itemLink, prospectiveAlchemyResult = GetAlchemyResultingItemLink(solventBagId, solventSlotIndex, reagent1BagId, reagent1SlotIndex, reagent2BagId, reagent2SlotIndex, reagent3BagId, reagent3SlotIndex)
					local solventType = GetItemType(solventBagId, solventSlotIndex)
					local itemTypeString = GetString(solventType == ITEMTYPE_POTION_BASE and SI_ITEM_FORMAT_STR_POTION or SI_ITEM_FORMAT_STR_POISON)
					control.tooltip.tip:LayoutAlchemyPreview(itemLink, itemTypeString, prospectiveAlchemyResult)
					if ctlAlchemyTooltip and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then 
						if itemLink and prospectiveAlchemyResult > 1 then
							control.tooltip:ClearAnchors()
							control.tooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, -254, -25)
							local maxIterations = GetMaxIterationsPossibleForAlchemyItem(control:GetAllCraftingBagAndSlots())
							ZO_Tooltip:LayoutAlchemyTradingTooltip(ctlAlchemyTooltip, itemLink, maxIterations)
							ctlAlchemyTooltip:SetHidden(false) 
						else
							control.tooltip:ClearAnchors()
							control.tooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -25)						
							ctlAlchemyTooltip.tip:ClearLines()
							ctlAlchemyTooltip:SetHidden(true) 
						end
					else
						control.tooltip:ClearAnchors()
						control.tooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -25)						
						if ctlAlchemyTooltip then					
							ctlAlchemyTooltip.tip:ClearLines()
							ctlAlchemyTooltip:SetHidden(true) 					
						end
					end
				else
					control.tooltip:SetHidden(true)
					if ctlAlchemyTooltip and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then 
						ctlAlchemyTooltip.tip:ClearLines()
						ctlAlchemyTooltip:SetHidden(true) 
					end
				end
				return true
			-- else
				-- control.tooltip:ClearAnchors()
				-- control.tooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -25)	
			-- end
		end)

		-- enchanting
		ZO_PreHook(ZO_GamepadEnchanting, "UpdateTooltip", function(control, ...)
			local ingredientsBar = control.control:GetNamedChild("RuneSlotContainer")
			local function KelaOnSelectedDataChangedCallback (list, selectedData)
				if selectedData and selectedData.bagId and selectedData.slotIndex then
					local SHOW_COMBINED_COUNT = true
					GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex, SHOW_COMBINED_COUNT)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
						local itemLink = GetItemLink(selectedData.bagId, selectedData.slotIndex)
						local itemUniqueId = GetItemUniqueId(selectedData.bagId, selectedData.slotIndex)
						local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl
						KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_ENCHANTING_EXTRACTION", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 7, nil, itemUniqueId)		
					end
				else
					GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end					
			end
			-- setting
			if not hookEnchantingTooltipAlready then
				control.resultTooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
				control.resultTooltip.tip:SetStyles(control.resultTooltip.tip:GetStyle("tooltip"))
				ingredientsBar:ClearAnchors()
				ingredientsBar:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, ZO_GAMEPAD_PROVISIONER_INGREDIENTS_BAR_OFFSET_X, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET + 30)
				if not ctlEnchantingTooltip then ctlEnchantingTooltip = CreateControlFromVirtual("$(parent)TradingTip", control.resultTooltip, "KPUI_CraftingTooltip") end
				ctlEnchantingTooltip:SetHidden(true)
				GAMEPAD_ENCHANTING_CREATION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
					if newState == SCENE_HIDDEN then
						if ctlEnchantingTooltip and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then 
							ctlEnchantingTooltip.tip:ClearLines()
							ctlEnchantingTooltip:SetHidden(true) 
						end
						HideEnchantingTooltipControls() -- fixes "too many achors processed" error
					end
				end)
				GAMEPAD_ENCHANTING_EXTRACTION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
					if newState == SCENE_SHOWING then
						control.inventory.list:SetOnSelectedDataChangedCallback(KelaOnSelectedDataChangedCallback)
						KelaOnSelectedDataChangedCallback (control.inventory.list, control.inventory.list:GetSelectedData())
					elseif newState == SCENE_HIDDEN then
						control.inventory.list:RemoveOnSelectedDataChangedCallback(KelaOnSelectedDataChangedCallback)
					end
				end)	
				hookEnchantingTooltipAlready = true
			end	
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				control.resultTooltip:ClearAnchors()
				control.resultTooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, -254, -25)
				if ctlEnchantingTooltip then
					ctlEnchantingTooltip:ClearAnchors()
					ctlEnchantingTooltip:SetAnchor(BOTTOMLEFT, control.resultTooltip, BOTTOMRIGHT, 38)
				end
			else
				control.resultTooltip:ClearAnchors()
				control.resultTooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -25)
				if ctlEnchantingTooltip then ctlEnchantingTooltip:SetHidden(true) end
			end
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				control.extractionSlotContainer:ClearAnchors()
				control.extractionSlotContainer:SetAnchor(CENTER, GuiRoot, CENTER, 740, 300)
			else
				control.extractionSlotContainer:ClearAnchors()
				control.extractionSlotContainer:SetAnchor(CENTER, GuiRoot, CENTER, 370, 300)			
			end
			if control:IsCraftable() then
				control.resultTooltip:SetHidden(false)
				control.resultTooltip.tip:ClearLines()
				control.resultTooltip.tip:LayoutEnchantingPreview(control:GetAllCraftingBagAndSlots())
				if ctlEnchantingTooltip and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then 
					local itemLink = GetEnchantingResultingItemLink(control:GetAllCraftingBagAndSlots())				
					local maxIterations = GetMaxIterationsPossibleForEnchantingItem(control:GetAllCraftingBagAndSlots())				
					ZO_Tooltip:LayoutEnchantingTradingTooltip(ctlEnchantingTooltip, itemLink, maxIterations)
					ctlEnchantingTooltip:SetHidden(false) 
				end
			elseif control:IsExtractable() and control.extractionSlot:HasOneItem() then
			else
				control.resultTooltip:SetHidden(true)
				if ctlEnchantingTooltip and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then 
					ctlEnchantingTooltip.tip:ClearLines()
					ctlEnchantingTooltip:SetHidden(true) 
				end
			end
			return true
		end)

		-- recipe crafting
		ZO_PreHook(ZO_GamepadProvisioner, "RefreshRecipeDetails", function(control, selectedData, ...)
			-- setting
			if not hookProvisionerTooltipAlready then
				control.resultTooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
				control.resultTooltip.tip:SetStyles(control.resultTooltip.tip:GetStyle("tooltip"))
				if not ctlProvisionerTooltip then ctlProvisionerTooltip = CreateControlFromVirtual("$(parent)TradingTip", control.resultTooltip, "KPUI_CraftingTooltip") end
				ctlProvisionerTooltip:ClearAnchors()
				ctlProvisionerTooltip:SetAnchor(BOTTOMLEFT, control.resultTooltip, BOTTOMRIGHT, 26)
				ctlProvisionerTooltip:SetHidden(false)

				GAMEPAD_PROVISIONER_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
					if newState == SCENE_HIDDEN then
						HideProvisionerTooltipControls() -- fixes "too many achors processed" error
					end
				end)
				hookProvisionerTooltipAlready = true
			end	
			local ingredientsBar = control.control:GetNamedChild("IngredientsBar")
			ingredientsBar:ClearAnchors()
			control.resultTooltip:ClearAnchors()
			ingredientsBar:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, ZO_GAMEPAD_PROVISIONER_INGREDIENTS_BAR_OFFSET_X, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET + 80)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				control.resultTooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, -248, -75)
			else
				control.resultTooltip:SetAnchor(BOTTOM, ingredientsBar, TOP, 0, -75)
			end
		end)
		SecurePostHook(ZO_GamepadProvisioner, "RefreshRecipeDetails", function(control, selectedData, ...)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				if selectedData then
					local recipeListIndex, recipeIndex = selectedData.recipeListIndex, selectedData.recipeIndex
					-- trading tooltip
					if ctlProvisionerTooltip then 
						ZO_Tooltip:LayoutProvisionerTradingTooltip(ctlProvisionerTooltip, recipeListIndex, recipeIndex, selectedData)
						ctlProvisionerTooltip:SetHidden(false)
					end
				end
			else
				if ctlProvisionerTooltip then ctlProvisionerTooltip:SetHidden(true) end
			end
		end)

		-- ammunition crafting
		ZO_PreHook(ZO_GamepadSmithingCreation, "SetupResultTooltip", function(control, selectedPatternIndex, selectedMaterialIndex, selectedMaterialQuantity, selectedStyleId, selectedTraitIndex, ...)
			-- setting
			if not hookCreationTooltipAlready then
				control.resultTooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
				control.resultTooltip.tip:SetStyles(control.resultTooltip.tip:GetStyle("tooltip"))
				if not ctlCreationTooltip then ctlCreationTooltip = CreateControlFromVirtual("$(parent)TradingTip", control.resultTooltip, "KPUI_CraftingTooltip") end
				ctlCreationTooltip:ClearAnchors()
				ctlCreationTooltip:SetAnchor(LEFT, control.resultTooltip, RIGHT, 26)				
				ctlCreationTooltip:SetHidden(true)
				hookCreationTooltipAlready = true
			end	
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				control.resultTooltip:ClearAnchors()
				control.resultTooltip:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)				
				ctlCreationTooltip:SetHidden(false)
			else
				control.resultTooltip:ClearAnchors()
				control.resultTooltip:SetAnchor(CENTER, GuiRoot, LEFT, ZO_GAMEPAD_PANEL_FLOATING_CENTER_QUADRANT_1_SHOWN, ZO_GAMEPAD_PANEL_FLOATING_CENTER_OFFSET_Y)	
				ctlCreationTooltip:SetHidden(true)
			end
			control.resultTooltip.tip:LayoutPendingSmithingItem(selectedPatternIndex, selectedMaterialIndex, selectedMaterialQuantity, selectedStyleId, selectedTraitIndex)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
				local itemLink = GetSmithingPatternResultLink(selectedPatternIndex, selectedMaterialIndex, selectedMaterialQuantity, selectedStyleId, selectedTraitIndex)
				if itemLink and itemLink ~= "" then 
					ZO_Tooltip:LayoutSmithingCreationTooltip(ctlCreationTooltip, itemLink) 
				end
			end
			return true
		end)

		-- Smithing Deconstruction
		SecurePostHook(ZO_GamepadSmithingExtraction, "UpdateSelection", function(control, ...)
			control.slotContainer:ClearAnchors()
			-- if CRAFT_ADVISOR_MANAGER:HasActiveWrits() then
				-- control.slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, GAMEPAD_SMITHING_EXTRACTION_CRAFTING_QUEST_OFFSET_X, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET)
			-- else
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
					control.slotContainer:SetAnchor(CENTER, GuiRoot, CENTER, 740, 300)
				else
					control.slotContainer:SetAnchor(BOTTOM, GuiRoot, BOTTOMLEFT, ZO_GAMEPAD_PANEL_FLOATING_CENTER_QUADRANT_1_2_SHOWN, ZO_GAMEPAD_CRAFTING_UTILS_FLOATING_BOTTOM_OFFSET)				
				end
			-- end
			-- setting
			if (SCENE_MANAGER:IsShowing("gamepad_smithing_deconstruct") and not hookDeconstructTooltipAlready) or (SCENE_MANAGER:IsShowing("gamepad_smithing_refine") and not hookRefineTooltipAlready) then
				control.slotContainer:GetNamedChild("ExtractionSlot"):GetNamedChild("Name"):SetFont("ZoFontGamepadCondensed34")
				control.tooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
				control.tooltip.tip:SetStyles(control.tooltip.tip:GetStyle("tooltip"))

				control.inventory.list:RemoveAllOnSelectedDataChangedCallbacks()
				control.inventory.list:SetOnSelectedDataChangedCallback(function(list, selectedData)
					KEYBIND_STRIP:UpdateKeybindButtonGroup(control.keybindStripDescriptor)
					control.itemActions:SetInventorySlot(selectedData)
					if selectedData and selectedData.bagId and selectedData.slotIndex then
						local SHOW_COMBINED_COUNT = true
						GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex, SHOW_COMBINED_COUNT)
						if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
							local itemLink = GetItemLink(selectedData.bagId, selectedData.slotIndex)
							local itemUniqueId = GetItemUniqueId(selectedData.bagId, selectedData.slotIndex)
							local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl
							KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
							KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_SMITHING_EXTRACTION", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 7, nil, itemUniqueId)		
						else
							KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						end
					else
						GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end)
				if SCENE_MANAGER:IsShowing("gamepad_smithing_deconstruct") then
					hookDeconstructTooltipAlready = true
				elseif SCENE_MANAGER:IsShowing("gamepad_smithing_refine") then 
					hookRefineTooltipAlready = true
				end
			end
		end)
		ZO_PreHook(ZO_GamepadSmithingExtraction, "RefreshTooltip", function(control, ...)
			if control.extractionSlot:HasOneItem() then
			else
				control.tooltip:SetHidden(true)
			end
			return true
		end)

		--	improvement scene
		ZO_PreHook(ZO_GamepadSmithingImprovement, "UpdateSelection", function(control, ...)
			-- Setting
			if not hookCraftingStationKeybindAlready then
				control.sourceTooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES				
				control.resultTooltip.tip.styleNamespace = ZO_TOOLTIP_STYLES
				control.sourceTooltip.tip:SetStyles(control.sourceTooltip.tip:GetStyle("tooltip"))
				control.resultTooltip.tip:SetStyles(control.resultTooltip.tip:GetStyle("tooltip"))	
				-- set up inventory keybinds and tooltips
				control.inventory.list:RemoveAllOnSelectedDataChangedCallbacks()
				control.inventory.list:SetOnSelectedDataChangedCallback(function(list, selectedData)
					KEYBIND_STRIP:UpdateKeybindButtonGroup(control.keybindStripDescriptor)
					control.itemActions:SetInventorySlot(selectedData)
					if selectedData and selectedData.bagId and selectedData.slotIndex then
						local itemUniqueId = GetItemUniqueId(selectedData.bagId, selectedData.slotIndex)
						ZO_Tooltip:LayoutSmithingTradingTooltip(control.sourceTooltip, selectedData.bagId, selectedData.slotIndex, nil, itemUniqueId, selectedData)
						control:Refresh()
						-- selectedData.quality is deprecated, included here for addon backwards compatibility
						local functionalQuality = selectedData.functionalQuality or selectedData.quality
						control:ColorizeText(control:GetBoosterRowForQuality(functionalQuality))
						control.selectedItem = selectedData
						if not control:HasSelections() then
							control.resultTooltip:SetHidden(true)
							control.slotContainer:SetHidden(true)
							control:EnableQualityBridge(false)
						end
						control:SetInventoryActive(true)
						if control.shouldActivateTabBar then
							ZO_GamepadGenericHeader_Activate(control.owner.header)
						end
						control.spinner:Deactivate()
						GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(control.resultTooltip)
						GAMEPAD_CRAFTING_RESULTS:SetTooltipAnimationSounds(ZO_SharedSmithingImprovement_GetImprovementTooltipSounds())
						GAMEPAD_CRAFTING_RESULTS:ClearSecondaryTooltipAnimationControls()
						GAMEPAD_CRAFTING_RESULTS:AddSecondaryTooltipAnimationControl(control.sourceTooltip)
						GAMEPAD_CRAFTING_RESULTS:AddSecondaryTooltipAnimationControl(control.qualityBridge)
					else
						control.sourceTooltip.tip:ClearLines()
						control.sourceTooltip:SetHidden(true)
						GAMEPAD_CRAFTING_RESULTS:SetCraftingTooltip(nil)
						control:ClearBoosterRowHighlight()
						control.selectedItem = nil
						control:Refresh()
					end
				end)
				KelaPadUI.kelaCraftingKeybindStripDescriptor =
					{
						-- toggle tooltip
						{
							alignment = KEYBIND_STRIP_ALIGN_CENTER,	
							name = function()
								return GetString(KELA_TRADING_VIEW_MODE)
							end,
							keybind = "UI_SHORTCUT_RIGHT_STICK",
							visible = function() return true end,
							callback = function() 
								local bagId, slotIndex
								if control.improvementSlot:HasItem() then
									bagId, slotIndex = control.improvementSlot:GetBagAndSlot()
								end
								if KELA_SMITHING_IMPROVED_TOOLTIP_TYPE == 0 then
									KELA_SMITHING_IMPROVED_TOOLTIP_TYPE = 1
								else
									KELA_SMITHING_IMPROVED_TOOLTIP_TYPE = 0
								end
								control:SetupResultTooltip(bagId, slotIndex, GetCraftingInteractionType())
							end,
						},		
					}			
				GAMEPAD_SMITHING_IMPROVEMENT_SCENE:RegisterCallback("StateChange", function(oldState, newState) 
					-- states: hiding, showing, shown, hidden
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
						if(newState == "showing") then
							KEYBIND_STRIP:AddKeybindButtonGroup(KelaPadUI.kelaCraftingKeybindStripDescriptor)
						elseif(newState == "hiding") then
							KEYBIND_STRIP:RemoveKeybindButtonGroup(KelaPadUI.kelaCraftingKeybindStripDescriptor)
						end
					end
				end) 
				hookCraftingStationKeybindAlready = true
			end	
			if control.selectedItem then
				-- control.selectedItem.quality is deprecated, included here for addon backwards compatibility
				local functionalQuality = control.selectedItem.functionalQuality or control.selectedItem.quality
				control:ColorizeText(control:GetBoosterRowForQuality(functionalQuality))
			else
				control:ClearBoosterRowHighlight()
			end
			control.inventory:PerformFullRefresh()
			return true
		end)
		ZO_PreHook(ZO_GamepadSmithingImprovement, "SetupResultTooltip", function(control, itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType, ...)
			-- source item
			local bagId, slotIndex
			if control.improvementSlot:HasItem() then
				bagId, slotIndex = control.improvementSlot:GetBagAndSlot()
			else
				local selectedData = control.selectedItem
				if selectedData and selectedData.bagId and selectedData.slotIndex then
					bagId = selectedData.bagId
					slotIndex = selectedData.slotIndex
				end
			end
			local itemUniqueId = GetItemUniqueId(bagId, slotIndex)
			ZO_Tooltip:LayoutSmithingTradingTooltip(control.sourceTooltip, bagId, slotIndex, nil, itemUniqueId, selectedData)
			-- result item
			local itemUniqueId = GetItemUniqueId(itemToImproveBagId, itemToImproveSlotIndex)
			ZO_Tooltip:LayoutSmithingTradingTooltip(control.resultTooltip, itemToImproveBagId, itemToImproveSlotIndex, craftingSkillType, itemUniqueId, selectedData)
			return true
		end)
		hookCraftingStationAlready = true
	end
end	

function KelaSetupTradingHouse()
	if not kpuiSVBuyingData or not kpuiSVListingData then
		return
	end
	if KelaPadUI.KelaTradingHouseSetupStarted then
		return
	end
	KelaPadUI.KelaTradingHouseSetupStarted = true

	-- set up the guild store
	SecurePostHook(ZO_GamepadTradingHouse, "OpenTradingHouse", function()
		if not hookTradingHouseAlready then
			-- hide when switching pages
			SecurePostHook(ZO_GamepadTradingHouse, "SetCurrentListObject", function(control, listObject, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
				end
			end)
			-- sell window
			SecurePostHook(GAMEPAD_TRADING_HOUSE_SELL, "UpdateItemSelectedTooltip", function(control, selectedData, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					if selectedData then
						local bag, index = ZO_Inventory_GetBagAndIndex(selectedData)
						
						local itemUniqueId = GetItemUniqueId(bag, index)
						-- CHAT_SYSTEM:AddMessage("itemUniqueId  "..tostring(itemUniqueId))						
						
						local itemLink = GetItemLink(bag, index)
						local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl
						KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_TRADING_HOUSE_SELL", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5, nil, itemUniqueId)		
					else
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end		
				end
			end)
			-- hide when leaving the page
			SecurePostHook(GAMEPAD_TRADING_HOUSE_SELL, "OnHiding", function(control, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
				end
			end)
			-- active listing window
			SecurePostHook(GAMEPAD_TRADING_HOUSE_LISTINGS, "UpdateItemSelectedTooltip", function(control, selectedData, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					if selectedData then
						local itemLink = selectedData.itemLink
						local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
						KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_TRADING_HOUSE_LISTINGS", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5)		
					else
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end
			end)
			-- SEARCH WINDOW
			-- add deal-value filter buttons
			SecurePostHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "OnShowing", function(control, ...)
				local keybind  = 
				{
					alignment = KEYBIND_STRIP_ALIGN_LEFT,	
					name = "Name",
					keybind = "UI_SHORTCUT_RIGHT_STICK",
					callback = function()
							KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX = (KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX == 5) and 1 or (KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX + 1)
							control:Deactivate()
							control:FilterScrollList()
							ZO_SortFilterList.CommitScrollList(control)
							control:RefreshPagingControls()
							control:UpdateKeybinds()
							control:Activate()
						end,
					ethereal = true,
				}
				control:AddUniversalKeybind(keybind)

				local keybind  = 
				{
					alignment = KEYBIND_STRIP_ALIGN_LEFT,	
					name = "Known Item Filter",
					keybind = "UI_SHORTCUT_LEFT_STICK",
					callback = function()
							if KELA_KNOWN_ITEM_FILTER == "ALL" then 
								KELA_KNOWN_ITEM_FILTER = "UNKNOWN"
							elseif KELA_KNOWN_ITEM_FILTER == "UNKNOWN" then
								KELA_KNOWN_ITEM_FILTER = "KNOWN"
							else
								KELA_KNOWN_ITEM_FILTER = "ALL"
							end
							control:Deactivate()
							control:FilterScrollList()
							ZO_SortFilterList.CommitScrollList(control)
							control:RefreshPagingControls()
							control:UpdateKeybinds()
							control:Activate()
						end,
					ethereal = true,
				}
				control:AddUniversalKeybind(keybind)

				local keybind  =
				{
					name = "Gamepad Interactive Sort Filter List Left Trigger",
					keybind = "UI_SHORTCUT_LEFT_TRIGGER",
					ethereal = true,
					callback = function()
						control:OnLeftTrigger()
					end,
				}
				control:AddUniversalKeybind(keybind)

				local keybind  =
				{
					name = "Gamepad Interactive Sort Filter List Right Trigger",
					keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
					ethereal = true,
					callback = function()
						control:OnRightTrigger()
					end,
				}
				control:AddUniversalKeybind(keybind)
			end)
			-- add the trade message
			SecurePostHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "UpdateItemSelectedTooltip", function(control, selectedData, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					if selectedData then
						local itemLink
						if selectedData.isGuildSpecificItem then
							itemLink = GetGuildSpecificItemLink(selectedData.slotIndex)
						else
							itemLink = selectedData.itemLink
						end
						local parentControl = GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.control
						KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						local customScale = GetUICustomScale()
						if customScale > 0.8 then
							KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, true, 50)		
						else
							KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 45)	
						end
					else
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end
			end)
			-- keep page-turn buttons visible on headers
			ZO_PreHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "RefreshPagingControls", function(control, ...)
				if IsKPUITradingHouseSettingEnabled() then
					local enablePrevious = TRADING_HOUSE_SEARCH:HasPreviousPage()
					local enableNext = TRADING_HOUSE_SEARCH:HasNextPage()
					local hideButtons = not (enablePrevious or enableNext)
					local prevButton = control.footer.previousButton
					local nextButton = control.footer.nextButton
					prevButton:SetEnabled(enablePrevious)
					nextButton:SetEnabled(enableNext)
					prevButton:SetHidden(hideButtons)
					nextButton:SetHidden(hideButtons)
					local scrollData = ZO_ScrollList_GetDataList(control.list)
					if next(scrollData) == nil then
						if TRADING_HOUSE_SEARCH.numItemsOnPage ~= 0 then
							control:SetEmptyText(colors.COLOR_WHITE:Colorize("0")..GetString(KELA_TRADING_TRADING_NOTEFFECTLOTS)..colors.COLOR_WHITE:Colorize(tostring(TRADING_HOUSE_SEARCH.numItemsOnPage)))
						end
					else
						control:SetEmptyText(GetString("SI_TRADINGHOUSESEARCHSTATE", 1))
					end
					if not hideButtons then
						control.footer.pageNumberLabel:SetHidden(false)
						control.footer.pageNumberLabel:SetText(tostring(#scrollData).." / "..tostring(TRADING_HOUSE_SEARCH.numItemsOnPage)..GetString(KELA_TRADING_TRADING_PAGES)..zo_strformat(SI_GAMEPAD_PAGED_LIST_PAGE_NUMBER, TRADING_HOUSE_SEARCH:GetPage() + 1))
					else
						control.footer.pageNumberLabel:SetHidden(true)
					end
					return true
				end
			end)
			-- empty-list text
			ZO_PreHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "OnSearchStateChanged", function(control, searchState, searchOutcome, ...)
				if IsKPUITradingHouseSettingEnabled() then
					local shouldActivateBrowseResults = false
					local shouldDeactivateBrowseResults = false
					if searchState == TRADING_HOUSE_SEARCH_STATE_NONE then
						control:SetEmptyText("")
						control:RefreshPagingControls()
					elseif searchState == TRADING_HOUSE_SEARCH_STATE_WAITING then
						control:SetEmptyText(GetString("SI_TRADINGHOUSESEARCHSTATE", searchState))
					elseif searchState == TRADING_HOUSE_SEARCH_STATE_COMPLETE then
						if searchOutcome == TRADING_HOUSE_SEARCH_OUTCOME_HAS_RESULTS then
							control:DeselectListData()
							shouldActivateBrowseResults = true
							control:RefreshPagingControls()
						else
							control:SetEmptyText(GetString("SI_TRADINGHOUSESEARCHOUTCOME", searchOutcome))
							shouldDeactivateBrowseResults = (searchOutcome == TRADING_HOUSE_SEARCH_OUTCOME_ALL_RESULTS_PURCHASED)
						end
					end
					control:RefreshData()
					if TRADING_HOUSE_GAMEPAD_SCENE:IsShowing() then
						if shouldActivateBrowseResults then
							if control:IsActive() then
								-- We are already activated, focus on the panel so we start on the first item entry
								control:ActivatePanelFocus()
							else
								TRADING_HOUSE_GAMEPAD:ActivateBrowseResults()
							end
						end
						if shouldDeactivateBrowseResults then
							if control:IsActive() then
								TRADING_HOUSE_GAMEPAD:DeactivateBrowseResults()
							end
						end
					end
					return true
				end
			end)
			ZO_PreHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "FilterScrollList", function(control, ...)		
				if IsKPUITradingHouseSettingEnabled() then
					local scrollData = ZO_ScrollList_GetDataList(control.list)
					-- Search results can be non-contiguous: bought items keep their index but get removed from the scroll list
					ZO_ClearTable(control.searchResultItemDataList)
					ZO_ClearNumericallyIndexedTable(scrollData)
					ZO_ClearNumericallyIndexedTable(control.previewListEntries)
					if TRADING_HOUSE_SEARCH:ShouldShowGuildSpecificItems() then
						for i = 1, GetNumGuildSpecificItems() do
							local itemData = TRADING_HOUSE_GAMEPAD:CreateGuildSpecificItemData(i, GetGuildSpecificItemInfo)
							if itemData then
								itemData.isGuildSpecificItem = true
								local dataEntry = ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, itemData)
								table.insert(scrollData, dataEntry)
							end
						end
					else
						for tradingHouseItemIndex = 1, TRADING_HOUSE_SEARCH:GetNumItemsOnPage() do
							local itemData = ZO_TradingHouse_CreateSearchResultItemData(tradingHouseItemIndex)
							if itemData then
								local _, _, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemData.itemLink)
								local valueEffectDeal = KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, itemData, "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS")

								local itemType, specializedItemType = GetItemLinkItemType(itemData.itemLink)
								local grantedCollectibleId = GetItemLinkContainerCollectibleId(itemData.itemLink)
								local isItemKnown = "ALL"
								if IsItemLinkBook(itemData.itemLink) or IsItemLinkBookPartOfCollection(itemData.itemLink) then
									-- Motifs and books
									if IsItemLinkBookKnown(itemData.itemLink) then
										isItemKnown = "KNOWN"
									else
										isItemKnown = "UNKNOWN"
									end
								elseif itemType == ITEMTYPE_RECIPE then
									-- Recipe's
									if IsItemLinkRecipeKnown(itemData.itemLink) then
										isItemKnown = "KNOWN"
									else
										isItemKnown = "UNKNOWN"
									end
								elseif IsItemLinkSetCollectionPiece(itemData.itemLink) then
									-- Sets: Armor, weapon, and jewelry
									local itemId = GetItemLinkItemId(itemData.itemLink)
									if IsItemSetCollectionPieceUnlocked(itemId) then
										isItemKnown = "KNOWN"
									else
										isItemKnown = "UNKNOWN"
									end
								elseif grantedCollectibleId > 0 then
									-- Other Collectibles: runeboxes, style pages, etc
									local collectibleCategory = GetCollectibleCategoryType(grantedCollectibleId)
									if IsCollectibleOwnedByDefId(grantedCollectibleId) then
										isItemKnown = "KNOWN"
									elseif collectibleCategory == COLLECTIBLE_CATEGORY_TYPE_COMBINATION_FRAGMENT and not CanCombinationFragmentBeUnlocked(grantedCollectibleId) then
										isItemKnown = "KNOWN"
									else
										isItemKnown = "UNKNOWN"
									end
								end

								if valueEffectDeal == "-" then 
									valueEffectDeal = KelaGetEffectIfUndefined(itemData)
								end
								if KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX == 1 or (KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX == 2 and valueEffectDeal == 0) or (KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX > 2 and valueEffectDeal >= KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX) then	
									if KELA_KNOWN_ITEM_FILTER=="ALL" or (KELA_KNOWN_ITEM_FILTER==isItemKnown) then
										local dataEntry = ZO_ScrollList_CreateDataEntry(ZO_GAMEPAD_INTERACTIVE_FILTER_LIST_PRIMARY_DATA_TYPE, itemData)
										control.searchResultItemDataList[tradingHouseItemIndex] = itemData
										table.insert(scrollData, dataEntry)
										if control:CanPreviewTradingHouseItem(itemData) then
											table.insert(control.previewListEntries, tradingHouseItemIndex)
										end
									end
								end
							end
						end
						control:RefreshPagingControls()
					end
					if TRADING_HOUSE_PREVIEW_GAMEPAD_SCENE:IsShowing() then
						control:UpdatePreviewForChangedData()
					end
					return true
				end
			end)
			SecurePostHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "FilterScrollList", function(control, ...)		
				if IsKPUITradingHouseSettingEnabled() then
					control.contentHeaderData.data1HeaderText = colors.COLOR_WHITE:Colorize(zo_iconFormat(kpuiConst.stringDDS.leftStickXBOne, 44, 44)).." Filter Known: "..KELA_KNOWN_ITEM_FILTER
					control.contentHeaderData.data2HeaderText = ""
					control.contentHeaderData.data3HeaderText = colors.COLOR_WHITE:Colorize(zo_iconFormat(kpuiConst.stringDDS.rightStickXBOne, 44, 44)).." "..KelaCreateColorizedResumePrice(KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX)
					--control.contentHeaderData.data1HeaderText = colors.COLOR_WHITE:Colorize(zo_iconFormat(kpuiConst.stringDDS.rightStickXBOne, 44, 44)).." "..KelaCreateColorizedResumePrice(KELA_CURRENT_EFFECTDEAL_SELECTION_INDEX)
					--control.contentHeaderData.data2HeaderText = ""
					--control.contentHeaderData.data3HeaderText = ""
					ZO_GamepadGenericHeader_RefreshData(control.contentHeader, control.contentHeaderData)
				end
			end)
			local PRICE_THRESHOLD_DIGITS = 6
			local PRICE_THRESHOLD = zo_pow(10, PRICE_THRESHOLD_DIGITS)
			ZO_PostHook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "SetupResultItemRow", function(selfControl, control, itemData, ...)		
				if IsKPUITradingHouseSettingEnabled() and TamrielTradeCentre ~= nil then
					local colorPrice = colors.COLOR_WHITE
					local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemData.itemLink)
					if trueTTC or trueATT then 				
						local valueEffectDeal, _, colorEffectDeal = KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, itemData, "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS")
						local avgPrice = priceInfoTTC.Avg
						local minPrice = priceInfoTTC.Min
						local maxPrice = priceInfoTTC.Max
						if valueEffectDeal ~= "-" then
							colorPrice = colorEffectDeal
						elseif avgPrice ~= 0 and itemData.purchasePricePerUnit ~= avgPrice then
							if itemData.purchasePricePerUnit <= minPrice + (avgPrice-minPrice)*0.1 then
								colorPrice = colors.COLOR_DEALGREAT
							elseif itemData.purchasePricePerUnit <= minPrice + (avgPrice-minPrice)*0.7 then
								colorPrice = colors.COLOR_DEALGOOD
							elseif itemData.purchasePricePerUnit <= avgPrice + (maxPrice-avgPrice)*0.3 then
								colorPrice = colors.COLOR_DEALNORMAL
							elseif itemData.purchasePricePerUnit <= avgPrice + (maxPrice-avgPrice)*0.7 then
								colorPrice = colors.COLOR_DEALBAD
							elseif itemData.purchasePricePerUnit >= avgPrice + (maxPrice-avgPrice)*0.7 then
								colorPrice = colors.COLOR_DEALTERRIBLE
							end
						end
					end
					control.unitPriceLabel:SetColor(colorPrice:UnpackRGB())
				end
			end)
			-- TRADING_HOUSE_CREATE_LISTING_GAMEPAD
			-- create-listing window
			SecurePostHook(TRADING_HOUSE_CREATE_LISTING_GAMEPAD, "Showing", function(control, ...)
				if IsKPUITradingHouseSettingEnabled() then
					local itemLink = GetItemLink(control.itemBag, control.itemIndex)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
						selectedData = control.selectedData
						local itemUniqueId = GetItemUniqueId(control.itemBag, control.itemIndex)
						if itemLink then
							local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
							KPUI_GAMEPAD_TOOLTIPS:ClearTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
							KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "TRADING_HOUSE_CREATE_LISTING_GAMEPAD", itemLink, selectedData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5, nil, itemUniqueId)		
						end
					end
					local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)
					_, _, _, _, _, _, _, _, _, _, _, _, compareValuePrice = KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, selectedData)				
					-- set a custom price
					if compareValuePrice and compareValuePrice ~= 0 then 
						control:SetListingPrice(math.ceil(compareValuePrice))
					end
				end
			end)
			SecurePostHook(TRADING_HOUSE_CREATE_LISTING_GAMEPAD, "Hiding", function(control, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE) then
					KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
				end
			end)
			SecurePostHook(TRADING_HOUSE_CREATE_LISTING_GAMEPAD, "SetListingPrice", function(selfControl, price, isPreview, ...)
				if IsKPUITradingHouseSettingEnabled() then
					local listingFee, _, profit = GetTradingHousePostPriceInfo(price)
					selfControl.validPrice = (GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= listingFee) and (price > 0) and (price <= MAX_PLAYER_CURRENCY)
					local HAS_ERROR = not selfControl.validPrice
					local colorValue = colors.COLOR_WHITE
					if HAS_ERROR then 
						colorValue = colors.COLOR_DEALTERRIBLE
					end
					selectedData = selfControl.selectedData
					local itemLink = GetItemLink(selfControl.itemBag, selfControl.itemIndex)
					if itemLink then
						local controlContainer = selfControl.control:GetNamedChild("Mask"):GetNamedChild("Container")
						local controlRail = controlContainer:GetNamedChild("Rail")
						local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
						local itemUniqueId = GetItemUniqueId(selfControl.itemBag, selfControl.itemIndex)
						local stackCount, buyPrice, buyPricePerUnit
						local itemType = GetItemLinkItemType(itemLink)
						if (itemType == ITEMTYPE_MASTER_WRIT) then
							stackCount = ArkadiusTradeToolsSales:GetVoucherCount(itemLink)
						else
							stackCount = selectedData.stackCount
						end
						if itemUniqueId then
							tblBuyingItems = kpuiSVBuyingData["buyingTable"]			
							itemUID = Id64ToString(itemUniqueId)
							if tblBuyingItems[itemUID] ~= nil then
								buyPricePerUnit = tonumber(tblBuyingItems[itemUID]["buyPricePerUnit"])
								buyPrice = buyPricePerUnit*stackCount
							end
						end				
						if stackCount > 1 then
							local numPrice = KelaRoundNumber(price / stackCount, 2)	 -- Round to 2 decimal places
							-- local strPrice = KelaLocalizedFormatNumber(numPrice, 2)
							local strPrice = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(numPrice, true, CURT_MONEY, true)
							if not ctlListingPriceLabel then ctlListingPriceLabel = CreateControlFromVirtual("$(parent)KPUI_ListingPrice", controlContainer, "KPUI_LabelValue") end				
							ctlListingPriceLabel:ClearAnchors()
							ctlListingPriceLabel:SetAnchor(TOPLEFT, controlRail, BOTTOMLEFT, 0, -265)
							ctlListingPriceLabel:SetAnchor(TOPRIGHT, controlRail, BOTTOMRIGHT, 0, -265)
							ctlListingPriceLabel:SetHidden(false)	
							ctlListingPriceLabel:GetNamedChild("Label"):SetText(GetString(KELA_TRADING_SALE_PRICE))
							ctlListingPriceLabel:GetNamedChild("Value"):SetText(colorValue:Colorize(strPrice))
						else
							if ctlListingPriceLabel then ctlListingPriceLabel:SetHidden(true) end
						end
						if buyPrice then
							-- local strClearProfit = KelaLocalizedFormatNumber(profit-buyPrice)
							local strClearProfit = profit-buyPrice

							if not HAS_ERROR then 
								-- CHAT_SYSTEM:AddMessage(tostring(strClearProfit).." / "..tostring(buyPrice))
								if strClearProfit >= buyPrice then
									colorValue = colors.COLOR_DEALGREAT
								elseif strClearProfit >= buyPrice*0.3 then
									colorValue = colors.COLOR_DEALGOOD
								elseif strClearProfit >= 0 then

								elseif strClearProfit >= 0-(buyPrice*0.2) then
									colorValue = colors.COLOR_DEALBAD
								elseif strClearProfit <= 0-(buyPrice*0.2) then
									colorValue = colors.COLOR_DEALTERRIBLE
								end
							end
							strClearProfit = ZO_CurrencyControl_FormatCurrencyAndAppendIcon(strClearProfit, true, CURT_MONEY, true)
							if not ctlListingClearProfitAmountLabel then ctlListingClearProfitAmountLabel = CreateControlFromVirtual("$(parent)KPUI_ListingProfit", controlContainer, "KPUI_LabelValue") end				
							ctlListingClearProfitAmountLabel:ClearAnchors()
							ctlListingClearProfitAmountLabel:SetAnchor(TOPLEFT, controlRail, BOTTOMLEFT, 0, 95)
							ctlListingClearProfitAmountLabel:SetAnchor(TOPRIGHT, controlRail, BOTTOMRIGHT, 0, 95)
							ctlListingClearProfitAmountLabel:SetHidden(false)	
							ctlListingClearProfitAmountLabel:GetNamedChild("Label"):SetText(GetString(KELA_TRADING_SALE_CLEARPROFIT))
							ctlListingClearProfitAmountLabel:GetNamedChild("Value"):SetText(colorValue:Colorize(strClearProfit))
						else
							if ctlListingClearProfitAmountLabel then ctlListingClearProfitAmountLabel:SetHidden(true) end
						end
					end
				end

			end)
			-- sell/purchase confirmation dialogs
			function ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog(itemData, dialogName, displayPrice, iconFile)
				local listingIndex = itemData.slotIndex
				local stackCount = itemData.stackCount
				local itemName = itemData.name
				-- local timeRemaining = itemData.timeRemaining
				-- local pricePerUnit = itemData.purchasePricePerUnit
				-- local uniqueId = itemData.itemUniqueId
				local price = displayPrice
				-- itemData.quality is deprecated, included here for addon backwards compatibility
				local displayQuality = itemData.displayQuality or itemData.quality
				local nameColor = GetItemQualityColor(displayQuality)
				local currencyType = itemData.currencyType or CURT_MONEY
				local itemNameWithQuantity = nameColor:Colorize(zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount))
				local title = itemNameWithQuantity
				if iconFile then
					local iconMarkup = zo_iconFormat(iconFile, ZO_GAMEPAD_DEFAULT_LIST_ENTRY_ICON_FULL_SIZE_DIMENSION, ZO_GAMEPAD_DEFAULT_LIST_ENTRY_ICON_FULL_SIZE_DIMENSION)
					title = string.format("%s %s", iconMarkup, itemNameWithQuantity)
				end
				local priceText = zo_strformat(SI_GAMEPAD_TRADING_HOUSE_ITEM_AMOUNT, ZO_CurrencyControl_FormatCurrency(price), ZO_Currency_GetGamepadFormattedCurrencyIcon(currencyType))
				local mainTextParams
				if stackCount > 1 then
					mainTextParams = 
					{
						title,
						"|c" .. nameColor:ToHex(),
						itemName,
						stackCount,
						priceText,
					}
				else
					mainTextParams =
					{
						title,
						nameColor:Colorize(itemName),
						priceText,
					}
				end
				if IsKPUITradingHouseSettingEnabled() then
					ZO_Dialogs_ShowGamepadDialog(dialogName, { listingIndex = listingIndex, stackCount = stackCount, uniqueId = itemData.itemUniqueId, itemName = itemName, price = price, pricePerUnit = itemData.purchasePricePerUnit, displayQuality = displayQuality, timeRemaining = itemData.timeRemaining }, { mainTextParams = mainTextParams })
				else
					ZO_Dialogs_ShowGamepadDialog(dialogName, { listingIndex = listingIndex, stackCount = stackCount, price = price }, { mainTextParams = mainTextParams })
				end
			end
			ESO_Dialogs["TRADING_HOUSE_CONFIRM_BUY_ITEM"] =
			{
				gamepadInfo =
				{
					dialogType = GAMEPAD_DIALOGS.BASIC,
				},
				title =
				{
					text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TITLE,
				},
				mainText = 
				{
					text = function(dialog)
					if dialog.data.stackCount > 1 then
							return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_MULTIPLE_DIALOG_TEXT
						else
							return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT
						end
					end,
				},
				buttons =
				{
					[1] =
					{
						text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CONFIRM,
						callback =  function(dialog)
										if IsKPUITradingHouseSettingEnabled() then
											KelaAddToBuyingUniqueTable(dialog.data.uniqueId, dialog.data.itemName, dialog.data.price, dialog.data.pricePerUnit, dialog.data.listingIndex, dialog.data.displayQuality)
										end
										ConfirmPendingItemPurchase()
									 end
					},
					[2] =
					{
						text =      SI_TRADING_HOUSE_PURCHASE_ITEM_DIALOG_CANCEL,
						callback =  function(dialog)
										ClearPendingItemPurchase()
									end
					}
				}
			}
			local exitOnFinished = true
			ESO_Dialogs["TRADING_HOUSE_CONFIRM_SELL_ITEM"] =
			{
				gamepadInfo =
				{
					dialogType = GAMEPAD_DIALOGS.BASIC,
				},
				title =
				{
					text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TITLE,
				},
				mainText = 
				{
					text =  function(dialog)
								if dialog.data.stackCount > 1 then
									return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_MULTIPLE_DIALOG_TEXT
								else
									return SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TEXT
								end
							end,
				},
				setup = function()
					exitOnFinished = false
				end,
				finishedCallback = function(dialog)
					if exitOnFinished then
						SCENE_MANAGER:HideCurrentScene()
					end
				end,
				buttons =
				{
					[1] =
					{
						text = SI_DIALOG_YES,
						callback = function(dialog)
							local stackCount = dialog.data.stackCount
							local desiredPrice = dialog.data.price
							local listingIndex = dialog.data.listingIndex
							local timeRemaining = dialog.data.timeRemaining
							RequestPostItemOnTradingHouse(BAG_BACKPACK, listingIndex, stackCount, desiredPrice, timeRemaining)
							
							if IsKPUITradingHouseSettingEnabled() then
								KelaAddToListingTable(BAG_BACKPACK, listingIndex, stackCount, desiredPrice, timeRemaining)
							end
							
							exitOnFinished = true
						end
					},
					[2] =
					{
						text = SI_DIALOG_NO,
					}  
				}
			}
			ESO_Dialogs["TRADING_HOUSE_CONFIRM_REMOVE_LISTING"] =
			{
				gamepadInfo =
				{
					dialogType = GAMEPAD_DIALOGS.BASIC,
				},
				title =
				{
					text = SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_DIALOG_TITLE,
				},
				mainText = 
				{
					text =  function(dialog)
								if dialog.data.stackCount > 1 then
									return SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_MULTIPLE_DIALOG_TEXT
								else
									return SI_GAMEPAD_TRADING_HOUSE_LISTING_REMOVE_DIALOG_TEXT
								end
							end,
				},
				buttons =
				{
					[1] =
					{
						text =      SI_DIALOG_REMOVE,
						callback =  function(dialog)
										CancelTradingHouseListing(dialog.data.listingIndex)
										if IsKPUITradingHouseSettingEnabled() then
											KelaRemoveFromListingTable(dialog.data.listingIndex, dialog.data.stackCount, dialog.data.price, dialog.data.timeRemaining)
										end
									end
					},
					[2] =
					{
						text =       SI_DIALOG_CANCEL,
					}  
				}
			}
			hookTradingHouseAlready = true
		end
	end)
	
	-- set up banking when the regular bank opens
	SecurePostHook(ZO_GamepadBanking, "OnOpenBank", function(control, bankBag, ...)
		if not hookBankingAlready then
			SecurePostHook(ZO_BankingCommon_Gamepad, "LayoutBankingEntryTooltip", function(control, inventoryData, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK) then
					if inventoryData and inventoryData.bagId then
						local itemLink = GetItemLink(inventoryData.bagId, inventoryData.slotIndex)
						local itemUniqueId = GetItemUniqueId(inventoryData.bagId, inventoryData.slotIndex)
						if itemLink then
							local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
							KPUI_GAMEPAD_TOOLTIPS:ClearLines(KPUI_GAMEPAD_TRADING_TOOLTIP)
							KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "ZO_BankingCommon_Gamepad", itemLink, inventoryData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5, nil, itemUniqueId)			
						end
					else
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end
			end)		
			SecurePostHook(ZO_BankingCommon_Gamepad, "OnCategoryChanged", function(control, selectedData, ...)
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK) then
					control:LayoutBankingEntryTooltip(selectedData)
				end
			end)
			hookBankingAlready = true
		end
	end)
	
	-- set up banking when the guild bank opens
	SecurePostHook(ZO_BankingCommon_Gamepad, "OnStateChanged", function(control, oldState, newState, ...)
		if not hookBankingAlready then
			if newState == SCENE_SHOWING then
				SecurePostHook(ZO_BankingCommon_Gamepad, "LayoutBankingEntryTooltip", function(control, inventoryData, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK) then
						if inventoryData and inventoryData.bagId then
							local itemLink = GetItemLink(inventoryData.bagId, inventoryData.slotIndex)
							local itemUniqueId = GetItemUniqueId(inventoryData.bagId, inventoryData.slotIndex)
							if itemLink then
								local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
								KPUI_GAMEPAD_TOOLTIPS:ClearLines(KPUI_GAMEPAD_TRADING_TOOLTIP)
								KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "ZO_BankingCommon_Gamepad", itemLink, inventoryData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5, nil, itemUniqueId)		
							end
						else
							KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						end
					end
				end)		
				SecurePostHook(ZO_BankingCommon_Gamepad, "OnCategoryChanged", function(control, selectedData, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK) then
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end	
				end)
				SecurePostHook(ZO_GuildBank_Gamepad, "ChangeGuildBank", function(control, guildBankId, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK) then
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
					end
				end)
				hookBankingAlready = true
			end
		end		
	end)

	-- set up stores
	SecurePostHook(ZO_GamepadStoreManager, "OnStateChanged", function(control, oldState, newState, ...)
		if not hookStoregAlready then
			if newState == SCENE_SHOWING then
				SecurePostHook(ZO_GamepadStoreBuy, "OnSelectedItemChanged", function(control, buyData, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_STORE) then
						if buyData then
							local itemLink = buyData.itemLink
							if itemLink then
								local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
								KPUI_GAMEPAD_TOOLTIPS:ClearLines(KPUI_GAMEPAD_TRADING_TOOLTIP)
								KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "ZO_GamepadStoreBuy", itemLink, buyData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5)		
							end
						end					
					end
				end)
				SecurePostHook(ZO_GamepadStoreSell, "OnSelectedItemChanged", function(control, inventoryData, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_STORE) then
						if inventoryData and inventoryData.bagId then
							local itemLink = GetItemLink(inventoryData.bagId, inventoryData.slotIndex)
							local itemUniqueId = GetItemUniqueId(inventoryData.bagId, inventoryData.slotIndex)
							if itemLink then
								local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
								KPUI_GAMEPAD_TOOLTIPS:ClearLines(KPUI_GAMEPAD_TRADING_TOOLTIP)
								KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "ZO_GamepadStoreSell", itemLink, inventoryData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5, nil, itemUniqueId)		
							end
						else
							KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
						end	
					end
				end)
				SecurePostHook(ZO_GamepadStoreBuyback, "OnSelectedItemChanged", function(control, buyBackData, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_STORE) then
						if buyBackData then
							local itemLink = GetBuybackItemLink(buyBackData.slotIndex)						
							if itemLink then
								local parentControl = GAMEPAD_TOOLTIPS:GetTooltipInfo(GAMEPAD_LEFT_TOOLTIP).bgControl	
								KPUI_GAMEPAD_TOOLTIPS:ClearLines(KPUI_GAMEPAD_TRADING_TOOLTIP)
								KPUI_GAMEPAD_TOOLTIPS:LayoutTradingTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP, "ZO_GamepadStoreBuyback", itemLink, buyBackData, KPUI_GAMEPAD_TRADING_TOOLTIP, parentControl, false, 5)		
							end
						else
							KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)	
						end
					end
				end)
				SecurePostHook(ZO_GamepadStoreManager, "HideActiveComponent", function(control, ...)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_STORE) then
						KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)	
					end
				end)
				hookStoregAlready = true
			end
		end		
	end)

	-- set up the ATT graph
	if ArkadiusTradeTools ~= nil and not hookATTAlready then 
		ZO_PreHook(ArkadiusTradeToolsSalesGraph, "AddDot", function(control, x, y, color)

				local drawAreaWidth, drawAreaHeight = control.drawArea:GetDimensions()
				local rangeX = control.maxX - control.minX

				local posX = x - control.minX
				local rangeY = control.maxY - control.minY
				local posY = control.maxY - y

				local left = drawAreaWidth / rangeX * posX
				local right = -(drawAreaWidth - left - 2)
				local top = drawAreaHeight / rangeY * posY
				local bottom = -(drawAreaHeight - top - 2)

				-- Serves as the index for our current surface
				control.numDots = control.numDots + 1

				if (control.numDots > control.numSurfaces) then
					control.drawArea:AddSurface(0.25, 0.75, 0.25, 0.75)
					control.numSurfaces = control.numSurfaces + 1
				else
					control.drawArea:SetSurfaceHidden(control.numDots, false)
				end

				control.drawArea:SetColor(control.numDots, color:UnpackRGBA())
				
				control.drawArea:SetPixelRoundingEnabled(false)
				if x == GetTimeStamp() then
					if color == colors.COLOR_TTC then -- then
						left = left - 8
						right = right + 2
						top = top - 1
						bottom = bottom	+ 2
						control.drawArea:SetPixelRoundingEnabled(true)
					elseif color == colors.COLOR_ATT then -- tradeSuggested == "ATT" then
						left = left - 2
						right = right + 8
						top = top - 1
						bottom = bottom	+ 2
						control.drawArea:SetPixelRoundingEnabled(true)
					end
				end
				control.drawArea:SetInsets(control.numDots, left - 2, right + 2, top - 2, bottom + 2)
				
				return true
		
		end)
		
	end

	--GUILD SELECTION DIALOG SETUP
	local function SetupTradingHouseGuildItem(control, data, ...)
		ZO_SharedGamepadEntry_OnSetup(control, data, ...)
		if data.isCurrentGuild then
			control.statusIndicator:AddIcon("EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_equipped.dds")
			control.statusIndicator:Show()
		end
	end
	local function SetupGuildSelectionDialog(dialog)
		local currentGuildId = GetSelectedTradingHouseGuildId()
		dialog.info.parametricList = {}
		local indexToSelect = nil
		for i = 1, GetNumGuilds() do
			local guildId = GetGuildId(i)
			local guildName = GetGuildName(guildId)
			local allianceId = GetGuildAlliance(guildId)
			local icon = GetLargeAllianceSymbolIcon(allianceId)
			local listItem = 
			{
				template = "ZO_GamepadSubMenuEntryWithStatusTemplate",
				templateData = 
				{
					 guildId = guildId,
					 guildName = guildName,
					 allianceId = allianceId,
					 fontScaleOnSelection = false,
					 setup = SetupTradingHouseGuildItem,
					 isCurrentGuild = guildId == currentGuildId
				},
				icon = icon,
				text = guildName,
			}
			table.insert(dialog.info.parametricList, listItem)
			if guildId == currentGuildId then
				indexToSelect = i
			end
		end
		if IsKPUITradingHouseSettingEnabled() then
			dialog.info.blockDialogReleaseOnPress = true
			-- ATT analysis period
			local function setupRow (control, data, selected, reselectingDuringRebuild, enabled, active)
				ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
				local label = control.label
				label:SetFont("ZoFontGamepad34")

				if not KPUI_SelectorContainer then KPUI_SelectorContainer = CreateControlFromVirtual("$(parent)KPUI_SelectorContainer", dialog, "KPUI_SelectorContainer") end
				KelaPadUI.selectorContainer = KPUI_SelectorContainer
				KelaPadUI.selectorContainer:ClearAnchors()
				KelaPadUI.selectorContainer:SetAnchor(TOPLEFT, control, TOPRIGHT, 0, 0)
				KelaPadUI.selectorContainer:SetAnchor(BOTTOMLEFT, control, BOTTOMRIGHT, 0, 0)			
				KelaPadUI.selectorContainer:SetHidden(false)			
				KelaPadUI.selector = ZO_CurrencySelector_Gamepad:New(KPUI_SelectorContainer:GetNamedChild("Selector"))
				KelaPadUI.selector:SetClampValues(true)
				KelaPadUI.selector:SetMaxValue(30)
				KelaPadUI.selector.control:SetHidden(false)
				KelaPadUI.selector:SetValue(KelaGetATTAnalysisPeriod())
			end
			local function callbackRow(dialog)
				KelaPadUI.selector:SetValue(KelaGetATTAnalysisPeriod())
				KelaPadUI.selectorContainer:SetHidden(false)
				KelaPadUI.selector.control:SetHidden(false)
				local targetControl = dialog.entryList:GetTargetControl()
				KelaPadUI.selector:Activate()
				KelaPadUI.selectorActive = true
			end
			local KelaOptionsPeriod = 
			{
				template = "Kela_GamepadFullWidthLabelEntryTemplate",
				header = "KelaPadUI",
				headerTemplate = "Kela_GamepadMenuEntryFullWidthHeaderTemplate",
				templateData =
				{
					text = GetString(KELA_SETTINGS_TRADE_ATTGRAPH_PERIOD),
					setup = setupRow,
					callback = callbackRow,
					visible = function()
							return SCENE_MANAGER:GetCurrentScene():GetName() == "gamepad_trading_house"
						end,
				},
			}
			table.insert(dialog.info.parametricList, KelaOptionsPeriod)
		end
		dialog:setupFunc()
		if indexToSelect then
			dialog.entryList:SetSelectedIndexWithoutAnimation(indexToSelect)
		end
	end
	function KelaDeactivateSelector()
		KelaPadUI.selector:SetValue(KelaGetATTAnalysisPeriod())
		KelaPadUI.selector:Deactivate()
		KelaPadUI.selectorActive = false
	end
	function KelaUpdateTradingHouseTooltip()
		if TRADING_HOUSE_GAMEPAD.currentListObject:GetTradingHouseMode() == ZO_TRADING_HOUSE_MODE_LISTINGS then 
			GAMEPAD_TRADING_HOUSE_LISTINGS:UpdateItemSelectedTooltip(KELA_TRADINGHOUSE_CURRENT_SELECTEDDATA)
		elseif TRADING_HOUSE_GAMEPAD.currentListObject:GetTradingHouseMode() == ZO_TRADING_HOUSE_MODE_SELL  then					
			GAMEPAD_TRADING_HOUSE_SELL:UpdateItemSelectedTooltip(KELA_TRADINGHOUSE_CURRENT_SELECTEDDATA)
		end	
	end
    local noChoiceCallback = function(dialog)
		KelaDeactivateSelector()
		KelaPadUI.selector.control:SetHidden(true)
	end	
	ESO_Dialogs["TRADING_HOUSE_CHANGE_ACTIVE_GUILD"] =
	{
		gamepadInfo =
		{
			dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
		},
		setup = SetupGuildSelectionDialog,
		blockDialogReleaseOnPress = IsKPUITradingHouseSettingEnabled() and true,
		title =
		{
			text = SI_GAMEPAD_TRADING_HOUSE_GUILD_SELECTION,
		},
		buttons =
		{
			[1] =
			{
				text = SI_GAMEPAD_SELECT_OPTION,
				callback = function(dialog)
					local data = dialog.entryList:GetTargetData()
					if IsKPUITradingHouseSettingEnabled() then
						if data.guildId then
							dialog.info.blockDialogReleaseOnPress = false
							local currentGuildId = GetSelectedTradingHouseGuildId()
							if data.guildId ~= currentGuildId then
								SelectTradingHouseGuildId(data.guildId)
							end
							KelaPadUI.selector.control:SetHidden(true)
							zo_callLater(KelaUpdateTradingHouseTooltip, 150)
						else
							if KelaPadUI.selectorActive then
								local amount = KelaPadUI.selector:GetValue()
								if amount == 0 then amount = 1 end
								KelaSetSetting(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ATT_PERIOD, amount, true)
								KelaDeactivateSelector()						
							elseif data and data.callback then
								data.callback(dialog)
							end					
						end
					else
					   if data.guildId then
						   SelectTradingHouseGuildId(data.guildId)
					   end					
					end
				end
			},

			[2] =
			{
				text = SI_DIALOG_EXIT,
				callback = function(dialog)
					if IsKPUITradingHouseSettingEnabled() then
						if KelaPadUI.selectorActive then
							KelaDeactivateSelector()
						else
							KelaPadUI.selector.control:SetHidden(true)
							dialog.info.blockDialogReleaseOnPress = false
						end	
						zo_callLater(KelaUpdateTradingHouseTooltip, 150)
					end
				end
			}
		},
        noChoiceCallback = noChoiceCallback,
	}
end


function ZO_Tooltip:LayoutEnchantingTradingTooltip(tooltip, itemLink, maxIterations, itemUniqueId)
    local icon = GetItemLinkIcon(itemLink)

	tooltip.scrollTooltip:ResetToTop()
	tooltip.tip:ClearLines()
	tooltip = tooltip.tip
	local lastControl

	local stackCount = maxIterations
	if not stackCount then stackCount = 1 end
	
    if itemLink and itemLink ~= "" then
        if tooltip.icon then
            tooltip.icon:SetTexture(icon)
            tooltip.icon:SetHidden(false)
        end

		local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
		bodySection:AddLine(GetString(KELA_TRADING_TRADING_INFO))
		bodySection:AddLine(" ")
		tooltip:AddSection(bodySection)
		lastControl = bodySection
		
		-- local resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink = GetItemLinks(itemLink)		
		local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
		local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)
		-- Purchased item information
		local isByingItem = false
		local tblBuyingItems = {}
		local itemUID
		if itemUniqueId then
			tblBuyingItems = kpuiSVBuyingData["buyingTable"]			
			itemUID = Id64ToString(itemUniqueId)
			if tblBuyingItems[itemUID] ~= nil then
				isByingItem = true
			end
		end	
		-- basic information
		if trueTTC or trueATT then
			if not ctlEnchantingInfo then ctlEnchantingInfo = CreateControlFromVirtual("$(parent)Info", tooltip, "KPUI_MainInfo") end	
			lastControl, _, isTwoRowFooter = SetSmithTradingInfo(ctlEnchantingInfo, lastControl, priceInfoTTC, priceInfoATT, nil, nil, stackCount)
			local offsetY = 15
			if isTwoRowFooter and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then offsetY = 35 end
			lastControl = AddClearLine(tooltip, lastControl, 0, offsetY)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
				if not ctlEnchantingGraph then ctlEnchantingGraph = CreateControlFromVirtual("$(parent)Graph", tooltip, "KPUI_Graph") end							
				lastControl = SetSmithGraph (ctlEnchantingGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, stackCount)		
			else
				if ctlEnchantingGraph then ctlEnchantingGraph:SetHidden(true) end	
			end
		else
			local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
			bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
			tooltip:AddSection(bodySection)
			bodySection:ClearAnchors()
			bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
			bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
			lastControl = bodySection
			lastControl = AddClearLine(tooltip, lastControl, 0, 0)
			if ctlEnchantingInfo then ctlEnchantingInfo:SetHidden(true) end	
			if ctlEnchantingGraph then ctlEnchantingGraph:SetHidden(true) end	
		end
		-- Purchased item information
		if isByingItem then
			local strBuyInfo = GetBuyInfo(tblBuyingItems, itemUID)
			lastControl = SetSmithNotes(tooltip, lastControl, strBuyInfo)			
		end	
		-- Previous sales
		if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
			if not ctlEnchantingListings then ctlEnchantingListings = CreateControlFromVirtual("$(parent)Listings", tooltip, "KPUI_PreviousListings") end	
			lastControl = SetSmithListings(ctlEnchantingListings, lastControl, listingItemsTable)
			lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
		else
			if ctlEnchantingListings then ctlEnchantingListings:SetHidden(true) end	
		end	
	else
		HideEnchantingTooltipControls()				
    end

end

function ZO_Tooltip:LayoutAlchemyTradingTooltip(tooltip, itemLink, maxIterations)
    local icon = GetItemLinkIcon(itemLink)

	tooltip.scrollTooltip:ResetToTop()
	tooltip.tip:ClearLines()
	tooltip = tooltip.tip
	local lastControl

	local stackCount = maxIterations
	if not stackCount then stackCount = 1 end
	
    if itemLink and itemLink ~= "" then
        if tooltip.icon then
            tooltip.icon:SetTexture(icon)
            tooltip.icon:SetHidden(false)
        end

		local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
		bodySection:AddLine(GetString(KELA_TRADING_TRADING_INFO))
		bodySection:AddLine(" ")
		tooltip:AddSection(bodySection)
		lastControl = bodySection
		
		local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
		local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)

		-- basic information
		if trueTTC or trueATT then
			if not ctlAlchemyInfo then ctlAlchemyInfo = CreateControlFromVirtual("$(parent)Info", tooltip, "KPUI_MainInfo") end	
			lastControl, _, isTwoRowFooter = SetSmithTradingInfo(ctlAlchemyInfo, lastControl, priceInfoTTC, priceInfoATT, nil, nil, stackCount)
			local offsetY = 15
			if isTwoRowFooter and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then offsetY = 35 end
			lastControl = AddClearLine(tooltip, lastControl, 0, offsetY)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
				if not ctlAlchemyGraph then ctlAlchemyGraph = CreateControlFromVirtual("$(parent)Graph", tooltip, "KPUI_Graph") end							
				lastControl = SetSmithGraph (ctlAlchemyGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, stackCount)			
			else
				if ctlAlchemyGraph then ctlAlchemyGraph:SetHidden(true) end	
			end
		else
			local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
			bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
			tooltip:AddSection(bodySection)
			bodySection:ClearAnchors()
			bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
			bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
			lastControl = bodySection
			lastControl = AddClearLine(tooltip, lastControl, 0, 0)
			if ctlAlchemyInfo then ctlAlchemyInfo:SetHidden(true) end	
			if ctlAlchemyGraph then ctlAlchemyGraph:SetHidden(true) end	
		end
		-- Previous sales
		if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
			if not ctlAlchemyListings then ctlAlchemyListings = CreateControlFromVirtual("$(parent)Listings", tooltip, "KPUI_PreviousListings") end	
			lastControl = SetSmithListings(ctlAlchemyListings, lastControl, listingItemsTable)
			lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
		else
			if ctlAlchemyListings then ctlAlchemyListings:SetHidden(true) end	
		end	
	else
		HideAlchemyTooltipControls()				
    end

end

function ZO_Tooltip:LayoutProvisionerTradingTooltip(tooltip, recipeListIndex, recipeIndex, selectedData)
    local _, icon = GetRecipeResultItemInfo(recipeListIndex, recipeIndex)
    local itemLink = GetRecipeResultItemLink(recipeListIndex, recipeIndex)

	tooltip.scrollTooltip:ResetToTop()
	tooltip.tip:ClearLines()
	tooltip = tooltip.tip
	local lastControl

	local stackCount = selectedData and selectedData.stackCount
	if not stackCount then stackCount = 1 end
	
    if itemLink and itemLink ~= "" then
        if tooltip.icon then
            tooltip.icon:SetTexture(icon)
            tooltip.icon:SetHidden(false)
        end

		local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
		bodySection:AddLine(GetString(KELA_TRADING_TRADING_INFO))
		bodySection:AddLine(" ")
		tooltip:AddSection(bodySection)
		lastControl = bodySection
	
		local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
		local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)

		-- basic information
		if trueTTC or trueATT then
			if not ctlProvisionerInfo then ctlProvisionerInfo = CreateControlFromVirtual("$(parent)ProvInfo", tooltip, "KPUI_MainInfo") end	
			lastControl, _, isTwoRowFooter = SetSmithTradingInfo(ctlProvisionerInfo, lastControl, priceInfoTTC, priceInfoATT, nil, selectedData, stackCount)
			local offsetY = 15
			if isTwoRowFooter and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then offsetY = 35 end
			lastControl = AddClearLine(tooltip, lastControl, 0, offsetY)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
				if not ctlProvisionerGraph then ctlProvisionerGraph = CreateControlFromVirtual("$(parent)ProvGraph", tooltip, "KPUI_Graph") end							
				lastControl = SetSmithGraph (ctlProvisionerGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, stackCount)
			else
				if ctlProvisionerGraph then ctlProvisionerGraph:SetHidden(true) end	
			end
		else
			local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
			bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
			tooltip:AddSection(bodySection)
			bodySection:ClearAnchors()
			bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
			bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
			lastControl = bodySection
			lastControl = AddClearLine(tooltip, lastControl, 0, 0)
			if ctlProvisionerInfo then ctlProvisionerInfo:SetHidden(true) end	
			if ctlProvisionerGraph then ctlProvisionerGraph:SetHidden(true) end	
		end
		-- Previous sales
		if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
			if not ctlProvisionerListings then ctlProvisionerListings = CreateControlFromVirtual("$(parent)SListings", tooltip, "KPUI_PreviousListings") end	
			lastControl = SetSmithListings(ctlProvisionerListings, lastControl, listingItemsTable)
			lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
		else
			if ctlProvisionerListings then ctlProvisionerListings:SetHidden(true) end	
		end	
	else
		HideProvisionerTooltipControls()				
    end

end

function ZO_Tooltip:LayoutSmithingCreationTooltip(tooltip, itemLink)

	tooltip.scrollTooltip:ResetToTop()
	tooltip.tip:ClearLines()
	tooltip = tooltip.tip
	local lastControl
	
    local icon = GetItemLinkIcon(itemLink)

    if itemLink and itemLink ~= "" then

	
		if tooltip.icon then
            tooltip.icon:SetTexture(icon)
            tooltip.icon:SetHidden(false)
        end

		local resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink = GetItemLinks(itemLink)
		local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
		local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)

		-- empty line
		-- AddClearLine(true)
		local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
		bodySection:AddLine(GetString(KELA_TRADING_TRADING_INFO))
		bodySection:AddLine(" ")
		tooltip:AddSection(bodySection)
		lastControl = bodySection
		
		-- basic information
		if trueTTC or trueATT then
			if not ctlCreationInfo then ctlCreationInfo = CreateControlFromVirtual("$(parent)Info", tooltip, "KPUI_MainInfo") end	
			lastControl = SetSmithTradingInfo(ctlCreationInfo, lastControl, priceInfoTTC, priceInfoATT)
			lastControl = AddClearLine(tooltip, lastControl, 0, 15)
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
				if not ctlCreationGraph then ctlCreationGraph = CreateControlFromVirtual("$(parent)Graph", tooltip, "KPUI_Graph") end							
				lastControl = SetSmithGraph (ctlCreationGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, 1)
			else
				if ctlCreationGraph then ctlCreationGraph:SetHidden(true) end	
			end
		else
			local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
			bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
			tooltip:AddSection(bodySection)
			bodySection:ClearAnchors()
			bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
			bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
			lastControl = bodySection
			lastControl = AddClearLine(tooltip, lastControl, 0, 0)
			if ctlCreationInfo then ctlCreationInfo:SetHidden(true) end	
			if ctlCreationGraph then ctlCreationGraph:SetHidden(true) end
		end		
		-- Previous sales
		if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
			if not ctlCreationListings then ctlCreationListings = CreateControlFromVirtual("$(parent)Listings", tooltip, "KPUI_PreviousListings") end	
			lastControl = SetSmithListings(ctlCreationListings, lastControl, listingItemsTable)
			lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
		else
			if ctlCreationListings then ctlCreationListings:SetHidden(true) end	
		end	
		-- Other item quality
		if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_QUALITY) and (normalItemLink or fineItemLink or superiorItemLink or epicItemLink or legendaryItemLink) then
			local notSuccess
			if not ctlCreationOther then ctlCreationOther = CreateControlFromVirtual("$(parent)Other", tooltip, "KPUI_OtherQualityInfo") end	
			lastControl, notSuccess = SetSmithQualityPrices(tooltip, ctlCreationOther, lastControl, itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink)
			if notSuccess then 
				if ctlCreationOther then ctlCreationOther:SetHidden(true) end	
			else
				lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
			end
		else
			if ctlCreationOther then ctlCreationOther:SetHidden(true) end	
		end		
	else
		HideCreationTooltipControls()
	end
	

end

function ZO_Tooltip:LayoutSmithingTradingTooltip(tooltip, itemBagId, itemSlotIndex, craftingSkillType, itemUniqueId, selectedData)

	tooltip.scrollTooltip:ResetToTop()
	tooltip.tip:ClearLines()
	tooltip = tooltip.tip
	local lastControl
    local itemLink, icon
	local hide
	if craftingSkillType then 
		hide = "result"
		itemLink = GetSmithingImprovedItemLink(itemBagId, itemSlotIndex, craftingSkillType) 
		_, icon = GetSmithingImprovedItemInfo(itemBagId, itemSlotIndex, craftingSkillType)
	else
		hide = "source"
		itemLink = GetItemLink(itemBagId, itemSlotIndex)
		icon = GetItemLinkIcon(itemLink)
	end

    if itemLink and itemLink ~= "" then

	
		if tooltip.icon then
            tooltip.icon:SetTexture(icon)
            tooltip.icon:SetHidden(false)
        end

		if not IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING) then
			KELA_SMITHING_IMPROVED_TOOLTIP_TYPE = 0
		end
	
		
		if KELA_SMITHING_IMPROVED_TOOLTIP_TYPE == 0 then
			HideImprovementTooltipControls()
			if craftingSkillType then 
				tooltip:LayoutImproveResultSmithingItem(itemBagId, itemSlotIndex, craftingSkillType)
			else
				tooltip:LayoutImproveSourceSmithingItem(itemBagId, itemSlotIndex)
			end			
		elseif KELA_SMITHING_IMPROVED_TOOLTIP_TYPE == 1 then
		
		 --GetItemLinkFinalEnchantId (itemLink)

			local resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink = GetItemLinks(itemLink)
			local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
			local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)

			-- add the item name
			local name = GetItemLinkName(itemLink)
			-- Purchased item information
			local isByingItem = false
			local tblBuyingItems = {}
			local itemUID
			if itemUniqueId then
				tblBuyingItems = kpuiSVBuyingData["buyingTable"]			
				itemUID = Id64ToString(itemUniqueId)
				if tblBuyingItems[itemUID] ~= nil then
					name = name.." *"
					isByingItem = true
				end
			end		
			tooltip:AddItemTitle(itemLink, name)
			
			-- empty line
			-- AddClearLine(true)
			local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
			bodySection:AddLine(" ")
			tooltip:AddSection(bodySection)
			lastControl = bodySection

			-- basic information
			if trueTTC or trueATT then
				if craftingSkillType then -- result tooltip
					if not ctlResultInfo then ctlResultInfo = CreateControlFromVirtual("$(parent)RInfo", tooltip, "KPUI_MainInfo") end	
					lastControl = SetSmithTradingInfo(ctlResultInfo, lastControl, priceInfoTTC, priceInfoATT, nil, selectedData)
					lastControl = AddClearLine(tooltip, lastControl, 0, 15)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
						if not ctlResultGraph then ctlResultGraph = CreateControlFromVirtual("$(parent)RGraph", tooltip, "KPUI_Graph") end							
						lastControl = SetSmithGraph (ctlResultGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, 1)
					else
						if ctlResultGraph then ctlResultGraph:SetHidden(true) end	
					end
				else
					if not ctlSourceInfo then ctlSourceInfo = CreateControlFromVirtual("$(parent)SInfo", tooltip, "KPUI_MainInfo") end	
					lastControl = SetSmithTradingInfo(ctlSourceInfo, lastControl, priceInfoTTC, priceInfoATT, nil, selectedData)
					lastControl = AddClearLine(tooltip, lastControl, 0, 15)
					if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
						if not ctlSourceGraph then ctlSourceGraph = CreateControlFromVirtual("$(parent)SGraph", tooltip, "KPUI_Graph") end							
						lastControl = SetSmithGraph (ctlSourceGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, 1)
					else
						if ctlSourceGraph then ctlSourceGraph:SetHidden(true) end	
					end
				end
			else
				local bodySection = tooltip:AcquireSection(tooltip:GetStyle("bodySection1"))
				bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
				tooltip:AddSection(bodySection)
				bodySection:ClearAnchors()
				bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
				bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
				lastControl = bodySection
				lastControl = AddClearLine(tooltip, lastControl, 0, 0)
				if hide == "source" then
					if ctlSourceInfo then ctlSourceInfo:SetHidden(true) end	
					if ctlSourceGraph then ctlSourceGraph:SetHidden(true) end					
				elseif hide == "result" then
					if ctlResultInfo then ctlResultInfo:SetHidden(true) end						
					if ctlResultGraph then ctlResultGraph:SetHidden(true) end
				end				
			end
			-- Purchased item information
			if isByingItem then
				local strBuyInfo = GetBuyInfo(tblBuyingItems, itemUID)
				lastControl = SetSmithNotes(tooltip, lastControl, strBuyInfo)			
			end					
			-- Previous sales
			if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
				if craftingSkillType then -- result tooltip
					if not ctlResultListings then ctlResultListings = CreateControlFromVirtual("$(parent)RListings", tooltip, "KPUI_PreviousListings") end	
					lastControl = SetSmithListings(ctlResultListings, lastControl, listingItemsTable)
				else
					if not ctlSourceListings then ctlSourceListings = CreateControlFromVirtual("$(parent)SListings", tooltip, "KPUI_PreviousListings") end	
					lastControl = SetSmithListings(ctlSourceListings, lastControl, listingItemsTable)
				end
				lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
			else
				if hide == "source" then
					if ctlSourceListings then ctlSourceListings:SetHidden(true) end	
				elseif hide == "result" then
					if ctlResultListings then ctlResultListings:SetHidden(true) end	
				end	
			end	
			-- Other item quality
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_QUALITY) and (normalItemLink or fineItemLink or superiorItemLink or epicItemLink or legendaryItemLink) then
				local notSuccess
				if craftingSkillType then -- result tooltip
					if not ctlResultOther then ctlResultOther = CreateControlFromVirtual("$(parent)ROther", tooltip, "KPUI_OtherQualityInfo") end	
					lastControl, notSuccess = SetSmithQualityPrices(tooltip, ctlResultOther, lastControl, itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink) --, traitInformation, tooltip)
				else
					if not ctlSourceOther then ctlSourceOther = CreateControlFromVirtual("$(parent)SOther", tooltip, "KPUI_OtherQualityInfo") end	
					lastControl, notSuccess = SetSmithQualityPrices(tooltip, ctlSourceOther, lastControl, itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink) --, traitInformation, tooltip)
				end
				if notSuccess then 
					if hide == "source" then
						if ctlSourceOther then ctlSourceOther:SetHidden(true) end	
					elseif hide == "result" then
						if ctlResultOther then ctlResultOther:SetHidden(true) end		
					end	
				else
					lastControl = AddClearLine(tooltip, lastControl, 0, -15)	
				end
			else
				if hide == "source" then
					if ctlSourceOther then ctlSourceOther:SetHidden(true) end	
				elseif hide == "result" then
					if ctlResultOther then ctlResultOther:SetHidden(true) end		
				end	
			end		
		else
			HideImprovementTooltipControls(hide)
		end
	else
		HideImprovementTooltipControls(hide)				
    end

	if craftingSkillType then -- result tooltip
		--Add line for tradeable loss
		if IsItemBoPAndTradeable(itemBagId, itemSlotIndex) then
			local section = tooltip:AcquireSection(tooltip:GetStyle("bodySection"))
			section:AddLine(GetString(SI_SMITHING_IMPROVEMENT_TRADE_BOP_WILL_BECOME_UNTRADEABLE), tooltip:GetStyle("bodyDescription"), tooltip:GetStyle("failed"))
			tooltip:AddSection(section)
		end
	end
	
end

function ZO_Tooltip:LayoutTradingTooltip(currentScene, itemLink, selectedData, tooltipType, parentControl, leftAnchor, offsetX, offsetY, itemUniqueId)


	KELA_TRADINGHOUSE_CURRENTSCENE = currentScene
	KELA_TRADINGHOUSE_CURRENT_SELECTEDDATA = selectedData
	
	local isCrafting

	if currentScene == "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS" and leftAnchor then
		KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_TRADING_TOOLTIP.bgType = KPUI_GAMEPAD_TOOLTIP_DARK_BG	
	-- elseif currentScene == "GAMEPAD_SMITHING_IMPROVEMENT" then
		-- isCrafting = true
	else
		KPUI_GAMEPAD_TOOLTIPS.tooltips.KPUI_GAMEPAD_TRADING_TOOLTIP.bgType = KPUI_GAMEPAD_TOOLTIP_NORMAL_BG
	end
	
	local currentSceneName = SCENE_MANAGER:GetCurrentScene():GetName()
	if currentSceneName ~= "tradingHousePreview_Gamepad" and not ITEM_PREVIEW_KEYBOARD:IsInteractionCameraPreviewEnabled() then

		if offsetX == nil then offsetX = 0 end
		if offsetY == nil then offsetY = 0 end


		local tooltypeTradingControl = KPUI_GAMEPAD_TOOLTIPS:GetTooltipInfo(tooltipType).control
		tooltypeTradingControl:ClearAnchors()
		if leftAnchor then 
			tooltypeTradingControl:SetAnchor(TOPRIGHT, parentControl, TOPLEFT, -offsetX, offsetY) 
			tooltypeTradingControl:SetAnchor(BOTTOMRIGHT, parentControl, BOTTOMLEFT, -offsetX, offsetY) 	
		-- elseif isCrafting then
			-- tooltypeTradingControl:SetAnchor(TOPRIGHT, parentControl, TOPRIGHT, -10, 53) 
			-- tooltypeTradingControl:SetAnchor(BOTTOMRIGHT, parentControl, BOTTOMRIGHT, -10, -125) 		
		else
			tooltypeTradingControl:SetAnchor(TOPLEFT, parentControl, TOPRIGHT, offsetX, offsetY) 
			tooltypeTradingControl:SetAnchor(BOTTOMLEFT, parentControl, BOTTOMRIGHT, offsetX, offsetY) 	
		end	

		local iconBank = zo_iconFormatInheritColor("esoui/art/icons/servicemappins/servicepin_bank.dds", 20, 20)
		local strGold = zo_strformat("|t20:20:<<3>>|t |<<1>> (<<2>>)|r ", ZO_CurrencyControl_FormatCurrency(GetCurrencyAmount(CURT_MONEY)), iconBank..ZO_CurrencyControl_FormatCurrency(GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_BANK)), GetCurrencyGamepadIcon(CURT_MONEY))
		local iconBag = zo_iconFormatInheritColor("EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds", 20, 20)
		local strBackpack = iconBag.." "..zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))			
		local updatedString = ""
		if TamrielTradeCentre ~= nil then
			updatedString = TamrielTradeCentrePrice:GetPriceTableUpdatedDateString()
		end
		
		-- Add Guild Name, Available Funds, and Inventory Capacity
		if KelaIsSceneTradingHouse(currentScene) then
			-- Shown in the Guild Trader
			local bodySection = self:AcquireSection(self:GetStyle("bodySection1"))
			local currentGuildId = GetSelectedTradingHouseGuildId()
			guildName = GetGuildName(currentGuildId)
			if currentGuildId and guildName ~= "" then
				local allianceId = GetGuildAlliance(currentGuildId)
				local icon = GetLargeAllianceSymbolIcon(allianceId)				
				local guildColor = colors.COLOR_WHITE
				if ArkadiusTradeTools ~= nil then
					guildColor = ArkadiusTradeTools:GetGuildColor(guildName)
				end
				local currentListings, maxListings = GetTradingHouseListingCounts()
				guildName = zo_iconFormat(icon, 22, 22).." "..guildColor:Colorize(guildName.." ("..tostring(currentListings).."/"..tostring(maxListings)..")")
				--KPUI_GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, guildName, strGold..", "..strBackpack, "* "..colors.COLOR_TTC:Colorize(GetString(KELA_TRADING_TTC_TITLE)).." - "..string.lower(updatedString), true)
				bodySection:AddLine(colors.GENERAL_COLOR_NORMAL:Colorize(GetString(SI_GAMEPAD_GUILD_BANK_GUILD_FOOTER_LABEL))..": "..guildName, self:GetStyle("bodyHeader"))
			
			end
			--KPUI_GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, guildName, strGold..", "..strBackpack, "* "..colors.COLOR_TTC:Colorize(GetString(KELA_TRADING_TTC_TITLE)).." - "..string.lower(updatedString), true)
			-- Show available funds and bank capacity
			bodySection:AddLine(colors.GENERAL_COLOR_NORMAL:Colorize(GetString(SI_GAMEPAD_GUILD_BANK_AVAILABLE_FUNDS))..": "..strGold, self:GetStyle("bodyHeader"))
			bodySection:AddLine(colors.GENERAL_COLOR_NORMAL:Colorize(GetString(SI_GAMEPAD_INVENTORY_CAPACITY))..": "..strBackpack, self:GetStyle("bodyHeader"))
			self:AddSection(bodySection)	
		else
			-- Shown in the Bank
			--KPUI_GAMEPAD_TOOLTIPS:SetStatusLabelText(tooltipType, "", strGold..", "..strBackpack, "* "..colors.COLOR_TTC:Colorize(GetString(KELA_TRADING_TTC_TITLE)).." - "..string.lower(updatedString), true)
		end


		-- Fill info when an item is selected
		local stackCount = selectedData and selectedData.stackCount
		if not stackCount then stackCount = 1 end
		local lastControl
		if itemLink then
			local listingItemsTable = KelaGetItemLinkListingTable(itemLink)
			local resultItemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink = GetItemLinks(itemLink)
			-- the name of the thing
			local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(itemLink))
			local nameColor = GetItemQualityColor(GetItemLinkDisplayQuality(itemLink))
			local colorizedItemName = nameColor:Colorize(name)
			-- Information about the purchased item
			local isByingItem = false
			local tblBuyingItems = {}
			local itemUID
			if itemUniqueId then
				tblBuyingItems = kpuiSVBuyingData["buyingTable"]			
				itemUID = Id64ToString(itemUniqueId)
				if tblBuyingItems[itemUID] ~= nil then
					colorizedItemName = colorizedItemName.." *"
					isByingItem = true
				end
			end			
			local function AddTitle(lastControl)
				-- Adds the Item name
				local bodySection = self:AcquireSection(self:GetStyle("bodySection1"))
				bodySection:AddLine(colorizedItemName, self:GetStyle("title"))
				self:AddSection(bodySection)
				if lastControl then
					bodySection:ClearAnchors()
					bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 10)
					bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 10)								
				end
				return bodySection			
			end

			-- information about the level of benefits in guilds by type of product	
			if KelaIsSceneTradingHouse(currentScene) and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_GUILDSTAT) then
				local itemTradeCategory = KelaGetItemTradeCategory(itemLink)
				if KELA_ATT_GUILD_STAT[itemTradeCategory] then 
					local bodySection = self:AcquireSection(self:GetStyle("bodySection1"))
					bodySection:AddLine(colors.GENERAL_COLOR_NORMAL:Colorize(GetString(KELA_TRADING_TRADING_ITEMTYPE))..GetString("KELA_TRADING_ITEMTYPE_SALES_BYGUILDS", itemTradeCategory), self:GetStyle("bodyHeader"))
					self:AddSection(bodySection)			
					lastControl = bodySection
					lastControl = AddTitle(lastControl)
					if not ctlItemTypeGuildStat then ctlItemTypeGuildStat = CreateControlFromVirtual("$(parent)ctlItemTypeGuildStat", self, "KPUI_ItemTypeGuildStat") end	
					lastControl = ctlItemTypeGuildStat.SetItemTypeGuildStat(itemLink, itemTradeCategory, lastControl)
					--lastControl = AddTitle(lastControl)
				else
					if ctlItemTypeGuildStat then ctlItemTypeGuildStat:SetHidden(true) end	
					lastControl = AddTitle()
				end
			else
				if ctlItemTypeGuildStat then ctlItemTypeGuildStat:SetHidden(true) end	
				lastControl = AddTitle()
			end
			
			-- basic information
			local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemLink)
			if trueTTC or trueATT then
				if not ctlTradingInfo then ctlTradingInfo = CreateControlFromVirtual("$(parent)Info", self, "KPUI_MainInfo") end	
				lastControl, effectOfDeal, isTwoRowFooter = SetSmithTradingInfo(ctlTradingInfo, lastControl, priceInfoTTC, priceInfoATT, currentScene, selectedData, stackCount)
				local offsetY = 15
				if isTwoRowFooter and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then offsetY = 35 end
				lastControl = AddClearLine(self, lastControl, 0, offsetY)
				if effectOfDeal and effectOfDeal ~= "" then
					SafeAddString(SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_DIALOG_TEXT, GetString(KELA_TRADING_TRADING_CONFIRM_BUY).."\n\n"..effectOfDeal, 1)
					SafeAddString(SI_GAMEPAD_TRADING_HOUSE_CONFIRM_BUY_MULTIPLE_DIALOG_TEXT, GetString(KELA_TRADING_TRADING_CONFIRM_BUY_MULT).."\n\n"..effectOfDeal, 0)
				end
				if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO) then
					if not KPUI_ATTGraph then KPUI_ATTGraph = CreateControlFromVirtual("$(parent)ProvGraph", self, "KPUI_Graph") end							
					lastControl = SetSmithGraph (KPUI_ATTGraph, lastControl, itemLink, priceInfoTTC, priceInfoATT, stackCount)
				else
					if KPUI_ATTGraph then KPUI_ATTGraph:SetHidden(true) end	
				end
			else
				local bodySection = self:AcquireSection(self:GetStyle("bodySection1"))
				bodySection:AddLine(GetString(KELA_TRADING_TRADING_NOTINFO))
				self:AddSection(bodySection)
				bodySection:ClearAnchors()
				bodySection:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
				bodySection:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)					
				lastControl = bodySection
				lastControl = AddClearLine(self, lastControl, 0, 0)
				if ctlTradingInfo then ctlTradingInfo:SetHidden(true) end	
				if KPUI_ATTGraph then KPUI_ATTGraph:SetHidden(true) end	
			end

			-- Information about the purchased item
			if isByingItem then
				local strBuyInfo = GetBuyInfo(tblBuyingItems, itemUID)
				lastControl = SetSmithNotes(self, lastControl, strBuyInfo)			
			end

			-- Previous sales
			if next(listingItemsTable) ~= nil and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS) then
				if not ctlPreviousListings then ctlPreviousListings = CreateControlFromVirtual("$(parent)Listings", self, "KPUI_PreviousListings") end	
				lastControl = SetSmithListings(ctlPreviousListings, lastControl, listingItemsTable)
				lastControl = AddClearLine(self, lastControl, 0, -15)	
			else
				if ctlPreviousListings then ctlPreviousListings:SetHidden(true) end	
			end

			-- Another level of things
			if IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_QUALITY) and (normalItemLink or fineItemLink or superiorItemLink or epicItemLink or legendaryItemLink) then
				local notSuccess
				if not ctlOtherQualityInfo then ctlOtherQualityInfo = CreateControlFromVirtual("$(parent)Other", self, "KPUI_OtherQualityInfo") end	
				lastControl, notSuccess = SetSmithQualityPrices(self, ctlOtherQualityInfo, lastControl, itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink)
				if notSuccess then 
					if ctlOtherQualityInfo then ctlOtherQualityInfo:SetHidden(true) end	
				else
					lastControl = AddClearLine(self, lastControl, 0, -15)	
				end
			else
				if ctlOtherQualityInfo then ctlOtherQualityInfo:SetHidden(true) end	
			end

			-- Production
			if resultItemLink and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_PRODUCTION) then
				local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(resultItemLink)
				if trueTTC or trueATT then
					if not ctlProductMaterialInfoRow then ctlProductMaterialInfoRow = CreateControlFromVirtual("$(parent)ctlProductMaterialInfoRow", self, "KPUI_ProductMaterialInfo") end	
					lastControl = SetProductionPrices(ctlProductMaterialInfoRow, lastControl, resultItemLink, priceInfoTTC, priceInfoATT)
				else
					if ctlProductMaterialInfoRow then ctlProductMaterialInfoRow:SetHidden(true) end	
				end
			else
				if ctlProductMaterialInfoRow then ctlProductMaterialInfoRow:SetHidden(true) end	
			end

			-- crafting components table
			local isATTCraftingInfo, craftingComponentPrices = KelaGetCurrentATTCraftingInfo(itemLink)
			if isATTCraftingInfo and IsKPUITradingHouseSettingEnabled(KELA_SETTING_PANEL_TRADE_TOOLTIP_COMPONENTS) then 
				if not ctlCraftingComponentsInfo then ctlCraftingComponentsInfo = CreateControlFromVirtual("$(parent)ctlCraftingInfo", self, "KPUI_CraftingInfo") end	
				SetCraftingComponents(ctlCraftingComponentsInfo, lastControl, craftingComponentPrices)
			else
				if ctlCraftingComponentsInfo then ctlCraftingComponentsInfo:SetHidden(true) end					
			end
			lastControl = AddClearLine(self, lastControl, 0, -15)	
		else
			HideTradingTooltipControls()
			KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)	
		end
	else
		KPUI_GAMEPAD_TOOLTIPS:HideTooltip(KPUI_GAMEPAD_TRADING_TOOLTIP)
	end
end



--Integration with TamrielTradeCentre and ArkadiusTradeTools

function GetATTPriceStats(itemLink)
	if not ArkadiusTradeTools then
		return nil
	end
	
	local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
    local seconds_in_day = ArkadiusTradeToolsSales.TooltipExtension.SECONDS_IN_DAY or 60 * 60 * 24
    local days = KelaGetATTAnalysisPeriod()
	local itemSales = ArkadiusTradeToolsSales:GetItemSalesInformation(itemLink, GetTimeStamp() - days * seconds_in_day) --	30 * 86400)

	local stats = {
		Avg = 0,
		Min = math.huge,
		Max = 0,
		Sales = 0,
		Quantity = 0,
	}

	-- local itemQuality = GetItemLinkQuality(itemLink)
	-- local itemType = GetItemLinkItemType(itemLink)

	for link, sales in pairs(itemSales) do
		--link == itemLink
		if KelaCompareLink(link, itemLink) then
			-- Found the item, get stats
			-- Loop through the recordes sales
			for _, sale in pairs(sales) do
				-- Get min and max price
				local price = sale.price / sale.quantity
				if (price < stats.Min) then 
					stats.Min = price 
				end
				if (price > stats.Max) then 
					stats.Max = price 
				end

				-- Tally the sale price, quantity, sale count
				stats.Avg = stats.Avg + sale.price
				stats.Quantity = stats.Quantity + sale.quantity
				stats.Sales = stats.Sales + 1
			end

			if stats.Min == math.huge then stats.Min = 0 end

			-- Calculate average price
			if (stats.Quantity > 1) then
				stats.Avg = math.attRound(stats.Avg / stats.Quantity, 2)
			end

			-- Return the data
			if stats.Quantity > 0 then return stats end
			

		end

	end
	return nil
end


function GetATTPriceAndStatus(itemLink)
	if not ArkadiusTradeTools then
		return "", ""
	end
	
	local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
    local seconds_in_day = ArkadiusTradeToolsSales.TooltipExtension.SECONDS_IN_DAY or 60 * 60 * 24
    local days = KelaGetATTAnalysisPeriod()
	local itemSales = ArkadiusTradeToolsSales:GetItemSalesInformation(itemLink, GetTimeStamp() - days * seconds_in_day) --	30 * 86400)



	local itemQuality = GetItemLinkQuality(itemLink)
	local itemType = GetItemLinkItemType(itemLink)
	for link, sales in pairs(itemSales) do
		averagePrice = 0
		quantity = 0

		--link == itemLink
		if KelaCompareLink(link, itemLink) then
			local minPrice = math.huge
			local maxPrice = 0
			local price
			for _, sale in pairs(sales) do
				price = sale.price / sale.quantity
				if (price < minPrice) then 
					minPrice = price 
				end
				if (price > maxPrice) then 
					maxPrice = price 
				end
			end
		end

		for _, sale in pairs(sales) do
			averagePrice = averagePrice + sale.price
			quantity = quantity + sale.quantity
		end

		if (quantity > 0) then
			averagePrice = math.attRound(averagePrice / quantity, 2)
		else
			averagePrice = 0
		end

		--averagePrice = KelaLocalizedFormatNumber(averagePrice, 2)
		
		if KelaCompareLink(link, itemLink) then
			if (quantity > 0) then
				if (#sales ~= quantity) then
					statsString = zo_strformat("|cf58585<<1>>|r", string.format(GetString(KELA_MM_PRICE_XLISTINGSYITEMS), KelaLocalizedFormatNumber(#sales, 0), KelaLocalizedFormatNumber(quantity, 0)))
				else
					statsString = zo_strformat("|cf58585<<1>>|r", string.format(GetString(KELA_MM_PRICE_XLISTINGS), KelaLocalizedFormatNumber(#sales, 0)))
				end
				return averagePrice, statsString
			end
		end
	end
	return nil, nil 
end

function KelaGetATTPriceInfo(itemLink)
	local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
	local ArkadiusTradeToolsTooltipExtension = ArkadiusTradeToolsSales.TooltipExtension


    local seconds_in_day = ArkadiusTradeToolsTooltipExtension.SECONDS_IN_DAY or 60 * 60 * 24
    local days = KelaGetATTAnalysisPeriod()

    itemLink = ArkadiusTradeToolsSales:NormalizeItemLink(itemLink)
    if itemLink == nil then return end

    local itemSales = ArkadiusTradeToolsSales:GetItemSalesInformation(itemLink, GetTimeStamp() - days * seconds_in_day)
    local itemType = GetItemLinkItemType(itemLink)
	local minPrice = 0
    local maxPrice = 0
	local averagePrice = 0
    local quantity = 0
    local vouchers = 0

	local suggestedPrice = 0
	local suggestedQuantity = 0	
	local valueGroup1 = {}
	local valueGroup2 = {}
	local valueGroup3 = {}
	local valueGroup4 = {}
	local valueGroup5 = {}

	local guildsInfo = {}
	local guildsPrice = {}
	
    for link, sales in pairs(itemSales) do

        if KelaCompareLink(link, itemLink) then
            minPrice = math.huge
            maxPrice = 0
            local price
            for _, sale in pairs(sales) do
                price = sale.price / sale.quantity
                if (price < minPrice) then minPrice = price end
                if ((price > maxPrice) and (price ~= math.huge)) then maxPrice = price end
            end
            --- There are no sales for this item ---
            if (minPrice == math.huge) then minPrice = 0 end
			for _, sale in pairs(sales) do
				averagePrice = averagePrice + sale.price
				quantity = quantity + sale.quantity
			end

			local val1 = minPrice*1.05
			local val2 = maxPrice*0.95
			local range = maxPrice - minPrice
			local borderGroup1 = range*0.25
			local borderGroup2 = range*0.50
			local borderGroup3 = range*0.75
			-- local borderGroup4 = range*0.80
			for _, sale in pairs(sales) do
				local salePrice = sale.price/sale.quantity
				if salePrice >= val1 and salePrice < borderGroup1 then
					valueGroup1[#valueGroup1 + 1] = salePrice
				elseif salePrice >= borderGroup1 and salePrice < borderGroup2 then
					valueGroup2[#valueGroup2 + 1] = salePrice
				elseif salePrice >= borderGroup2 and salePrice < borderGroup3 then
					valueGroup3[#valueGroup3 + 1] = salePrice
				-- elseif salePrice >= borderGroup3 and salePrice < borderGroup4 then
					-- valueGroup4[#valueGroup4 + 1] = salePrice
				elseif salePrice >= borderGroup3 and salePrice <= val2 then
					valueGroup4[#valueGroup4 + 1] = salePrice
				end
			end	
			
			for _, sale in pairs(sales) do
				KelaSetValueIfNil(guildsInfo, sale.guildName, 0)
				guildsInfo[sale.guildName] = guildsInfo[sale.guildName] + sale.quantity --1
			end	
			for _, sale in pairs(sales) do
				local salePrice = sale.price --/sale.quantity
				KelaSetValueIfNil(guildsPrice, sale.guildName, 0)
				guildsPrice[sale.guildName] = guildsPrice[sale.guildName] + salePrice
			end	

        end

		for guildName, countSales in pairs(guildsInfo) do
			if (countSales > 0) then
				guildsPrice[guildName] = math.attRound(guildsPrice[guildName] / countSales, 2)
			else
				guildsPrice[guildName] = 0
			end
		end

        if (quantity > 0) then
            averagePrice = math.attRound(averagePrice / quantity, 2)
        else
            averagePrice = 0
        end

		local selectedSales = valueGroup1
		if #selectedSales < #valueGroup2 then selectedSales = valueGroup2 end
		if #selectedSales < #valueGroup3 then selectedSales = valueGroup3 end
		if #selectedSales < #valueGroup4 then selectedSales = valueGroup4 end
		-- if #selectedSales < #valueGroup5 then selectedSales = valueGroup5 end
		if #selectedSales >= 3 then
			for _, price in ipairs(selectedSales) do
				suggestedPrice = suggestedPrice + price
				suggestedQuantity = suggestedQuantity + 1
			end
		end
        if (suggestedQuantity > 0) then
            suggestedPrice = math.attRound(suggestedPrice / suggestedQuantity, 2)
        else
            suggestedPrice = 0
        end

        if KelaCompareLink(link, itemLink) then
            if (quantity > 0) then
                if (itemType == ITEMTYPE_MASTER_WRIT) then
                    vouchers = ArkadiusTradeToolsSales:GetVoucherCount(itemLink)
                end
				return minPrice, maxPrice, averagePrice, suggestedPrice, vouchers, #sales, quantity, guildsInfo, guildsPrice
            end
			
        end
    end
end

function KelaGetCurrentATTCraftingInfo(itemLink)
	
	local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
    local seconds_in_day = ArkadiusTradeToolsSales.TooltipExtension.SECONDS_IN_DAY or 60 * 60 * 24
    local days = KelaGetATTAnalysisPeriod()
    local itemType = GetItemLinkItemType(itemLink)

	fromTimeStamp = GetTimeStamp() - days * seconds_in_day

	local craftingComponentPrices = {}	



	if itemType == ITEMTYPE_MASTER_WRIT then
		craftingComponentPrices = ArkadiusTradeToolsSales:GetCrafingComponentPrices(itemLink, fromTimeStamp)
		if #craftingComponentPrices > 0 then
			return true, craftingComponentPrices
		end
	elseif itemType == ITEMTYPE_RECIPE then
		local numIngredients = GetItemLinkRecipeNumIngredients(itemLink)
	    local components = {}
		local component
		if(numIngredients > 0) then
			for i = 1, numIngredients do
				local ingredientLink = GetItemLinkRecipeIngredientItemLink(itemLink, i)
				local _, _, ingredientQuantity = GetItemLinkRecipeIngredientInfo(itemLink, i)
				component = { itemLink = ingredientLink, quantity = ingredientQuantity }
				table.insert(components, component)
			end
		end	
		for i = 1, #components do
			if ((components[i].itemLink == nil) or (components[i].quantity == nil)) then
				return false
			end
		end
		for i = 1, #components do
			local component = components[i]
			component.price = ArkadiusTradeToolsSales:GetAveragePricePerItem(component.itemLink, fromTimeStamp)
		end
		if #components > 0 then
			return true, components
		end
		
	end	
	
	return false

end

function KelaUpdateATTGraph(itemLink, graphControl, priceInfoATTSuggestedPrice, priceInfoTTCSuggestedPrice)
	local ArkadiusTradeToolsSales = ArkadiusTradeTools.Modules.Sales
	local L = ArkadiusTradeToolsSales.Localization
	local attRound = math.attRound
    local seconds_in_day = ArkadiusTradeToolsSales.TooltipExtension.SECONDS_IN_DAY or 60 * 60 * 24
    local days = KelaGetATTAnalysisPeriod()
    itemLink = ArkadiusTradeToolsSales:NormalizeItemLink(itemLink)
    if itemLink == nil then return end

    local itemSales = ArkadiusTradeToolsSales:GetItemSalesInformation(itemLink, GetTimeStamp() - days * seconds_in_day)
    local averagePrice = 0
    local quantity
    local guildColors = {}

    graphControl.object:Clear()

    for link, sales in pairs(itemSales) do
        averagePrice = 0
        quantity = 0

        if KelaCompareLink(link, itemLink) then
            local minPrice = math.huge
            local maxPrice = 0
            local price

            for _, sale in pairs(sales) do
                price = sale.price / sale.quantity

                if (price < minPrice) then minPrice = price end
                if ((price > maxPrice) and (price ~= math.huge)) then maxPrice = price end
            end

            --- There are no sales for this item ---
            if (minPrice == math.huge) then
                minPrice = 0
            end


			if priceInfoTTCSuggestedPrice then
				if priceInfoTTCSuggestedPrice < minPrice then minPrice = priceInfoTTCSuggestedPrice - minPrice end
				if priceInfoTTCSuggestedPrice > maxPrice then maxPrice = priceInfoTTCSuggestedPrice + maxPrice end
			end



			graphControl.object:SetRange(GetTimeStamp() - days * seconds_in_day, GetTimeStamp(), minPrice, maxPrice)
			graphControl.object:SetXLabels(-days .. " " .. L["ATT_STR_DAYS"], -days / 2 .. " " .. L["ATT_STR_DAYS"], L["ATT_STR_NOW"])
			graphControl.object:SetYLabels(ArkadiusTradeTools:LocalizeDezimalNumber(attRound(maxPrice, 2)) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t", "", ArkadiusTradeTools:LocalizeDezimalNumber(attRound(minPrice, 2)) .. " |t16:16:EsoUI/Art/currency/currency_gold.dds|t")
        end

        for _, sale in pairs(sales) do
            averagePrice = averagePrice + sale.price
            quantity = quantity + sale.quantity
            if KelaCompareLink(link, itemLink) then
                if (not guildColors[sale.guildName]) then
                    guildColors[sale.guildName] = ArkadiusTradeTools:GetGuildColor(sale.guildName)
                end

                graphControl.object:AddDot(sale.timeStamp, sale.price / sale.quantity, guildColors[sale.guildName])
            end
        end

		if priceInfoATTSuggestedPrice and priceInfoATTSuggestedPrice ~= 0 then
			graphControl.object:AddDot(GetTimeStamp(), priceInfoATTSuggestedPrice, colors.COLOR_ATT)
		end
		
		if priceInfoTTCSuggestedPrice and priceInfoTTCSuggestedPrice ~= 0 then
			graphControl.object:AddDot(GetTimeStamp(), priceInfoTTCSuggestedPrice, colors.COLOR_TTC)
		end		



    end

end

function KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, data, action, stackCount)
	
	local purchasePrice, suggestedATT, suggestedTCC

	if not stackCount then
		stackCount = 1
		if data then stackCount = data.stackCount end
	end

	if data then purchasePrice = data.purchasePrice or data.stackSellPrice end
	
	local multiplier = 1
	local IsMasterWrit = priceInfoATT and (priceInfoATT.Vouchers ~= 0)
	local colorEffectDeal
	local valueEffectDeal				
	local effectOfDeal
	local compareValuePrice
	local compareValueSuffix	
	
	if IsMasterWrit then
		multiplier = priceInfoATT.Vouchers
	end

	if priceInfoATT and priceInfoATT.SuggestedPrice then 
		suggestedATT = math.floor(priceInfoATT.SuggestedPrice)
	else
		suggestedATT = 0
	end
	if priceInfoTTC.SuggestedPrice then 
		suggestedTCC = math.floor(priceInfoTTC.SuggestedPrice)
	else
		suggestedTCC = 0
	end
	local suggestedAVG
	local suggestedATTStack
	local suggestedTCCStack
	local suggestedAVGStack
	local suggestedATTWrit
	local suggestedTCCWrit
	local suggestedAVGWrit

	suggestedATTStack = suggestedATT*stackCount
	suggestedATTWrit = suggestedATT*multiplier
	suggestedTCCStack = suggestedTCC*stackCount
	suggestedTCCWrit = suggestedTCC*multiplier

	if suggestedATT == 0 or suggestedTCC == 0 then
		suggestedAVG = 0
	else
		suggestedAVG = (suggestedATT + suggestedTCC)/2
	end
	if suggestedATTStack == 0 or suggestedTCCStack == 0 then
		suggestedAVGStack = 0
	else
		suggestedAVGStack = (suggestedATTStack + suggestedTCCStack)/2
	end
	if suggestedATTWrit == 0 or suggestedTCCWrit == 0 then
		suggestedAVGWrit = 0
	else
		suggestedAVGWrit = (suggestedATTWrit + suggestedTCCWrit)/2
	end
	
	if IsMasterWrit then
		if suggestedAVGWrit ~= 0 then
			compareValuePrice = suggestedAVGWrit 
			compareValueSuffix = colors.COLOR_WHITE:Colorize(" (AVG)")
		elseif suggestedTCCWrit ~= 0 then
			compareValuePrice = suggestedTCCWrit 
			compareValueSuffix = colors.COLOR_TTC:Colorize(" (TCC)")
		elseif suggestedATTWrit ~= 0 then
			compareValuePrice = suggestedATTWrit 
			compareValueSuffix = colors.COLOR_ATT:Colorize(" (ATT)")
		else
			compareValuePrice = 0
		end
	elseif stackCount ~= 0 then					
		if suggestedAVGStack ~= 0 then
			compareValuePrice = suggestedAVGStack 
			compareValueSuffix = colors.COLOR_WHITE:Colorize(" (AVG)")
		elseif suggestedTCCStack ~= 0 then
			compareValuePrice = suggestedTCCStack 
			compareValueSuffix = colors.COLOR_TTC:Colorize(" (TCC)")
		elseif suggestedATTStack ~= 0 then
			compareValuePrice = suggestedATTStack 
			compareValueSuffix = colors.COLOR_ATT:Colorize(" (ATT)")
		else
			compareValuePrice = 0
		end						
	else
		compareValuePrice = 0
	end
	if action then
		if action == "GAMEPAD_TRADING_HOUSE_LISTINGS" then
			colorEffectDeal = colors.COLOR_GREY
			valueEffectDeal = 0
			if compareValuePrice == 0 then 
				valueEffectDeal = "-"
			elseif compareValuePrice > purchasePrice*1.5 then 
				valueEffectDeal = 2
				colorEffectDeal = colors.COLOR_DEALBAD
			elseif compareValuePrice > purchasePrice*1.1 then 
				valueEffectDeal = 4
				colorEffectDeal = colors.COLOR_DEALGOOD
			elseif compareValuePrice > purchasePrice*0.9 then 
				valueEffectDeal = 5
				colorEffectDeal = colors.COLOR_DEALGREAT
			elseif compareValuePrice > purchasePrice*0.5 then 
				valueEffectDeal = 3
				colorEffectDeal = colors.COLOR_DEALNORMAL
			elseif compareValuePrice > 0 then 
				valueEffectDeal = 1
				colorEffectDeal = colors.COLOR_DEALTERRIBLE
			end
		end
		if action == "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS" then
			colorEffectDeal = colors.COLOR_GREY
			valueEffectDeal = 0
			if compareValuePrice == 0 then 
				valueEffectDeal = "-"
				effectOfDeal = colors.COLOR_GREY:Colorize(GetString("KELA_TRADING_RESUMEPRICEDIALOG", 0))
			elseif compareValuePrice > purchasePrice*1.5 then 
				valueEffectDeal = 5
				colorEffectDeal = colors.COLOR_DEALGREAT
			elseif compareValuePrice > purchasePrice*1.1 then 
				valueEffectDeal = 4
				colorEffectDeal = colors.COLOR_DEALGOOD
			elseif compareValuePrice > purchasePrice*0.9 then 
				valueEffectDeal = 3
				colorEffectDeal = colors.COLOR_DEALNORMAL
			elseif compareValuePrice > purchasePrice*0.5 then 
				valueEffectDeal = 2
				colorEffectDeal = colors.COLOR_DEALBAD
			elseif compareValuePrice > 0 then 
				valueEffectDeal = 1
				colorEffectDeal = colors.COLOR_DEALTERRIBLE
			end
		
			if not effectOfDeal then effectOfDeal = colorEffectDeal:Colorize(GetString("KELA_TRADING_RESUMEPRICEDIALOG", valueEffectDeal))..compareValueSuffix end
		
		end
	end


	
	return valueEffectDeal, effectOfDeal, colorEffectDeal, suggestedTCC, suggestedATT, suggestedAVG, suggestedTCCStack, suggestedATTStack, suggestedAVGStack, suggestedTCCWrit, suggestedATTWrit, suggestedAVGWrit, compareValuePrice

end

function KelaGetEffectIfUndefined(itemData)
	local trueTTC, trueATT, priceInfoTTC, priceInfoATT = KelaGetPriceInfoTTCATT(itemData.itemLink)
	local result = 0
	local colorPrice = colors.COLOR_WHITE
	if trueTTC or trueATT then 				
		local avgPrice = priceInfoTTC.Avg
		local minPrice = priceInfoTTC.Min
		local maxPrice = priceInfoTTC.Max
		if avgPrice ~= 0 and itemData.purchasePricePerUnit ~= avgPrice then
			if itemData.purchasePricePerUnit <= minPrice + (avgPrice-minPrice)*0.1 then
				result = 5
				colorPrice = colors.COLOR_DEALGREAT
			elseif itemData.purchasePricePerUnit <= minPrice + (avgPrice-minPrice)*0.7 then
				result = 4
				colorPrice = colors.COLOR_DEALGOOD
			elseif itemData.purchasePricePerUnit <= avgPrice + (maxPrice-avgPrice)*0.3 then
				result = 3
				colorPrice = colors.COLOR_DEALNORMAL
			elseif itemData.purchasePricePerUnit <= avgPrice + (maxPrice-avgPrice)*0.7 then
				result = 2
				colorPrice = colors.COLOR_DEALBAD
			elseif itemData.purchasePricePerUnit >= avgPrice + (maxPrice-avgPrice)*0.7 then
				result = 1
				colorPrice = colors.COLOR_DEALTERRIBLE
			end
		end
	end
	return result, colorPrice
end

function KelaGetPriceInfoTTCATT (itemLink)

	local priceInfoTTC, priceInfoATT, trueTTC, trueATT
	if TamrielTradeCentre ~= nil then
		local price = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
		if price then 
			priceInfoTTC = price 
			trueTTC = true
		else
			priceInfoTTC = {
			Avg = 0,
			Max = 0,
			Min = 0,
			EntryCount = 0,
			AmountCount = 0,
			SuggestedPrice = 0,
			}			 
			trueTTC = false		
		end
	end
	if ArkadiusTradeTools ~= nil then 
		local minPrice, maxPrice, averagePrice, suggestedPrice, vouchers, sales, quantity, guildsInfo, guildsPrice = KelaGetATTPriceInfo(itemLink)
		if quantity then
			priceInfoATT = {
			Avg = averagePrice,
			Max = maxPrice,
			Min = minPrice,
			EntryCount = sales,
			AmountCount = quantity,
			SuggestedPrice = suggestedPrice,
			Vouchers = vouchers,
			GuildsInfo = guildsInfo,
			GuildsPrice = guildsPrice,
			}
			trueATT = true
		else
			priceInfoATT = {
			Avg = 0,
			Max = 0,
			Min = 0,
			EntryCount = 0,
			AmountCount = 0,
			SuggestedPrice = 0,
			Vouchers = 0,
			GuildsInfo = {},
			GuildsPrice = {},
			}
			trueATT = false
		end
	end
	return trueTTC, trueATT, priceInfoTTC, priceInfoATT
end







------------------------------------
-- Initialization functions
------------------------------------

	
function KPUI_ItemTypeGuildStat_OnInitialize(control)
	local rows = {}
	control.SetItemTypeGuildStat = function(itemLink, itemTradeCategory, lastControl)
		
		control:GetNamedChild("Header"):SetHidden(false)
		control:GetNamedChild("Header"):ClearAnchors()
		control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, 0, 0)
		control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 0, 0)
		control:GetNamedChild("Header"):GetNamedChild("StatGuild"):SetText(GetString(KELA_TRADING_TRADING_GUILD))
		control:GetNamedChild("Header"):GetNamedChild("QuantityGuild"):SetText(GetString(KELA_TRADING_TRADING_QUANTITY))
		control:GetNamedChild("Header"):GetNamedChild("PriceGuild"):SetText(GetString(KELA_TRADING_PRICE_TITLE))
		control:GetNamedChild("Header"):GetNamedChild("ValueGuild"):SetText(GetString(KELA_TRADING_TRADING_PROFIT_COEF))
		lastControl = control:GetNamedChild("Header")
		lastControl = lastControl:GetNamedChild("Divider")
		local tblItemCategorySales = {}
		
		-- spairs(listingItemsTable, function (t, a, b) return (a > b) end) do
		
		for guildName, value in pairs (KELA_ATT_GUILD_STAT[itemTradeCategory]) do
			local K = 1 - (100/(value["price"]/value["quantity"]))
			KelaSetValueIfNil(tblItemCategorySales, K, {})
			KelaSetValueIfNil(tblItemCategorySales[K], "guildName", guildName)
			KelaSetValueIfNil(tblItemCategorySales[K], "price", value["price"])
			KelaSetValueIfNil(tblItemCategorySales[K], "quantity", value["quantity"])
		end

		for _, row in pairs(rows) do
			row:SetHidden(true)
		end

		local count = 0
		for K, value in spairs (tblItemCategorySales, function (t, a, b) return (a > b) end) do
			K = KelaLocalizedFormatNumber(K, 3)
			count = count + 1
			local color = ArkadiusTradeTools:GetGuildColor(value["guildName"])
			local row = GetControl(control:GetName().."row"..count)
			if not row then row = CreateControlFromVirtual("$(parent)row", control, "KPUI_ItemTypeGuildStatRow", count) end	
			rows[#rows + 1] = row
			row:ClearAnchors()
			row:SetHidden(false)
			row:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			row:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
			row:GetNamedChild("StatGuild"):SetText(color:Colorize(value["guildName"]))
			row:GetNamedChild("QuantityGuild"):SetText(value["quantity"])
			row:GetNamedChild("PriceGuild"):SetText(value["price"])
			row:GetNamedChild("ValueGuild"):SetText(K)
			lastControl = row
		end					
		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		return control:GetNamedChild("Footer")
	end
end

function KPUI_MainInfo_OnInitialize(control)
	control.SetItemInfo = function(priceInfoTTC, priceInfoATT, currentScene, selectedData, stackCount)
		local colors = kpuiConst.Colors
		
		if not stackCount then
			stackCount = 1
			if selectedData then stackCount = selectedData.stackCount end
		end
							
		local lastControl
		local strAmountCount = GetString(KELA_TRADING_AMOUNTCOUNT)
		local strAvgPrice = GetString(KELA_TRADING_AVGPRICE)
		local multiplier = 1
		local IsMasterWrit = false
		
		control:GetNamedChild("Header"):GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_INDICATOR_SALES_OFFERS))
		control:GetNamedChild("Header"):GetNamedChild("ATT"):SetText(colors.COLOR_ATT:Colorize("ATT"))
		control:GetNamedChild("Header"):GetNamedChild("TTC"):SetText(colors.COLOR_TTC:Colorize("TTC"))
		lastControl = control:GetNamedChild("Header")

		IsMasterWrit = (priceInfoATT.Vouchers ~= 0)
		
		if stackCount > 1 or IsMasterWrit then
			rowEntryCount = GetControl(control:GetName().."rowEntryCount")
			if not rowEntryCount then rowEntryCount = CreateControlFromVirtual("$(parent)rowEntryCount", control, "KPUI_MainRow") end
			rowEntryCount:ClearAnchors()
			rowEntryCount:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			rowEntryCount:GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_ENTRYCOUNT))
			rowEntryCount:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.EntryCount))
			rowEntryCount:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.EntryCount))	
			rowEntryCount:SetHidden(false)
			lastControl = rowEntryCount
		else
			if rowEntryCount then rowEntryCount:SetHidden(true) end
		end

		if IsMasterWrit then
			multiplier = priceInfoATT.Vouchers
			strAmountCount = GetString(KELA_TRADING_VOUCHERSCOUNT)
			strAvgPrice = GetString(KELA_TRADING_AVGPRICE_MASTERWRIT)
		else
			multiplier = 1					
			strAmountCount = GetString(KELA_TRADING_AMOUNTCOUNT)
			strAvgPrice = GetString(KELA_TRADING_AVGPRICE)
		end
		local rowAmountCount = GetControl(control:GetName().."rowAmountCount")
		if not rowAmountCount then rowAmountCount = CreateControlFromVirtual("$(parent)rowAmountCount", control, "KPUI_MainRow") end
		rowAmountCount:ClearAnchors()
		rowAmountCount:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		rowAmountCount:GetNamedChild("Stat"):SetText(strAmountCount)
		rowAmountCount:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.AmountCount))
		rowAmountCount:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.AmountCount))	
		lastControl = rowAmountCount
		
		local rowMin = GetControl(control:GetName().."rowMin")
		if not rowMin then rowMin = CreateControlFromVirtual("$(parent)rowMin", control, "KPUI_MainRow") end
		rowMin:ClearAnchors()
		rowMin:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		rowMin:GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_MINPRICE))
		rowMin:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.Min))
		rowMin:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.Min))	
		lastControl = rowMin
		
		local rowMax = GetControl(control:GetName().."rowMax")
		if not rowMax then rowMax = CreateControlFromVirtual("$(parent)rowMax", control, "KPUI_MainRow") end
		rowMax:ClearAnchors()
		rowMax:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		rowMax:GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_MAXPRICE))
		rowMax:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.Max))
		rowMax:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.Max))	
		lastControl = rowMax
		
		if IsMasterWrit then
			rowVoucherPrice = GetControl(control:GetName().."rowVoucherPrice")
			if not rowVoucherPrice then rowVoucherPrice = CreateControlFromVirtual("$(parent)rowVoucherPrice", control, "KPUI_MainRow") end
			rowVoucherPrice:ClearAnchors()
			rowVoucherPrice:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			rowVoucherPrice:GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_VOUCHERPRICE))
			rowVoucherPrice:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.Avg))
			rowVoucherPrice:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(0))
			rowVoucherPrice:SetHidden(false)
			lastControl = rowVoucherPrice
		else
			if rowVoucherPrice then rowVoucherPrice:SetHidden(true) end
		end

		local rowAvg = GetControl(control:GetName().."rowAvg")
		if not rowAvg then rowAvg = CreateControlFromVirtual("$(parent)rowAvg", control, "KPUI_MainRow") end
		rowAvg:ClearAnchors()
		rowAvg:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		rowAvg:GetNamedChild("Stat"):SetText(strAvgPrice)
		rowAvg:GetNamedChild("ATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT.Avg * multiplier))
		rowAvg:GetNamedChild("TTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.Avg))
		lastControl = rowAvg

		local valueEffectDeal, effectOfDeal, colorEffectDeal, suggestedTTC, suggestedATT, suggestedAVG, suggestedTTCStack, suggestedATTStack, suggestedAVGStack, suggestedTTCWrit, suggestedATTWrit, suggestedAVGWrit 
		
		if selectedData and (currentScene == "GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS" or currentScene == "GAMEPAD_TRADING_HOUSE_LISTINGS") then
			valueEffectDeal, effectOfDeal, colorEffectDeal, suggestedTTC, suggestedATT, suggestedAVG, suggestedTTCStack, suggestedATTStack, suggestedAVGStack, suggestedTTCWrit, suggestedATTWrit, suggestedAVGWrit = KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, selectedData, currentScene, stackCount)
			if not effectOfDeal then effectOfDeal = "" end
		else
			_, _, _, suggestedTTC, suggestedATT, suggestedAVG, suggestedTTCStack, suggestedATTStack, suggestedAVGStack, suggestedTTCWrit, suggestedATTWrit, suggestedAVGWrit = KelaGetEffectOfDeal (priceInfoTTC, priceInfoATT, selectedData, nil, stackCount)
		end
		
		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		if valueEffectDeal then
			control:GetNamedChild("Footer"):GetNamedChild("EffectOfDeal"):SetText(colorEffectDeal:Colorize(tostring(valueEffectDeal)))
			control:GetNamedChild("Footer"):GetNamedChild("EffectOfDeal"):SetHidden(false)
		else
			control:GetNamedChild("Footer"):GetNamedChild("EffectOfDeal"):SetText("")
			control:GetNamedChild("Footer"):GetNamedChild("EffectOfDeal"):SetHidden(true)
		end
		control:GetNamedChild("Footer"):GetNamedChild("Recomend"):SetText(GetString(KELA_TRADING_RECOMENDEDPRICE_SYSTEM))
		control:GetNamedChild("Footer"):GetNamedChild("ATT"):SetText(colors.COLOR_ATT:Colorize(KelaLocalizedFormatNumber(suggestedATT))) 
		control:GetNamedChild("Footer"):GetNamedChild("TTC"):SetText(colors.COLOR_TTC:Colorize(KelaLocalizedFormatNumber(suggestedTTC))) 
		control:GetNamedChild("Footer"):GetNamedChild("AVG"):SetText(KelaLocalizedFormatNumber(suggestedAVG).." ~")
		if IsMasterWrit then
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetText(GetString(KELA_TRADING_TRADING_FORWRIT).."("..multiplier..")")
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetText(colors.COLOR_ATT:Colorize(KelaLocalizedFormatNumber(suggestedATTWrit))) 
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetText(colors.COLOR_TTC:Colorize(KelaLocalizedFormatNumber(suggestedTTCWrit))) 
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetText(KelaLocalizedFormatNumber(suggestedAVGWrit).." ~") 
		elseif stackCount > 1 then
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetHidden(false)
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetText(GetString(KELA_TRADING_TRADING_FORLOT).."("..stackCount..")")
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetText(colors.COLOR_ATT:Colorize(KelaLocalizedFormatNumber(suggestedATTStack))) 
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetText(colors.COLOR_TTC:Colorize(KelaLocalizedFormatNumber(suggestedTTCStack))) 
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetText(KelaLocalizedFormatNumber(suggestedAVGStack).." ~") 
		else 
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetHidden(true)
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetHidden(true)
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetHidden(true)
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetHidden(true)
			control:GetNamedChild("Footer"):GetNamedChild("RecomendStack"):SetText("")
			control:GetNamedChild("Footer"):GetNamedChild("ATTStack"):SetText("")
			control:GetNamedChild("Footer"):GetNamedChild("TTCStack"):SetText("")
			control:GetNamedChild("Footer"):GetNamedChild("AVGStack"):SetText("")
		end	
		return control:GetNamedChild("Footer"), effectOfDeal, (stackCount > 1 or IsMasterWrit or valueEffectDeal)
	end
end

function KPUI_Graph_OnInitialize(control)
	local rows = {}
	local rowFake
	ArkadiusTradeToolsSalesGraph:New(control)
	control.SetGuildSalesInfo = function(GuildsInfo, GuildsPrice, stackCount, lastControl)
		if not stackCount then stackCount = 1 end
		stackCount = math.floor(stackCount)
		
		control:GetNamedChild("Header"):SetHidden(false)
		control:GetNamedChild("Header"):ClearAnchors()
		control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT, -10)
		control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT, 10)
		control:GetNamedChild("Header"):GetNamedChild("Stat"):SetText(GetString(KELA_TRADING_TRADING_GUILD))
		if stackCount > 1 then
			control:GetNamedChild("Header"):GetNamedChild("AVGStack"):SetHidden(false)
			control:GetNamedChild("Header"):GetNamedChild("AVGStack"):SetText(GetString(KELA_TRADING_AVGPRICE_SHORT).." ("..stackCount..")")
		else
			control:GetNamedChild("Header"):GetNamedChild("AVGStack"):SetHidden(true)
			control:GetNamedChild("Header"):GetNamedChild("AVGStack"):SetText(GetString(KELA_TRADING_AVGPRICE_SHORT))
		end
		control:GetNamedChild("Header"):GetNamedChild("AVG"):SetText(GetString(KELA_TRADING_AVGPRICE_SHORT))
		control:GetNamedChild("Header"):GetNamedChild("Value"):SetText(GetString(KELA_TRADING_SOLD))
		lastControl = control:GetNamedChild("Header")
		
		if next(GuildsInfo) ~= nil then
			if rowFake then rowFake:SetHidden(true) end
			for _, row in pairs(rows) do
				row:SetHidden(true)
			end
			for guildName, countSales in spairs(GuildsInfo, function(t, a, b) return t[a] > t[b]  end) do
				local color = ArkadiusTradeTools:GetGuildColor(guildName)
				local guildRow = string.gsub(guildName, "%s+", "")
				if string.len(guildRow) > 15 then guildRow = string.sub(guildRow, 1, 15) end
				local row = GetControl(control:GetName().."row"..guildRow)
				if not row then row = CreateControlFromVirtual("$(parent)row", control, "KPUI_GraphRow", guildRow) end
				rows[#rows + 1] = row
				row:ClearAnchors()
				row:SetHidden(false)
				row:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
				row:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
				row:GetNamedChild("Stat"):SetText(color:Colorize(guildName))
				
				local guildPrice = math.floor(GuildsPrice[guildName])
				
				if stackCount > 1 then
					row:GetNamedChild("AVGStack"):SetHidden(false)
					row:GetNamedChild("AVGStack"):SetText(KelaLocalizedFormatNumber(guildPrice*stackCount))
				else
					row:GetNamedChild("AVGStack"):SetHidden(true)
					row:GetNamedChild("AVGStack"):SetText("-")
				end
				row:GetNamedChild("AVG"):SetText(KelaLocalizedFormatNumber(guildPrice))
				row:GetNamedChild("Value"):SetText(countSales)
				lastControl = row
			end
		else
			for _, row in pairs(rows) do
				row:SetHidden(true)
			end
			control:GetNamedChild("Header"):GetNamedChild("AVGStack"):SetText(GetString(KELA_TRADING_AVGPRICE_SHORT).." (".."-"..")")
			rowFake = GetControl(control:GetName().."rowFake")
			if not rowFake then rowFake = CreateControlFromVirtual("$(parent)rowFake", control, "KPUI_GraphRow") end	
			rowFake:ClearAnchors()
			rowFake:SetHidden(false)
			rowFake:SetAnchor(TOPLEFT, control:GetNamedChild("Header"), BOTTOMLEFT)
			rowFake:SetAnchor(TOPRIGHT, control:GetNamedChild("Header"), BOTTOMRIGHT)
			rowFake:GetNamedChild("Stat"):SetText("-")
			if stackCount > 1 then
				rowFake:GetNamedChild("AVGStack"):SetText("-")
			else
				rowFake:GetNamedChild("AVGStack"):SetText("")
			end
			rowFake:GetNamedChild("AVG"):SetText("-")	
			rowFake:GetNamedChild("Value"):SetText("-")
			lastControl = rowFake											
		end

		control:GetNamedChild("Footer"):SetHidden(false)
		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)

		return control:GetNamedChild("Footer")
	end
end

function KPUI_PreviousListings_OnInitialize(control)
	control.SetPreviousListings = function(listingItemsTable, lastControl)
		--local kelaPlayerAccountName = GetUnitDisplayName('player')
		
		for i = 1, 5 do
			local row = GetControl(control:GetName().."row"..i)
			if row then row:SetHidden(true) end
		end

		control:GetNamedChild("Header"):GetNamedChild("Title"):SetText(GetString(KELA_SETTING_TRADE_TOOLTIP_LISTINGS))	
		control:GetNamedChild("Header"):GetNamedChild("TitleValue"):SetText(" ")		
		control:GetNamedChild("Header"):GetNamedChild("Guild"):SetText(GetString(KELA_TRADING_TRADING_GUILD))
		control:GetNamedChild("Header"):GetNamedChild("Result"):SetText(" ")
		control:GetNamedChild("Header"):GetNamedChild("Period"):SetText(GetString(KELA_TRADING_PERIOD))
		control:GetNamedChild("Header"):GetNamedChild("PriceForOne"):SetText(GetString(KELA_TRADING_PRICE_TITLE))
		control:GetNamedChild("Header"):GetNamedChild("PriceForLot"):SetText(GetString(KELA_TRADING_PRICEFORLOT))
		control:GetNamedChild("Header"):ClearAnchors()
		control:GetNamedChild("Header"):SetHidden(false)
		control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		lastControl = control:GetNamedChild("Header")

		local count = 0
		local isStack
		for listingTime, listingItem in spairs(listingItemsTable, function (t, a, b) return (a > b) end) do
			
			count = count + 1
			
			local color = ArkadiusTradeTools:GetGuildColor(listingItem["guildName"])
			
			local periodValue
			if listingItem["period"] then
				local timeString 
				if listingItem["period"] == 0 then 
					timeString = "-"
				else
					timeString = zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(listingItem["period"], TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING))
				end
				periodValue = KelaTimeStampToDateTimeString(listingTime).." ("..timeString..")"
			else
				local timeString = zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(GetTimeStamp() - listingTime, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING))							
				periodValue = KelaTimeStampToDateTimeString(listingTime).." ("..timeString..")"
			end

			local row = GetControl(control:GetName().."row"..count)
			if not row then row = CreateControlFromVirtual("$(parent)row", control, "KPUI_PreviousListingsRow", count) end	
			
			row:GetNamedChild("Guild"):SetText(color:Colorize(listingItem["guildName"]))
			row:GetNamedChild("Result"):SetText(listingItem["result"])
			row:GetNamedChild("Period"):SetText(periodValue)
			row:GetNamedChild("PriceForOne"):SetText(KelaLocalizedFormatNumber(listingItem["desiredPrice"]/listingItem["stackCount"]))
			
			if listingItem["stackCount"] > 1 then
				row:GetNamedChild("PriceForLot"):SetText(KelaLocalizedFormatNumber(listingItem["desiredPrice"]).." ("..listingItem["stackCount"]..")")
				isStack = true
			else
				row:GetNamedChild("PriceForLot"):SetText("")
				isStack = false
			end
			
			row:ClearAnchors()
			row:SetHidden(false)
			row:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			row:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)						
			
			lastControl = row						
			
			if count >= 5 then break end

		end	
		
		if not isStack then 
			control:GetNamedChild("Header"):GetNamedChild("PriceForLot"):SetText("")
		end
		
		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		return control:GetNamedChild("Footer")
	end
end

function KPUI_OtherQualityInfo_OnInitialize(control)
	control.SetOtherQualityPrices = function(itemLink, normalItemLink, fineItemLink, superiorItemLink, epicItemLink, legendaryItemLink, lastControl)

		local titleSubTitle = " "
		local transmutted = GetItemTraitInformationFromItemLink(itemLink) and GetItemTraitInformationFromItemLink(itemLink) == 4
		local notCurrentName = GetItemLinkName(itemLink) ~= GetItemLinkName(normalItemLink)

		if transmutted then
			local traitType = GetItemLinkTraitInfo(normalItemLink)
			local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
			titleSubTitle = kpuiConst.Colors.COLOR_POISON:Colorize(GetString(KELA_TRADING_BEFORETRANSMUTE)..traitName)
		elseif notCurrentName then
			local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(normalItemLink))
			titleSubTitle = kpuiConst.Colors.COLOR_POISON:Colorize(name)
		end		
		
		control:GetNamedChild("Header"):GetNamedChild("Title"):SetText(GetString(KELA_TRADING_INANOTHERQUALITY))
		control:GetNamedChild("Header"):GetNamedChild("TitleValue"):SetText(kpuiConst.Colors.COLOR_POISON:Colorize(titleSubTitle))
		control:GetNamedChild("Header"):ClearAnchors()
		control:GetNamedChild("Header"):SetHidden(false)
		control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		lastControl = control:GetNamedChild("Header")					
		
		control:GetNamedChild("ColumnTitle"):GetNamedChild("TradeSystem"):SetText(GetString(KELA_TRADING_TRADESYSTEM))
		control:GetNamedChild("ColumnTitle"):GetNamedChild("PriceRec"):SetText(GetString(KELA_TRADING_PRICEREC))
		control:GetNamedChild("ColumnTitle"):GetNamedChild("PriceAvg"):SetText(GetString(KELA_TRADING_PRICEAVG))
		control:GetNamedChild("ColumnTitle"):GetNamedChild("AmountCount"):SetText(GetString(KELA_TRADING_GOODUNIT))
		control:GetNamedChild("ColumnTitle"):GetNamedChild("EntryCount"):SetText(GetString(KELA_TRADING_LOTS))
		control:GetNamedChild("ColumnTitle"):ClearAnchors()
		control:GetNamedChild("ColumnTitle"):SetHidden(false)
		control:GetNamedChild("ColumnTitle"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("ColumnTitle"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		lastControl = control:GetNamedChild("ColumnTitle")

		local lastControlATT, lastControlTTC
		local isStack
		local function addATTRow(sufText, itemLink, priceInfoATT)
			local rowATT
			local qualityColor = GetItemQualityColor(GetItemLinkDisplayQuality(itemLink))
		
			rowATT = GetControl(control:GetName().."rowATT"..sufText)
			if not rowATT then rowATT = CreateControlFromVirtual("$(parent)rowATT", control, "KPUI_OtherQualityInfoRow", sufText) end
			local isFirst
			if lastControlATT then 
				lastControl = lastControlATT
			else
				isFirst = true
			end
			rowATT:ClearAnchors()
			rowATT:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			if priceInfoATT.Avg ~= 0 then 
				rowATT:SetHidden(false)
				if isFirst then 
					rowATT:GetNamedChild("TradeSystem"):SetText(kpuiConst.Colors.COLOR_ATT:Colorize("Arkadius Trade Tools"))
				else
					rowATT:GetNamedChild("TradeSystem"):SetText(" ")
				end
				rowATT:GetNamedChild("PriceRec"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoATT.SuggestedPrice)))
				rowATT:GetNamedChild("PriceAvg"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoATT.Avg)))
				rowATT:GetNamedChild("AmountCount"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoATT.AmountCount)))
				if not isStack and priceInfoATT.AmountCount ~= priceInfoATT.EntryCount then isStack = true end
				if isStack then
					rowATT:GetNamedChild("EntryCount"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoATT.EntryCount)))
				else
					rowATT:GetNamedChild("EntryCount"):SetText("")
				end
				lastControlATT = rowATT
			else
				if rowATT then rowATT:SetHidden(true) end
				--if isFirst then lastControlATT = nil end
			end
		end
		local function addTTCRow(sufText, itemLink, priceInfoTTC)
			local rowTTC
			local qualityColor = GetItemQualityColor(GetItemLinkDisplayQuality(itemLink))

			rowTTC = GetControl(control:GetName().."rowTTC"..sufText)
			if not rowTTC then rowTTC = CreateControlFromVirtual("$(parent)rowTTC", control, "KPUI_OtherQualityInfoRow", sufText) end
			
			local isFirst
			if lastControlTTC then 
				lastControl = lastControlTTC
			else
				lastControl = lastControlATT or lastControl
				isFirst = true
			end
			
			rowTTC:ClearAnchors()
			rowTTC:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)		
			if priceInfoTTC.Avg ~= 0 then
				rowTTC:SetHidden(false)
				if isFirst then 
					rowTTC:GetNamedChild("TradeSystem"):SetText(kpuiConst.Colors.COLOR_TTC:Colorize("Tamriel Trade Centre"))
				else
					rowTTC:GetNamedChild("TradeSystem"):SetText(" ")
				end
				rowTTC:GetNamedChild("PriceRec"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoTTC.SuggestedPrice)))
				rowTTC:GetNamedChild("PriceAvg"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoTTC.Avg)))
				rowTTC:GetNamedChild("AmountCount"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoTTC.AmountCount)))
				if not isStack and priceInfoTTC.AmountCount ~= priceInfoTTC.EntryCount then isStack = true end
				if isStack then
					rowTTC:GetNamedChild("EntryCount"):SetText(qualityColor:Colorize(KelaLocalizedFormatNumber(priceInfoTTC.EntryCount)))
				else
					rowTTC:GetNamedChild("EntryCount"):SetText("")
				end
				lastControlTTC = rowTTC
			else
				if rowTTC then rowTTC:SetHidden(true) end
				--if isFirst then lastControlTTC = nil end
			end
		end			

		local trueTTCNormal, trueATTNormal, priceInfoTTCNormal, priceInfoATTNormal
		local trueTTCFine, trueATTFine, priceInfoTTCFine, priceInfoATTFine
		local trueTTCSuperior, trueATTSuperior, priceInfoTTCSuperior, priceInfoATTSuperior
		local trueTTCEpic, trueATTEpic, priceInfoTTCEpic, priceInfoATTEpic
		local trueTTCLegendary, trueATTLegendary, priceInfoTTCLegendary, priceInfoATTLegendary

		if normalItemLink then trueTTCNormal, trueATTNormal, priceInfoTTCNormal, priceInfoATTNormal = KelaGetPriceInfoTTCATT(normalItemLink) end
		if fineItemLink then trueTTCFine, trueATTFine, priceInfoTTCFine, priceInfoATTFine = KelaGetPriceInfoTTCATT(fineItemLink) end
		if superiorItemLink then trueTTCSuperior, trueATTSuperior, priceInfoTTCSuperior, priceInfoATTSuperior = KelaGetPriceInfoTTCATT(superiorItemLink) end
		if epicItemLink then trueTTCEpic, trueATTEpic, priceInfoTTCEpic, priceInfoATTEpic = KelaGetPriceInfoTTCATT(epicItemLink) end
		if legendaryItemLink then trueTTCLegendary, trueATTLegendary, priceInfoTTCLegendary, priceInfoATTLegendary = KelaGetPriceInfoTTCATT(legendaryItemLink) end


		if trueATTNormal then
			addATTRow("normal", normalItemLink, priceInfoATTNormal)
		else 
			if GetControl(control:GetName().."rowATT".."normal") then GetControl(control:GetName().."rowATT".."normal"):SetHidden(true) end
		end
		if trueATTFine then
			addATTRow("fine", fineItemLink, priceInfoATTFine)
		else 
			if GetControl(control:GetName().."rowATT".."fine") then GetControl(control:GetName().."rowATT".."fine"):SetHidden(true) end
		end					
		if trueATTSuperior then
			addATTRow("superior", superiorItemLink, priceInfoATTSuperior)
		else 
			if GetControl(control:GetName().."rowATT".."superior") then GetControl(control:GetName().."rowATT".."superior"):SetHidden(true) end
		end					
		if trueATTEpic then
			addATTRow("epic", epicItemLink, priceInfoATTEpic)
		else 
			if GetControl(control:GetName().."rowATT".."epic") then GetControl(control:GetName().."rowATT".."epic"):SetHidden(true) end
		end					
		if trueATTLegendary then
			addATTRow("legendary", legendaryItemLink, priceInfoATTLegendary)
		else 
			if GetControl(control:GetName().."rowATT".."legendary") then GetControl(control:GetName().."rowATT".."legendary"):SetHidden(true) end
		end					
		
		if trueTTCNormal then
			addTTCRow("normal", normalItemLink, priceInfoTTCNormal)
		else 
			if GetControl(control:GetName().."rowTTC".."normal") then GetControl(control:GetName().."rowTTC".."normal"):SetHidden(true) end
		end
		if trueTTCFine then
			addTTCRow("fine", fineItemLink, priceInfoTTCFine)
		else 
			if GetControl(control:GetName().."rowTTC".."fine") then GetControl(control:GetName().."rowTTC".."fine"):SetHidden(true) end
		end	
		if trueTTCSuperior then
			addTTCRow("superior", superiorItemLink, priceInfoTTCSuperior)
		else 
			if GetControl(control:GetName().."rowTTC".."superior") then GetControl(control:GetName().."rowTTC".."superior"):SetHidden(true) end
		end		
		if trueTTCEpic then
			addTTCRow("epic", epicItemLink, priceInfoTTCEpic)
		else 
			if GetControl(control:GetName().."rowTTC".."epic") then GetControl(control:GetName().."rowTTC".."epic"):SetHidden(true) end
		end		
		if trueTTCLegendary then
			addTTCRow("legendary", legendaryItemLink, priceInfoTTCLegendary)
		else 
			if GetControl(control:GetName().."rowTTC".."legendary") then GetControl(control:GetName().."rowTTC".."legendary"):SetHidden(true) end
		end									

		if not isStack then
			control:GetNamedChild("ColumnTitle"):GetNamedChild("EntryCount"):SetText("")
		end
		
		local notSuccess
		if lastControlTTC then
			lastControl = lastControlTTC
		elseif lastControlATT then
			lastControl = lastControlATT
		else
			notSuccess = true
		end

		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		
		return control:GetNamedChild("Footer"), notSuccess
	end
end

function KPUI_ProductMaterialInfo_OnInitialize(control)
	control.SetRawProductPrices = function(resultItemLink, priceInfoTTC, priceInfoATT, lastControl)
		
		local rowTTC, rowATT
		local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(resultItemLink))
		local nameColor = GetItemQualityColor(GetItemLinkDisplayQuality(resultItemLink))
		local colorizedItemName = nameColor:Colorize(name)
		local itemType = GetItemLinkItemType(resultItemLink)
		
		if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_GLYPH_ARMOR or itemType == ITEMTYPE_GLYPH_JEWELRY or itemType == ITEMTYPE_GLYPH_WEAPON or itemType == ITEMTYPE_WEAPON then
			control:GetNamedChild("Header"):GetNamedChild("Title"):SetText(" ")	
		else
			control:GetNamedChild("Header"):GetNamedChild("Title"):SetText(GetString(KELA_PRODUCT))	
		end
		control:GetNamedChild("Header"):GetNamedChild("TitleValue"):SetText(colorizedItemName)
		control:GetNamedChild("Header"):GetNamedChild("TradeSystem"):SetText(GetString(KELA_TRADING_TRADESYSTEM))
		control:GetNamedChild("Header"):GetNamedChild("PriceRec"):SetText(GetString(KELA_TRADING_PRICEREC))
		control:GetNamedChild("Header"):GetNamedChild("PriceAvg"):SetText(GetString(KELA_TRADING_PRICEAVG))
		control:GetNamedChild("Header"):GetNamedChild("AmountCount"):SetText(GetString(KELA_TRADING_GOODUNIT))
		control:GetNamedChild("Header"):GetNamedChild("EntryCount"):SetText(GetString(KELA_TRADING_LOTS))

		control:GetNamedChild("Header"):ClearAnchors()
		control:GetNamedChild("Header"):SetHidden(false)
		control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)

		lastControl = control:GetNamedChild("Header")

		rowATT = GetControl(control:GetName().."rowATT")
		if not rowATT then rowATT = CreateControlFromVirtual("$(parent)rowATT", control, "KPUI_ProductMaterialInfoRow") end
		rowATT:ClearAnchors()
		rowATT:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		if priceInfoATT.Avg ~= 0 then 
			rowATT:SetHidden(false)
			rowATT:GetNamedChild("TradeSystem"):SetText(kpuiConst.Colors.COLOR_ATT:Colorize("Arkadius Trade Tools"))
			rowATT:GetNamedChild("PriceRec"):SetText(KelaLocalizedFormatNumber(priceInfoATT.SuggestedPrice))
			rowATT:GetNamedChild("PriceAvg"):SetText(KelaLocalizedFormatNumber(priceInfoATT.Avg))
			rowATT:GetNamedChild("AmountCount"):SetText(KelaLocalizedFormatNumber(priceInfoATT.AmountCount))
			rowATT:GetNamedChild("EntryCount"):SetText(KelaLocalizedFormatNumber(priceInfoATT.EntryCount))
			lastControl = rowATT
		else
			if rowATT then rowATT:SetHidden(true) end
		end
	
		rowTTC = GetControl(control:GetName().."rowTTC")
		if not rowTTC then rowTTC = CreateControlFromVirtual("$(parent)rowTTC", control, "KPUI_ProductMaterialInfoRow") end
		rowTTC:ClearAnchors()
		rowTTC:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)				
		if priceInfoTTC.Avg ~= 0 then
			rowTTC:SetHidden(false)
			rowTTC:GetNamedChild("TradeSystem"):SetText(kpuiConst.Colors.COLOR_TTC:Colorize("Tamriel Trade Centre"))
			rowTTC:GetNamedChild("PriceRec"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.SuggestedPrice))
			rowTTC:GetNamedChild("PriceAvg"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.Avg))
			rowTTC:GetNamedChild("AmountCount"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.AmountCount))
			rowTTC:GetNamedChild("EntryCount"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.EntryCount))
			lastControl = rowTTC
		else
			if rowTTC then rowTTC:SetHidden(true) end
		end

		control:GetNamedChild("Footer"):ClearAnchors()
		control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
		control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
		return control:GetNamedChild("Footer")
	end
end

function KPUI_CraftingInfo_OnInitialize(control)
	control.SetItemPrices = function(craftingComponentPrices, lastControl)
		if next(craftingComponentPrices) ~= nil then
		
			local iconsHave = zo_iconFormatInheritColor("EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_inventory.dds", 15, 15)
			iconsHave = iconsHave..zo_iconFormatInheritColor("esoui/art/icons/servicemappins/servicepin_bank.dds", 15, 15)
			control:GetNamedChild("Header"):GetNamedChild("Title"):SetText(GetString(SI_PROVISIONER_INGREDIENTS_HEADER))
			control:GetNamedChild("Header"):GetNamedChild("Quantity"):SetText(iconsHave)
			control:GetNamedChild("Header"):GetNamedChild("ItemName"):SetText(GetString(KELA_TRADING_ITEM))
			control:GetNamedChild("Header"):GetNamedChild("CurrencyTTC"):SetText(GetString(KELA_TRADING_ITEM).."|cf23d8eTTC|r")
			control:GetNamedChild("Header"):GetNamedChild("CurrencyATT"):SetText(GetString(KELA_TRADING_ITEM).."|cf58585ATT|r")
			
			control:GetNamedChild("Header"):ClearAnchors()
			control:GetNamedChild("Header"):SetHidden(false)
			control:GetNamedChild("Header"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			control:GetNamedChild("Header"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)

			lastControl = control:GetNamedChild("Header")

			local totalPriceATT = 0
			local totalPriceTTC = 0
			for i = 1, 7 do
				local rowOld = GetControl(control:GetName().."row"..i)
				if rowOld then
					row = rowOld
				else
					row = CreateControlFromVirtual("$(parent)row", control, "KPUI_CraftingInfoRow", i)
				end					
				row:ClearAnchors()
				if craftingComponentPrices[i] == nil then
					row:SetHidden(true)
				else
					row:SetHidden(false)
					if i == 1 then
						row:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
					else
						row:SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
						row:SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
					end
					local bagCount, bankCount, craftBagCount = GetItemLinkStacks(craftingComponentPrices[i].itemLink)
					local stackCount = bagCount + bankCount + craftBagCount							
					if craftingComponentPrices[i].quantity > stackCount then 
						stackCount = "|cDC8122"..tostring(stackCount).."|r"
						row:GetNamedChild("Quantity"):SetFont("ZoFontGamepad22")								
					else
						stackCount = "|cFFFFFF"..tostring(stackCount).."|r" 
						row:GetNamedChild("Quantity"):SetFont("ZoFontGamepad20")
					end
					row:GetNamedChild("Quantity"):SetText(stackCount) 
					row:GetNamedChild("ItemName"):SetText(craftingComponentPrices[i].itemLink.." *"..craftingComponentPrices[i].quantity)

					local priceInfoTTC = TamrielTradeCentrePrice:GetPriceInfo(craftingComponentPrices[i].itemLink)

					if priceInfoTTC then 
						row:GetNamedChild("CurrencyTTC"):SetText(KelaLocalizedFormatNumber(priceInfoTTC.Avg * craftingComponentPrices[i].quantity)) 
						totalPriceTTC = totalPriceTTC + (priceInfoTTC.Avg * craftingComponentPrices[i].quantity)	
					end	

					local priceInfoATT
					if craftingComponentPrices[i].price and	craftingComponentPrices[i].quantity then
						priceInfoATT = craftingComponentPrices[i].price * craftingComponentPrices[i].quantity
					end
					
					if priceInfoATT then 
						row:GetNamedChild("CurrencyATT"):SetText(KelaLocalizedFormatNumber(priceInfoATT)) 
						totalPriceATT = totalPriceATT + priceInfoATT
					end

					lastControl = row
				end
			end
			control:GetNamedChild("Footer"):ClearAnchors()
			control:GetNamedChild("Footer"):SetAnchor(TOPLEFT, lastControl, BOTTOMLEFT)
			control:GetNamedChild("Footer"):SetAnchor(TOPRIGHT, lastControl, BOTTOMRIGHT)
			control:GetNamedChild("Footer"):GetNamedChild("SummaryLabel"):SetText(GetString(KELA_TRADING_SUMMARY)..":")
			control:GetNamedChild("Footer"):GetNamedChild("SummaryValueTTC"):SetText("|cf23d8e"..KelaLocalizedFormatNumber(totalPriceTTC).."|r") 
			control:GetNamedChild("Footer"):GetNamedChild("SummaryValueATT"):SetText("|cf58585"..KelaLocalizedFormatNumber(totalPriceATT).."|r") 
			return control:GetNamedChild("Footer")
		end
	end
end

