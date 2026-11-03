# KelaPadUI TODO

This file tracks open and deferred work. Keep it updated after each refactor phase. When an item is completed, call it out in `changelog.txt` and remove it from this list. Rated candidate enhancements and addon integrations live in the section at the end of this file.

## Open work

- [ ] Replace the custom `KPUI_*` tooltip controls/XML with supported core hooks or templates where feasible; keep copied confirmation dialogs only where C API callbacks cannot be hooked.
- [x] Closed: one-off `Attempt to call a userdata value` with an empty traceback, logged at 2026-11-02 17:27:57 on first login of a character in Cyrodiil. Not reproduced by `/reloadui`, by relogging the same character, or by logging in another character; LibDebugLogger captured no entry. No cause identified; reopen only if it recurs.

## Candidate enhancements

New runtime modules must be added to `KelaPadUI.txt` and, when gated, initialized from `KelaPadUI.lua`; new settings go in `kpui_core/kpui_settings_gamepad.lua` and `docs/SETTINGS.md`; new user-facing text goes in `kpui_lang/en.lua`; optional libraries go in `OptionalDependsOn` and must be guarded.

Any candidate must preserve the current invariants: TTC and ATT stay independent optional providers; keep the five tooltip types, `QUAD1*` styles and `getStyleHeaderLine`; keep the flattened settings list and retired IDs `7503` and `7100`-`7104`; keep the KELAPADUI main-menu entry append-only; avoid xml styling in favor of dynamically initialized visual elements; avoid overwriting or rewriting core base-game elements to prevent issues when the game is updated;

- Extend the `LibCustomMenu` player menu to gamepad lists with whisper, invite and copy-name; keep the library optional.
- Reintroduce a Research and trait knowledge submenu under the kelapadui main menu entry that reads from `craftstore` and/or `libcharacterknowledge`
- Additional price providers: optional Master Merchant, LibPrice or ESO-Hub adapters behind capability checks and source labels.
- Additional Filters and sorting for gamepad menus: Achievements, Guild Roster
- Localization: new locale files, manifest entries and translated strings for DE/FR/RU. Use  `kpui_lang/*.lua`; `KelaPadUI.txt`


## Already implemented: Do not duplicate

enhanced gamepad item/trading tooltips, set browser, antiquities filters and leads, trading history and TTC/ATT price rows, companion rapport, companion Collections tooltip details (perk and description, level and XP, rapport progress and tier, equipped gear with weight and trait; skills tracked but hidden), dungeon-finder pledges and `/pledges`, chat commands/achievement links/player context menu, gamepad map rally point, main-menu quick shortcuts, the KELAPAD dashboard, and PersonalAssistant permanent-junk marking.