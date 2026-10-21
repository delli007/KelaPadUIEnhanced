# KelaPadUI Trading House

This document covers the trading-house compatibility layer, its dependencies,
stored history, settings, and the areas that need re-testing after an ESO
update.

## Dependencies and startup gate

Trading features require both:

- `Tamriel Trade Centre` (TTC) for TTC price data;
- `Arkadius Trade Tools` (ATT) for ATT sales data and guild colors.

`KelaPadUI_OnLoaded()` checks both dependencies and the master setting:

```lua
local hasTradingDependencies = TamrielTradeCentre ~= nil and ArkadiusTradeTools ~= nil
if hasTradingDependencies and IsFeatureEnabled(KELA_SETTING_PANEL_TRADE_ENABLED) then
    KelaInitializeTradingHistory()
    KelaSetupTradingHouse()
    KelaSetupCraftingStation()
elseif not hasTradingDependencies then
    KelaSetSetting(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED, false)
end
```

There is no partial TTC-only or ATT-only mode. If either dependency is missing,
the trading setup is skipped and the master setting is forced off. The trading
settings panel also disables the master checkbox when either dependency is
absent. Re-enabling trading requires both add-ons and a `/reload`.

## Main modules

### `kpui_compat/kpui_tradinghouse_gamepad_updated.lua`

- Replaces or hooks the gamepad trading-house search-result filtering.
- Adds the known-item filter and price-effect/deal rating.
- Adds TTC/ATT-enhanced tooltips in the guild store, bank, vendors, and crafting
  stations.
- Adds ATT statistics, guild statistics, listing rows, quality rows, production
  rows, and crafting-component rows to tooltips.
- Tracks buying confirmation data for the history table through pre/post hooks;
  core dialog text and narration remain ZOS-owned.
- Restores normal paginated search behavior; the old one-page search experiment
  was removed.

### `kpui_compat/kpui_trading_history.lua`

- Owns `kpuiSavedVariables.buyingData` and `kpuiSavedVariables.listingData`.
- Tracks purchased items and player listings.
- Reconstructs sales from ATT and records sold/recalled results.
- Builds `KELA_ATT_GUILD_STAT`, the guild/category statistics used by the tooltip.
- Runs retention cleanup when trading history is initialized.

### `KelaSetupCraftingStation()`

Adds the same price and component data to crafting-station tooltips when the
trading master setting is enabled and TTC/ATT are available.

## Settings

| ID | Purpose |
| --- | --- |
| `7501` | Master trading-interface toggle. Disabled without TTC + ATT. |
| `7502` | ATT analysis period in days, range 1-30, default 15. |
| `7504` | Guild-store tooltips. |
| `7505` | Bank tooltips. |
| `7506` | Vendor/store tooltips. |
| `7507` | Crafting tooltips. |
| `7508` | Guild statistics module. |
| `7509` | ATT price information module. |
| `7510` | Player listing rows. |
| `7511` | Quality/price comparison rows. |
| `7512` | Production/result rows. |
| `7513` | Crafting-component rows. |

The retired one-page search setting was `7503`. Do not reuse it.

Most sub-options are visible only when the master setting is on and at least one
tooltip surface is enabled. `gamepadHasEnabledDependencies` refreshes the list so
dependent controls appear or disappear immediately.

## Search behavior

The current guild-store search uses the normal ESO pagination:

- `FilterScrollList` walks `TRADING_HOUSE_SEARCH:GetNumItemsOnPage()` and applies
  the known-item filter and price-effect filter to the current page.
- `RefreshPagingControls` preserves the page buttons, page number, and the
  filtered-result count. It does not combine pages.
- Left/right trigger keybinds page through results.
- The preview keybind remains available through the core visibility callback.
- The previous item is removed from the current result list after a successful
  purchase, and the core response handler refreshes the page.

Search tooltip/header controls show the current known-item mode and the current
price-effect selection.

## History storage and retention

Trading history lives in the existing `kpuiSavedVariables` file:

| Table | Contents |
| --- | --- |
| `kpuiSavedVariables.buyingData.buyingTable` | Purchases keyed by item unique ID. |
| `kpuiSavedVariables.listingData.listingTable` | Listings keyed by listing timestamp. |
| `kpuiSavedVariables.listingData.guildsTable` | Known guild names and listing state. |

- Buying history is retained for 30 days.
- Listing history is retained for 30 days.
- Cleanup runs in `KelaInitializeTradingHistory()`.
- ATT sales are used to mark listings as sold/recalled and to rebuild guild
  statistics.

Do not store history in new top-level saved variables. Keeping it under
`kpuiSavedVariables` preserves the manifest's single saved-variable declaration.

## Guild statistics

`KelaUpdateGuildATTStat()` rebuilds `KELA_ATT_GUILD_STAT` from ATT sales whose
timestamps fall inside the configured analysis period. Sales are grouped by:

- trade category, using the `KELA_TRADE_CATEGORY_*` constants and
  `ITEM_TYPE_TO_CATEGORY_MAP`;
- guild name;
- total price and quantity.

The tooltip reads this table for guild-stat rows. If ATT sales tables are not
available yet, the update returns false and the setup retry handles it later.

## Testing checklist

Test with both TTC and ATT installed and up to date:

- Open the guild store and confirm the known-item filter cycles and the result
  count/page number update.
- Confirm the known-item filter treats books, recipes, set pieces, owned
  collectibles, and locked combination fragments correctly.
- Confirm the price-effect/deal filter cycles and does not hide the page
  controls.
- Buy an item and confirm it disappears from the current page, appears in buying
  history, and survives a reload.
- List an item, then confirm it appears in listing history.
- Check a sold and a recalled listing when ATT data is available.
- Open the bank, a vendor, a crafting station, and the guild store and confirm
  the enabled tooltip sections appear.
- Change the ATT analysis period and confirm the guild-stat period changes.
- Disable each tooltip module and confirm only that section disappears.
- Remove or disable TTC or ATT, reload, and confirm trading is forced off with
  no Lua errors.

Also test the failure path with only one dependency installed. The add-on should
not attempt to call TTC/ATT APIs and should leave the master setting off.

## Known deferred work

See `OPTIMIZATION_TODO.md` for the trading-house backlog. The `KPUI_*` XML
templates are bespoke gamepad tooltip layouts; only `KPUI_Graph` overrides an
ATT template. The remaining work is to:

- re-test all price, sales, category, and graph data after each ESO update;
- keep the ATT graph override under review if ATT adds a supported extension
  point;
- replace other core overrides only where a supported hook exists.

The old one-page search code was removed rather than repaired. If it is ever
reintroduced, design it as an explicit opt-in feature with its own tested search
path; do not reuse setting ID `7503` without migrating old values.
