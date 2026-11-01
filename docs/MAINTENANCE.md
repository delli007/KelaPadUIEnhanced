# KelaPadUI Maintenance Guide

This guide describes the current add-on structure, load order, validation
workflow, and the areas that are most likely to need attention after an ESO
update. For the compact maintenance checklist and recurring pitfalls, see
`docs/DEVELOPMENT_NOTES.md`.

## Runtime requirements

- The add-on is designed for the gamepad UI.
- `LibSets` is required and is declared in `KelaPadUI.txt`.
- `Tamriel Trade Centre` (TTC) and `Arkadius Trade Tools` (ATT) are optional
  trading-data providers. At least one is required for the trading features;
  either provider can be used alone. Without either dependency, the trading
  setup is skipped and the trading master setting is forced off.
- `LibCustomMenu` is optional and is used only for chat context-menu actions.
- `LibItemLink` is optional and is used only for the other-quality price rows in
  trading tooltips. Those rows are skipped when it is absent.
- The manifest currently targets API version `101051`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `KelaPadUI.lua` | Add-on bootstrap, scene fragments, and feature initialization. |
| `KelaPadUI.txt` | Manifest and load order. |
| `kpui_core/` | Settings, constants, utilities, tooltip styles, and gamepad tooltip code. |
| `kpui_features/` | Optional features: companion info, dungeon finder, chat tools, map rally, antiquities, sets, the main menu, and trading house. |
| `kpui_features/tradinghouse/` | Trading-house tooltips, hooks, custom XML, and trading history. |
| `kpui_lang/` | English strings; `en.lua` is the only locale file. |
| `kpui_data/` | Static trial and companion data used by feature modules. |
| `docs/` | Maintenance, development, research, settings, trading-house, and main-menu notes. |
| `_tools/audit_addon.py` | Static manifest, XML, string, optional-library, `SI_*` assignment, and removed-reference audit. |
| `TODO.md` | Open refactors, rated enhancement candidates, and completed cleanup history. |
| `changelog.txt` | Release-facing change history. |

## Load order

Keep the manifest order in mind when adding code that runs at file scope:

1. `kpui_lang/en.lua`.
2. Core constants, utilities, and tooltip styles.
3. Core templates XML.
4. Settings Lua and XML.
5. Tooltip Lua and XML.
6. Sets, antiquities, and trading-house history/UI modules.
7. Feature modules.
8. `KelaPadUI.lua` bootstrap, which initializes settings and enabled features.

Feature modules that write to the `KelaPadUI` table at file scope must be loaded
after the table exists. In practice, register event hooks and scene callbacks in
setup functions rather than at file scope where possible.

## Settings architecture

The KelaPadUI settings screen is a single gamepad options list in the
`kela_options_root` scene. There is no category submenu. The category order is
defined by `KELA_SETTINGS_CATEGORY_ORDER` in
`kpui_core/kpui_settings_gamepad.lua`:

1. Features (`7400`)
2. Item sets (`7300`)
3. Trading Interface (`7500`)

`Kela_GamepadOptions:RefreshOptionsList()` clears the list and calls
`AddSettingGroup(panelId, categoryHeader)` for each category. The first visible
setting in each group receives the category heading. Existing section headings,
such as `Trading tooltip`, still work inside a group.

See `docs/SETTINGS.md` for the settings data model, IDs, and the procedure for
adding a setting.

## Feature toggles

The Features category contains reload-gated toggles:

| Setting | Default |
| --- | --- |
| Companion information | on |
| Dungeon finder information | on |
| Chat tools | on |
| Map rally point | on |
| Antiquity filters | on |
| Antiquity lead details | on |
| Main-menu quick access | on |
| Main-menu daily dashboard | on |
| PersonalAssistant junk integration | on |
| PS5 button map | off |

The PS5 button map is the exception: it is not reload-gated, and its settings
checkbox applies or reverses the texture redirects immediately.

`KelaPadUI_OnLoaded()` checks these settings before calling the corresponding
setup function. Changing a toggle therefore requires `/reload`; the setting
tooltip communicates this, and leaving the options after a change shows a
"reload required" dialog with Reload UI and Later. Keep the feature-gating
checks in the bootstrap when adding a new load-time feature, and add a matching
default and string. The PersonalAssistant junk toggle depends on the optional
PersonalAssistant add-on; it is installed regardless of load order and checks PA
availability per item.

The Item sets toggle hides the Sets entry in the KelaPadUI main-menu submenu but
does not remove the sets list from the add-on. The KELAPADUI main-menu entry
itself is always visible so the user cannot lock themselves out of settings.

Companion information covers both `kpui_features/kpui_companion.lua` (companion
menu details and rapport notifications) and
`kpui_features/kpui_companion_collections.lua` (extra rows in the gamepad
Collections companion tooltip). The Collections module post-hooks
`GAMEPAD_COLLECTIONS_BOOK.RefreshStandardTooltip` and records build and rapport
snapshots, because the game only exposes live level, skills, and gear for the
summoned companion. Companion builds are account-wide; rapport is stored per
character. Skills and the ultimate are captured but not rendered. Neither part
registers a setting of its own.

## Trading features

The trading stack is initialized when at least one of TTC or ATT is present and
the trading master setting is enabled. It includes:

- guild-store search filtering and price-effect indicators;
- TTC/ATT-enhanced item tooltips, using whichever provider is available;
- buying and listing history with retention cleanup;
- ATT-based guild statistics and category mapping when ATT is available;
- crafting-station tooltip integration.

Provider-specific tooltip rows show `N/A` for a missing source. The ATT sales
graph and guild-statistics section are omitted without ATT; TTC-only use keeps
the core guild-selection dialog. The custom `KPUI_Graph` control does not inherit
an ATT template, so the trading XML loads without ATT installed.

See `docs/TRADING_HOUSE.md` for module details and test notes.

The trading confirmation dialogs (`TRADING_HOUSE_CONFIRM_BUY_ITEM`,
`TRADING_HOUSE_CONFIRM_SELL_ITEM`, `TRADING_HOUSE_CONFIRM_REMOVE_LISTING`,
`TRADING_HOUSE_CHANGE_ACTIVE_GUILD`) are copies of the current core tables
because their actions are C API calls that cannot be hooked for history
updates. They must be kept in sync with
`ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog`. Do not add global
`ZO_Dialogs_ShowDialog` / `ZO_Dialogs_ShowGamepadDialog` hooks to decorate
their data: an earlier version did that, and the decoration silently stopped
working once the display pre-hook was removed. Decorate from a
dialog-owned `setup` function instead.

## Gamepad dialog callstack pitfall

ESO marks a closure as untrusted based on where it was created (see the
`ZO_Menu` pre-allocation comment in `zo_contextmenus.lua`). The gamepad
dialog button-keybind descriptors
(`g_keybindStripDescriptors` in `ZO_GenericDialog_Gamepad.lua`) are created
lazily on the first dialog show and then reused by every later dialog. If the
pool is grown while add-on code is on the callstack, the descriptor's
`callback` closure is untrusted, and pressing a button on any later core
dialog that calls a private function (for example `CancelTaskbarWindowFlash`
when a ready check is accepted) fails with "Attempt to access a private
function ... from insecure code". Verify a descriptor with
`IsTrustedFunction(descriptor.callback)`, and prefer add-on scenes over
`ZO_Dialogs_ShowGamepadDialog` for KelaPadUI-owned panels.

KelaPadUI's Quick Access uses the gamepad main menu's own submenu, opened from
the Options keybind, so it does not touch the dialog pool. Any add-on-shown
gamepad dialog that can appear before a core dialog must either avoid core
`buttons` and manage its own keybind group, or use an add-on scene. Reload clears
an already-poisoned pool.

## Tooltip styles

`kpui_core/kpui_tooltip_styles.lua` applies only properties that differ from the
current core `ZO_TOOLTIP_STYLES` table through `KelaOverrideTooltipStyle`. This
keeps future ESO default properties unless the old override deliberately omitted
them; those four omissions are passed as `removedKeys`. Add-on-only styles
(`kelaTrade`, `QUAD1*`, and `InfoTooltip*`) remain complete tables.

When updating for a new ESO version, compare the helper calls with core
`tooltipstyles.lua` and re-test the five active tooltip types.

## Validation workflow

Run these checks after a change:

```powershell
python _tools\audit_addon.py
```

The audit checks manifest entries, Lua syntax, XML well-formedness, removed
feature references, TODO/FIXME markers, direct `SI_*` constant assignments,
declared optional-library dependencies, unused virtual templates, and
undefined/unused KELA strings. It counts any KELA token in Lua/XML as a
reference, so localization IDs passed indirectly are not reported as unused.
Virtual-template references are counted across add-on Lua/XML, including
`inherits`, `CreateControlFromVirtual`, and template strings. When the sibling
`LibSets` add-on is installed, the audit also checks its API version and that
every `LibSets.*` call and `LIBSETS_*` constant used here exists. It is a
static check, not an in-game test.

To parse-check every Lua file, use `luaparse` through Node:

```powershell
npx.cmd --yes luaparse path\to\file.lua > $null
```

`kpui_lang/en.lua` is stored as UTF-8 without a BOM, so it can be passed to
`luaparse` directly. All Lua files should parse without errors.

Manual in-game checks are still required for:

- opening KelaPadUI from the gamepad main menu;
- opening Quick Access with the Options keybind, checking section spacing, and
  using Select/Back on each shortcut;
- scrolling the flattened settings list and confirming category headings;
- changing and resetting settings, including reload-gated toggles;
- entering the guild store with TTC only, ATT only, both, and neither;
- confirming tooltips, search filters, and trading history;
- checking the Known filter for collectible fragments, books, recipes, and set
  pieces;
- verifying purchased listings disappear without duplicate or misaligned rows;
- switching between gamepad and keyboard UI modes.

## Diagnostics

Chat text cannot be copied out of the gamepad UI, so diagnostics are logged
through `LibDebugLogger` rather than `d()`:

- `LibDebugLogger` is an optional dependency
  (`## OptionalDependsOn: LibDebugLogger`). `KelaPadUI.log` is created at load and
  is nil when the library is missing, so every call site must be nil-safe.
- Entries are written to the LibDebugLogger saved variables in `SavedVariables`,
  which can be read from disk. The default minimum level is Info;
  `/debuglogger level debug` enables `:Debug` entries and `/debuglogger clear`
  empties the buffer.
- `/keladiag` is the built-in daily-quest dump: it logs every journal quest with
  its type, repeat type and complete state, plus every daily quest the game
  records as completed with its zone. Run it whenever a dashboard daily row looks
  wrong.

## Performance profiling

ESO does not expose per-add-on CPU time, so profile with elapsed-time checks
inside the add-on. `GetFrameTimeMilliseconds()` is suitable for elapsed time,
and `collectgarbage("count")` returns Lua memory in kilobytes.

Use these measurements if a future performance regression is reported:

- **Load time:** temporarily record `GetFrameTimeMilliseconds()` before and
  after each initialization step in `KelaPadUI_OnLoaded()`, then log the
  differences with `d()`. Remove the instrumentation after measuring.
- **Hot paths:** after `/reloadui`, wrap a tooltip or search function at runtime
  and log only slow calls. For example, this reports trading-tooltip layouts
  that take at least 2 ms:

  ```lua
  /script local f=ZO_Tooltip.LayoutTradingTooltip; ZO_Tooltip.LayoutTradingTooltip=function(self,...) local t=GetFrameTimeMilliseconds(); local r=f(self,...); local e=GetFrameTimeMilliseconds()-t; if e>=2 then d(string.format("Kela trading tooltip: %d ms",e)) end; return r end
  ```

  `/reloadui` removes the wrapper.
- **FPS and memory:** sample `GetFramerate()` and
  `collectgarbage("count")/1024` once per second while repeating the same
  camera movement and tooltip interaction:

  ```lua
  /script local n=0; local function s() n=n+1; d(string.format("%d fps, %.1f MB",GetFramerate(),collectgarbage("count")/1024)); if n<30 then zo_callLater(s,1000) end end; s()
  ```

  Compare the same location and interaction with the feature enabled and
  disabled. Lua memory is only the add-on/runtime Lua heap, not total UI or GPU
  memory.
- **External profiler:** `ESO Profiler` exists, but its last public build
  targets an old API. Verify compatibility before relying on it.

## Git workflow

Git is not on `PATH` on this machine. Use:

```powershell
& 'C:\Program Files\Git\cmd\git.exe' status
& 'C:\Program Files\Git\cmd\git.exe' diff
& 'C:\Program Files\Git\cmd\git.exe' add <files>
& 'C:\Program Files\Git\cmd\git.exe' commit -m "Short description"
```

Keep commits focused on one feature or cleanup. Do not commit generated audit
output or local editor files. The repository has a `.gitignore` for the usual
Python, build, editor, and OS artifacts.

## Change checklist

1. Update the setting/string/default together when adding a setting.
2. Keep feature-gating checks and defaults in sync.
3. Check that removed settings are also removed from all data tables and
   localization files; retired IDs stay retired.
4. Run the audit and Lua parse check.
5. Perform the relevant in-game checks.
6. Update `changelog.txt`.
7. Add deferred or risky work to `TODO.md` rather than leaving untracked TODOs
   in code.

## Known deferred work

`TODO.md` is the source of truth. The current open items are the trading-house
file split and the replacement of custom controls with supported core
hooks/templates where feasible. Rated enhancement candidates are in the
`Candidate enhancements` section of `TODO.md`. Ongoing maintenance also includes:

- verifying tooltip overrides against new core styles after each ESO update;
- validating LibSets metadata after set/DLC updates;
- reviewing trading-house display edge cases and testing TTC/ATT data after
  each ESO update.

## Documentation map

- `docs/DEVELOPMENT_NOTES.md` - recurring conventions, validation matrix, and
  pitfalls for future updates, additions, and fixes.
- `TODO.md` - the `Candidate enhancements` table rates researched gamepad
  features and addon integrations with usefulness/difficulty.
- `docs/SETTINGS.md` - settings storage, IDs, and adding settings.
- `docs/TRADING_HOUSE.md` - trading dependencies, modules, and history data.
- `docs/main_menu_notes.md` - removed pause-menu notes feature and restoration
  guidance.
