# KelaPadUI Development Notes

This is the quick reference for future updates, additions, and fixes. Use it
with `docs/MAINTENANCE.md` and `TODO.md`.

## Current architecture

- Target API: `101051`.
- Startup is eager. Do not reintroduce lazy loading for sets or trading history;
  the lazy-loading experiment was reverted after regressions.
- `LibSets` is required (`0.9.4`, API `101051`/`101052`).
- TTC and ATT are independent optional providers. The add-on must work with
  TTC-only, ATT-only, both, and neither.
- Trading-house code lives under `kpui_features/tradinghouse/`:
  - `kpui_tradinghouse_shared.lua`
  - `kpui_tradinghouse_hooks.lua`
  - `kpui_tradinghouse_tooltips.lua`
  - `kpui_tradinghouse_data.lua`
  - `kpui_tradinghouse_controls.lua`
  - `kpui_tradinghouse_gamepad.xml`
  - `kpui_trading_history.lua`
- Static trial and companion data lives in `kpui_data/kpui_data.lua`; keep
  large data tables out of feature modules.
- Keep the manifest order. Trading-house modules load before
  `kpui_features/kpui_info_tooltip.lua`.

## Do not regress these

- Keep the five tooltip types:
  `KPUI_GAMEPAD_RIGHT_TOOLTIP`, `KPUI_GAMEPAD_TRADING_TOOLTIP`,
  `KPUI_GAMEPAD_COMPARE_TOOLTIP`, `KPUI_GAMEPAD_COMPARE_TOOLTIP2`, and
  `KPUI_GAMEPAD_LEFT_DIALOG_TOOLTIP`.
- Keep the `QUAD1*` styles and `getStyleHeaderLine`.
- Keep the `ZO_CRAFTING_TOOLTIP_STYLES` copy; core reads that table directly.
- Keep the `SafeAddString` override for `SI_ITEM_FORMAT_STR_SET_NAME`; do not
  assign to the `SI_*` constant directly.
- Keep the flattened settings list and the KELAPADUI main-menu entry. The menu
  entry is append-only; settings use the separate KelaPadUI submenu.
- Retired setting IDs stay retired: `7503` and `7100`-`7104`.
- Guild-specific-store purchases are not added to Kela buying history. Core item
  data has no `itemUniqueId` for those purchases.
- `LibItemLink` is optional. Guard `LIB_ITEM_LINK`; other-quality rows are
  skipped when it is absent. The rows are built only when setting `7511` is on.
- Do not re-add `KELA_RESEARCH_COMPAT`, the dead trait-tooltip replacement
  block, `getTraitHeaderLine`, or `kelaGetSameTraitCount`. They were removed
  after confirming the trait block was never assigned or called.

## Trading-house notes

- TTC-only uses the core active-guild dialog. ATT-only graph and guild-stat
  sections are skipped when ATT is absent.
- The custom `KPUI_*` tooltip controls are retained intentionally. The copied
  buy/sell/remove confirmation dialogs remain because their C API callbacks
  cannot be hooked for history updates.
- Reset custom crafting-station tooltips from the scene that is actually
  embedded: provisioner recipe mode uses
  `GAMEPAD_PROVISIONER_CREATION_SCENE`, not the root scene, and smithing
  creation uses `GAMEPAD_SMITHING_CREATION_SCENE`. Treat
  `RefreshRecipeDetails(nil)` as teardown and do not re-anchor controls on that
  path.
- Clear cached guild-row arrays after hiding rows before rebuilding them; do not
  append the same controls on every tooltip refresh.
- Other core overrides should be replaced only where a supported hook exists.
- The future split and custom-control replacement are tracked in `TODO.md`.

## Standard change workflow

1. Read this file, `docs/MAINTENANCE.md`, and the relevant section of `TODO.md`.
2. Search for existing patterns before adding a new helper, setting, string, or
   tooltip style.
3. Keep the change focused. Do not mix cleanup, behavior changes, and
   main-menu color changes in one commit.
4. Update `changelog.txt` and any affected docs.
5. Add deferred or risky work to `TODO.md`; do not leave untracked
   `TODO`/`FIXME` markers in Lua/XML.
6. Run the static audit:

   ```powershell
   python _tools\audit_addon.py
   ```

7. Perform the relevant in-game checks before considering the change complete.

## Never do this

### Do not hook protected dialog show functions

Never install `ZO_PreHook`, `ZO_PostHook`, `SecurePreHook`, or `SecurePostHook`
on `ZO_Dialogs_ShowDialog`, `ZO_Dialogs_ShowGamepadDialog`,
`ZO_Dialogs_ShowPlatformDialog`, `ZO_Dialogs_ButtonKeybindPressed`, or
`ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog`. The audit fails on
any of these.

Why: ESO decides whether a closure is trusted at *creation* time (compare the
`ZO_Menu` pre-allocation comment in `zo_contextmenus.lua`, which exists only so
those closures are created as secure code). The gamepad dialog button-keybind
descriptors live in a shared pool
(`g_keybindStripDescriptors` in `ZO_GenericDialog_Gamepad.lua`) that is filled
lazily on dialog shows and then reused by every later dialog. If the pool is
grown while add-on code is on the callstack - which is what a hooked
`ZO_Dialogs_ShowDialog` does, because the original call then runs inside an
add-on wrapper - the descriptor's `callback` closure is untrusted for the rest
of the session. Pressing a button on any later core dialog that calls a private
function then fails:

```
Attempt to access a private function 'CancelTaskbarWindowFlash' from insecure code.
The callstack became untrusted 3 stack frame(s) from the top.
```

This is exactly what the ready-check error was (10/23/2026): the fix was
deleting the dead confirmation-dialog hooks in
`kpui_features/tradinghouse/kpui_tradinghouse_hooks.lua`. Both the
"reload, then accept a ready check" and "reload, open Quick Access, then accept
a ready check" tests passed afterwards.

Instead of hooking:

- decorate dialog data from a `setup` function owned by the dialog table you
  replace or register;
- prefer a KelaPadUI scene/fragment over `ZO_Dialogs_ShowGamepadDialog` for
  KelaPadUI's own panels;
- for anything else on a core path, use the `Secure*` hook variants and keep the
  hook out of the callstack that creates controls or closures.

To check a descriptor at runtime, run this with a dialog on screen and look for
`trusted = false`:

```
/script for g in pairs(KEYBIND_STRIP.keybindGroups) do for i=1,#g do local d=g[i] if type(d)=="table" and d.dialog then d(string.format("descriptor callback trusted = %s", tostring(IsTrustedFunction(d.callback)))) end end end
```

### Do not wrap core functions with the non-secure hooks

`ZO_PreHook`/`ZO_PostHook` build the replacement closure in add-on code, so the
wrapped core function runs inside untrusted code; any private call it makes will
fail. Use `SecurePreHook`/`SecurePostHook` for core functions. `ZO_PreHook` and
`ZO_PostHook` stay acceptable for add-on-owned or pure data/UI functions.

## Validation matrix

For trading or tooltip changes, check:

- TTC only, ATT only, both providers, and neither provider.
- Trading-house, bank, vendor/store, and crafting-station tooltips.
- Other-quality rows with `LibItemLink` present and absent.
- Buying, listing, and removal history updates.
- The five active tooltip types and their styles.
- Settings screen navigation, defaults, apply/reset behavior, and reload-gated
  feature toggles.

For non-trading changes, at minimum load the add-on and exercise the affected
feature plus the shared tooltip path.

## Documentation map

- `docs/MAINTENANCE.md` - architecture, load order, and validation workflow.
- `docs/SETTINGS.md` - settings storage, IDs, and adding settings.
- `docs/TRADING_HOUSE.md` - trading dependencies, modules, and history data.
- `docs/main_menu_notes.md` - removed pause-menu notes and restoration guidance.
- `TODO.md` - open work, completed cleanup history, and rated enhancement
  candidates with implementation touchpoints and controller-glyph notes.
