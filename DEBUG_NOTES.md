# Preserved Commented Debug Code

These commented debug statements came from files removed during the refactor. They are kept here for future troubleshooting. The complete original files are also in `AddOns/KelaPadUI-backup-refactor-2026-10-18.zip` outside the add-on.

## KelaPadUIBuyingData/KelaPadUIBuyingData.lua
```lua
-- line 68
-- CHAT_SYSTEM:AddMessage(tostring(KELA_ITEMDATA_WITH_COUNTCHANGE["itemName"])..tostring(data["itemName"]))
```

## KelaPadUIListingData/KelaPadUIListingData.lua
```lua
-- line 405
-- CHAT_SYSTEM:AddMessage("DONE KelaSetupATTFunctions")
```

## _broken_not_needed/kpui_achievements.lua
```lua
-- line 11
-- CHAT_SYSTEM:AddMessage("OnShowing")
-- line 15
-- CHAT_SYSTEM:AddMessage("PerformUpdate")
-- line 19
-- CHAT_SYSTEM:AddMessage("PopulateAchievements")
-- line 32
-- CHAT_SYSTEM:AddMessage("showing")
-- line 52
-- CHAT_SYSTEM:AddMessage("PopulateCategories")
-- line 145
-- CHAT_SYSTEM:AddMessage(tostring(chainId))
```

## _broken_not_needed/kpui_achievements_gamepad.lua
```lua
-- line 930
-- CHAT_SYSTEM:AddMessage(tostring(chainId))
```

## _broken_not_needed/kpui_tradinghouse_gamepad.lua
```lua
-- line 89
-- CHAT_SYSTEM:AddMessage(GetString("SI_ITEMTYPE", itemType))
-- line 698
-- CHAT_SYSTEM:AddMessage("itemUniqueId  "..tostring(itemUniqueId))
-- line 962
-- CHAT_SYSTEM:AddMessage(tostring(selectedData.itemUniqueId).." / "..tostring(selectedData.purchasePrice))
-- line 1235
-- CHAT_SYSTEM:AddMessage(tostring(strClearProfit).." / "..tostring(buyPrice))
```

## KelaPadUI.lua (old info-tooltip/pledge code)
```lua
-- old info-tooltip code, line 317
-- CHAT_SYSTEM:AddMessage(GetString(KELA_SETSKEY_CLEARSEARCH))

-- old pledge display, lines 850/852/866
-- CHAT_SYSTEM:AddMessage("\n|cFFD700Active Pledges|r")
-- CHAT_SYSTEM:AddMessage("|cAAAAAA  " .. tostring(key) .. " " .. tostring(value))
-- CHAT_SYSTEM:AddMessage("|cAAAAAA  " .. tostring(key) .. " " .. tostring(value))

-- old dungeon-finder debug, lines 915/918/921/924/930/933/936/937
-- CHAT_SYSTEM:AddMessage("post hook on refreshSingularSectionPanel")
-- CHAT_SYSTEM:AddMessage("passed navigation mode: mode: "..self.navigationMode)
-- CHAT_SYSTEM:AddMessage("has currentlist")
-- CHAT_SYSTEM:AddMessage("has targetdata")
-- CHAT_SYSTEM:AddMessage('Triggered attempt to modify dungeon description')
-- CHAT_SYSTEM:AddMessage("Activity Type: " .. entryData.activityType)
-- CHAT_SYSTEM:AddMessage(tprint(targetData))
-- CHAT_SYSTEM:AddMessage(tprint(entryData))

-- old context-menu debug, line 1124
-- CHAT_SYSTEM:AddMessage("Found libCustomMenu")
```

## Old rally-point experiment
```lua
-- active debug line from the old AddGamepadRallyPoint experiment
-- CHAT_SYSTEM:AddMessage("Initializing Group Rally Point Map Option")
```

Note: active debug output in retained code is intentionally left in place where it is still useful; this file only records debug statements from removed code.
