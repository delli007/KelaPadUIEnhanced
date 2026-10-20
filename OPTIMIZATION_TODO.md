# KelaPadUI Optimization Backlog

This file tracks deferred, higher-risk work. Keep it updated after each refactor phase.

## Completed in the initial cleanup
- [x] Removed Quick Access, old Researching, old Undaunted scene, and the broken rally-point experiment.
- [x] Removed `KelaPadUIBuyingData` and `KelaPadUIListingData`.
- [x] Split companion, dungeon-finder/pledge, chat, and trial-link code out of `KelaPadUI.lua`.
- [x] Added a gamepad group-rally-point control in the map info screen.
- [x] Trimmed dead settings/templates/sets XML controls.
- [x] Retired Russian localization text (English fallback retained in `ru.lua`).
- [x] Preserved commented debugging code and archived debug snippets from removed files.
- [x] Reorganized retained modules into `kpui_core/`, `kpui_features/`, `kpui_data/`, and `kpui_compat/`.
- [x] Made the KelaPadUI main-menu entry append-only (no re-indexing of core entries).
- [x] Removed the retired settings panels and unused settings XML/templates.
- [x] Added the gamepad map-info rally-point keybind.
- [x] Completed the static audit (manifest, Lua syntax, XML, Cyrillic, removed references).

## Trading house (deferred, higher risk)
- [ ] Replace `kpui_compat/kpui_tradinghouse_gamepad_updated.xml` with the core trading-house XML plus a small custom-control XML.
- [ ] Rebuild `KPUI_Graph`, `KPUI_PreviousListings`, `KPUI_OtherQualityInfo`, `KPUI_ProductMaterialInfo`, and `KPUI_CraftingInfo` via core hooks instead of copied core templates.
- [ ] Replace the `ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog` override with a pre/post hook.
- [ ] Audit the deprecated `quality` fields retained for add-on compatibility (`selectedData.quality`, `control.selectedItem.quality`, `itemData.quality`).
- [ ] Re-test TTC/ATT price tooltips, graphs, listings, and crafting-component rows after each ESO update.

## Tooltips and styles (deferred)
- [ ] Replace the full `ZO_TOOLTIP_STYLES` redefinition in `kpui_tooltip_styles.lua` with additive custom keys plus a minimal, documented core-override table.
- [ ] Audit `kpui_tooltip_gamepad.xml` for templates/controls that duplicate core tooltip XML; extract only the KPUI additions.
- [ ] Verify custom tooltip styles against new core styles after every game update.
- [ ] Review the `ZO_CRAFTING_TOOLTIP_STYLES` copy/override and move it to a custom style namespace if possible.

## Sets
- [ ] Replace hardcoded `SetsCrafting`/`SetsOverland`/`SetsDungeon`/`SetsMonster` metadata with LibSets APIs where practical.
- [ ] Remove set entries that are obsolete or superseded; update new DLC sets.
- [ ] Add a build-time validation check comparing hardcoded set IDs with LibSets.

## Main menu
- [ ] Use a supported ZOS menu-extension API if one is added; the current approach appends to `ZO_MENU_ENTRIES`.
- [ ] Revisit the KelaPadUI entry position now that it is append-only.
- [ ] Consider moving the custom settings entry into the core Options menu instead of a duplicate Settings submenu.

## Crafting panel
- [ ] Decide whether `kpui_features/kpui_crafting_panel_tips.lua` should be wired into the manifest. It is currently unloaded (as before the refactor); do not enable it until its hooks, tooltip interactions, and missing `KELA_STAT_GAMEPAD_CRAFTING_PANEL_*` strings are addressed. Load it after `KelaPadUI.lua` if it is enabled, because it writes to the `KelaPadUI` table at file scope.

## XML
- [ ] Audit the remaining virtual templates and remove unused ones.
- [ ] Consolidate small XML files only if it reduces maintenance; do not convert controls to Lua blindly.
- [ ] Keep `kpui_sets_list_gamepad.xml`, the custom tooltip XML, and the trading-house compatibility XML until their replacements are tested.

## Performance
- [ ] Profile add-on load time and tooltip/trading-house hook overhead.
- [ ] Cache frequently used strings and globals in hot paths.
- [ ] Consider lazy-loading optional features (sets/trading house) if load time becomes an issue.
- [ ] Remove any remaining per-frame scans or unnecessary deep table copies.

## Constants and helper functions
- [ ] Audit `kpuiConst` tables and remove data used only by the retired Researching/Quick Access modules.
- [ ] Convert genuinely internal `kpui_utils.lua` helpers to locals after confirming no cross-file callers (keep `getTraitHeaderLine`, `KelaGetAvailableResearchLines`, and other tooltip-facing helpers global until then).
- [ ] Review the `KELA_RESEARCH_COMPAT` read-only shim; remove it if the tooltip research section is retired or re-implemented with core APIs.

## API / dependencies
- [ ] Verify and update `## APIVersion` for the current live client.
- [ ] Re-check `LibSets` API compatibility and required version.
- [ ] Remove obsolete compatibility shims after game updates.
- [ ] Keep `LibCustomMenu` optional; do not make optional integrations hard dependencies.

## Localization / comments
- [ ] Keep English as the single source of strings; `ru.lua` is an English no-op.
- [ ] Remove any newly unused `KELA_*` strings.
- [ ] Preserve commented debug statements; add new debug notes to `DEBUG_NOTES.md` only when code is removed.
