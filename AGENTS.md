# AGENTS.md

KelaPadUI Enhanced (folder and manifest `KelaPadUIEnhanced`) is an Elder Scrolls
Online gamepad-UI add-on (Lua 5.1, with frozen legacy XML templates). This folder
is the live installed add-on; ESO loads it directly, so edit files in place.
There is no package manager or test runner. A static audit and a packaging script
live in `_tools/`, and GitHub Actions runs both (see `docs/RELEASING.md`).

## Add-on identity

- The identity is three strings that must stay identical: the folder name, the
  manifest filename, and `KelaPadUI.name`. `_tools/audit_addon.py` derives
  `ADDON_NAME` and fails when the folder, manifest, `name` field, or an
  `EVENT_MANAGER` namespace disagrees.
- Add-on managers (Minion, ESOUI) match an installed add-on by folder name plus
  manifest filename. Changing either one makes the add-on look new to them, so
  every rename needs a changelog note telling users to delete the old folder.
- Never rename it back to `KelaPadUI`. That folder is the abandoned original;
  both add-ons define the `KelaPadUI` global and write `kpuiSavedVariables`, so
  loading both corrupts settings. `KelaPadUI.lua` refuses to initialize while
  the original is loaded and shows a gamepad dialog instead.
- `kpuiSavedVariables` must not be renamed: it is what preserves settings and
  trading history across upgrades. Do not declare the retired
  `kpuiSavedVariablesBuyingData` / `kpuiSavedVariablesListingData` again.

## Verification

- Run the static audit after every change:

  ```powershell
  python _tools\audit_addon.py
  ```

  It checks manifest files, add-on identity, Lua syntax, XML, KELA string
  coverage, retired references, TODO markers, `SI_*` assignments, setting ID
  allocation, version consistency, encoding damage, broken quoted `GetString`
  calls, optional dependencies, virtual templates, LibSets API compatibility,
  and forbidden dialog hooks. It prints `AUDIT PASSED` only when no hard errors
  remain; undefined or unused KELA IDs are reported separately.
- The audit's Lua check looks for `LUA53` in the environment first, then
  `lua53.exe` from the sibling `ArkadiusTradeTools\ArkadiusTradeToolsExports`
  folder, then `lua5.3` on `PATH` (which is what CI installs). If none is found,
  the audit reports failure instead of skipping the check.
- For a quick single-file parse check:

  ```powershell
  npx.cmd --yes luaparse path\to\file.lua
  ```

- There is no automated in-game test. Run `/reloadui`, then exercise the
  affected feature. The manual checklist is in `docs/MAINTENANCE.md`.

## Load order and wiring

- `KelaPadUIEnhanced.txt` is the load order. Add every new Lua/XML file there.
  `KelaPadUI.lua` stays last; it initializes settings and gated features on
  `EVENT_ADD_ON_LOADED`.
- `kpui_core/` holds shared settings, constants, utilities, and tooltip code.
  `kpui_features/` holds feature modules. Group multi-file features in their own
  subfolders; keep single-file features at the feature root. The trading-house
  split is load-ordered (history, shared, hooks, tooltips, data, controls).
- Static data belongs in `kpui_data/`, not in feature modules.
- Prefer registering hooks and scene callbacks in `KelaSetup*()` functions;
  file-scope registration depends on manifest order.
- Startup is eager. Do not reintroduce lazy loading for sets or trading history.

## UI construction: Lua first, XML frozen

- Do not add XML files or XML-defined controls. Build UI in Lua from a
  `KelaSetup*()` function with `WINDOW_MANAGER:CreateControl`, `CreateControl`,
  `CreateControlFromVirtual` for core templates, `ZO_ObjectPool` for reusable
  rows, and `kpuiConst.TextStyles` for text.
- The seven XML files in the audit's `XML_ALLOWLIST` are frozen legacy. Edit one
  only for a fix that cannot be expressed in Lua. A new reusable virtual
  template belongs in `kpui_core/kpui_templates.xml` and is the only allowed
  XML addition; the audit fails on any other XML file.
- XML is parsed before Lua and always loads, so a settings-gated feature still
  creates its controls and global names when disabled. Lua setup can be gated,
  and its failures surface as Lua errors instead of a client log line.

## Adding a feature or setting

- A gated load-time feature needs a setting ID/default in
  `kpui_core/kpui_settings_gamepad.lua`, a `KELA_*` string in
  `kpui_lang/en.lua`, settings metadata/order, and a gated `KelaSetup*()` call in
  `KelaPadUI.lua`. See `docs/SETTINGS.md`.
- Most feature toggles are reload-gated; the PS5 button map is the exception.
- Setting IDs are private to `SETTING_TYPE_KELA` (`7000`). Allocate from the
  blocks in `docs/SETTINGS.md`; the audit rejects IDs outside the Kela block,
  duplicates, orphaned IDs, and any ID listed in `KELA_RETIRED_SETTING_IDS`.
  Never reuse a number that has shipped; add it to that table instead.
- Read/write settings through `KelaGetSetting_*` / `KelaSetSetting`; do not
  write `kpuiSavedVariables` directly.
- User-facing text must use `KELA_*` IDs in `kpui_lang/en.lua`. That file is the
  English source and must stay UTF-8 without BOM; localized files
  (`kpui_lang/de.lua`, `fr.lua`, `ru.lua`, loaded through
  `kpui_lang/$(language).lua`) may use non-Latin scripts such as Cyrillic. Read
  strings with the numeric constant, `GetString(KELA_FOO)`; a quoted name
  (`GetString("KELA_FOO")`) silently returns nothing. See
  `docs/DEVELOPMENT_NOTES.md`. The audit reports undefined or unused KELA IDs.
- Keep the KELAPADUI main-menu entry directly below Options; do not reindex
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
- Never hook a keybind dispatcher (`ZO_KeybindStrip_HandleKeybindDown`,
  `ZO_KeybindStrip_HandleKeybindUp`, `ZO_KeybindStrip:TryHandlingKeybindDown`)
  either. A secure post-hook runs the dispatcher's original body inside the
  engine's `PostHookFunction` trampoline, so every press that reaches it is
  insecure; dialog buttons that fall through to the strip then fail on private
  calls (duel and ready-check accepts raised `CancelTaskbarWindowFlash`). Add a
  keybind button group on the owning scene. The audit fails on these hooks too.
- Do not leave `TODO` / `FIXME` / `HACK` / `XXX` markers in Lua/XML; record
  deferred work in `TODO.md`.
- Do not assign `SI_*` globals directly; use `SafeAddString`.

## Runtime gotchas

- ESO runs a Havok-flavored Lua 5.1: no `goto`, bitwise operators, or `//`, and
  no `io`, `package`, or `coroutine`. `os.date` and `debug.traceback` are the
  supported escapes. Use `unpack`, not `table.unpack`.
- Never use `pairs` order for UI or saved-data order. `#` returns 0 on a table
  with gaps, and `ipairs` stops at the first `nil`; both silently produce empty
  loops on saved data.
- Keep the `addonName ~= KelaPadUI.name` filter on `EVENT_ADD_ON_LOADED` and
  unregister one-shot events. Do not read player or character state at add-on
  load; it runs before `EVENT_PLAYER_ACTIVATED`.
- Saved-variable writes persist on `/reloadui` or logout, not immediately.
  `KELA_SETTINGS_DEFAULTS` is shared; never mutate it. Stored strings are
  length-capped, and the profile-less account bucket is shared across NA, EU,
  and PTS.
- Control names and virtual-template names are global across every installed
  add-on. Prefix them with `Kela`/`KPUI_` and make `CreateControlFromVirtual`
  names unique per parent.
- Optional add-ons can load after us even when listed in `OptionalDependsOn`;
  guard every use of their globals and never `assert` on them.
- Gamepad UI has no readable chat history. Use `LibDebugLogger` for diagnostics;
  keep `CHAT_SYSTEM:AddMessage` for deliberate user output only.
- Do not own globals the game defines (`ZO_*`, `SI_*`, style tables). Keep the
  documented exceptions (`SafeAddString`, the tooltip style copy) as they are.
- Reset anchors, colors, and texture coords when recycling pooled controls, and
  clear cached row arrays before rebuilding.

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
  KELAPADUI entry directly below Options.
- Keep `README.bbcode` in sync with `README.md`; it is the ESOUI listing
  description. It has no tables and no `[code]` (use
  `[font=Courier New][color=#4682B4]` for inline code), and each `[*]` item sits
  on its own line inside `[list]` / `[/list]`.
- Update `changelog.txt` (newest first) and affected docs for user-facing
  changes. Keep `## Version`, `## AddOnVersion`, the top `changelog.txt` version,
  and the release tag (`v<version>`) in sync; the audit checks the first three
  and the release workflow rejects a mismatched tag.
- ESOUI's `compatible` field takes the game version (`12.1.0`), not
  `## APIVersion` (`101051`). Bump `## APIVersion` and add the pair to
  `COMPATIBLE_VERSIONS` in `_tools/esoui_compat.py` on every game update; the
  release workflow fails when the pair is missing or not offered by ESOUI.

## Read next

- `docs/DEVELOPMENT_NOTES.md` - conventions, pitfalls, and the "never do this"
  list.
- `docs/MAINTENANCE.md` - architecture, validation workflow, and in-game checks.
- `docs/SETTINGS.md` - setting IDs and the add-a-setting procedure.
- `docs/TRADING_HOUSE.md` - trading modules and test notes.
- `docs/RELEASING.md` - packaging, GitHub Actions, and the ESOUI upload API.
- `docs/FEEDBACK.md` - the ESOUI comment to GitHub issue pipeline and its tags.
- `TODO.md` - open work and rated candidates.
