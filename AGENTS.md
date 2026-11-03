# AGENTS.md

KelaPadUI is an Elder Scrolls Online gamepad-UI add-on (Lua 5.1 + XML). This
folder is the live installed add-on; ESO loads it directly. There is no build,
package manager, test runner, or CI, so edit files in place.

## Verification

- Run the static audit after every change:

  ```powershell
  python _tools\audit_addon.py
  ```

  It checks manifest files, Lua syntax, XML, KELA string coverage, retired
  references, TODO markers, `SI_*` assignments, optional dependencies, virtual
  templates, LibSets API compatibility, and forbidden dialog hooks. It prints
  `AUDIT PASSED` only when no hard errors remain; undefined or unused KELA IDs
  are reported separately.
- The audit's Lua check uses `lua53.exe` from the sibling
  `ArkadiusTradeTools\ArkadiusTradeToolsExports` folder. If that file is
  missing, the audit reports failure instead of skipping the check.
- For a quick single-file parse check:

  ```powershell
  npx.cmd --yes luaparse path\to\file.lua
  ```

- There is no automated in-game test. Run `/reloadui`, then exercise the
  affected feature. The manual checklist is in `docs/MAINTENANCE.md`.

## Load order and wiring

- `KelaPadUI.txt` is the load order. Add every new Lua/XML file there.
  `KelaPadUI.lua` stays last; it initializes settings and gated features on
  `EVENT_ADD_ON_LOADED`.
- `kpui_core/` holds shared settings, constants, utilities, and tooltip code.
  `kpui_features/` holds feature modules; `kpui_features/tradinghouse/` is a
  load-ordered split (history, shared, hooks, tooltips, data, controls).
- Static data belongs in `kpui_data/`, not in feature modules.
- Prefer registering hooks and scene callbacks in `KelaSetup*()` functions;
  file-scope registration depends on manifest order.
- Startup is eager. Do not reintroduce lazy loading for sets or trading history.

## Adding a feature or setting

- A gated load-time feature needs a setting ID/default in
  `kpui_core/kpui_settings_gamepad.lua`, a `KELA_*` string in
  `kpui_lang/en.lua`, settings metadata/order, and a gated `KelaSetup*()` call in
  `KelaPadUI.lua`. See `docs/SETTINGS.md`.
- Most feature toggles are reload-gated; the PS5 button map is the exception.
- Never reuse retired setting IDs `7503` or `7100`-`7104`.
- Read/write settings through `KelaGetSetting_*` / `KelaSetSetting`; do not
  write `kpuiSavedVariables` directly.
- User-facing text must use `KELA_*` IDs in `kpui_lang/en.lua` (English only,
  UTF-8 without BOM; Cyrillic text fails the audit). The audit reports undefined
  or unused KELA IDs.
- Keep the KELAPADUI main-menu entry append-only; do not reindex
  `ZO_MENU_ENTRIES`.

## Hooks and core safety

- Use `SecurePostHook` for core functions; ESO has no `SecurePreHook`.
  `ZO_PreHook` / `ZO_PostHook` are only for add-on-owned or pure data/UI
  functions.
- Never hook `ZO_Dialogs_ShowDialog`, `ZO_Dialogs_ShowGamepadDialog`,
  `ZO_Dialogs_ShowPlatformDialog`, `ZO_Dialogs_ButtonKeybindPressed`, or
  `ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog`. It poisons the
  shared gamepad dialog keybind pool for the rest of the session, and the audit
  fails on these hooks. Use a dialog-owned `setup` function or an add-on scene.
- Do not leave `TODO` / `FIXME` / `HACK` / `XXX` markers in Lua/XML; record
  deferred work in `TODO.md`.
- Do not assign `SI_*` globals directly; use `SafeAddString`.

## Compatibility invariants

- Target API `101051`; `LibSets` is required.
- Gamepad UI only; features are read-only information or UI shortcuts, not
  gameplay automation.
- TTC and ATT are independent optional providers. TTC-only, ATT-only, both, and
  neither must all work.
- Guard optional libraries and add-ons (`LibItemLink`, `LibCustomMenu`, `USPF`,
  `LibDebugLogger`, PersonalAssistant).
- Preserve the five tooltip types, `QUAD1*` styles, `getStyleHeaderLine`, the
  `ZO_CRAFTING_TOOLTIP_STYLES` copy, the flattened settings list, and the
  append-only KELAPADUI entry.
- Update `changelog.txt` (newest first) and affected docs for user-facing
  changes.

## Read next

- `docs/DEVELOPMENT_NOTES.md` - conventions, pitfalls, and the "never do this"
  list.
- `docs/MAINTENANCE.md` - architecture, validation workflow, and in-game checks.
- `docs/SETTINGS.md` - setting IDs and the add-a-setting procedure.
- `docs/TRADING_HOUSE.md` - trading modules and test notes.
- `TODO.md` - open work and rated candidates.
