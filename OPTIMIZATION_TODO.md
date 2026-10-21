# KelaPadUI Optimization Backlog

This file tracks deferred, higher-risk work. Keep it updated after each refactor phase.

## Completed in the dead-code cleanup
- [x] Removed the four unused hardcoded set tables and dead Researching/Quick Access constants.
- [x] Removed dead `kpui_utils.lua` helpers and fixed accidental globals.
- [x] Pruned unused custom tooltip types, methods, XML controls/templates, and status-label UI; kept the five active tooltip types.
- [x] Removed 65 unused or core-identical tooltip styles and the commented style archive; kept active overrides.
- [x] Removed dead settings callbacks, the unused `GetATTPriceAndStatus` helper, and commented-out implementations.
- [x] Removed the empty `ru.lua`, the stale implementation/debug archives, and the commented-code archive.
- [x] Re-ran the audit with zero undefined or unused KELA strings.
- [x] Added audit checks for TODO/FIXME markers and unused virtual templates.

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
- [x] Retired Russian localization text; English is the single source of strings.
- [x] Removed preserved commented code and the debug archive during the dead-code cleanup.
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
- [ ] Verify the five active custom tooltip types and their remaining styles against new core styles after every game update.
- [ ] Review the `ZO_CRAFTING_TOOLTIP_STYLES` copy/override and move it to a custom style namespace if possible.

## Sets
- [ ] Validate LibSets metadata and set-browser entries after set/DLC updates.
- [ ] Add a build-time validation check comparing the sets browser's LibSets assumptions with the installed LibSets version.

## Main menu
- [ ] Use a supported ZOS menu-extension API if one is added; the current approach appends to `ZO_MENU_ENTRIES`.
- [ ] Revisit the KelaPadUI entry position now that it is append-only.
- [ ] Consider moving the custom settings entry into the core Options menu instead of a duplicate Settings submenu.

## XML
- [x] Audit the remaining virtual templates; all 27 are referenced.
- [ ] Consolidate small XML files only if it reduces maintenance; do not convert controls to Lua blindly.
- [ ] Keep `kpui_sets_list_gamepad.xml`, the custom tooltip XML, and the trading-house compatibility XML until their replacements are tested.

## Performance
- [ ] Profile add-on load time and tooltip/trading-house hook overhead.
- [ ] Cache frequently used strings and globals in hot paths.
- [ ] Consider lazy-loading optional features (sets/trading house) if load time becomes an issue.
- [x] Remove any remaining per-frame scans; no `OnUpdate`/`RegisterForUpdate` handlers remain.

## Constants and helper functions
- [ ] Re-audit `kpuiConst` after future feature changes and remove data that loses its last caller.
- [ ] Convert genuinely internal `kpui_utils.lua` helpers to locals after confirming no cross-file callers; keep tooltip-facing helpers global until then.
- [ ] Review the `KELA_RESEARCH_COMPAT` read-only shim; remove it if the tooltip research section is retired or re-implemented with core APIs.

## Settings UI
- [ ] Design disabled-state colors for gamepad sliders.
- [ ] If sliders or horizontal lists gain dependent controls, call `RefreshVisible` when their values change.

## API / dependencies
- [x] Verify and update `## APIVersion` for the current live client (`101051`).
- [x] Re-check `LibSets` API compatibility and required version (`0.9.4`, API `101051`/`101052`).
- [ ] Remove obsolete compatibility shims after game updates.
- [ ] Keep `LibCustomMenu` optional; do not make optional integrations hard dependencies.

## Localization / comments
- [ ] Keep English as the single source of strings in `kpui_lang/en.lua`.
- [ ] Remove any newly unused `KELA_*` strings.
- [ ] Remove commented-out implementations instead of preserving them; document only non-obvious decisions in comments.
