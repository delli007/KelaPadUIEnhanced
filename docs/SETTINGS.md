# KelaPadUI Settings

This document covers the gamepad settings screen, the account-wide settings
store, the current setting IDs, and the steps for adding or retiring a setting.

## Storage model

Settings are stored in the `kpuiSavedVariables` saved variable. The add-on uses
the account-wide table under `settingsAccountWide` and keeps three views in
memory:

| Global | Role |
| --- | --- |
| `kpuiSVSettingsDefault` | Defaults created by `ZO_SavedVars`. |
| `kpuiSVSettingsSaved` | Last saved account-wide values. |
| `kpuiSVSettingsCurrent` | Working copy changed by the UI. |

`KelaInitializeSettings()` creates the saved-variable store with version `0.52`,
rebuilds it when the stored version does not match, and then calls
`ApplyMissingSettingDefaults()` on all three views. Missing values are filled
from `KELA_SETTINGS_DEFAULTS` without overwriting user choices.

Changes are held in `kpuiSVSettingsCurrent`. The root settings scene saves them
when it is hidden. The reset dialogs either restore the last saved values or
load defaults. Do not write settings directly into the saved-variable table from
feature code; use `KelaSetSetting()`.

## Reading and writing

```lua
KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_FEATURES_COMPANION)
KelaGetSetting_Number(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ATT_PERIOD)
KelaSetSetting(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ATT_PERIOD, "20", true)
```

- `KelaGetSetting_Bool` accepts booleans, `"true"`/`"t"`/`"1"`/`"y"`, and
  numbers greater than zero.
- `KelaGetSetting_Number` converts string values with `tonumber`.
- `KelaSetSetting` stores strings. The third argument is the value; the fourth
  saves immediately when true.
- The ATT analysis period has a side effect: changing it calls
  `KelaUpdateGuildATTStat()`.

## Current setting IDs

The base setting type is `SETTING_TYPE_KELA = 7000`.

### Item sets

| ID | Constant | Default |
| --- | --- | --- |
| `7300` | `KELA_SETTING_PANEL_SETS` (panel) | - |
| `7301` | `KELA_SETTING_PANEL_SETS_ENABLED` | `true` |

### Trait research

| ID | Constant | Default |
| --- | --- | --- |
| `7302` | `KELA_SETTING_PANEL_TRAIT_RESEARCH` (panel) | - |
| `7303` | `KELA_SETTING_PANEL_TRAIT_RESEARCH_ENABLED` | `true` |

The trait research matrix is reload-gated. Its help text is built in
`RefreshOptionsList()` (not from the static metadata) so the
`LibCharacterKnowledge` line reports "available" in light green or "not found"
in light red on every open.

### Features

| ID | Constant | Default |
| --- | --- | --- |
| `7400` | `KELA_SETTING_PANEL_FEATURES` (panel) | - |
| `7401` | `KELA_SETTING_PANEL_FEATURES_COMPANION` | `true` |
| `7402` | `KELA_SETTING_PANEL_FEATURES_DUNGEON_FINDER` | `true` |
| `7403` | `KELA_SETTING_PANEL_FEATURES_CHAT_TOOLS` | `true` |
| `7404` | `KELA_SETTING_PANEL_FEATURES_MAP_RALLY` | `true` |
| `7406` | `KELA_SETTING_PANEL_FEATURES_ANTIQUITY_LEADS` | `true` |
| `7408` | `KELA_SETTING_PANEL_FEATURES_MAIN_MENU_SHORTCUTS` | `true` |
| `7409` | `KELA_SETTING_PANEL_FEATURES_MAIN_MENU_DASHBOARD` | `true` |
| `7410` | `KELA_SETTING_PANEL_FEATURES_PA_JUNK` | `true` |
| `7411` | `KELA_SETTING_PANEL_FEATURES_PS5_BUTTONS` | `false` |
| `7412` | `KELA_SETTING_PANEL_FEATURES_GAMEPAD_FILTERS` | `true` |
| `7413` | `KELA_SETTING_PANEL_FEATURES_BASE_GAME_FIXES` | `true` |

All Features toggles except the PS5 button map are reload-gated. The PS5 button
map applies immediately: its checkbox events call `kpuiPS5ButtonMap:SetEnabled`,
and the bootstrap also applies the saved value during `KelaPadUI_OnLoaded()`.
Leaving the KelaPadUI options after changing a reload-gated toggle shows a
"reload required" dialog
(`KELA_OPTIONS_RELOAD_REQUIRED`) with Reload UI and Later, so the reload is
requested only once the player is done with the options; the prompt is deferred
off the scene-transition callstack. The PersonalAssistant junk toggle is on by
default and does nothing when PersonalAssistant is not installed or PA's custom
junk rules are disabled.

Additional gamepad filters (`7412`) gates Antiquities, set-name searches in Item
Set Collections and transmute reconstruction, provisioning and furnishing recipe
filters, achievement filters, and future filters. The former Antiquity filters
setting `7405` is retired; existing saved filter preferences remain available.

Base game fixes (`7413`) gates `kpui_features/kpui_basegame_fixes.lua`: L2/R2
battle-round paging on the Battleground scoreboard, correct 6v6v6 / 9v9
scoreboard panel heights, and an Activity Finder Battleground entry that
unlocks as soon as its data loads. The module mirrors fixes ZOS is preparing and
is deliberately standalone; once a game update ships them, delete the module,
its manifest line, and this setting ID.

The Companion information toggle (`7401`) also gates the extra details in the
gamepad Collections > Allies > Companions tooltip
(`kpui_features/companion/kpui_companion_collections.lua`). That module stores build
snapshots account-wide in `kpuiSavedVariables.companionSnapshots.builds` and
rapport snapshots per character in
`kpuiSavedVariables.companionSnapshots.rapport[characterId]`; it adds no
separate setting.

### Trading Interface

| ID | Constant | Default |
| --- | --- | --- |
| `7500` | `KELA_SETTING_PANEL_TRADE` (panel) | - |
| `7501` | `KELA_SETTING_PANEL_TRADE_ENABLED` | `true` |
| `7502` | `KELA_SETTING_PANEL_TRADE_ATT_PERIOD` | `15` |
| `7504` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_TRADINGHOUSE` | `true` |
| `7505` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_BANK` | `true` |
| `7506` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_STORE` | `true` |
| `7507` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_CRAFTING` | `true` |
| `7508` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_GUILDSTAT` | `true` |
| `7509` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_ATTINFO` | `true` |
| `7510` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_LISTINGS` | `true` |
| `7511` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_QUALITY` | `true` |
| `7512` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_PRODUCTION` | `true` |
| `7513` | `KELA_SETTING_PANEL_TRADE_TOOLTIP_COMPONENTS` | `true` |

`7503` was the one-page guild-store search setting. It was nonfunctional and has
been removed. Do not reuse that ID.

The old pause-menu notes feature used `7100`-`7104`; those IDs are also retired.
Do not reuse them.

## Screen structure

The settings scene is `kela_options_root`. It contains one gamepad parametric
list, `self.optionsList`, created from the screen's main list. There is no
category list and no `kela_options_panel` scene.

`KELA_SETTINGS_CATEGORY_ORDER` controls the display order:

```lua
local KELA_SETTINGS_CATEGORY_ORDER =
{
    KELA_SETTING_PANEL_FEATURES,
    KELA_SETTING_PANEL_TRAIT_RESEARCH,
    KELA_SETTING_PANEL_SETS,
    KELA_SETTING_PANEL_TRADE,
}
```

`RefreshOptionsList()` clears the list and calls:

```lua
self:AddSettingGroup(panelId, GetString("KELA_SETTINGSYSTEMPANEL", panelId))
```

The category name is attached as the header of the first visible setting in
that group. A setting can still define its own `header` for a section inside a
group, such as `KELA_SETTING_TRADE_TOOLTIP_HEADER`. Do not give the first
setting in a group its own header unless the category header is intentionally
being replaced.

The screen uses:

- `self.keybindStripDescriptor` for dismiss/default/back actions;
- `self.optionsKeybindDescriptor` for list triggers;
- `self.primaryActionDescriptor` for the selected option's primary action.

The primary action keybind is added or removed as selection changes. It toggles
checkboxes, opens color pickers, or invokes callbacks.

## Adding a setting

1. **Choose an ID.** Add a constant next to the related group and leave gaps
   alone. Never reuse a retired ID.
2. **Add ordering data.** Add a `{ panel, system, settingId }` entry to
   `KELA_SETTINGS_DATA[panel]` in the desired position. Add `header` only when a
   section heading is needed.
3. **Add control metadata.** Add the control entry to
   `kela_SettingsData[panel][SETTING_TYPE_KELA][settingId]` with:
   - `controlType`;
   - `system`, `panel`, and `settingId`;
   - `text` and `tooltipText`;
   - optional `visible`, `enabled`, `requiresReload`, `requiresText`, and
     dependency flags.
4. **Add a default.** Add the value to `KELA_SETTINGS_DEFAULTS` as a string.
5. **Add English text.** Add every new `KELA_*` string to `kpui_lang/en.lua`;
   it is the add-on's only locale file.
6. **Gate load-time code.** If the setting is checked once during
   `KelaPadUI_OnLoaded()`, add the check to the bootstrap and set
   `requiresReload = true`.
7. **Run the audit and parse check.** See `docs/MAINTENANCE.md`.
8. **Test in game.** Confirm the control appears in the right category, the
   tooltip shows the default and reload/apply text, and the value survives a
   reload.

### Checkbox example

```lua
[KELA_SETTING_PANEL_FEATURES_NEW] =
{
    controlType = OPTIONS_CHECKBOX,
    system = SETTING_TYPE_KELA,
    panel = KELA_SETTING_PANEL_FEATURES,
    settingId = KELA_SETTING_PANEL_FEATURES_NEW,
    text = KELA_SETTINGS_FEATURES_NEW,
    tooltipText = KELA_SETTINGS_FEATURES_NEW_TOOLTIP,
    requiresReload = true,
},
```

### Slider notes

Sliders use `OPTIONS_SLIDER` and must define `minValue` and `maxValue`. Use
`gamepadValueStep` for an absolute step or `gamepadValueStepPercent` for a
percentage step. `showValue` appends the current value to the label.
`valueFormat` controls the displayed value; the ATT period uses `"%d"`.

Read the ATT analysis period through `KelaGetATTAnalysisPeriod()`. It falls back
to the default of 15 days and clamps the result to the supported 1-30 range, so
old or malformed saved values cannot produce an invalid ATT query window.

### Visibility and dependencies

- `visible` can be a boolean or a function. A function is evaluated each time
  the list is refreshed.
- `enabled` can be a boolean or a function. It greys out a control without
  hiding it.
- `gamepadHasEnabledDependencies = true` tells the screen to refresh the list
  after the checkbox changes, revealing or hiding dependent controls.
- `requiresText` adds a custom requirement line to the tooltip. It can be a
  string or a localization ID.

The information tooltip automatically appends the default value, the
immediate/reload note, and any requirement line.

## Resetting settings

Two gamepad dialogs are registered in
`Kela_GamepadOptions:InitializeSaveReloadDialog()`:

- `KELA_OPTIONS_RESET_TO_SAVED` restores the last saved account-wide values.
- `KELA_OPTIONS_RESET_TO_DEFAULTS` loads `KELA_SETTINGS_DEFAULTS`.

Both refresh the visible options list after applying the reset. The dialogs are
available from the settings keybind strip only when the corresponding dirty
state is true.

## Testing checklist

- Open KelaPadUI, then Settings, and confirm all four category headings are
  visible in one scrollable list.
- Confirm `Sets` is visible or hidden according to the Item sets setting,
  `Trait Research` according to the Trait research setting, and that Settings
  still opens when either is disabled.
- Toggle each feature and confirm the tooltip says a reload is required.
- Change the ATT period with the slider and confirm the value is retained.
- Toggle trading tooltip sub-options and confirm dependent options hide/show.
- Reset to saved values and reset to defaults from a dirty state.
- Fully close the settings scene, reload the UI, and confirm values persist.
