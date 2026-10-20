local colors = kpuiConst.Colors	
local OPTIONS_LIST = "optionsList"

	-- replace tooltip Quad1 (left collection)
function kelaReplaceTooltipQuad1 (tooltip)	
	
	local oldLayoutCollectible = tooltip.LayoutCollectible
	tooltip.LayoutCollectible = function(control, collectibleId, collectionName, collectibleName, collectibleNickname, isPurchasable, description, hint, isPlaceholder, showVisualLayerInfo, cooldownSecondsRemaining, showBlockReason, ...)	

	--KelaPostMsg("LayoutCollectible")
		
		if not isPlaceholder then 
            --things added to the collection top section stacks to the right (side by side) 
            local topSection = control:AcquireSection(control:GetStyle("collectionsTopSection")) 

            if collectionName then 
                local formattedName = ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectionName) 
                topSection:AddLine(formattedName) 
            end 

            local unlockState = GetCollectibleUnlockStateById(collectibleId) 
            topSection:AddLine(GetString("SI_COLLECTIBLEUNLOCKSTATE", unlockState)) 

            if showVisualLayerInfo then 
                local visualLayerHidden, highestPriorityVisualLayerThatIsShowing = WouldCollectibleBeHidden(collectibleId) 
                if visualLayerHidden then 
                    topSection:AddLine(ZO_SELECTED_TEXT:Colorize(GetHiddenByStringForVisualLayer(highestPriorityVisualLayerThatIsShowing))) 
                end 
            end 

            control:AddSection(topSection) 
        end 

        local formattedName = colors.COLOR_WHITE:Colorize(ZO_CachedStrFormat(SI_COLLECTIBLE_NAME_FORMATTER, collectibleName))
        control:AddLine(formattedName, QUALITY_NORMAL, control:GetStyle("QUAD1title")) 
     
        local headerSection = control:AcquireSection(control:GetStyle("bodyHeader")) 

        if collectibleNickname and collectibleNickname ~= "" then 
            formattedName = ZO_CachedStrFormat(SI_TOOLTIP_COLLECTIBLE_NICKNAME, collectibleNickname) 
            headerSection:AddLine(formattedName, QUALITY_NORMAL, control:GetStyle("bodyHeader")) 
        end 

        control:AddSection(headerSection) 
		
		--KelaPostMsg(tostring(type(tonumber(cooldownSecondsRemaining))))
        if cooldownSecondsRemaining and type(tonumber(cooldownSecondsRemaining)) == "number" then
			if cooldownSecondsRemaining > 0 then 
				local cooldownSection = control:AcquireSection(control:GetStyle("QUAD1collectionsStatsSection")) 
				local cooldownPair = cooldownSection:AcquireStatValuePair(control:GetStyle("statValuePair")) 
				cooldownPair:SetStat(COOLDOWN_TEXT, control:GetStyle("collectionsTopSection")) 
			 
				local secondsRemainingString = ZO_FormatTimeLargestTwo(cooldownSecondsRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_MINIMAL) 
				cooldownPair:SetValue(secondsRemainingString, control:GetStyle("collectionsStatsValue")) 
				cooldownSection:AddStatValuePair(cooldownPair) 
				control:AddSection(cooldownSection) 
			end
        end 

        local bodySection = control:AcquireSection(control:GetStyle("QUAD1collectionsInfoSection")) 
        local descriptionStyle = control:GetStyle("bodyDescription") 

        if description then 
            local formattedDescription = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, description) 
            bodySection:AddLine(formattedDescription, descriptionStyle) 
        end 

        if isPurchasable then  
            bodySection:AddLine(PURCHASED_TEXT, descriptionStyle) 
        end 

        if hint and hint ~= "" then 
            local formattedHint = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, hint) 
            bodySection:AddLine(formattedHint, descriptionStyle) 
        end 

        local emoteOverrideNames = {GetCollectiblePersonalityOverridenEmoteDisplayNames(collectibleId)} 
        if #emoteOverrideNames > 0 then 
            local numEmoteNames = #emoteOverrideNames 
            local emoteString = ZO_GenerateCommaSeparatedList(emoteOverrideNames) 
            local formattedEmoteString = zo_strformat(SI_COLLECTIBLE_TOOLTIP_PERSONALITY_OVERRIDES_DISPLAY_NAMES_FORMATTER, emoteString, numEmoteNames) 
            bodySection:AddLine(formattedEmoteString, descriptionStyle, control:GetStyle("collectionsPersonality")) 
        end 

        control:AddSection(bodySection) 

        -- Layout the use restrictions 
        local failsRestriction = false 
        local restrictionsSection = control:AcquireSection(control:GetStyle("QUAD1collectionsRestrictionsSection")) 

        for restrictionType = COLLECTIBLE_RESTRICTION_TYPE_MIN_VALUE, COLLECTIBLE_RESTRICTION_TYPE_MAX_VALUE do 
            local hasRestrictions, passesRestrictions, allowedNamesString = GetCollectibleRestrictionsByType(collectibleId, restrictionType) 
            if hasRestrictions then 
                local statValuePair = restrictionsSection:AcquireStatValuePair(control:GetStyle("statValuePair"), control:GetStyle("fullWidth")) 
                statValuePair:SetStat(GetString("SI_COLLECTIBLERESTRICTIONTYPE", restrictionType), control:GetStyle("statValuePairStat")) 
                if passesRestrictions then 
                    statValuePair:SetValue(allowedNamesString, control:GetStyle("statValuePairValue")) 
                else 
                    statValuePair:SetValue(allowedNamesString, control:GetStyle("failed"), control:GetStyle("statValuePairValue")) 
                    failsRestriction = true 
                end 
                restrictionsSection:AddStatValuePair(statValuePair) 
            end 
        end 

        control:AddSection(restrictionsSection) 

        bodySection = control:AcquireSection(control:GetStyle("QUAD1collectionsInfoSection")) 

        if failsRestriction then 
            bodySection:AddLine(GetString(SI_COLLECTIBLE_TOOLTIP_NOT_USABLE_BY_CHARACTER), descriptionStyle, control:GetStyle("failed")) 
        elseif showBlockReason then 
            local usageBlockReason = GetCollectibleBlockReason(collectibleId) 
            if usageBlockReason ~= COLLECTIBLE_USAGE_BLOCK_REASON_NOT_BLOCKED then 
                local formattedBlockReason = ZO_CachedStrFormat(ZO_CACHED_STR_FORMAT_NO_FORMATTER, GetString("SI_COLLECTIBLEUSAGEBLOCKREASON", usageBlockReason)) 
                bodySection:AddLine(formattedBlockReason, descriptionStyle, control:GetStyle("failed")) 
            end 
        end 

        control:AddSection(bodySection) 
		-- local ret = oldCallbackkelaReplaceTitleStyle(control, itemLink, ...)
		-- return ret
	end

end
------------------------------------------------------------------------------
function kelaReplaceTooltipChamps (tooltip)	
	-- replace champions perks tooltips
	local oldLayoutChampionConstellation = tooltip.LayoutChampionConstellation
	tooltip.LayoutChampionConstellation = function(control, attributeName, attributeIcon, constellationName, constellationDescription, numPointsAvailable, numSpentPoints, ...)	
		local attributeTitleSection = control:AcquireSection(control:GetStyle("attributeTitleSection")) 
		attributeTitleSection:AddLine(attributeName, control:GetStyle("attributeTitle")) 
		attributeTitleSection:AddTexture(attributeIcon, control:GetStyle("attributeIcon")) 
		attributeTitleSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, control:GetStyle("dividerLine")) 
		control:AddSection(attributeTitleSection) 

		local availablePointsSection = control:AcquireSection(control:GetStyle("championPointsSection")) 
		availablePointsSection:AddLine(GetString(SI_GAMEPAD_CHAMPION_AVAILABLE_POINTS_LABEL), control:GetStyle("pointsHeader")) 
		availablePointsSection:AddLine(numPointsAvailable, control:GetStyle("pointsValue")) 
		control:AddSection(availablePointsSection) 

		local constellationTitleSection = control:AcquireSection(control:GetStyle("championTitleSection"), control:GetStyle("championTitle")) 
		constellationTitleSection:AddLine(constellationName, control:GetStyle("championTitle")) 
		constellationTitleSection:AddTexture(ZO_GAMEPAD_HEADER_DIVIDER_TEXTURE, control:GetStyle("dividerLine")) 
		control:AddSection(constellationTitleSection) 

		local spentPointsSection = control:AcquireSection(control:GetStyle("championPointsSection")) 
		spentPointsSection:AddLine(GetString(SI_GAMEPAD_CHAMPION_ALLOCATED_POINTS_LABEL), control:GetStyle("pointsHeader")) 
		spentPointsSection:AddLine(numSpentPoints, control:GetStyle("pointsValue")) 
		control:AddSection(spentPointsSection) 

		local bodySection = control:AcquireSection(control:GetStyle("championBodySection"), control:GetStyle("bodySection")) 
		bodySection:AddLine(constellationDescription, control:GetStyle("bodyDescription")) 
		control:AddSection(bodySection) 
	end
	------------------------------------------------------------------------------
	local oldLayoutChampionSkillAbility = tooltip.LayoutChampionSkillAbility
	tooltip.LayoutChampionSkillAbility = function(control, disciplineIndex, skillIndex, pendingPoints) 
		local abilityId = GetChampionAbilityId(disciplineIndex, skillIndex) 
		local HIDE_RANK = true 
		local OVERRIDE_RANK = nil 
		--control:LayoutAbility(abilityId, HIDE_RANK, OVERRIDE_RANK, pendingPoints) 
		if(DoesAbilityExist(abilityId)) then 
			local hasProgression, progressionIndex, lastRankXP, nextRankXP, currentXP, atMorph = GetAbilityProgressionXPInfoFromAbilityId(abilityId) 
			--control:AddAbilityName(abilityId, HIDE_RANK, OVERRIDE_RANK) 
			local abilityName = GetAbilityName(abilityId) 
			local rank = OVERRIDE_RANK 
			if(OVERRIDE_RANK == nil) then 
				rank = GetAbilityProgressionRankFromAbilityId(abilityId) 
			end 
			if(not HIDE_RANK and rank ~= nil and rank > 0) then 
				control:AddLine(zo_strformat(SI_ABILITY_NAME_AND_RANK, abilityName, rank), control:GetStyle("championTitle")) 
			else 
				control:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_NAME, abilityName), control:GetStyle("championTitle")) 
			end 
			if(hasProgression) then 
				control:AddAbilityProgressBar(currentXP, lastRankXP, nextRankXP, atMorph) 
			end 
			if(not IsAbilityPassive(abilityId)) then 
				control:AddAbilityStats(abilityId) 
			end 
			if(addNewEffects) then 
				control:AddAbilityNewEffects(GetAbilityNewEffectLines(abilityId)) 
			end 
			--control:AddAbilityDescription(abilityId, pendingPoints) 
			local descriptionHeader = GetAbilityDescriptionHeader(abilityId) 
			local description 
			if not pendingPoints then 
				description = GetAbilityDescription(abilityId) 
			else 
				description = GetChampionAbilityDescription(abilityId, pendingPoints) 
			end 
			if(descriptionHeader ~= "" or description ~= "") then 
				local descriptionSection = control:AcquireSection(control:GetStyle("championBodySection"), control:GetStyle("bodySection"))  
				if(descriptionHeader ~= "") then 
					descriptionSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION_HEADER, descriptionHeader), control:GetStyle("championBodyHeader")) 
				end 
				if(description ~= "") then 
					descriptionSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION, description), control:GetStyle("bodyDescription")) 
				end 
				control:AddSection(descriptionSection) 
			end 
		end 
		local unlockLevel = GetChampionSkillUnlockLevel(disciplineIndex, skillIndex) 
		if unlockLevel ~= nil then 
			local unlockSection = control:AcquireSection(control:GetStyle("championBodySection"), control:GetStyle("bodySection")) 
			local unlockText 
			local textColor 
			if not WillChampionSkillBeUnlocked(disciplineIndex, skillIndex) then 
				unlockText = SI_CHAMPION_TOOLTIP_LOCKED 
				textColor = control:GetStyle("failed") 
			else 
				unlockText = SI_CHAMPION_TOOLTIP_UNLOCKED 
				textColor = control:GetStyle("succeeded") 
			end 
			unlockSection:AddLine(zo_strformat(unlockText, GetChampionDisciplineName(disciplineIndex), unlockLevel), control:GetStyle("bodyDescription"), textColor) 
			control:AddSection(unlockSection) 
		else 
			--if it's possible to spend more points on this skill (we haven't hit cap) 
			if GetNumPointsSpentOnChampionSkill(disciplineIndex, skillIndex) + pendingPoints < GetMaxPossiblePointsInChampionSkill() then 
				local upgradeSection = control:AcquireSection(control:GetStyle("championBodySection"), control:GetStyle("bodySection")) 
				local nextPointDescription = GetChampionAbilityDescription(abilityId, pendingPoints + 1) 
				if nextPointDescription ~= "" then 
					upgradeSection:AddLine(GetString(SI_CHAMPION_TOOLTIP_NEXT_POINT), control:GetStyle("championAbilityUpgrade"), control:GetStyle("championBodyHeader")) 
					upgradeSection:AddLine(zo_strformat(SI_ABILITY_TOOLTIP_DESCRIPTION, nextPointDescription), control:GetStyle("championAbilityUpgrade"), control:GetStyle("bodyDescription")) 
					control:AddSection(upgradeSection) 
				end 

				local attribute = GetChampionDisciplineAttribute(disciplineIndex) 
				local iconPath = GetChampionPointAttributeIcon(attribute) 
				local pointCostSection = control:AcquireSection(control:GetStyle("championBodySection"), control:GetStyle("bodySection")) 
				if HasAvailableChampionPointsInAttribute(attribute) then 
					if CHAMPION_PERKS:GetNumAvailablePointsThatCanBeSpent(attribute) > 0 then 
						pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_UPGRADE, iconPath), control:GetStyle("bodyDescription"), control:GetStyle("succeeded")) 
					else 
						local attributeName = ZO_Champion_GetUnformattedConstellationGroupNameFromAttribute(attribute) 
						pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_REACHED_MAX_SPEND_LIMIT, GetMaxSpendableChampionPointsInAttribute(), iconPath, attributeName), control:GetStyle("bodyDescription"), control:GetStyle("failed")) 
					end 
				else 
					pointCostSection:AddLine(zo_strformat(SI_CHAMPION_TOOLTIP_POINTS_REQUIRED, iconPath), control:GetStyle("bodyDescription"), control:GetStyle("failed")) 
				end 
				control:AddSection(pointCostSection) 
			end 
		end 
	end 
	------------------------------------------------------------------------------
end
	-- replace tooltips
function kelaReplaceTooltips (tooltip)	

	-- replace type, style and unique info
	local oldAddTypeSlotUniqueLine = tooltip.AddTypeSlotUniqueLine
	tooltip.AddTypeSlotUniqueLine = function(control, itemLink, itemType, section, text1, text2, ...)	
		
		--KelaPostMsg(tostring(text1))
		if(text1) then 
			local unique = IsItemLinkUnique(itemLink) 
			local uniqueEquipped = IsItemLinkUniqueEquipped(itemLink) 
			local formatSuffix 
			if(unique) then 
				formatSuffix = "_UNIQUE"
			elseif(uniqueEquipped) then 
				formatSuffix = "_UNIQUE_EQUIPPED"
			else 
				formatSuffix = "" 
			end 		
			local lineText 
			local itemStyle = GetItemLinkItemStyle(itemLink)
			local equipType = GetItemLinkEquipType(itemLink) 	
			if equipType and itemStyle ~= ITEMSTYLE_NONE and equipType ~= EQUIP_TYPE_INVALID and equipType ~= EQUIP_TYPE_RING and equipType ~= EQUIP_TYPE_POISON and equipType ~= EQUIP_TYPE_NECK and equipType ~= EQUIP_TYPE_COSTUME then
		
				local itemType, specializedItemType = GetItemLinkItemType(itemLink) 
				local specializedItemTypeText = ZO_GetSpecializedItemTypeText(itemType, specializedItemType) 
				local armorType = GetItemLinkArmorType(itemLink)
				local weaponType = GetItemLinkWeaponType(itemLink) 			
				local styleColor, styleText = getStyleHeaderLine(itemStyle)
				if itemType == ITEMTYPE_ARMOR and weaponType == WEAPONTYPE_NONE then 
					lineText = GetString("SI_EQUIPTYPE", equipType).." ("..GetString("SI_ARMORTYPE", armorType).." - "..styleColor:Colorize(styleText)..")"
				elseif weaponType ~= WEAPONTYPE_NONE then 
					lineText = GetString("SI_WEAPONTYPE", weaponType).." ("..GetString("SI_EQUIPTYPE", equipType).." - "..styleColor:Colorize(styleText)..")" 					
				end
			else
				if(text2) then 
					if equipType ~= EQUIP_TYPE_RING and equipType ~= EQUIP_TYPE_NECK and equipType ~= EQUIP_TYPE_COSTUME then
						local format = _G["SI_ITEM_FORMAT_STR_TEXT1_TEXT2"..formatSuffix]
						lineText = zo_strformat(format, text1, text2) 
					else
						local format = _G["SI_ITEM_FORMAT_STR_TEXT1"..formatSuffix] 
						lineText = zo_strformat(format, text1) 
					end					
				else 
					local format = _G["SI_ITEM_FORMAT_STR_TEXT1"..formatSuffix] 
					lineText = text1
					if formatSuffix == "_UNIQUE" then
						lineText = text1.." "..GetString(SI_ITEM_FORMAT_STR_UNIQUE)
					elseif formatSuffix == "_UNIQUE_EQUIPPED" then
						lineText = text1.." "..GetString(SI_ITEM_FORMAT_STR_UNIQUE_EQUIPPED)
					end
				end 				
			end 
			if(lineText) then 
				section:AddLine(lineText, {fontSize = KELA_TOOLTIPS_FONT_SMALL, customSpacing = 0, childSpacing = 0})
			end 
			

		end
		-- local ret = oldAddTypeSlotUniqueLine(control, itemLink, itemType, section, text1, text2, ...)	
		-- return ret	
	end 
	
	-- replace currency and add trading info
	local oldAddItemValue = tooltip.AddItemValue -- hide old AddItemValue
	tooltip.AddItemValue = function(control, itemLink, ...)
	
	end
	
	local oldAddItemTitle = tooltip.AddItemTitle
	tooltip.AddItemTitle = function(control, itemLink, name, ...)
		local kelaLine = control:AcquireSection(control:GetStyle("kelaTrade")) 
		local kelaRecipeLine = control:AcquireSection(control:GetStyle("kelaTrade"))
		local valueColor = colors.COLOR_WHITE
		local itemStyle = GetItemLinkItemStyle(itemLink)
		local itemType, specializedItemType = GetItemLinkItemType(itemLink) 
		local specializedItemTypeText = ZO_GetSpecializedItemTypeText(itemType, specializedItemType) 
		local equipType = GetItemLinkEquipType(itemLink) 
		local armorType = GetItemLinkArmorType(itemLink)
		local weaponType = GetItemLinkWeaponType(itemLink) 	

		-- build the price line for the item and product (for recipes)
		local iconGold = zo_iconFormat("EsoUI/Art/currency/gamepad/gp_gold.dds", "32", "32") 

		local hideItemLevel = ignoreLevel or ShouldHideTooltipRequiredLevel(itemLink)
		local CONSIDER_CONDITION = true 
		local value = GetItemLinkValue(itemLink, not CONSIDER_CONDITION)
		local finalValue
		local effectiveValue
		local valueString = colors.COLOR_WHITE:Colorize(zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, "0", iconGold))
		local resultItemLink = nil
		local resultValueString
		local averageGuildPrice = 0
		local countGuildPrice = 0

		local valueStringAdditionalTTC = nil
		local valueStringAdditionalATT = nil
		-- if itemType == ITEMTYPE_RECIPE then
		-- 	resultItemLink = GetItemLinkRecipeResultItemLink(itemLink)
		-- 	resultValueString = colors.COLOR_WHITE:Colorize(GetString(KELA_PRODUCT))
		-- end
		if(value > 0) then 
			effectiveValue = GetItemLinkValue(itemLink, CONSIDER_CONDITION) 
			finalValue = value 
			if(effectiveValue ~= value) then 
				finalValue = zo_strformat(SI_ITEM_FORMAT_STR_EFFECTIVE_VALUE_OF_MAX, effectiveValue, value)
			end 
			valueString = colors.COLOR_WHITE:Colorize(zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, finalValue, iconGold))
			-- if resultItemLink then
			-- 	resultFinalValue = GetItemLinkValue(resultItemLink, not CONSIDER_CONDITION) 
			-- 	resultValueString = resultValueString..colors.COLOR_WHITE:Colorize(zo_strformat(SI_GAMEPAD_TOOLTIP_ITEM_VALUE_FORMAT, resultFinalValue, iconGold))				
			-- end			
		end
		if TamrielTradeCentre then
			local priceInfoTTC = TamrielTradeCentrePrice:GetPriceInfo(itemLink)

			if priceInfoTTC then
				local valueTTC = nil
				-- Get one of 2 prices from TTC
				if priceInfoTTC.SuggestedPrice then
					valueTTC = priceInfoTTC.SuggestedPrice
				elseif priceInfoTTC.Avg then
					valueTTC = priceInfoTTC.Avg
				end
				
				-- Update the valueString
				valueString = valueString..colors.COLOR_WHITE:Colorize(", ")
				if valueTTC then
					averageGuildPrice = averageGuildPrice + (valueTTC * 1.125)
					local valueTTCStr = KelaLocalizedFormatNumber(valueTTC * 1.125, 0)
					valueString = valueString..zo_strformat("|c1fcae0TTC: <<1>>|r", valueTTCStr) -- old color: cf23d8e
					--defaultValueTTC = zo_strformat("|cf23d8eTTC: <<1>>|r", valueTTC)
					countGuildPrice = countGuildPrice + 1
				else
					valueString = valueString..zo_strformat("|c1fcae0TTC: N/A|r")
				end

				-- Create additional TTC Info Lines
				valueStringAdditionalTTC = zo_strformat("|c1fcae0TTC - <<1>> Avg / <<3>> min / <<4>> max [<<2>> Listings]|r", 
					KelaLocalizedFormatNumber(priceInfoTTC.Avg), --TamrielTradeCentre:FormatNumber(priceInfoTTC.Avg), 
					KelaLocalizedFormatNumber(priceInfoTTC.EntryCount), 
					KelaLocalizedFormatNumber(priceInfoTTC.Min), 
					KelaLocalizedFormatNumber(priceInfoTTC.Max))
				
			end
			
			-- if resultItemLink then
			-- 	resultValueString = resultValueString..colors.COLOR_WHITE:Colorize(", ")
			-- 	local priceInfoTTC = TamrielTradeCentrePrice:GetPriceInfo(resultItemLink)
			-- 	if (priceInfoTTC ~= nil) then
			-- 		if (priceInfoTTC.SuggestedPrice ~= nil) then
			-- 			local resultValueTTC = KelaLocalizedFormatNumber(priceInfoTTC.SuggestedPrice * 1.125, 2)
			-- 			resultValueString = resultValueString..zo_strformat("|cf23d8e<<1>> TTC|r", resultValueTTC)
			-- 		else
			-- 			resultValueString = resultValueString..zo_strformat("|cf23d8e- TTC|r")
			-- 		end
			-- 	else
			-- 		resultValueString = resultValueString..zo_strformat("|cf23d8e- TTC|r")
			-- 	end
			-- end
		end
		if MasterMerchant then 
			-- valueString = valueString..zo_strformat("|cf23d8e, |r")
			valueString = valueString..colors.COLOR_WHITE:Colorize(", ")
			local tipStats = MasterMerchant:itemStats(itemLink, false)
			if tipStats.avgPrice then -- and tipStats.avgPrice ~= nil
				averageGuildPrice = averageGuildPrice + tipStats['avgPrice']
				local valueMM = KelaLocalizedFormatNumber(tonumber(tipStats['avgPrice']), 0)
				valueString = valueString..zo_strformat("|c7171d1MM: <<1>>|r", valueMM)
				countGuildPrice = countGuildPrice + 1
			else
				valueString = valueString..zo_strformat("|c7171d1MM: N/A|r")
			end
			-- if resultItemLink then
			-- 	resultValueString = resultValueString..zo_strformat("|cf23d8e, |r")
			-- 	local tipStats = MasterMerchant:itemStats(resultItemLink, false)
			-- 	if tipStats.avgPrice then
			-- 		if (tipStats.avgPrice ~= nil) then
			-- 			local resultValueMM = KelaLocalizedFormatNumber(tonumber(tipStats['avgPrice']), 2)
			-- 			resultValueString = resultValueString..zo_strformat("|c7171d1<<1>> MM|r", resultValueMM)
			-- 		else
			-- 			resultValueString = resultValueString..zo_strformat("|c7171d1- MM|r")
			-- 		end
			-- 	else
			-- 		resultValueString = resultValueString..zo_strformat("|c7171d1- MM|r")
			-- 	end
			-- end		
		end
		if ArkadiusTradeTools ~= nil then 
			-- valueString = valueString..zo_strformat("|c7171d1, |r") 
			valueString = valueString..colors.COLOR_WHITE:Colorize(", ")
			local statsATT = GetATTPriceStats(itemLink)
			if statsATT then -- and averagePrice ~= nil
				averageGuildPrice = averageGuildPrice + statsATT.Avg
				-- local valueATT = averagePrice
				-- valueString = valueString..zo_strformat("|cf58585<<1>> ATT|r", valueATT)
				local resultValueATT = KelaLocalizedFormatNumber(tonumber(statsATT.Avg), 0)
				valueString = valueString..zo_strformat("|c1fe095ATT: <<1>>|r", resultValueATT) -- old color: f58585
				countGuildPrice = countGuildPrice + 1

				-- Create the Additional ATT Info String
				valueStringAdditionalATT = zo_strformat("|c1fe095ATT - <<1>> Avg / <<3>> min / <<4>> max [<<2>> Sales]|r", 
					KelaLocalizedFormatNumber(statsATT.Avg), --TamrielTradeCentre:FormatNumber(priceInfoTTC.Avg), 
					KelaLocalizedFormatNumber(statsATT.Sales), 
					KelaLocalizedFormatNumber(statsATT.Min or 0), 
					KelaLocalizedFormatNumber(statsATT.Max))
			else
				valueString = valueString..zo_strformat("|c1fe095ATT: N/A|r")
			end

			-- if resultItemLink then
			-- 	resultValueString = resultValueString..zo_strformat("|c7171d1, |r") 
			-- 	local averagePrice = GetATTPriceAndStatus(resultItemLink)
			-- 	if averagePrice then
			-- 		if (averagePrice ~= nil) then
			-- 			local resultValueATT = averagePrice
			-- 			resultValueString = resultValueString..zo_strformat("|cf58585<<1>> ATT|r", resultValueATT)
			-- 		else
			-- 			resultValueString = resultValueString..zo_strformat("|cf58585- ATT|r")
			-- 		end
			-- 	else
			-- 		resultValueString = resultValueString..zo_strformat("|cf58585- ATT|r")
			-- 	end
			-- end		
		end
		
		if countGuildPrice > 1 then 
			local averageGuildValue = KelaLocalizedFormatNumber(averageGuildPrice / countGuildPrice, 2)
			valueString = valueString..", "..'|t24:24:EsoUI/Art/currency/currency_gold.dds|t'.." "..colors.COLOR_GOLD:Colorize(averageGuildValue)
		end

		kelaLine:AddLine(valueString)
		if valueStringAdditionalTTC then kelaLine:AddLine(valueStringAdditionalTTC) end
		if valueStringAdditionalATT then kelaLine:AddLine(valueStringAdditionalATT) end
		control:AddSection(kelaLine)
		-- local ret = oldAddItemTitle(control, itemLink, name, ...)
		oldAddItemTitle(control, itemLink, name, ...)
	end
	
	-- replace charge, condition and poison bar
	local oldAddPoisonInfo = tooltip.AddPoisonInfo
	tooltip.AddPoisonInfo = function(control, itemLink, equipSlot, ...)	
		local hasPoison, poisonCount, poisonHeader, poisonItemLink = GetItemPairedPoisonInfo(equipSlot) 
		if(hasPoison) then 
			--Poison Count 
			local poisonSection = control:AcquireSection(control:GetStyle("bodyHeader"), {paddingTop = 2, paddingBottom = -5, uppercase = false})
			local poisonString = colors.COLOR_POISON:Colorize(zo_iconTextFormatNoSpace("EsoUI/Art/Tooltips/icon_poison.dds", 32, 32, poisonCount).." - "..poisonHeader)
			poisonSection:AddLine(poisonString, {fontSize = KELA_TOOLTIPS_FONT_MEDIUM}) 
			control:AddSection(poisonSection) 
			--Poison Ability 
			control:AddOnUseAbility(poisonItemLink, {fontSize = KELA_TOOLTIPS_FONT_SMALL})
		end 
		-- local ret = oldAddPoisonInfo(control, itemLink, equipSlot, ...)	
	end
	-- local oldAddEnchantChargeBar = tooltip.AddEnchantChargeBar
	-- tooltip.AddEnchantChargeBar = function(control, itemLink, forceFullDurability, previewChargeToAdd, ...)	
		-- local minValue = 0 
		-- local maxValue = 100
		-- local currentValue = 0
		-- local previewToAdd = previewChargeToAdd
		-- local bar = nil 
		-- if(DoesItemLinkHaveArmorDecay(itemLink)) then
			-- currentValue = GetItemLinkCondition(itemLink) 
		-- elseif(DoesItemLinkHaveEnchantCharges(itemLink)) then	
			-- maxValue = GetItemLinkMaxEnchantCharges(itemLink) 
			-- currentValue = forceFullDurability and maxValue or GetItemLinkNumEnchantCharges(itemLink) 
		-- end 
		-- local kelaEnchantChargeBar = control:AcquireSection(control:GetStyle("conditionOrChargeBarSection"), {paddingTop = 0, paddingBottom = 7})
		-- if previewToAdd then 
		    -- bar = control:AcquireStatusBar(control:GetStyle("itemImprovementConditionOrChargeBar"), {paddingTop = 0, paddingBottom = 7}) 
			-- bar:SetMinMax(minValue, maxValue) 
			-- local newValue = zo_clamp(currentValue + previewToAdd, minValue, maxValue) 
			-- bar:SetValueAndPreviewValue(currentValue, newValue) 
		-- else
			-- bar = control:AcquireStatusBar(control:GetStyle("conditionOrChargeBar"), {paddingTop = 0, paddingBottom = 7})
			-- bar:SetMinMax(minValue, maxValue) 
			-- bar:SetValue(currentValue) 
		-- end 
		-- kelaEnchantChargeBar:AddStatusBar(bar) 
		-- control:AddSection(kelaEnchantChargeBar)	
	-- end			
	-- local oldAddConditionBar = tooltip.AddConditionBar
	-- tooltip.AddConditionBar = function(control, itemLink, previewConditionToAdd, ...)	
		-- local minValue = 0 
		-- local maxValue = 100
		-- local currentValue = 0
		-- local previewToAdd = previewConditionToAdd
		-- local bar = nil 
		-- if(DoesItemLinkHaveArmorDecay(itemLink)) then
			-- currentValue = GetItemLinkCondition(itemLink) 
		-- elseif(DoesItemLinkHaveEnchantCharges(itemLink)) then	
			-- maxValue = GetItemLinkMaxEnchantCharges(itemLink) 
			-- currentValue = forceFullDurability and maxValue or GetItemLinkNumEnchantCharges(itemLink) 
		-- end 
		-- local kelaConditionBar = control:AcquireSection(control:GetStyle("conditionOrChargeBarSection"), {paddingTop = 5, paddingBottom = 5})
		-- if previewToAdd then 
			-- bar = control:AcquireItemImprovementStatusBar(itemLink, currentValue, maxValue, previewToAdd) 
		-- else 
			-- bar = control:AcquireStatusBar(control:GetStyle("conditionOrChargeBar"), {paddingTop = 5, paddingBottom = 5})
			-- bar:SetMinMax(minValue, maxValue) 
			-- bar:SetValue(currentValue)		
		-- end 
		-- kelaConditionBar:AddStatusBar(bar) 
		-- control:AddSection(kelaConditionBar)
	-- end	
------------------------------------------------------------------------------
	-- replace enchant section	ESOUI/art/enchanting/enchanting_highlight.dds
	local oldAddEnchant = tooltip.AddEnchant	
	tooltip.AddEnchant = function(control, itemLink, enchantDiffMode, equipSlot, ...) 
		stringEnchant = ""
		enchantDiffMode = enchantDiffMode or ZO_ENCHANT_DIFF_NONE 
		local enchantSection = control:AcquireSection(control:GetStyle("bodySection"))  
		local hasEnchant, enchantHeader, enchantDescription = GetItemLinkEnchantInfo(itemLink) 
		local itemType = GetItemLinkItemType(itemLink)
		local equipType = GetItemLinkEquipType(itemLink) 	
		local strIcon = "ESOUI/art/enchanting/enchanting_highlight.dds"
		if(hasEnchant) then 
			stringEnchant = enchantHeader
				local stringEnchantShort
			if string.find(stringEnchant,":") then 
				stringEnchantShort = string.upper(string.sub(stringEnchant, string.find(stringEnchant,":") + 2, string.len(stringEnchant)))
			else 
				stringEnchantShort = string.upper(stringEnchant)
			end
			if enchantDiffMode == ZO_ENCHANT_DIFF_NONE then 
				if (IsItemAffectedByPairedPoison(equipSlot)) then 
					stringEnchant = zo_iconFormat(strIcon, 44, 44).." "..colors.COLOR_WHITE:Colorize(stringEnchantShort).." - "..colors.COLOR_POISON:Colorize(GetString(SI_TOOLTIP_ENCHANT_SUPPRESSED_BY_POISON))
					local suppressedStyle = control:GetStyle("suppressedAbility") 
				else 
					stringEnchant = zo_iconFormat(strIcon, 44, 44).." "..colors.COLOR_WHITE:Colorize(stringEnchantShort).." - "..enchantDescription
				end 
			end 
		end 
		enchantSection:AddLine(stringEnchant, control:GetStyle("bodyDescription"))  
		control:AddSection(enchantSection) 
		if hasEnchant and enchantDiffMode ~= ZO_ENCHANT_DIFF_NONE then 
			local diffColorStyle, icon 
			if enchantDiffMode == ZO_ENCHANT_DIFF_ADD then 
				diffColorStyle = control:GetStyle("enchantDiffAdd") 
				icon = "EsoUI/Art/Buttons/pointsPlus_up.dds" 
			elseif enchantDiffMode == ZO_ENCHANT_DIFF_REMOVE then 
				diffColorStyle = control:GetStyle("enchantDiffRemove") 
				icon = "EsoUI/Art/Buttons/pointsMinus_up.dds" 
			else 
				-- If this assert is hit, support needs to be added for the additional 
				-- enchant diff modes, which do not exist at the time of writing. 
				assert(false) 
			end 
			local enchantmentDescriptionSection = control:AcquireSection(diffColorStyle, control:GetStyle("enchantDiff")) 
			local diffSection = control:AcquireSection(control:GetStyle("enchantDiffTextureContainer")) 
			diffSection:AddTexture(icon, control:GetStyle("enchantDiffTexture")) 
			enchantmentDescriptionSection:AddSection(diffSection) 
			enchantmentDescriptionSection:AddLine(enchantDescription, control:GetStyle("bodyDescription")) 
			control:AddSection(enchantmentDescriptionSection) 
		end 
		--local ret = oldAddEnchant(control, itemLink, enchantDiffMode, equipSlot, ...) 
	end	
------------------------------------------------------------------------------	
	-- replace trait section
	
	local newTraitFunction = function(control, itemLink, ...)
		local kelaNewLine = control:AcquireSection(control:GetStyle("bodySection")) 
		local itemStyle = GetItemLinkItemStyle(itemLink)
		local equipType = GetItemLinkEquipType(itemLink)
		local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
		local armorType = GetItemLinkArmorType(itemLink)
		local weaponType = GetItemLinkWeaponType(itemLink)
		local researchColor = nil
		local researchIcon = nil	
		local traitText = ""		
		local countBank = kelaGetSameTraitCount(BAG_BANK, armorType, weaponType, equipType, traitType)
		local countPack = kelaGetSameTraitCount(BAG_BACKPACK, armorType, weaponType, equipType, traitType)
		local countWorn = kelaGetSameTraitCount(BAG_WORN, armorType, weaponType, equipType, traitType)
		local researchStatus = KELA_RESEARCH_COMPAT:GetItemLinkResearchStatus(itemLink)
		
		researchIcon, researchColor, traitText = getTraitHeaderLine(researchStatus, countBank, countPack, countWorn)
		local traitTextIntricate = traitText
		local traitTextOrnate = traitText	
		
		local function IsIntricateTrait(traitType)
			return traitType == ITEM_TRAIT_TYPE_JEWELRY_INTRICATE or traitType == ITEM_TRAIT_TYPE_WEAPON_INTRICATE or traitType == ITEM_TRAIT_TYPE_ARMOR_INTRICATE
		end
		local function IsOrnateTrait(traitType)
			return traitType == ITEM_TRAIT_TYPE_JEWELRY_ORNATE or traitType == ITEM_TRAIT_TYPE_WEAPON_ORNATE or traitType == ITEM_TRAIT_TYPE_ARMOR_ORNATE
		end

		if equipType and traitType ~= 0 and not IsOrnateTrait(traitType) and not IsIntricateTrait(traitType) then --itemStyle ~= ITEMSTYLE_NONE and equipType ~= EQUIP_TYPE_INVALID and equipType ~= EQUIP_TYPE_POISON and equipType ~= EQUIP_TYPE_COSTUME then
			local traitName = GetString("SI_ITEMTRAITTYPE", traitType)
			local traitInformation = GetItemTraitInformationFromItemLink(itemLink)
			local traitInformationIconPath = GetPlatformTraitInformationIcon(traitInformation)
			local formattedTraitName
			if traitInformationIconPath then
				formattedTraitName = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_WITH_ICON_HEADER, zo_iconFormat(traitInformationIconPath, 32, 32), traitName)
			else
				formattedTraitName = zo_strformat(SI_ITEM_FORMAT_STR_ITEM_TRAIT_HEADER, traitName)
			end
			if not researchStatus then --type(researchStatus) == "table" then
				local iconResearch = zo_iconFormat("ESOUI/art/crafting/smithing_tabicon_research_disabled.dds", 44, 44)
				local additionalTooltipStyle
				if extraData and extraData.showTraitAsNew then
					additionalTooltipStyle = control:GetStyle("succeeded")
				end
				kelaNewLine:AddLine(iconResearch.." "..string.upper(colors.COLOR_WHITE:Colorize(formattedTraitName)), control:GetStyle("bodyDescription"))
				kelaNewLine:AddLine(traitDescription, control:GetStyle("bodyDescription"))

				kelaNewLine:AddLine("", control:GetStyle("bodyDescription"))
				kelaNewLine:AddLine("", control:GetStyle("bodyDescription"))


				kelaNewLine:AddLine(colors.COLOR_WHITE:Colorize(string.upper(GetString(KELA_TOOLTIP_TRAIT_USE))), control:GetStyle("bodyDescription"))


				local researchListText = ""
				local strResIndex = 0
				local resNameIndex = 0
				local researches = kpuiSVCharData and kpuiSVCharData["researches"]

				if researches then
				for i, tradeSkill in pairs(researches) do
					local blnTradeSkill = false
					local countLines = 0	

					for k, resIndex in pairs(tradeSkill) do
						--CHAT_SYSTEM:AddMessage("k "..tostring(k))
						
						
						if i == 2 and k == 1 then
							resNameIndex = 3
						elseif i == 2 and k == 8 then
							resNameIndex = 4
						elseif i == 1 and k == 1 then
							resNameIndex = 1
						elseif i == 1 and k == 8 then
							resNameIndex = 2
						elseif i == 6 and k == 1 then
							resNameIndex = 5
						elseif i == 6 and k == 6 then
							resNameIndex = 6
						elseif i == 7 and k == 1 then
							resNameIndex = 7
						end						
						for researchTraitType, researchStatus in pairs(resIndex) do

								
							if researchTraitType == traitType then
								blnTradeSkill = true
								countLines = countLines + 1
								local color = colors.COLOR_GREY
								if researchStatus == 1 then color = colors.COLOR_WHITE end
								if countLines == 1 then 
									strResIndex = string.upper(GetString("KELA_RESEARCH_TYPE", resNameIndex))
									researchListText = strResIndex..": "..color:Colorize(GetSmithingResearchLineInfo(i, k))
								elseif countLines == 8 then
									kelaNewLine:AddLine(researchListText, control:GetStyle("bodyDescription")) 
									strResIndex = string.upper(GetString("KELA_RESEARCH_TYPE", resNameIndex))
									researchListText = strResIndex..": "..color:Colorize(GetSmithingResearchLineInfo(i, k))
								else
									researchListText = researchListText..", "..color:Colorize(GetSmithingResearchLineInfo(i, k))
								end
							end
						end
					end
					if blnTradeSkill then kelaNewLine:AddLine(researchListText, control:GetStyle("bodyDescription")) end 
				end
				end

				kelaNewLine:AddLine("", control:GetStyle("bodyDescription"))
				kelaNewLine:AddLine("", control:GetStyle("bodyDescription"))


				local traitResearchSourceDescription, traitMaterialSourceDescription

				if researches then
				for i, tradeSkill in pairs(researches) do
					local countTraitIndex = 0
					for k, resIndex in pairs(tradeSkill) do
						countTraitIndex = countTraitIndex + 1
						for researchTraitType, researchStatus in pairs(resIndex) do
							if researchTraitType == traitType then
								_, traitResearchSourceDescription, traitMaterialSourceDescription = GetSmithingResearchLineTraitDescriptions(i, k, countTraitIndex)
								break
							end
						end
					end
				end
				end
				
			
				if traitResearchSourceDescription or traitMaterialSourceDescription then 
					kelaNewLine:AddLine(colors.COLOR_WHITE:Colorize(string.upper(GetString(KELA_TOOLTIP_TRAIT_SEARCH))), control:GetStyle("bodyDescription")) 
					kelaNewLine:AddLine(traitResearchSourceDescription, control:GetStyle("bodyDescription")) 
					kelaNewLine:AddLine(traitMaterialSourceDescription, control:GetStyle("bodyDescription"))
				end

				control:AddSection(kelaNewLine)		
			
			
			elseif researchStatus then
				--CHAT_SYSTEM:AddMessage("researchStatus")
				if traitText then
					traitText = zo_iconFormat(researchIcon, 44, 44).." "..colors.COLOR_WHITE:Colorize(string.upper(formattedTraitName)).." ("..researchColor:Colorize(string.lower(traitText))..")"
				end
				kelaNewLine:AddLine(traitText.." - "..traitDescription, control:GetStyle("bodyDescription")) 
				control:AddSection(kelaNewLine)
			end
		end
		if IsIntricateTrait(traitType) then
			traitTextIntricate = zo_iconFormat("/esoui/art/tutorial/inventory_trait_intricate_icon.dds", 32, 32).." "..colors.COLOR_WHITE:Colorize(GetString("SI_ITEMTRAITTYPE", traitType))
			kelaNewLine:AddLine(string.upper(traitTextIntricate).." - "..traitDescription, control:GetStyle("bodyDescription")) 
			control:AddSection(kelaNewLine)
		elseif IsOrnateTrait(traitType) then
			traitTextOrnate = zo_iconFormat("/esoui/art/tutorial/inventory_trait_ornate_icon.dds", 32, 32).." "..colors.COLOR_WHITE:Colorize(GetString("SI_ITEMTRAITTYPE", traitType))
			kelaNewLine:AddLine(string.upper(traitTextOrnate).." - "..traitDescription, control:GetStyle("bodyDescription")) 
			control:AddSection(kelaNewLine)
		end
		--local ret = oldAddTrait(control, itemLink, ...)
		--return ret
	end
	-- local oldAddTrait = tooltip.AddTrait
	-- tooltip.AddTrait = newTraitFunction
	
------------------------------------------------------------------------------
	-- replace set : Not Needed, doesn't highlight trial sets
	-- local oldAddSet = tooltip.AddSet
	-- tooltip.AddSet = function(control, itemLink, equipped, ...)	
	-- 	local hasSet, setName, numBonuses, numEquipped, maxEquipped = GetItemLinkSetInfo(itemLink) 
	-- 	if(hasSet) then
	-- 		local setSection = control:AcquireSection(control:GetStyle("bodySection")) 
	-- 		setSection:AddLine(colors.COLOR_WHITE:Colorize(string.upper(zo_strformat(SI_ITEM_FORMAT_STR_SET_NAME, setName, numEquipped, maxEquipped))), control:GetStyle("bodyDescription"))  
	-- 		for i = 1, numBonuses do 
	-- 			local numRequired, bonusDescription = GetItemLinkSetBonusInfo(itemLink, equipped, i) 
	-- 			if(numEquipped >= numRequired) then 
	-- 				setSection:AddLine(bonusDescription, control:GetStyle("activeBonus"), control:GetStyle("bodyDescription")) 
	-- 			else 
	-- 				setSection:AddLine(bonusDescription, control:GetStyle("inactiveBonus"), control:GetStyle("bodyDescription")) 
	-- 			end  
	-- 		end	
	-- 		control:AddSection(setSection)
	-- 	end
	-- 	-- local ret = oldAddSet(control, itemLink, ...)
	-- 	-- return ret
	-- end
------------------------------------------------------------------------------
	-- replace achievement bars sections
	-- local oldLayoutAchievementSummary = tooltip.LayoutAchievementSummary
	-- tooltip.LayoutAchievementSummary = function(control, ...)	
	-- 	for categoryIndex=1, GetNumAchievementCategories() do 
	-- 		local categoryName, numSubCategories, numAchievements, earnedPoints, totalPoints = GetAchievementCategoryInfo(categoryIndex) 

	-- 		local categorySection = control:AcquireSection(control:GetStyle("achievementSummaryCategorySection")) 
	-- 		categorySection:AddLine(categoryName, control:GetStyle("achievementSummaryCriteriaHeader")) 

	-- 		local barSection = control:AcquireSection(control:GetStyle("achievementTopSummarySection")) 
	-- 		local statusBar = control:AcquireStatusBar(control:GetStyle("achievementCriteriaBar")) 
	-- 		statusBar:SetMinMax(0, totalPoints) 
	-- 		statusBar:SetValue(earnedPoints) 
	-- 		barSection:AddStatusBar(statusBar) 
	-- 		categorySection:AddSection(barSection) 

	-- 		control:AddSection(categorySection) 
	-- 	end 
	-- end 	
------------------------------------------------------------------------------
	-- local oldLayoutAchievementCriteria = tooltip.LayoutAchievementCriteria
	-- tooltip.LayoutAchievementCriteria = function(control, achievementId, ...)	
	-- 	local numCriteria = GetAchievementNumCriteria(achievementId) 
	-- 	if numCriteria == 1 then 
	-- 		local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, 1) 
	-- 		if numRequired == 1 then 
	-- 			-- Do not show a single checkbox. 
	-- 			return 
	-- 		end 
	-- 	end 

	-- 	local criteriaSection = control:AcquireSection(control:GetStyle("achievementCriteriaSection")) 

	-- 	for i = 1, numCriteria do 
	-- 		local description, numCompleted, numRequired = GetAchievementCriterion(achievementId, i) 
	-- 		local isComplete = (numCompleted == numRequired) 

	-- 		if numRequired == 1 then -- Checkbox 
	-- 			criteriaSection:AddSection(control:GetCheckboxSection(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description), isComplete, SI_ACHIEVEMENT_CRITERION_FORMAT)) 

	-- 		else -- Progress bar. 
	-- 			local entrySection = control:AcquireSection(control:GetStyle("achievementTopCriteriaSection")) 
	-- 			local statusBar = control:AcquireStatusBar(control:GetStyle("achievementCriteriaBar")) 
	-- 			statusBar:SetMinMax(0, numRequired) 
	-- 			statusBar:SetValue(numCompleted) 
	-- 			entrySection:AddStatusBar(statusBar) 
	-- 			local stringDescription = colors.COLOR_WHITE:Colorize(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, numCompleted, numRequired)).." - "..colors.COLOR_BROWN:Colorize(description)
	-- 			entrySection:AddLine (stringDescription, control:GetStyle("achievementSubtitleText"))
	-- 			-- entrySection:AddLine(zo_strformat(SI_JOURNAL_PROGRESS_BAR_PROGRESS, numCompleted, numRequired), control:GetStyle("statValuePairValueSmall")) 
	-- 			-- entrySection:AddLine(zo_strformat(SI_ACHIEVEMENT_CRITERION_FORMAT, description)) 

	-- 			criteriaSection:AddSection(entrySection) 
	-- 		end 
	-- 	end 
	-- 	control:AddSection(criteriaSection) 
	-- end 
------------------------------------------------------------------------------



------------------------------------------------------------------------------
end
