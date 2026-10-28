# KelaPadUI TODO

This file tracks open and deferred work. Keep it updated after each refactor phase. When an item is completed, call it out in `changelog.txt` and remove it from this list. Rated candidate enhancements and addon integrations live in the section at the end of this file.

## Open work

- [ ] Replace the custom `KPUI_*` tooltip controls/XML with supported core hooks or templates where feasible; keep copied confirmation dialogs only where C API callbacks cannot be hooked.

## Candidate enhancements (rated)

Research snapshot: October 2026. Re-check ESOUI pages and addon status after an ESO update before starting work. Use/Difficulty are the ratings from the original research (5 is best for Usefulness, 1 is lowest risk for Difficulty). Paths are relative to the add-on root. New runtime modules must be added to `KelaPadUI.txt` and, when gated, initialized from `KelaPadUI.lua`; new settings go in `kpui_core/kpui_settings_gamepad.lua` and `docs/SETTINGS.md`; new user-facing text goes in `kpui_lang/en.lua`; optional libraries go in `OptionalDependsOn` and must be guarded.

Any candidate must preserve the current invariants: TTC and ATT stay independent optional providers; keep the five tooltip types, `QUAD1*` styles and `getStyleHeaderLine`; keep the flattened settings list and retired IDs `7503` and `7100`-`7104`; keep the KELAPADUI main-menu entry append-only; do not add guild-specific purchases to Kela buying history; no lazy loading, profiling or caching work; `LibSets` stays required and `LibItemLink` optional/guarded.

Already implemented, do not duplicate: enhanced gamepad item/trading tooltips, set browser, antiquities filters and leads, trading history and TTC/ATT price rows, companion rapport, dungeon-finder pledges and `/pledges`, chat commands/achievement links/player context menu, gamepad map rally point, main-menu quick shortcuts, the KELAPAD dashboard, and PersonalAssistant permanent-junk marking.

| # | Candidate | Use | Diff | Primary files | Scope |
| --- | --- | --- | --- | --- | --- |
| 1 | Gamepad narration and accessibility | 4 | 2 | `kpui_core/kpui_tooltip_gamepad.lua/.xml`; `kpui_features/sets/`; `kpui_features/antiquities/`; `kpui_features/tradinghouse/` | Add narration text and a predictable selection order to the custom controls, reusing core narration helpers. |
| 2 | Gamepad chat and social quick actions | 4 | 2 | `kpui_features/kpui_chat_tools.lua`; `kpui_lang/en.lua` | Extend the `LibCustomMenu` player menu to gamepad lists with whisper, invite and copy-name; keep the library optional. |
| 3 | Research and trait knowledge | 5 | 3 | `kpui_features/kpui_research.lua` (new); `kpui_features/kpui_info_tooltip.lua` | Normalize an optional LibTraitResearch/Character Knowledge/TraitBuddy provider into tooltips. No Kela research database. |
| 4 | Gamepad inventory badges | 5 | 3 | `kpui_features/kpui_inventory_badges.lua` (new); `kpui_core/kpui_settings_gamepad.lua` | Post-hook the gamepad inventory row setup for junk, price, set, research, ornate and intricate badges. |
| 5 | Additional price providers | 5 | 3 | `kpui_features/tradinghouse/kpui_price_providers.lua` (new); `kpui_features/tradinghouse/*` | Add optional Master Merchant, LibPrice or ESO-Hub adapters behind capability checks and source labels. |
| 6 | Trading listing assistant | 4 | 3 | `kpui_features/tradinghouse/kpui_listing_assistant.lua` (new) | Extend the listing price/profit path with sales velocity, undercut warnings and stack suggestions. |
| 7 | Map intel panel | 4 | 3 | `kpui_features/kpui_map_intel.lua` (new); `kpui_features/kpui_main_menu_shortcuts.lua` | Read-only zone summary for surveys, treasure maps, antiquities and points of interest. |
| 8 | Build and gear quick-swap | 4 | 3 | `kpui_features/kpui_build_switcher.lua` (new) | Main-menu entry for core Armory or a supported Bandits Gear Manager callback; start read-only. |
| 9 | Crafting and writ helper | 4 | 4 | `kpui_features/kpui_crafting_helper.lua` (new) | Gamepad writ/crafting scene requirements, craftability and a turn-in checklist. No automation. |
| 10 | Guild trader kiosk intel | 4 | 4 | `kpui_features/kpui_kiosk_intel.lua` (new) | Read-only guild names and item availability at kiosks; no bid automation. |
| 11 | Group and combat integration | 4 | 4 | `kpui_features/kpui_group_combat.lua` (new) | Optional read-only ultimate-ready, role and combat-alert indicators via HodorReflexes/CrutchAlerts/CombatMetrics. |
| 12 | Companion gear and loadout | 3 | 3 | `kpui_features/kpui_companion.lua`; `kpui_features/kpui_companion_gear.lua` (new) | Extend the companion overview with gear comparison and quick-swap; keep rapport behavior. |
| 13 | Controller glyphs | 3 | 2 | `kpui_core/kpui_controller_glyphs.lua` (new); `kpui_data/kpui_controller_glyph_data.lua` (new); `kpui_core/kpui_constants.lua`; `kpui_core/kpui_settings_gamepad.lua` | Replace the two hardcoded Xbox icon paths with a resolver plus a reload-gated Xbox/PS5/Steam/Switch selection. |
| 14 | Fishing and maintenance QoL | 3 | 2 | `kpui_features/kpui_fishing_qol.lua` (new) | Optional fishing bite/reel feedback and auto-repair/auto-charge toggles. Avoid duplicating GamePadHelper. |
| 15 | Guild roster and social tools | 3 | 3 | `kpui_features/kpui_guild_roster.lua` (new); `kpui_features/kpui_chat_tools.lua` | Post-hook the gamepad guild roster for sorting and filters, then reuse the social callbacks. |
| 16 | Housing tools | 2 | 4 | `kpui_features/kpui_housing.lua` (new) | Optional housing shortcut or furnishing search, only if requested; guard any Essential Housing Tools API. |
| 17 | Localization (DE/FR/RU) | 3 | 3 | `kpui_lang/*.lua`; `KelaPadUI.txt` | Separate from glyphs: new locale files, manifest entries and translated strings. |

Controller glyphs (#13) notes: the local `PS5Buttons` add-on (`..\PS5Buttons`, author Fyro, API `101044`) is not a runtime dependency and should not become one. It contains only 249 `RedirectTexture` calls mapping core Xbox paths to core PS5 paths (240 unique), with no DDS files to copy. Add a `KELA_GLYPH_*` resolver in `kpui_core/kpui_controller_glyphs.lua` plus the Xbox-to-PS5 redirect table in `kpui_data/kpui_controller_glyph_data.lua`, use the resolver for the two `kpuiConst.stringDDS` trading-header lookups, and apply the selected family's redirect once at load with a reload-gated setting. The PS5 paths are ESOUI assets that must exist in the live client; Steam and Switch paths are not in `PS5Buttons` and need new or permission-cleared textures (do not copy unlicensed DDS). Validate the Xbox default, each family after a reload, missing-texture fallbacks, and the PS5Buttons-disabled case.
