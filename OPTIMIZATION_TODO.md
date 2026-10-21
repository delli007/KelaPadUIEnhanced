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
- [x] Consolidated 121 tooltip style overrides so they now change only differing properties and inherit the rest from core.

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
- [x] Aligned the copied buy/sell/remove confirmation dialogs with current core and removed the obsolete sell API argument.
- [x] Fixed remaining accidental globals in trading-tooltip and sets code; removed stale commented assignments.
- [x] Pruned unused `kpuiConst` fields with no remaining callers.
- [x] Removed the optional `LibCustomMenu` absence warning and localized the trading known-item filter label.
- [x] Guarded ATT tooltip-extension access with a one-day fallback when the optional extension is absent.
- [x] Guarded optional MasterMerchant tooltip data access.
- [x] Replaced the direct `SI_ITEM_FORMAT_STR_SET_NAME` assignment with a `SafeAddString` override; verify set-name tooltips in game.
- [x] Added an audit check that rejects direct assignments to `SI_*` constants.

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
- [x] Reviewed the trading-house XML: the `KPUI_*` templates are bespoke tooltip controls, not copied core XML; `KPUI_Graph` now creates an ATT graph child at runtime only when ATT is available.
- [x] Made TTC and ATT independent: either provider can enable trading, missing-provider tooltip values show `N/A`, ATT-only graph/guild sections are skipped without ATT, and the trading XML no longer inherits an ATT template at load time.
- [x] Reviewed the graph/list/quality/production/crafting controls: they are custom layouts, so replacing them with core hooks would add risk without removing duplicated core code.
- [x] Replaced the `ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog` override with pre/post hooks; core text and narration now stay intact.
- [x] Audited the deprecated `quality` fields; retained because core and third-party data still expose `quality`/`displayQuality` variants.
- [x] Audited the copied confirmation dialogs against current core; retained core-owned narration/display handling and left guild-specific-item/display-error dialogs core-owned.
- [x] Closed as out of scope: guild-specific-store purchases are not added to Kela buying history, and the core guild-specific dialog remains untouched.
- [ ] Re-test TTC-only, ATT-only, and combined price tooltips, graphs, listings, and crafting-component rows after each ESO update.

## Tooltips and styles
- [x] Replaced the full `ZO_TOOLTIP_STYLES` copies with `KelaOverrideTooltipStyle`, which applies only differing properties and preserves four intentional omissions.
- [ ] Verify the five active custom tooltip types and their remaining styles against new core styles after every game update.
- [ ] Verify the shortened set-name format in item tooltips after the `SafeAddString` change.
- [x] Reviewed the `ZO_CRAFTING_TOOLTIP_STYLES` copy; core's crafting consumer reads that global directly, so the copy is required and now documented.

## Sets
- [ ] Validate LibSets metadata and set-browser entries after set/DLC updates.
- [x] Added an audit check for the sets browser's LibSets API calls and API-version compatibility against the sibling LibSets add-on.

## Main menu
- [ ] Use a supported ZOS menu-extension API if one is added; the current approach appends to `ZO_MENU_ENTRIES`.
- [x] Revisited the KelaPadUI entry position: append-only is required because API `101051` has no supported menu-extension hook.
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
- [x] Re-audited `kpuiConst` and pruned fields with no remaining callers; re-check after future feature changes.
- [x] Converted the internal `KelaGetLocalTimeShift` helper to a local; remaining helpers have cross-file callers.
- [x] Reviewed the `KELA_RESEARCH_COMPAT` shim; retained as a read-only compatibility layer because no current writer populates its research data.

## Settings UI
- [x] Disabled sliders already follow core's `ZO_GamepadMenuEntryTemplate_GetLabelColor` path; no separate palette is needed.
- [x] Reviewed `RefreshVisible`: no configured sliders or horizontal lists currently have dependent controls; apply it when such a dependency is added.

## API / dependencies
- [x] Verify and update `## APIVersion` for the current live client (`101051`).
- [x] Re-check `LibSets` API compatibility and required version (`0.9.4`, API `101051`/`101052`).
- [ ] Remove obsolete compatibility shims after game updates.
- [x] Kept `LibCustomMenu` optional and removed the absence warning from the player-activation path.

## Localization / comments
- [x] Keep English as the single source of strings in `kpui_lang/en.lua`; the audit enforces zero undefined or unused KELA strings.
- [x] Removed the remaining stale commented-out assignments; keep explanatory comments only.
