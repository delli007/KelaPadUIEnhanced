# KelaPadUI Enhanced Settings

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

## Setting ID allocation

`SETTING_TYPE_KELA = 7000` is the add-on's private system id. Every setting ID
lives inside it and is stored in `kpuiSavedVariables.settingsAccountWide`; the
numbers are never passed to the ZOS `GetSetting`/`SetSetting` API. They only need
to be unique within this add-on and stable across releases.

| Range | Purpose |
| --- | --- |
| `7000` | `SETTING_TYPE_KELA` (system id, not a setting) |
| `7001`-`7299` | Reserved buffer; do not allocate |
| `7300`-`7399` | Core panels (Journals and Browsers) |
| `7400`-`7499` | Feature toggles |
| `7500`-`7599` | Trading house |
| `7600`-`7699` | Fixes and Patches panel |
| `7700`-`7799` | Account-wide game settings panel |
| `7800`-`7899` | Ability Bar panel |
| `7900`-`7999` | Reserve |

Allocate the lowest free number in the block that owns the feature. IDs are
never reused after a public release; add a retired ID to
`KELA_RETIRED_SETTING_IDS` in `kpui_core/kpui_settings_gamepad.lua`, and the
audit will reject it. The unused feature ID `7405` and the unused
trading ID `7503` are free; remove a number from `KELA_LEGACY_SETTING_IDS` before
assigning it.

### Journals and Browsers

| ID | Constant | Default |
| --- | --- | --- |
| `7304` | `KELA_SETTING_PANEL_JOURNALS` (panel) | - |
| `7301` | `KELA_SETTING_PANEL_SETS_ENABLED` | `true` |
| `7303` | `KELA_SETTING_PANEL_TRAIT_RESEARCH_ENABLED` | `true` |
| `7414` | `KELA_SETTING_PANEL_FEATURES_CHARACTER_KNOWLEDGE` | `true` |
| `7415` | `KELA_SETTING_PANEL_FEATURES_LOOT_LOG` | `true` |
| `7416` | `KELA_SETTING_PANEL_FEATURES_COLLECTIBLES_TRACKER` | `true` |
| `7417` | `KELA_SETTING_PANEL_FEATURES_RAIDIFICATOR` | `true` |
| `7418` | `KELA_SETTING_PANEL_FEATURES_FIGHT_STATS` | `true` |
| `7419` | `KELA_SETTING_PANEL_FIGHT_STATS_PVE` | `true` |
| `7420` | `KELA_SETTING_PANEL_FIGHT_STATS_BATTLEGROUNDS` | `true` |
| `7421` | `KELA_SETTING_PANEL_FIGHT_STATS_KEPT` | `10` (fights, 1-40) |

- One panel for the menu screens: the sets browser, the trait research matrix,
  Character Knowledge, Loot Log, Collectibles Tracker, and Raidificator.
- Each toggle keeps the ID it shipped with, so saved values carry over.
  Character Knowledge keeps its Features-block number.
- The old one-row panels, `7300` (Item sets) and `7302` (Trait research), are
  retired in `KELA_RETIRED_SETTING_IDS`, and so is `7407` (Extended Journal),
  which the three add-on toggles replaced.
- Fight Stats (`7418`-`7421`) lives in `kpui_features/journals/fightstats/` (recording in `kpui_fight_records.lua`).
  - `7418` is the master toggle and needs LibCombat. The rows below it follow it
    (`enabled` is a function). All four fire `KELA_FIGHT_STATS_SETTINGS_CHANGED`,
    so changes apply live, with no reload.
  - `7419` records PvE fights; `7420` records battlegrounds as one entry per
    match. Cyrodiil, Imperial City, Vengeance, and Jerall Pass have no setting
    and are never recorded.
  - `7421` is the number of entries kept (1-40). It is Fight Stats' own and
    never reads or writes Combat Metrics' `fighthistory`. The slider help shows
    an estimate of the memory Fight Stats uses at the current value
    (`BYTES_PER_ENTRY`, about 40 KB per entry).
- The trait research matrix is reload-gated. The sets browser, Character
  Knowledge, Loot Log, Collectibles Tracker, and Raidificator check their
  setting whenever the menu is built.

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

`7407` and `7414` are in the Features block but show in the Journals and
Browsers panel.

All Features toggles except the PS5 button map are reload-gated. The PS5 button
map applies immediately: its checkbox events call `kpuiPS5ButtonMap:SetEnabled`,
and the bootstrap also applies the saved value during `KelaPadUI_OnLoaded()`.
Leaving the KelaPadUI Enhanced options after changing a reload-gated toggle shows a
"reload required" dialog
(`KELA_OPTIONS_RELOAD_REQUIRED`) with Reload UI and Later, so the reload is
requested only once the player is done with the options; the prompt is deferred
off the scene-transition callstack. The PersonalAssistant junk toggle is on by
default and does nothing when PersonalAssistant is not installed or PA's custom
junk rules are disabled.

Additional gamepad filters (`7412`) gates Antiquities, set-name searches in Item
Set Collections and transmute reconstruction, provisioning and furnishing recipe
filters, achievement filters, and future filters.

### Fixes and patches

| ID | Constant | Default |
| --- | --- | --- |
| `7600` | `KELA_SETTING_PANEL_FIXES` (panel) | - |
| `7601` | `KELA_SETTING_PANEL_FIXES_GROUP_MENU` | `true` |
| `7413` | `KELA_SETTING_PANEL_FIXES_BG_U51` | `true` |

Fixes and Patches sits directly below Features in the settings list. Both toggles
are reload-gated.

The group menu fix (`7601`) gates
`kpui_features/fixes/kpui_group_menu_fix.lua`. The gamepad group menu attaches
its "Current Group" panel (the member list plus a background panel) to whichever
scene is current when the list selection changes, so a rebuild while the menu is
closed puts the panel on the HUD scene, where it stays until that scene hides or
the UI reloads. The module registers a `SelectedDataChanged` callback on the
group menu's main list and a `StateChange` callback on `GAMEPAD_GROUP_SCENE`, and
detaches the panel whenever the group scene is not showing. It hooks no core
function.

The U51 BG fixes toggle (`7413`) gates
`kpui_features/fixes/kpui_basegame_fixes.lua`: L2/R2 battle-round paging on the
Battleground scoreboard, correct 6v6v6 / 9v9 scoreboard panel heights, and an
Activity Finder Battleground entry that unlocks as soon as its data loads. The
module mirrors fixes ZOS is preparing and is deliberately standalone; once a game
update ships them, delete the module, its manifest line, and this setting ID.
`7413` keeps the number it shipped with inside the Features panel, so existing
saved values survive the move. The constant was renamed from
`KELA_SETTING_PANEL_FEATURES_BASE_GAME_FIXES`; the label and tooltip keep their
`KELA_SETTINGS_FEATURES_BASE_GAME_FIXES*` string IDs so the generated
translations continue to apply.

### Account-wide game settings

| ID | Constant | Default |
| --- | --- | --- |
| `7700` | `KELA_SETTING_PANEL_ACCOUNT` (panel) | - |
| `7701` | `KELA_SETTING_PANEL_ACCOUNT_SYNC_COMBAT` | `false` |
| `7702` | `KELA_SETTING_PANEL_ACCOUNT_SYNC_CAMERA` | `false` |
| `7703` | `KELA_SETTING_PANEL_ACCOUNT_SYNC_INTERFACE` | `false` |
| `7704` | `KELA_SETTING_PANEL_ACCOUNT_SYNC_NAMEPLATES` | `false` |
| `7705` | `KELA_SETTING_PANEL_ACCOUNT_SYNC_SOCIAL` | `false` |

The rows are listed in the game's Options order (Camera, Interface, Nameplates,
Social, Combat) and built by `KelaAccountSyncRow`, which labels each one with the
game's own panel name.

This panel sits below Fixes and Patches. Its toggles are not reload-gated: each
checkbox fires `KELA_ACCOUNT_SETTINGS_TOGGLED` through its `events` table, and
`kpui_features/kpui_account_settings.lua` acts on the change. That module is the
only code that calls the base-game `GetSetting`/`SetSetting` API, and only with
base-game setting constants, never with Kela IDs. Social and Interface also use
the chat APIs `Get`/`SetChatCategoryColor`, `IsChatBubbleCategoryEnabled` /
`SetChatBubbleCategoryEnabled`, and `Get`/`SetGamepadChatFontSize`.

What each category leaves out, and why:

- **Camera:** inversion, sensitivity, assassination camera, screen shake, and
  siege camera are saved in the client's `UserSettings.txt`, so every character
  on the PC already shares them.
- **Interface:** the text language is a client setting that needs a UI reload.
- **Social:** the keyboard chat text size and minimum opacity are stored per
  chat window by the keyboard chat, and restricted communication is an account
  control.

Each toggle shares one base-game Options category across every character on
the account (last change wins):

- Turning it on copies the current character's values into
  `kpuiSavedVariables.accountGameSettings.categories[<key>].values`.
- At the first `EVENT_PLAYER_ACTIVATED` of a session, values that differ are
  written with `SetSetting`, then `SendAllCachedSettingMessages()` is called.
- The shared copy is re-read when the gamepad Options scenes hide, on
  `EVENT_INTERFACE_SETTING_CHANGED` for the UI, BUFFS, NAMEPLATES, IN_WORLD,
  CAMERA, and CHAT_BUBBLE systems (which covers the HUD editor), and on `EVENT_PLAYER_DEACTIVATED`. Nothing is re-read before
  the login apply has run, so a new character never overwrites the shared copy
  with its old values.
- Saved keys are the constant names (`SETTING_TYPE_UI|UI_SETTING_SHOW_ACTION_BAR`),
  resolved through `_G` at runtime; chat options use `CHAT_COLOR|<category>`,
  `CHAT_BUBBLE|<category>`, and `GAMEPAD_CHAT_FONT_SIZE`. Values are `"1"`/`"0"`
  for booleans, integer strings for lists, formatted numbers for sliders
  (`%.2f` unless the entry sets a format), and `"r,g,b"` for colors. The data is account-wide and shared across NA, EU,
  and PTS.

To add a category, add a `CATEGORIES` entry and its key to `CATEGORY_ORDER` in
that module, allocate the next `77xx` ID with a `KelaAccountSyncRow` row, and list
the settings from the base game's `optionspanel_*_shared.lua`. Skip settings that
use `GetSettingOverride`/`SetSettingOverride`, settings already stored in the
client's `UserSettings.txt` (shared by every character already), and settings
that are per character on purpose (Gameplay appearance options).

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

### Ability Bar

| ID | Constant | Default |
| --- | --- | --- |
| `7800` | `KELA_SETTING_PANEL_ACTIONBAR` (panel) | - |
| `7801` | `KELA_SETTING_PANEL_ACTIONBAR_ENABLED` | `false` |
| `7802` | `KELA_SETTING_PANEL_ACTIONBAR_STACKS` | `true` |
| `7803` | `KELA_SETTING_PANEL_ACTIONBAR_EXPIRY_WARNING` | `3` (seconds, 0 = off) |
| `7804` | `KELA_SETTING_PANEL_ACTIONBAR_RAISE` | `10` (pixels, 0-40) |
| `7805` | `KELA_SETTING_PANEL_ACTIONBAR_SECONDS` (timer numbers) | `false` |
| `7806` | `KELA_SETTING_PANEL_ACTIONBAR_RESOURCE_SHIFT` | `0` (pixels) |
| `7807` | `KELA_SETTING_PANEL_ACTIONBAR_ALWAYS_SHOW` | `false` |
| `7808` | `KELA_SETTING_PANEL_ACTIONBAR_BAR` (timer progress bar) | `true` |
| `7809` | `KELA_SETTING_PANEL_ACTIONBAR_HEALTH_RAISE` | `0` (pixels, -100 to 200) |

The panel sits below Account-Wide Settings.

**`7801` (master switch)**
- Reload-gated. It gates `kpui_features/hud/kpui_action_bar.lua`
  (`KelaSetupActionBar`).
- That module decorates the game's own ability bar; it does not replace it.
  - It adds stack labels on the front buttons (`KelaFrontStack<slot>`) and
    above them for the back row (`KelaBackBarStack<slot>`).
  - It post-hooks `ZO_ActionBarTimer.ApplyAnchor` (raise),
    `ZO_ActionBarTimer.ApplyStyle` (timer mode) and
    `ZO_ActionBarTimer.UpdateFillBar` (expiry color and seconds label).
- The module stays off when Fancy Action Bar+ (`FancyActionBar`) or Action
  Duration Reminder is loaded, since both replace the back row.

**`7802`–`7805`, `7807` and `7808`**
- Shown only while `7801` is on.
- Apply as soon as they change. These rows and `7806` fire
  `KELA_ACTIONBAR_SETTINGS_CHANGED` (checkbox `events`, slider `changedEvent`),
  and both HUD modules refresh on it.
- While the KelaPadUI settings are open, `kpui_features/hud/kpui_hud_preview.lua`
  shows the ability bar and attribute bars behind them, through
  `ZO_ContextualActionBar_AddReference` and `PLAYER_ATTRIBUTE_BARS:ForceShow`.
  The game's "Never" choice for the ability bar still hides it.
- The timer progress bar (`7808`) and the timer numbers (`7805`, still named
  `..._SECONDS`) are independent. The numbers show on a slot with a running
  effect, with or without the bar; with both on they share the strip above the
  front button, so raise the back row a little. The countdown sits at the left
  of the slot and the stack count at the right, at the same height: both hang
  from the front button's top edge (`BACK_LABEL_DROP`, `BACK_TIMER_INSET_X`,
  `BACK_STACK_INSET_X`). The countdown is lifted by `BACK_TIMER_LIFT` (2 px) so its
  smaller text lines up with the count by eye.
- The countdown is formatted like the front bar's timer
  (`ZO_FormatTimeShowUnitOverThresholdShowDecimalUnderThreshold`): whole seconds,
  tenths under 2 s ("1.6"). The text is rebuilt only when the shown value would
  change: each second, then each tenth.
- The stack count font is chosen by measurement, once, from `STACK_FONTS_BACK`
  (largest first): the widest countdown ("8.8") and one digit must fit in the
  slot's width minus both insets and a 3 px gap. The pick and the measured
  widths are logged at Info level (`Action bar: back row text: ...`), so a
  different font or smaller list can be checked from the log.
- Turning the bar off also moves the back row up by the freed space: the slot
  is positioned so the redrawn 3 px border stays where the top edge was with the
  bar, which lifts the icon by 9 px (`GetRaisedOffsetY`).
- Turning the bar off trims the back slot's top 12 px (the timer bar's groove in the
  frame art): the slot and frame get shorter, the frame textures skip those
  rows, and the icon anchors to the top. The frame's 3 px top border is the
  first rows of the same texture, so it is redrawn as its own texture above the
  trimmed frame. The game's `ApplyStyle` undoes the trim; the module re-trims
  after it.
- The raise also survives bar swaps: each swap resets the slide animation to
  the default offset (`PlayBackBarSwapAnimation`), so a post-hook on
  `ZO_ActionBarTimer.ApplySwapAnimationStyle` points it back at the raised one.

**Stack refresh cost**
- Stack labels refresh from events that can arrive many times a second in a
  big fight (slot effect updates, tracked-buff changes, slot updates). They are
  queued and applied at most every 100 ms (`QueueStackRefresh`); settings
  changes and loading screens refresh at once.
- The tracked-buff handler ignores anything that is not a tracked buff on the
  player or whose count did not change, even if its event filter were dropped.

**Timers for stacking skills**
- A tracked buff's expiry (`timeEnding` from `GetUnitBuffInfo` and
  `EVENT_EFFECT_CHANGED`, in `GetFrameTimeSeconds` time; 0 length means no
  expiry) is stored in `buffEnds` / `buffDurationsMS`.
- For a slot whose skill is linked to the buff and has no timer of its own
  (`GetActionSlotEffectTimeRemaining` under the game's 1000 ms minimum), the
  remaining time is fed into the game's own timers: `ActionButton:SetTimer` on
  the front button (its text, with the dimming overlay hidden) and
  `ZO_ActionBarTimer:SetFillBar` on the back row. So the front text, the back
  row bar, numbers, expiry warning, and Always show back row all treat it like
  any other timer.
- The game sets these to 0 whenever a slot's own effect is gone, on swaps, and
  on slot changes; post-hooks on `SetTimer` and `SetFillBar` put the linked
  timer back when called with 0. `kelaLinkedTimer` marks a timer that is ours,
  so a fade only clears ours. Calls that set a time are ignored, which keeps the
  hooks from calling themselves.
- It follows `Show stack counts` (`7802`): off, and the linked timers go away.
- Syncing runs with the stack refresh (at most every 100 ms), not per frame.

**Stack sources**
- The slot's own effect: `GetActionSlotEffectStackCount`. The game shows this
  itself on the front bar when Ability Bar Timers is on.
- Player buffs listed in `STACK_BUFFS` in the module
  (`[buff ID] = { slotted skill IDs }`), such as Seething Fury for Molten Whip
  and Crux for Arcanist skills.
  - Each buff has its own `EVENT_EFFECT_CHANGED` registration, filtered by
    ability ID and the player unit.
  - A debug-level log line names each tracked buff the first time it gains
    stacks, which helps confirm or add IDs.

**`7807` (always show back row)**
- The game shows a back slot only while an effect runs on it. It hides the slot
  in `ZO_ActionBarTimer:ApplyStyle`, `SetupBackRowSlot`, and `UpdateFillBar`
  (when the timer ends). Post-hooks on all three call `ShowIdleSlot`, which
  shows the slot again when it holds a skill. The ultimate slot is left out:
  it only shows while its own effect is running.
- The game's own state still decides whether a slot can show: `timer.active`
  (false on hotbars without a back row), `timer.showBackRowSlot` (the game's
  Ability Bar Timers and Back Row options), and gamepad mode.
- Turning it off hides each idle slot again (`HasValidDuration` is false).

**`7806` (attribute bar shift)**
- Independent of `7801`. It is handled by
  `kpui_features/hud/kpui_resource_bars.lua` (`KelaSetupResourceBars`).
- It moves `ZO_PlayerAttributeMagicka` right and `ZO_PlayerAttributeStamina`
  left by the same amount.
- It re-applies after the base-game HUD manager resets anchors (the
  `"PropagateSettings"` and `"OffsetsChanged"` callbacks).
- A bar the player moved in Edit HUD keeps that position.

**`7809` (health bar height)**
- Independent of `7801`; handled by the same module as `7806`.
- It raises `ZO_PlayerAttributeHealth` by the slider value (a negative value lowers it). The
  siege and shield bars are anchored to the health bar, so they follow; Magicka and Stamina
  are anchored to the group and stay put.
- It only changes the health bar's own anchor offset, so it composes with Edit HUD: moving the
  whole group moves the parent and the offset stays relative to it, and a health bar the player
  moved on its own (after unchecking Combined Resources) keeps its position.
- It re-applies on the same HUD manager callbacks as `7806`.

## Screen structure

The settings scene is `kela_options_root`. It contains one gamepad parametric
list, `self.optionsList`, created from the screen's main list. There is no
category list and no `kela_options_panel` scene.

`KELA_SETTINGS_CATEGORY_ORDER` controls the display order:

```lua
local KELA_SETTINGS_CATEGORY_ORDER =
{
    KELA_SETTING_PANEL_FEATURES,
    KELA_SETTING_PANEL_FIXES,
    KELA_SETTING_PANEL_ACCOUNT,
    KELA_SETTING_PANEL_ACTIONBAR,
    KELA_SETTING_PANEL_JOURNALS,
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

1. **Choose an ID.** Allocate the lowest free number in the feature's block
   (see "Setting ID allocation") and add the constant next to the related group.
   Never reuse a number that has shipped; when a setting is removed, list its ID
   in `KELA_RETIRED_SETTING_IDS`.
2. **Add ordering data.** Add a `{ panel, system, settingId }` entry to
   `KELA_SETTINGS_DATA[panel]` in the desired position. Add `header` only when a
   section heading is needed.
3. **Add control metadata.** Add the control entry to
   `kela_SettingsData[panel][SETTING_TYPE_KELA][settingId]` with:
   - `controlType`;
   - `system`, `panel`, and `settingId`;
   - `text` and `tooltipText`;
   - optional `visible`, `enabled`, `requiresReload`, `requiresText`,
     `addons`, and dependency flags.
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
Sliders do not support `events`; set `changedEvent` to a callback name instead,
and it fires (with no arguments) whenever the slider's value changes.

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
- `addons` lists the other add-ons a setting depends on, using entries from
  `KELA_ADDONS` (each has the add-on's own title and an `isLoaded` check on the
  global the feature reads). Groups, each optional:
  - `required`: shows "found" in green or "not found" in red.
  - `oneOf`: at least one must be loaded (the trading providers). A missing
    entry is red only when none of them is loaded.
  - `optional`: the feature works without it; a missing entry is grey.
  - `conflicts`: the feature stays off while one is loaded; "loaded" is red.

  The status is read each time the tooltip is drawn, so it is current without
  a reload. Add an add-on to `KELA_ADDONS` (and to `## OptionalDependsOn` when
  the feature reads its globals) before using it here.

The information tooltip automatically appends any add-on status, the default
value, the immediate/reload note, and any requirement line.

## Resetting settings

Two gamepad dialogs are registered in
`Kela_GamepadOptions:InitializeSaveReloadDialog()`:

- `KELA_OPTIONS_RESET_TO_SAVED` restores the last saved account-wide values.
- `KELA_OPTIONS_RESET_TO_DEFAULTS` loads `KELA_SETTINGS_DEFAULTS`.

Both refresh the visible options list after applying the reset. The dialogs are
available from the settings keybind strip only when the corresponding dirty
state is true.

## Testing checklist

- Open KelaPadUI Enhanced, then Settings, and confirm all six category headings are
  visible in one scrollable list.
- Confirm `Sets` is visible or hidden according to the Item sets setting,
  `Trait Research` according to the Trait research setting, and that Settings
  still opens when either is disabled.
- Toggle each feature and confirm the tooltip says a reload is required.
- Change the ATT period with the slider and confirm the value is retained.
- Toggle trading tooltip sub-options and confirm dependent options hide/show.
- Reset to saved values and reset to defaults from a dirty state.
- Fully close the settings scene, reload the UI, and confirm values persist.
