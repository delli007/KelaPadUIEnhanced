-- redefine styles	
function kelaTotalRedefineStyles ()
	local colors = kpuiConst.Colors
    --General 

    ZO_TOOLTIP_STYLES.title = { 
        fontSize = KELA_TOOLTIPS_FONT_BIG, 
        customSpacing = 8, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
		fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    }
    ZO_TOOLTIP_STYLES.statValuePairStat = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE,
    }
    ZO_TOOLTIP_STYLES.statValuePairValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
	}
    ZO_TOOLTIP_STYLES.championRequirements = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.fullWidth = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    }
    ZO_TOOLTIP_STYLES.statValueSlider = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,	
        gradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.statValueSliderStat = { 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL, 
    }
    ZO_TOOLTIP_STYLES.statValueSliderValue = { 
        fontSize = KELA_TOOLTIPS_FONT_SMALL,
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,		
        gradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.succeeded = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_SUCCEEDED,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.failed = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.bodySection = { 
        customSpacing = 15, 
        childSpacing = 10, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,	
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.bodySection1 = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,	
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.bodyHeader = { 
        fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,	
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    }
    ZO_TOOLTIP_STYLES.itemTagsSection = { 
        customSpacing = 40, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.itemTradeBoPSection = { 
        customSpacing = 80, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.itemTradeBoPHeader = { 
        fontColor = ZO_TRADE_BOP_COLOR,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,	
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 		
    }
    ZO_TOOLTIP_STYLES.bodyDescription = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    }
    ZO_TOOLTIP_STYLES.enchantIrreplaceable = { 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
    }
    --Character Attribute Tooltip 
    ZO_TOOLTIP_STYLES.attributeBody = {    
        customSpacing = 30, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    }
    ZO_TOOLTIP_STYLES.equipmentBonusValue = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.equipmentBonusLowestPieceHeader = { 
        uppercase = true, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
    }
    --Item Tooltip 
    ZO_TOOLTIP_STYLES.baseStatsSection = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "down", 
        statValuePairSpacing = 3, 
        childSpacing = 10, 
        childSecondarySpacing = 3, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
    }
    ZO_TOOLTIP_STYLES.valueStatsSection = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "down", 
        paddingTop = 15, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
    }
    ZO_TOOLTIP_STYLES.conditionOrChargeBarSection = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "down", 
        statValuePairSpacing = 6, 
        childSpacing = 10, 
        customSpacing = 10, 
        childSecondarySpacing = 3, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
    }
    ZO_TOOLTIP_STYLES.conditionOrChargeBar = { 
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium", 
        statusBarTemplateOverrideName = "ArrowBar", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.itemImprovementConditionOrChargeBar = { 
        statusBarTemplate = "ZO_ItemImproveBar_Gamepad", 
        statusBarTemplateOverrideName = "ImproveBar", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.ridingTrainingChargeBar = { 
        statusBarTemplate = "ZO_StableTrainingBar_Gamepad", 
        statusBarTemplateOverrideName = "TrainBar", 
        customSpacing = 4, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,    
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.enchantDiff = { 
        customSpacing = 30, 
        childSpacing = 10, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,    
    }
    ZO_TOOLTIP_STYLES.enchantDiffAdd =  { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.enchantDiffRemove = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.enchantDiffTextureContainer = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "down", 
        paddingLeft = -35, 
        paddingTop = 3, 
        paddingRight = 3, 
        paddingBottom = -49, 
    }
    ZO_TOOLTIP_STYLES.enchantDiffTexture = { 
        width = 32, 
        height = 32 
    } 
    ZO_TOOLTIP_STYLES.topSection = { 
        layoutPrimaryDirection = "up", 
        layoutSecondaryDirection = "right", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        childSpacing = 1, 
		fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.topSubsection = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "up", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,    
        childSpacing = 8, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
    }
    ZO_TOOLTIP_STYLES.collectionsTopSection = { 
        layoutPrimaryDirection = "up", 
        layoutSecondaryDirection = "right", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        childSpacing = 1, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.topSubsectionItemDetails = { 
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "up", 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        childSpacing = 15, 
        customSpacing = -4, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        height = 32, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.flavorText = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    } 
	ZO_TOOLTIP_STYLES.prioritySellText =
    {
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,
    }
	ZO_TOOLTIP_STYLES.inactiveBonus = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.activeBonus = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.degradedStat = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.qualityTrash = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_TRASH, 
    }
    ZO_TOOLTIP_STYLES.qualityNormal = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_NORMAL, 
    }
    ZO_TOOLTIP_STYLES.qualityMagic = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_MAGIC, 
    }
    ZO_TOOLTIP_STYLES.qualityArcane = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_ARCANE, 
    }
    ZO_TOOLTIP_STYLES.qualityArtifact = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_ARTIFACT, 
    }
    ZO_TOOLTIP_STYLES.qualityLegendary = { 
        fontColorType = INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, 
        fontColorField = ITEM_QUALITY_LEGENDARY, 
    }
    ZO_TOOLTIP_STYLES.bind =  { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.stolen =  { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_RED, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }
    ZO_TOOLTIP_STYLES.bagCountSection = { 
        layoutPrimaryDirection = "down", 
        layoutSecondaryDirection = "right", 
        customSpacing = 30, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    }
    ZO_TOOLTIP_STYLES.itemTagTitle = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        uppercase = true, 
    }
    ZO_TOOLTIP_STYLES.itemTagDescription = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    }

    --Gamepad Stable Tooltip 
    ZO_TOOLTIP_STYLES.stableGamepadTooltip = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
        customSpacing = 50, 
        fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_GREY, 
        fontStyle = "soft-shadow-thick", 
    }
    ZO_TOOLTIP_STYLES.stableGamepadFlavor = { 
        customSpacing = 30, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    } 
    ZO_TOOLTIP_STYLES.stableGamepadTitle = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        customSpacing = 8, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        uppercase = false, 
    }
    ZO_TOOLTIP_STYLES.poisonCount = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.equippedPoisonSection = { 
        customSpacing = 15, 
        paddingBottom = -20, 
    }

    --Ability Tooltip 
    ZO_TOOLTIP_STYLES.abilityStatsSection = { 
        statValuePairSpacing = 10, 
        childSpacing = 3, 
        customSpacing = 20, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.abilityUpgrade = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE, 
        uppercase = true, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.newEffectTitle = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        uppercase = true, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.newEffectBody = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ABILITY_UPGRADE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.abilityProgressBar = { 
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium", 
        statusBarTemplateOverrideName = "ArrowBar", 
        customSpacing = 10, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
        statusBarGradientColors = ZO_XP_BAR_GRADIENT_COLORS, 
    }
	-- Traits, Ingredient
    ZO_TOOLTIP_STYLES.hasIngredient = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ACTIVE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.doesntHaveIngredient = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.traitKnown = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_ACTIVE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.traitUnknown = { 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 


    ZO_TOOLTIP_STYLES.keepBaseTooltipContent = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        width = KELA_TOOLTIPS_CONTENT_WIDTH - 120,
    }
    ZO_TOOLTIP_STYLES.keepUpgradeTooltipContent = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
    } 
    ZO_TOOLTIP_STYLES.gamepadElderScrollTooltipContent = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        uppercase = true, 
    }	
	
	
    -- Achievement Tooltip 
    ZO_TOOLTIP_STYLES.achievementRewardsSection = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,   
        paddingTop = 10, 
        uppercase = true, 
        childSpacing = 10, 
        layoutPrimaryDirection = "down", 
        layoutSecondaryDirection = "right", 
    }
    ZO_TOOLTIP_STYLES.achievementSummaryCategorySection = { 
        paddingBottom = 10, 
        uppercase = true, 
        layoutPrimaryDirection = "down", 
        layoutSecondaryDirection = "right", 
    } 
    ZO_TOOLTIP_STYLES.achievementCriteriaSection = { 
        paddingTop = 10, 
        paddingBottom = 7, 
        childSpacing = 7, 
        uppercase = true, 
        layoutPrimaryDirection = "down", 
        layoutSecondaryDirection = "right", 
    } 
    ZO_TOOLTIP_STYLES.achievementCriteriaBar = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH - 20,  
        statusBarTemplate = "ZO_GamepadArrowStatusBarWithBGMedium", 
        customSpacing = 4, 
        statusBarGradientColors = ZO_SKILL_XP_BAR_GRADIENT_COLORS, 
    }
    ZO_TOOLTIP_STYLES.achievementDescriptionComplete = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH - 40,  
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.achievementDescriptionIncomplete = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH - 40, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_INACTIVE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.achievementName = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH - 60, 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.achievementComplete = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.achievementIncomplete = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }


    -- Loot tooltip 
    ZO_TOOLTIP_STYLES.lootTooltip = { 
        width = 100, --295, 
        fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_GREY, 
        fontStyle = "soft-shadow-thick", 
    } 
    -- Gamepad Social Tooltip 
    ZO_TOOLTIP_STYLES.socialTitle = { 
        customSpacing = 3, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontStyle = "soft-shadow-thick", 
        fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
        fontColorField = INTERFACE_TEXT_COLOR_NORMAL, 
    }
    ZO_TOOLTIP_STYLES.socialStatsSection = { 
        statValuePairSpacing = 10, 
        childSpacing = 3, 
        customSpacing = 15, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,      
	} 
    ZO_TOOLTIP_STYLES.socialStatsValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.socialOffline = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_GREY, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    -- Gamepad Collections  
	ZO_TOOLTIP_STYLES.collectionsInfoSection = { 
        customSpacing = 25, 
        childSpacing = 25, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }

    ZO_TOOLTIP_STYLES.collectionsStatsSection = { 
        statValuePairSpacing = 10, 
        childSpacing = 20, 
        customSpacing = 20, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }

    ZO_TOOLTIP_STYLES.collectionsRestrictionsSection = { 
        statValuePairSpacing = 10, 
        childSpacing = 10, 
        customSpacing = 20, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }

    ZO_TOOLTIP_STYLES.collectionsStatsValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        customSpacing = 8, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }

    ZO_TOOLTIP_STYLES.collectionsPersonality = { 
        fontColor = ZO_PERSONALITY_EMOTES_COLOR, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }

    ZO_TOOLTIP_STYLES.collectionsEmoteGranted = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    -- Gamepad Crown Store Market 
    ZO_TOOLTIP_STYLES.instantUnlockIneligibilitySection = { 
        customSpacing = 25, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_RED, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.instantUnlockIneligibilityLine = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    } 
    -- Gamepad Keep Information 
    ZO_TOOLTIP_STYLES.keepInfoSection = { 
        paddingTop = 20, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    } 
    --Gamepad Voice Chat 
    ZO_TOOLTIP_STYLES.voiceChatBodyHeader = { 
        fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_SMALL,
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.voiceChatPairLabel = { 
        fontSize = KELA_TOOLTIPS_FONT_SMALL,
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.voiceChatPairText = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.voiceChatGamepadReputation = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_RED, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        uppercase = false, 
    }
    ZO_TOOLTIP_STYLES.voiceChatGamepadSpeaker = { 
        height = 43, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        layoutPrimaryDirection = "right", 
        childSpacing = 10, 
        customSpacing = 15,         
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,  
    }
    ZO_TOOLTIP_STYLES.voiceChatGamepadSpeakerTitle = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,  
        customSpacing = 8, 
        uppercase = false, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.voiceChatGamepadSpeakerText = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT - 10, 
    }
    ZO_TOOLTIP_STYLES.voiceChatGamepadStatValuePair = { 
        height = 40, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
    }

    ZO_TOOLTIP_STYLES.groupTitleSection = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,  
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.groupDescription = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
    }
    ZO_TOOLTIP_STYLES.groupDescriptionError = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_RED, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    ZO_TOOLTIP_STYLES.groupRolesTitleSection = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,  
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        paddingTop = 70, 
    }
    ZO_TOOLTIP_STYLES.groupRolesStatValuePairValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        uppercase = false, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
	-- Gamepad Champion Screen 
	ZO_TOOLTIP_STYLES.championTitleSection = { 
		customSpacing = 15, 
		widthPercent = 100, 
		width = 390, 
		uppercase = true, 
	} 
	ZO_TOOLTIP_STYLES.championTitle = { 
		widthPercent = 100, 
		width = 390, 
		horizontalAlignment = TEXT_ALIGN_CENTER, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
		fontFace = "$(GAMEPAD_MEDIUM_FONT)", 
	} 
	ZO_TOOLTIP_STYLES.dividerLine = { 
		textureCoordinateLeft = 0.25, 
		textureCoordinateRight = 0.75, 
		textureCoordinateTop = 0.25, 
		textureCoordinateBottom = 0.75, 
		widthPercent = 100, 
		width = 390, 
		height = 8, 
	}
	-- Comparison
    ZO_TOOLTIP_STYLES.itemComparisonStatSection = { 
        customSpacing = 25, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    } 
    ZO_TOOLTIP_STYLES.itemComparisonStatValuePair = { 
        height = 40, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    } 
    ZO_TOOLTIP_STYLES.itemComparisonStatValuePairValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        horizontalAlignment = TEXT_ALIGN_RIGHT, 
    }
    ZO_TOOLTIP_STYLES.itemComparisonStatValuePairDefaultColor = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }
    -- Dyes 
    ZO_TOOLTIP_STYLES.dyesSection = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH, 
        paddingTop = 30, 
        childSpacing = 10, 
        layoutPrimaryDirection = "down", 
        layoutSecondaryDirection = "right", 
    } 
    ZO_TOOLTIP_STYLES.dyeSwatchStyle = { 
        customSpacing = 2, 
        width = 38, 
        height = 38, 
        edgeTextureFile = "EsoUI/Art/Miscellaneous/Gamepad/gp_emptyFrame_gold_edge.dds", 
        edgeTextureWidth = 128, 
        edgeTextureHeight = 16, 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,  
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.dyeSwatchEntrySection = { 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
        layoutPrimaryDirection = "right", 
        layoutSecondaryDirection = "down", 
    } 
    ZO_TOOLTIP_STYLES.dyeStampError = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    -- Housing Tooltips 
    ZO_TOOLTIP_STYLES.defaultAccessTopSection = { 
        customSpacing = 10, 
        paddingTop = 30, 
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
    } 
    ZO_TOOLTIP_STYLES.defaultAccessTitle = { 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.defaultAccessBody = {    
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,
    } 
    --Gamepad Currency Tooltip 
    ZO_TOOLTIP_STYLES.currencyStatValuePair = { 
        height = 40, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT - 2, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    } 
    ZO_TOOLTIP_STYLES.currencyStatValuePairStat = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    } 
    ZO_TOOLTIP_STYLES.currencyStatValuePairValue = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        horizontalAlignment = TEXT_ALIGN_RIGHT, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    } 
    ZO_TOOLTIP_STYLES.requirementPass = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_SUCCEEDED,
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 		
    } 
    ZO_TOOLTIP_STYLES.requirementFail = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        fontColorField = GAMEPAD_TOOLTIP_COLOR_FAILED, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP, 
    }

	-- Kela Styles
	ZO_TOOLTIP_STYLES.kelaTrade = {
		paddingTop = 3,
		paddingBottom = 3,
		customSpacing = 5, 
		childSpacing = 5, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
		fontSize = KELA_TOOLTIPS_FONT_SMALL, 
		fontFace = "$(GAMEPAD_LIGHT_FONT)", 
		fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
		fontColorField = INTERFACE_TEXT_COLOR_NORMAL, 
		fontStyle = "soft-shadow-thick",
		uppercase = true, 
	}
	-- kela Quad1 (left collection) styles
 	ZO_TOOLTIP_STYLES.QUAD1title = { 
		fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
        customSpacing = 5,		
        uppercase = true, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_WHITE, 
        widthPercent = 100, 
	}
	ZO_TOOLTIP_STYLES.QUAD1collectionsInfoSection = { 
		customSpacing = 25, 
		childSpacing = 25, 
		widthPercent = 100, 
		fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
		fontColorField = INTERFACE_TEXT_COLOR_NORMAL,         
		fontFace = "$(GAMEPAD_LIGHT_FONT)", 
	}
	ZO_TOOLTIP_STYLES.QUAD1collectionsStatsSection = { 
		statValuePairSpacing = 10, 
		childSpacing = 20, 
		customSpacing = 20, 
		widthPercent = 100, 
		fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
		fontColorField = INTERFACE_TEXT_COLOR_NORMAL,  
	}
	ZO_TOOLTIP_STYLES.QUAD1collectionsRestrictionsSection = { 
		statValuePairSpacing = 10, 
		childSpacing = 10, 
		customSpacing = 20, 
		widthPercent = 100, 
		fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
		fontColorField = INTERFACE_TEXT_COLOR_NORMAL,  
	}
	
	-- Kela Styles InfoTooltip-------------------////////////////////////////////////////////////////////////
	
	ZO_TOOLTIP_STYLES.InfoTooltipDesc = {
		statValuePairSpacing = 20, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
		fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
		fontFace = "$(GAMEPAD_LIGHT_FONT)", 
		fontColorType = INTERFACE_COLOR_TYPE_TEXT_COLORS, 
		fontColorField = INTERFACE_TEXT_COLOR_NORMAL, 
		fontStyle = "soft-shadow-thick",
		uppercase = false, 
	}
    ZO_TOOLTIP_STYLES.InfoTooltipStatValuePair = { 
        height = 30, 
        widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
    } 
    ZO_TOOLTIP_STYLES.InfoTooltipStatValuePairValueLeftAlign = { 
        fontSize = KELA_TOOLTIPS_FONT_MEDIUM, 
		widthPercent = KELA_TOOLTIPS_CONTENT_WIDTH_PERCENT, 
		width = KELA_TOOLTIPS_CONTENT_WIDTH,
        fontFace = "$(GAMEPAD_LIGHT_FONT)", 
        horizontalAlignment = TEXT_ALIGN_LEFT, 
    }
    ZO_TOOLTIP_STYLES.InfoTooltipStatValuePairStat = { 
        fontSize = KELA_TOOLTIPS_FONT_SMALL, 
		fontFace = "$(GAMEPAD_LIGHT_FONT)",
        uppercase = false, 
        fontColorField = kpuiConst.Colors.GENERAL_COLOR_OFF_WHITE, 
		fontColorType = INTERFACE_COLOR_TYPE_GAMEPAD_TOOLTIP,
    }

end
