# KelaPadUI Optimization Backlog

This file tracks deferred, higher-risk work. Keep it updated after each refactor phase.

## Completed in the current maintenance pass
- [x] Fixed settings navigation and removed obsolete support/donation/message settings.
- [x] Added selected-setting information, defaults, apply behavior, and requirement text.
- [x] Added the Features category and six reload-gated feature toggles.
- [x] Flattened all settings categories into one list with category headings; removed the category submenu and panel scene.
- [x] Restored buying/listing history, retention cleanup, guild statistics, category mapping, and history icons.
- [x] Centralized the ATT analysis-period default and clamped it to 1-30 days.
- [x] Fixed the recursive trading-house setup retry and the listing-retention deletion bug.
- [x] Cleaned chat-tool command/context-menu registration and guarded missing research data.
- [x] Removed the dead `kpui_features/kpui_crafting_panel_tips.lua` file.
- [x] Removed the nonfunctional one-page trading search setting (`7503`) and its hooks.
- [x] Fixed the known-item filter for combination-fragment collectibles in trading results.
- [x] Fixed the gamepad map rally keybind's cosmic-map check, moved it to QUINARY, and exposed it on the main map.
- [x] Branded the KELAPADUI main-menu entry with a champion icon and purple text/icon tint.
- [x] Removed the retired pause-menu travel-notes feature; documented restoration notes.
- [x] Added `docs/MAINTENANCE.md`, `docs/SETTINGS.md`, and `docs/TRADING_HOUSE.md`.
- [x] Removed 47 dead KELA localization strings and tightened the audit's dynamic/unused detection.

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
