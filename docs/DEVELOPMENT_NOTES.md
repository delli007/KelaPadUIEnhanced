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

## Text styling

`kpuiConst.TextStyles` in `kpui_core/kpui_constants.lua` is the single source of
truth for how KelaPadUI text looks. Pick a style instead of hardcoding a font or
a colour:

| Style | Look | Use for |
| --- | --- | --- |
| `Title` | large, white | screen and page titles |
| `SectionTitle` | bold, gold | section titles such as WEAPONS / ARMOR / JEWELRY |
| `ListHeader` | bold, uppercase, interface-normal colour, left-aligned | headers inside a list, such as CHARACTERS — matches the game's own list headers |
| `CharacterName` | condensed 42px, white | the selected character's name on the trait research page |
| `Body` | 20px, white | normal text and group headings |
| `BodyLarge` | 27px, white | trait names and group headings |
| `Dim` | 20px, off-white | secondary text |
| `ValuePositive` / `ValueWarning` / `ValueNegative` / `ValueTimer` | light green / light orange / light red / gold | complete, nearly full, full, and running timers |

Apply a style with `KelaApplyTextStyle(label, style)` for a plain label, or
`KelaApplyEntryTextStyle(entryData, style)` for a gamepad list row. Row colours
live on the entry data, because the core row setup re-applies them on every
refresh; calling `SetColor` straight on a row label is overwritten.

Coloured runs inside a longer string (a green count, a gold timer) use the same
styles through `ZO_ColorDef:Colorize`.

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

## Companion snapshot notes

- `kpui_features/kpui_companion.lua` handles the companion menu and rapport
  notifications. `kpui_features/kpui_companion_collections.lua` post-hooks
  `GAMEPAD_COLLECTIONS_BOOK.RefreshStandardTooltip` to add the extra Collections
  tooltip rows. `ZO_GamepadCollectionsBook` is file-local, so the global
  singleton must be hooked.
- Level, XP, slotted skills, ultimate, equipped gear, and the passive perk are
  account-wide, but the game only exposes them for the summoned companion.
  Rapport is per character and is also active-only.
- Store builds in
  `kpuiSavedVariables.companionSnapshots.builds[companionId]` and rapport in
  `kpuiSavedVariables.companionSnapshots.rapport[characterId][companionId]`.
- Merge only sections that are ready. Never write an empty skills or gear table
  over a good snapshot, and never fabricate missing values. Rows read from a
  cache are labeled as recorded while summoned.
- Read normal skill slots up to `ACTION_BAR_ULTIMATE_SLOT_INDEX`; the ultimate is
  `ACTION_BAR_ULTIMATE_SLOT_INDEX + 1`, and each captured skill also stores a
  1-based `index`. Companion gear uses `BAG_COMPANION_WORN`; skip
  `EQUIP_SLOT_COSTUME`, and skip the off-hand when the main hand is two-handed.
- Skills and the ultimate are captured but not rendered. The tooltip shows the
  perk and description, level/XP, rapport progress and tier, and gear with
  weight and trait.
- Use the `companionCollectionsSection` tooltip style; it matches the Collections
  body text (27px light font, off-white) and uses `bodyHeader` for titles.

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
4. Update `changelog.txt` and any affected docs. For a release, keep the newest
   `major.minor.patch` changelog version and the `## Version` in `KelaPadUI.txt`
   in sync; pre-2.5.0 changelog versions were assigned retrospectively.
5. Add deferred or risky work to `TODO.md`; do not leave untracked
   `TODO`/`FIXME` markers in Lua/XML.
6. Run the static audit:

   ```powershell
   python _tools\audit_addon.py
   ```

7. Perform the relevant in-game checks before considering the change complete.

## Never do this

### Do not pass a bare quoted `KELA_*` name to `GetString`

`GetString`'s first argument is a string *variable prefix*, not a string id, and
its optional second argument is a context id appended to that prefix:

```lua
GetString(KELA_SETTINGS_SETS_ENABLED)                 -- works: numeric constant
GetString("KELA_SETSSOURCE", sourceIndex)             -- works: resolves KELA_SETSSOURCE<index>
GetString("KELA_TRAIT_RESEARCH_TITLE")                -- BROKEN: returns nothing
```

The game uses the same convention: it defines `SI_ITEMTRAITTYPE0`,
`SI_ITEMTRAITTYPE1`, `SI_ITEMTRAITTYPE10`, ... and calls
`GetString("SI_ITEMTRAITTYPE", traitType)`.

A broken lookup renders as *nothing at all*, which looks exactly like a missing
font or a wrong colour, so this cost several rounds of styling changes on the
trait research page before the real cause was found. When a label is blank:

1. grep for `GetString\("KELA_` and fix the call before touching any styling;
2. only then consider the font, the colour, or the control's size.

The static audit cannot catch this: it verifies that the ids exist, not how they
are read. Note also that this pattern is invisible in review, because
`GetString(KELA_FOO)` and `GetString("KELA_FOO")` look almost identical.

### Do not draw a button texture without the game's texture coords

Some base-game button textures are not full-bleed: the artwork sits in one
corner of a larger canvas. `EsoUI/Art/Buttons/closeButton_up.dds` is a 32x32
texture whose X is drawn in the top-left 20x20, and the game's own close button
crops it:

```xml
<Button name="ZO_CloseButton" ...>
    <Dimensions x="20" y="20"/>
    <TextureCoords left="0" top="0" right="0.625" bottom="0.625"/>
    <Textures normal="EsoUI/Art/Buttons/closeButton_up.dds" .../>
</Button>
```

`20 / 0.625 = 32`, so the crop is the top-left 20x20. Drawn whole into a square
control, the X renders at 62.5% and offset up-left — it looks like a broken
anchor, but it is a texture-coords bug, and no amount of re-anchoring will move
it. When a texture looks consistently off-centre, find the game template that
uses it and copy its `TextureCoords` before touching any anchors.

If one control is reused for several states, reset the other states to the full
texture with `(0, 1, 0, 1)`; a stale crop leaks when the control changes texture.

Watch the argument order: `SetTextureCoords` takes
`(left, right, top, bottom)`, which is *not* the order the XML
`<TextureCoords left top right bottom>` attributes are written in. Passing the
XML order to the call silently produces zero-width or zero-height coordinates,
which renders nothing at all — it blanked every marker in the trait research
table until the order was fixed.

### Do not hook protected dialog show functions

Never install `ZO_PreHook`, `ZO_PostHook`, or `SecurePostHook` on
`ZO_Dialogs_ShowDialog`, `ZO_Dialogs_ShowGamepadDialog`,
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
`kpui_features/tradinghouse/kpui_tradinghouse_hooks.lua`. The
"reload, then accept a ready check" test passed afterwards. Quick Access later
reintroduced the error by showing its own gamepad dialog; it now lives in the
main menu, so that path no longer touches the pool.

Instead of hooking:

- decorate dialog data from a `setup` function owned by the dialog table you
  replace or register;
- prefer a KelaPadUI scene/fragment over `ZO_Dialogs_ShowGamepadDialog` for
  KelaPadUI's own panels;
- for anything else on a core path, use the `Secure*` hook variants and keep the
  hook out of the callstack that creates controls or closures.

KelaPadUI's Quick Access avoids the pool by reusing the gamepad main menu's own
submenu, opened from the Options keybind. Any add-on-shown gamepad dialog that
can appear before a core dialog must either avoid core `buttons` and manage its
own keybind group (passing `KEYBIND_STRIP:GetTopKeybindStateIndex()`), or use an
add-on scene. A reload clears an already-poisoned pool.

The Quick Access entry is deliberately not in `ZO_MENU_ENTRIES`. The keybind
flags an override, pushes `playerSubmenu`, and replaces the sublist from the
scene's `SCENE_SHOWING` callback (with a `SCENE_SHOWN` check as a safety net).
The main menu also rebuilds the sublist from the selected main-list entry when
inventory, mail, level, or daily-reward updates mark it dirty. A
`SecurePostHook` on `RefreshLists` puts the Quick Access list back afterwards.
ESO has no `SecurePreHook`, so the selected row is tracked by a
`SecurePostHook` on the manager's `OnSelectionChanged` instead of a
before/after snapshot; that hook ignores the selection reports produced by the
core rebuild because the rebuilt rows are not Quick Access rows.
The main menu passes `postPadding = 0` for every entry, which also disables the
list's automatic header padding; set
`postPadding = GAMEPAD_HEADER_DEFAULT_PADDING` on the entry before each section
header or the header overlaps the previous row.

To check a descriptor at runtime, run this with a dialog on screen and look for
`trusted = false`:

```
/script for g in pairs(KEYBIND_STRIP.keybindGroups) do for i=1,#g do local d=g[i] if type(d)=="table" and d.dialog then d(string.format("descriptor callback trusted = %s", tostring(IsTrustedFunction(d.callback)))) end end end
```

### Do not wrap core functions with the non-secure hooks

`ZO_PreHook`/`ZO_PostHook` build the replacement closure in add-on code, so the
wrapped core function runs inside untrusted code; any private call it makes will
fail. Use `SecurePostHook` for core functions. `ZO_PreHook` and `ZO_PostHook`
stay acceptable for add-on-owned or pure data/UI functions. ESO exposes no
`SecurePreHook`; where a before/after value is needed, hook a separate core
function that reports the value (for example `OnSelectionChanged`) instead.

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
