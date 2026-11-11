# KelaPadUI TODO

This file tracks open and deferred work. Keep it updated after each refactor phase. When an item is completed, call it out in `changelog.txt` and remove it from this list. Rated candidate enhancements and addon integrations live in the section at the end of this file.

## Open work

- Remove the seven frozen legacy XML files by porting their controls to Lua, and
  delete each entry from `XML_ALLOWLIST` in `_tools/audit_addon.py` as it goes.


## Candidate enhancements

- Add support for the Extended Journal: place in the KelaPadUI menu and in the journal menu at the end of the list.
- Additional price providers: optional Master Merchant, LibPrice or ESO-Hub adapters behind capability checks and source labels.

## Enhancement Notes

New runtime modules must be added to `KelaPadUIEnhanced.txt` and, when gated, initialized from `KelaPadUI.lua`; new settings go in `kpui_core/kpui_settings_gamepad.lua` and `docs/SETTINGS.md`; new user-facing text goes in `kpui_lang/en.lua`; optional libraries go in `OptionalDependsOn` and must be guarded.

Any candidate must preserve the current invariants: TTC and ATT stay independent optional providers; keep the five tooltip types, `QUAD1*` styles and `getStyleHeaderLine`; keep the flattened settings list and the setting-ID blocks in `docs/SETTINGS.md`; keep the KELAPADUI main-menu entry append-only; build new UI in Lua and do not add XML files (the legacy XML set is frozen and slated for removal); avoid overwriting or rewriting core base-game elements to prevent issues when the game is updated;

## Already implemented: Do not duplicate

enhanced gamepad item/trading tooltips, set browser, antiquities filters and leads, trading history and TTC/ATT price rows, companion rapport, companion Collections tooltip details (perk and description, level and XP, rapport progress and tier, equipped gear with weight and trait; skills tracked but hidden), dungeon-finder pledges and `/pledges`, chat commands/achievement links/player context menu, gamepad map rally point, main-menu quick shortcuts, the KELAPAD dashboard, PersonalAssistant permanent-junk marking, and the trait research matrix.