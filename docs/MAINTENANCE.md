# KelaPadUI Enhanced Maintenance Guide

This guide describes the current add-on structure, load order, validation
workflow, and the areas that are most likely to need attention after an ESO
update. For the compact maintenance checklist and recurring pitfalls, see
`docs/DEVELOPMENT_NOTES.md`.

## Runtime requirements

- The add-on is designed for the gamepad UI.
- `LibSets` is required and is declared in `KelaPadUIEnhanced.txt`.
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
| `KelaPadUIEnhanced.txt` | Manifest and load order. |
| `kpui_core/` | Settings, constants, utilities, add-on dialogs (`kpui_dialogs.lua`), the gamepad data browser (`kpui_gamepad_browser.lua`), tooltip styles, and gamepad tooltip code. |
| `kpui_features/` | Optional features: companion info, dungeon finder, chat tools, map rally, antiquities, sets, Character Knowledge, the main menu, and trading house. |
| `kpui_features/journals/` | The gamepad Extended Journal: reads any LibExtendedJournal tab as a gamepad browser source. |
| `kpui_features/fixes/` | Base-game fixes: the group menu panel leak and the U51 battleground fixes. |
| `kpui_features/filters/` | Additional gamepad set, recipe, and achievement filters. |
| `kpui_features/mainmenu/` | Main-menu entry, dashboard, and Quick Access. |
| `kpui_features/companion/` | Companion menu and Collections tooltip information. |
| `kpui_features/tradinghouse/` | Trading-house tooltips, hooks, custom XML, and trading history. |
| `kpui_lang/` | English source strings in `en.lua`, plus generated `de.lua`, `fr.lua`, `ru.lua`, `jp.lua`, `es.lua`, and `zh.lua` loaded through `$(language)`. |
| `kpui_data/` | Static trial, companion, and generated antiquity-lead data used by feature modules. |
| `docs/` | Maintenance, development, research, settings, trading-house, and main-menu notes. |
| `_tools/audit_addon.py` | Static identity, manifest, XML, string, optional-library, `SI_*` assignment, and removed-reference audit. |
| `_tools/package_addon.py` | Builds and verifies the ESOUI-ready zip in `dist/`. |
| `_tools/translate_kpui_lang.py` | Generates the six locale files in `kpui_lang/` from `en.lua` and validates placeholders. |
| `.github/workflows/` | CI audit/package run and the tag-triggered release plus ESOUI upload. |
| `TODO.md` | Open refactors, rated enhancement candidates, and completed cleanup history. |
| `changelog.txt` | Release-facing change history. |

The folder name, the manifest filename, and `KelaPadUI.name` are the add-on
identity; add-on managers match on the first two. They must stay identical, and
they must not change back to `KelaPadUI`, which is the abandoned original. The
audit enforces this.

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

The KelaPadUI Enhanced settings screen is a single gamepad options list in the
`kela_options_root` scene. There is no category submenu. The category order is
defined by `KELA_SETTINGS_CATEGORY_ORDER` in
`kpui_core/kpui_settings_gamepad.lua`:

1. Features (`7400`)
2. Fixes and Patches (`7600`)
3. Account-Wide Settings (`7700`)
4. Ability Bar (`7800`)
5. Journals and Browsers (`7304`)
6. Trading Interface (`7500`)

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
| Additional gamepad filters | on |
| Antiquity lead details | on |
| Main-menu quick access | on |
| Main-menu daily dashboard | on |
| PersonalAssistant junk integration | on |
| PS5 button map | off |

The Journals and Browsers category groups the menu screens. Only the trait
research matrix is reload-gated; the others are checked whenever the menu is
built:

| Setting | Default |
| --- | --- |
| Sets interface | on |
| Trait research matrix | on |
| Character Knowledge | on |
| Extended Journal | on |

Settings that depend on another add-on list it in their help text with a live
status (see `addons` in `docs/SETTINGS.md`). To check it, open the help for
Character Knowledge with LibCharacterKnowledge disabled (red "not found"), and
for Ability bar enhancements with Fancy Action Bar+ enabled (red "loaded").

The Fixes and Patches category follows it:

| Setting | Default |
| --- | --- |
| Group menu fix | on |
| U51 BG fixes | on |

The Account-Wide Settings category follows it:

| Setting | Default |
| --- | --- |
| Share Camera settings with all characters | off |
| Share Interface settings with all characters | off |
| Share Nameplates settings with all characters | off |
| Share Social settings with all characters | off |
| Share Combat settings with all characters | off |

The PS5 button map and the Account-Wide Settings toggles are the exceptions:
they are not reload-gated. The PS5 checkbox applies or reverses the texture
redirects immediately; an account-wide toggle copies the current character's
values when turned on (see `docs/SETTINGS.md`).

In-game check for account-wide settings (repeat per category):

1. On character A, set distinctive options in the category: for Combat, action
   bar Always and one buff option off; for Camera, a field of view; for
   Interface, the quest tracker off and one chat bubble channel off; for
   Nameplates, an enemy nameplate choice and a glow intensity; for Social, a
   chat color and the duel auto-decline. Turn the toggle on, leave the menu,
   run `/reloadui`, and confirm A is unchanged.
2. Log in to character B: its panel matches A. LibDebugLogger lists each
   setting that was written, plus a warning for any that did not take.
3. On B, change one option (for Combat, also one HUD-editor option), log back
   to A, and confirm it arrived.
4. Turn the toggle off on A, change an option, and confirm B keeps the shared
   value at its next login.

In-game check for the Ability Bar panel. Use gamepad mode with the game's
Ability Bar Timers and Ability Bar Back Row options on, and Fancy Action Bar+
disabled.

1. Turn on Ability bar enhancements and `/reloadui`. The back row sits about
   10 px higher. Swap bars: the animation lands in the same place, and nothing
   overlaps the health bar.
2. Slot Molten Whip and cast Ardent Flame skills. The whip shows 1-3 on the
   front bar, and the count shows above it on the back row after a swap.
   Try a skill whose own effect stacks (Bound Armaments): there should be only
   one number.
   Also check the timer: with Seething Fury (Molten Whip) or Crux (an Arcanist
   skill) stacked, while the buff has stacks, the front button shows a countdown like a skill's own
   effect, and the back row shows the bar and numbers. Gaining another stack
   (refresh) restarts it; spending the stacks clears it. A skill with its own
   timer (Bound Armaments) keeps that timer instead.
3. Let a back-row effect run out. Its timer turns red at the Expiry warning
   value; 0 turns that off.
   Turn on Always show back row: every skill on the other bar stays visible
   above the front buttons, with an empty bar when nothing is running. Swap
   bars, change a skill, and empty a slot: the back row follows, and an empty
   slot stays hidden, and so does the ultimate while nothing runs on it. Turn it
   off and idle slots disappear again.
4. Turn off Back row progress bar and turn on Back row timer numbers. The thin
   bar and its empty groove are gone, and a countdown shows above the front
   button, turning red near the end. Swap bars a few times: the slots keep the
   raise and the trim. With the bar off, the back row sits about 9 px higher
   than with it on. Turn the bar back on with the numbers still on: both
   show. Turn the numbers off: only the bar. Set Raise back row to 40 and check
   the slots still look right.
   The back row stack count should sit inside the icon's right edge, not past
   it, and be easy to read. With a stack count and a countdown on the same slot,
   they should not touch, including when the countdown shows tenths under 2 s
   ("1.6"). Read the `Action bar: back row text` line in LibDebugLogger for the
   measured widths and the font that was picked.
5. Set Attribute bar shift to 200. Magicka and Stamina move toward the health
   bar, and stay there after a screen-mode change and `/reloadui`.
6. With the KelaPadUI settings open, the ability bar and attribute bars show
   behind the menu, and moving the raise and shift sliders moves them right
   away.

`KelaPadUI_OnLoaded()` checks these settings before calling the corresponding
setup function. Changing a toggle therefore requires `/reload`; the setting
tooltip communicates this, and leaving the options after a change shows a
"reload required" dialog with Reload UI and Later. Keep the feature-gating
checks in the bootstrap when adding a new load-time feature, and add a matching
default and string. The PersonalAssistant junk toggle depends on the optional
PersonalAssistant add-on; it is installed regardless of load order and checks PA
availability per item.

### Group menu fix

`kpui_features/fixes/kpui_group_menu_fix.lua` stops the gamepad group menu from
acting on group and unit events while it is closed. Three core behaviours
combine:

- The handlers are guarded by `self.control:IsControlHidden()`, but that test is
  only true once the close animation has finished: the group scene's fragment is
  a `ZO_FadeSceneFragment` on the control, and
  `ZO_AnimatedSceneFragment.animationReverseOnStop` calls `SetHidden(true)`
  (`zo_scenefragmenttemplates.lua:68`) when the fade ends. A group event during
  the fade therefore still rebuilds the closed menu.
- `UpdateMenuList()` has no open-state guard of its own, and other add-ons call
  it directly. LibGroupBroadcast's LibGroupSocket does so from its unit events
  (`LibGroupSocket.lua:128`), so dismissing a pet rebuilds the closed menu long
  after the fade finished.
- A rebuild calls `UpdateMenuList()`, which reselects the list's default index 2,
  the **Current Group** row. That selection callback runs
  `SCENE_MANAGER:AddFragmentGroup(...)` without checking the group scene, so the
  panel lands on whichever scene is current and stays until that scene hides. The
  same callback calls `GAMEPAD_TOOLTIPS:ClearTooltip` and, through
  `GAMEPAD_GROUP_ROLES_BAR:Deactivate()`, `Reset` on `GAMEPAD_LEFT_TOOLTIP`, which
  removes the open screen's help or item panel from the current scene.

The module `ZO_PreHook`s `UpdateMenuList`, a pure UI rebuild, and skips it while
`GAMEPAD_GROUP_SCENE` is not showing; this is what fixes both symptoms.
`OnStateChanged` rebuilds the list when the scene shows, so nothing is lost. A
`SelectedDataChanged` callback and the reset detach anything that was already
attached when the scene hid. The module also keeps the menu control hidden while
the scene is not showing, as a belt-and-braces guard for the fade window; the
engine already hides it at the end of the fade. Its `StateChange` callback is
registered with a priority, because `ZO_Scene:SetState` fires callbacks before it
refreshes fragments, so the control is visible again before the screen's own
handler runs. It hooks no secure, dialog, or keybind function.

Do not hide the control earlier than the fade-out, and never hide it while the
scene is showing: the fade is an alpha animation on that control, and a control
hidden out of band while the fragment still reports shown leaves an invisible but
open menu whose `IsControlHidden` guards block every update.

To check it: open the group menu and close it, then summon or dismiss a pet (or
have a group member join or leave) while the KelaPadUI settings, Guilds, bank or
Activity Finder screen is open. The help or item panel must stay, and no panel
may appear over the HUD. Open the group menu again to confirm the member list,
roles bar and tooltips still work.

### U51 battleground fixes

`kpui_features/fixes/kpui_basegame_fixes.lua` mirrors three battleground gamepad
fixes that ZOS is preparing. The toggle is reload-gated and the module is
intentionally self-contained so the whole thing can be deleted after the
official fix ships:

- L2/R2 round paging: the module adds `UI_SHORTCUTS_ACTION_LAYER_FRAGMENT` (in
  Lua, no XML) to the scoreboard scenes and registers an ethereal
  `UI_SHORTCUT_LEFT_TRIGGER` / `RIGHT_TRIGGER` group that calls
  `BATTLEGROUND_SCOREBOARD_FRAGMENT:OnKeybindDown`. The core round actions exist
  but inherit from unbound `*_DUMMY` actions, and the scoreboard scenes did not
  activate the UI-shortcuts layer. Ethereal entries are dispatched but draw no
  button. The in-game scene already shows the gamepad keybind strip; the
  end-of-game recap keeps it hidden, so the module adds
  `KEYBIND_STRIP_GAMEPAD_FRAGMENT` there (without the backdrop group) to make the
  strip control visible with nothing drawn. Nothing hooks the dispatcher.
- Scoreboard sizing: `SecurePostHook` on the team-panel `UpdatePanelHeight` /
  `UseSmallPlayerEntries`, the fragment's `UpdateAll`, and the player row's
  `SetupOnAcquire`. Large rows use 40 px, small rows 32 px, and the row gap is 9,
  matching the 12.2.0 fix. Small rows keep the single `ZoFontGamepad27` font so
  the rows stay at 32 px. The module is skipped when
  `ZO_BATTLEGROUND_SCOREBOARD_PLAYER_SMALL_ROW_HEIGHT_GAMEPAD` exists.
- Activity Finder: the module subscribes to
  `ZO_ACTIVITY_FINDER_ROOT_MANAGER`'s `OnUpdateLocationData` and re-commits the
  root list while the screen is open, because `CategoryEntrySetup` caches the
  lock state and the gamepad root never re-evaluates it.

When ZOS ships any of these, delete the matching code (or the whole module and
its manifest entry) and the setting ID `7413`.

The Item sets toggle hides the Sets entry in the KelaPadUI Enhanced main-menu submenu but
does not remove the sets list from the add-on. The KELAPADUI main-menu entry
itself is always visible so the user cannot lock themselves out of settings. It
sits directly below Options; the game's Quit and Log Out entries follow it.

Companion information covers both `kpui_features/companion/kpui_companion.lua` (companion
menu details and rapport notifications) and
`kpui_features/companion/kpui_companion_collections.lua` (extra rows in the gamepad
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
`ZO_Dialogs_ShowGamepadDialog` for add-on-owned panels.

KelaPadUI Enhanced's Quick Access uses the gamepad main menu's own submenu, opened from
the Options keybind, so it does not touch the dialog pool. Any add-on-shown
gamepad dialog that can appear before a core dialog must either avoid core
`buttons` and manage its own keybind group, or use an add-on scene. Reload clears
an already-poisoned pool. `KelaRegisterGamepadDialog` in
`kpui_core/kpui_dialogs.lua` handles the keybind group for every add-on dialog,
and the audit rejects `ZO_Dialogs_RegisterCustomDialog` outside that file.

### Keybind dispatcher hooks

A secure post-hook on an input dispatcher taints the whole press.
`SecurePostHook` runs the original body through the engine's `PostHookFunction`
trampoline, so every keybind that reaches `ZO_KeybindStrip_HandleKeybindDown`
executes with that frame on the callstack. `ZO_Dialogs_ButtonKeybindPressed`
falls through to the keybind strip when it does not handle the button itself
(`handledButton` is false in its locals), which is why accepting a duel or a
ready check failed inside `ZO_PlayerToPlayer:Accept` ->
`RemoveEntryFromIncomingQueueTable` on the private `CancelTaskbarWindowFlash`.

Do not hook the input dispatchers (`ZO_KeybindStrip_HandleKeybindDown`,
`ZO_KeybindStrip_HandleKeybindUp`, `ZO_KeybindStrip:TryHandlingKeybindDown`);
`_tools/audit_addon.py` rejects them. Register a keybind button group on the
scene that owns the input instead, as `kpui_map_rally.lua` and the Battleground
scoreboard paging in `kpui_features/fixes/kpui_basegame_fixes.lua` do.

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

The audit checks manifest entries, add-on identity, Lua syntax, XML
well-formedness, removed feature references, TODO/FIXME markers, direct `SI_*`
constant assignments, setting ID allocation, version fields, encoding damage,
quoted `GetString` calls, declared optional-library dependencies, unused virtual
templates, and undefined/unused KELA strings. Cyrillic is rejected everywhere
except the localized `kpui_lang` files. It counts any KELA token in Lua/XML as a
reference, so localization IDs passed indirectly are not reported as unused.
The identity check requires the folder name, the manifest filename, `ADDON_NAME`
in the audit, `KelaPadUI.name`, and every `EVENT_MANAGER` namespace to agree; it
also rejects the retired buying/listing saved variables and a
`KELA_MAINMENU_TITLE` that differs between locales.
The setting check rejects IDs outside the `7300`-`7999` Kela block, duplicates,
IDs listed in `KELA_RETIRED_SETTING_IDS`, and settings that are missing from
`KELA_SETTINGS_DATA` or `KELA_SETTINGS_DEFAULTS`; it also prints the next free
ID per block.
The XML check fails on any `.xml` file outside `XML_ALLOWLIST`, which exists so
the frozen legacy XML set can only shrink. The version check requires
`## AddOnVersion` to equal `major*10000 + minor*100 + patch` for `## Version`,
and both to match the top `changelog.txt` version. The encoding check rejects a
UTF-8 BOM or a U+FFFD replacement character in any client-loaded file, and the
`GetString` check rejects the context-free `GetString("KELA_FOO")` form.
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

- opening KelaPadUI Enhanced from the gamepad main menu and confirming it sits
  directly below Options;
- opening Quick Access with the Options keybind, checking section spacing, and
  using Select/Back on each shortcut;
- checking that Rumours opens the correct Journal tab, and that Tome Challenges,
  PVP Veterancy, and Golden Pursuit open from Events and return correctly; check
  seasonal shortcuts are disabled when unavailable;
- leaving Quick Access open through an inventory, mail, level, or daily-reward
  update and confirming its rows and selected position stay in place;
- checking the dashboard's skill-point count after a fresh character login and
  `/reloadui`, with and without USPF; confirm it updates while the menu is open
  and remains N/A if USPF or the required game data is unavailable;
- scrolling the flattened settings list and confirming category headings;
- opening Trait Research with and without LibCharacterKnowledge, switching
  characters with active research, and checking each station's line, trait and
  countdown; verify the right stick scrolls the entire matrix and active list
  without affecting character navigation, including at 1080p;
- starting, cancelling and completing research while the page is open, checking
  countdown refreshes and that empty or unavailable data is not shown as active;
- at a transmute station, search for set names (including Cyrodiil sets), test
  mixed case, no matches, clearing and leaving/re-entering; confirm existing
  locked-item filters and reconstruction selection and Back navigation work;
- repeat set-name searches in Item Set Collections and check the two screens do
  not share queries; disable Additional gamepad filters, reload, and confirm both
  searches disappear while the game's existing filters remain available;
- at provisioning and furnishing stations, check recipe text, quality, CP 150-160,
  Unique Dishes and other-level selections individually and together, including
  no matches, clear/cancel,
  station changes, repeated filter openings, multiple active writs and the game's ingredient, skill and quest filters;
  open the game's own options menu and confirm the same ingredient, skill and
  quest choices are checked, then toggle them natively and confirm this dialog
  reflects them; confirm the choices persist after `/reloadui`, crafting and
  furniture preview still work, and the setting disables the filters;
- search Achievements from both the category root and an achievement list; check
  earned, unearned, in-progress and tracked filters alone and in combination,
  with no matches and achievement chains. Verify both the custom and native
  status choices survive zone changes, but reset after `/reloadui` or logout;
- verify changes apply immediately and Back retains them in all filter dialogs;
  check Antiquities text, difficulty, lead/recovery, codex and native progress
  filters, including combinations, old saved preferences and Clear Filters;
- verify the shared filter shortcut in Antiquities, Achievements, Item Set
  Collections, reconstruction and recipe lists, without disrupting core actions;
- changing and resetting settings, including reload-gated toggles;
- entering the guild store with TTC only, ATT only, both, and neither;
- confirming tooltips, search filters, and trading history;
- checking the Known filter for collectible fragments, books, recipes, and set
  pieces;
- verifying purchased listings disappear without duplicate or misaligned rows;
- switching between gamepad and keyboard UI modes.

## Packaging and release

`python _tools\package_addon.py` builds `dist\KelaPadUIEnhanced-<version>.zip`
with a single top-level `KelaPadUIEnhanced/` folder and verifies that the
manifest and every file it lists are inside. `--check` verifies without keeping
the archive; `--notes` writes the current changelog section for the GitHub release
body, and `--esoui-changelog` writes the whole `changelog.txt` for the ESOUI
changelog field.

`.github/workflows/ci.yml` runs the audit and the packaging check on every push
and pull request. `.github/workflows/release.yml` runs on a `v<version>` tag,
publishes the GitHub release, and uploads the same zip to ESOUI when the
`ESOUI_API_KEY` secret and the `ESOUI_ADDON_ID` variable are configured. See
`docs/RELEASING.md`.

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
   localization files; add removed IDs to `KELA_RETIRED_SETTING_IDS`.
4. Build new UI in Lua; do not add an XML file or an XML-defined control.
5. Run the audit and Lua parse check.
6. Perform the relevant in-game checks.
7. Update `changelog.txt` and keep `## Version`, `## AddOnVersion`, and its top
   version in sync.
8. Add deferred or risky work to `TODO.md` rather than leaving untracked TODOs
   in code.

## Known deferred work

`TODO.md` is the source of truth. The current open items are the trading-house
file split, the replacement of custom controls with supported core
hooks/templates where feasible, and the removal of the seven frozen legacy XML
files. Rated enhancement candidates are in the `Candidate enhancements` section
of `TODO.md`. Ongoing maintenance also includes:

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
