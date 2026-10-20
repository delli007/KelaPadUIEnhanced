# KelaPadUI Refactor — Implementation Plan

## Overview

Clean up and reorganize KelaPadUI without changing the working gamepad features. The work is split into safe phases: remove dead/unreachable features, separate feature code from `KelaPadUI.lua`, translate all Russian text/comments to English while keeping `ru.lua`, preserve commented debugging code, trim dead XML, add the missing gamepad group-rally-point control, and document deferred trading-house/tooltip optimization work.

## Scope Decisions

- Remove: Quick Access, old Researching module/UI, old broken Undaunted scene/UI/settings, old rally-point experiment, `KelaPadUIBuyingData`, `KelaPadUIListingData`, `_broken_not_needed`, `kpuiMainMenu_original.lua.old`.
- Keep: working pledge/dungeon-finder additions (`GetGoalPledges`, `show_pledges`, `/pledges`, activity-finder enhancements), sets browser, trading house hooks, custom tooltips, settings, main info tooltip, crafting tips, companion info, chat tools.
- Keep `kpui_lang/ru.lua` in the manifest, but make it an English no-op; `en.lua` is the single source of strings.
- Translate every remaining Cyrillic comment/string to English in retained files.
- Preserve all commented debugging code. Extract debug snippets from deleted files into `DEBUG_NOTES.md`.
- Cautious phase: keep the copied trading-house/tooltip XML and Lua in place (moved to `kpui_compat/` for trading house); defer their reconstruction and the `ZO_TOOLTIP_STYLES` rewrite to `OPTIMIZATION_TODO.md`.
- `kpui_features/kpui_crafting_panel_tips.lua` is retained but remains unloaded, matching its pre-refactor state; see `OPTIMIZATION_TODO.md`.
- Add a gamepad map-info rally-point button (Quaternary) that sets/removes the group rally point at the map cursor.

## Types / Data Structures

- `KELA_TRIALS_DATA` (new `kpui_data/kpui_trials_data.lua`): moved `TRIALS`/`ARENAS` achievement and portal data.
- Pledge/dungeon data remains in `kpui_features/kpui_dungeon_finder.lua` initially.
- `kpuiConst` remains in `kpui_core/kpui_constants.lua`; remove `kpuiConst.test`, dead research tables, and unused globals after reference audit.
- Retained `KELA_SETTING_*` IDs are never renumbered; settings version stays `0.52`.
- `KELA_ANTIQUITY_LEAD_SOURCES` / `KELA_ANTIQUITY_LEAD_SOURCE_OVERRIDES` stay in the combined antiquity leads file.

## Target Files

New:
- `kpui_features/kpui_companion.lua`
- `kpui_features/kpui_dungeon_finder.lua`
- `kpui_features/kpui_chat_tools.lua`
- `kpui_features/kpui_map_rally.lua`
- `kpui_features/kpui_main_menu.lua`
- `kpui_features/kpui_info_tooltip.lua`
- `kpui_features/kpui_crafting_panel_tips.lua`
- `kpui_data/kpui_trials_data.lua`
- `kpui_features/sets/kpui_sets_gamepad.lua`, `.xml`, `kpui_sets_list_gamepad.xml`
- `kpui_features/antiquities/kpui_antiquityfilters_gamepad.lua`
- `kpui_features/antiquities/kpui_antiquityleads_gamepad.lua`
- `kpui_compat/kpui_tradinghouse_gamepad_updated.lua`, `.xml`
- `DEBUG_NOTES.md` (preserved commented debug snippets)
- `OPTIMIZATION_TODO.md`
- `_tools/audit_addon.py`

Modified:
- `KelaPadUI.txt` — new load order, dependencies, no dead manifest entries.
- `KelaPadUI.lua` — initialization/orchestration only.
- `kpui_core/kpui_settings_gamepad.lua` / `.xml` — remove Quick Access/Research/Undaunted/UPU; trim unused settings XML.
- `kpui_core/kpui_templates.xml` — keep only used templates.
- `kpui_core/kpui_sets_gamepad.xml` — remove unused `Kela_GamepadItemSubEntryTemplate`.
- `kpui_lang/en.lua` / `ru.lua` — remove dead strings; `ru.lua` becomes English no-op.
- `changelog.txt` — refactor entry and ongoing history.
- `_tools/generate_antiquity_lead_data.py` — new target path.

Deleted:
- `_broken_not_needed/`
- `kpuiMainMenu_original.lua.old`
- `KelaPadUIBuyingData/`
- `KelaPadUIListingData/`
- `kpui_textures/` (after reference check)
- `kpui_core/kpuiEntryicon.xml`
- `kpui_core/kpui_quickaccess_gamepad.lua`, `.xml`
- Dead code blocks/functions in `KelaPadUI.lua`; dead XML controls/templates/strings.

## Functions

New:
- `KelaSetupCompanionInfo`, `KelaSetupDungeonFinder`, `KelaSetupChatTools`, `KelaSetupMapRally`, `KelaSetupMainMenu`, `KelaSetupInfoTooltip`, `KelaSetupCraftingPanelTips`, `KelaSetupTooltips`.
- `KelaMapRally_GetCursorNormalizedPosition` using `ZO_WorldMapScroll:GetCenter()` + `NormalizePointToControl(..., ZO_WorldMapContainer)`.
- `KelaMapRally_IsAtRallyPoint`, `KelaMapRally_Toggle` (`PingMap(MAP_PIN_TYPE_RALLY_POINT, ...)` / `RemoveRallyPoint()`), `KelaMapRally_IsVisible` (`IsUnitGrouped` + `IsUnitGroupLeader`), `KelaMapRally_ShowKeybind` / `HideKeybind`.

Modified:
- `KelaPadUI_OnLoaded` — calls feature setup functions; no dead feature references.
- `setupTooltips` → `KelaSetupTooltips`; remove dead `kelaAddInfoTooltip` call.
- `KelaInitializeSettings` — remove dead feature settings/panels.
- `kpuiMainMenu.lua` — append the KelaPadUI entry instead of inserting at index 14/re-IDing; remove Researching/Undaunted submenu entries.

Removed:
- `kelaAddInfoTooltip` (dead no-op).
- `AddGamepadRallyPoint` (broken; replaced).
- Old Quick Access / Research / Undaunted classes and initialization functions.
- Custom functions moved to feature files.
- Unused research helpers/data after reference audit.
- Active dead code, while preserving commented debug lines and archiving non-debug commented blocks.

## Classes

- Remove `Kela_QuickAccess` and `Kela_Undaunted`.
- Keep `Kela_Sets`, `Kela_GamepadOptions`, and custom tooltip classes.
- No new classes; map rally is hook-based.

## Dependencies

- `DependsOn: LibSets`.
- Remove `LibItemLink` and `UndauntedPledgesUtilities` after reference audit.
- `OptionalDependsOn: TamrielTradeCentre ArkadiusTradeTools LibCustomMenu`.
- Remove sub-add-on folders.
- Keep current `APIVersion` for now; TODO to verify/update.

## Localization and Debug Policy

- Replace all Russian comments/strings in retained files with English.
- `kpui_lang/ru.lua` stays but is an English no-op:
  `-- Russian localization retired; English strings come from en.lua.`
- Preserve commented debug code: `--CHAT_SYSTEM`, `--print`, `--d`, `--trace`, `--debug`, etc.
- Before deleting files/features, extract their commented debug lines into `DEBUG_NOTES.md`.
- Move large non-debug commented blocks to `docs/commented_code_archive.md` only if they obstruct cleanup.
- `_tools/audit_addon.py` checks: zero Cyrillic in retained files, `ru.lua` exists and is English-only, debug-comment count preserved, manifest/XML/Lua validity.

## Testing

Static per phase:
- `lua53.exe` `loadfile` for every Lua file.
- Python XML parse for every XML file.
- `_tools/audit_addon.py` for manifest, removed identifiers, Cyrillic, debug comments, unused/undefined `KELA_*` strings.
- Grep for deleted references (`KELA_RESEARCH`, `KELA_UNDAUNTED`, `KELA_QUICKACCESS`, `AddGamepadRallyPoint`, `kelaAddInfoTooltip`, `kpui_textures`, sub-add-on names).

In-game per phase (user-run):
1. Add-on loads with no Lua errors; main menu entry works.
2. Sets/settings comparison, tooltips, trading house, companion, dungeon finder/pledges, chat commands.
3. Rally point: group leader sets/removes at cursor; solo/member hidden; maps/floors/cosmic map.
4. Settings persist after `/reloadui`; removed panels are gone.
5. Russian client displays English text.

## Implementation Order

1. Baseline backup, `implementation_plan.md`, `OPTIMIZATION_TODO.md`, changelog entry, audit script.
2. Localization/comment preservation: translate Cyrillic; convert `ru.lua` to English no-op; extract debug snippets from doomed files.
3. Remove dead features/files/sub-add-ons/XML; trim settings/templates/sets XML; remove dependencies and dead manifest entries.
4. Split custom additions out of `KelaPadUI.lua`; create feature/data modules; move/rename retained modules into folders.
5. Cautious core cleanup: append-only main-menu entry; keep tooltip/tradinghouse compatibility files and add TODO items.
6. Add gamepad map rally-point feature.
7. Constants/functions/settings/strings cleanup; final XML trim.
8. Final audit, changelog, TODO, hand-off for in-game testing.

## Deferred Optimization Backlog

See `OPTIMIZATION_TODO.md` for trading-house XML/function replacement, tooltip template/style extraction, LibSets metadata use, main-menu API, XML consolidation, performance, and APIVersion work.
