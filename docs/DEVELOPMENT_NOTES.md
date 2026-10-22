# KelaPadUI Development Notes

This is the quick reference for future updates, additions, and fixes. Use it
with `docs/MAINTENANCE.md` and `OPTIMIZATION_TODO.md`.

## Current architecture

- Target API: `101051`.
- Startup is eager. Do not reintroduce lazy loading for sets or trading history;
  the lazy-loading experiment was reverted after regressions.
- `LibSets` is required (`0.9.4`, API `101051`/`101052`).
- TTC and ATT are independent optional providers. The add-on must work with
  TTC-only, ATT-only, both, and neither.
- Trading-house code lives under `kpui_features/tradinghouse/`:
  - `kpui_tradinghouse_gamepad.lua`
  - `kpui_tradinghouse_gamepad.xml`
  - `kpui_trading_history.lua`
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
- Other core overrides should be replaced only where a supported hook exists.
- The future split and custom-control replacement are tracked in
  `OPTIMIZATION_TODO.md`.

## Standard change workflow

1. Read this file, `docs/MAINTENANCE.md`, and the relevant section of
   `OPTIMIZATION_TODO.md`.
2. Search for existing patterns before adding a new helper, setting, string, or
   tooltip style.
3. Keep the change focused. Do not mix cleanup, behavior changes, and
   main-menu color changes in one commit.
4. Update `changelog.txt` and any affected docs.
5. Add deferred or risky work to `OPTIMIZATION_TODO.md`; do not leave untracked
   `TODO`/`FIXME` markers in Lua/XML.
6. Run the static audit:

   ```powershell
   python _tools\audit_addon.py
   ```

7. Perform the relevant in-game checks before considering the change complete.

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
- `OPTIMIZATION_TODO.md` - open work and completed cleanup history.
