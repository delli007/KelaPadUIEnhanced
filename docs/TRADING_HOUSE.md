# KelaPadUI Trading House

This document covers the trading-house compatibility layer, its dependencies,
stored history, settings, and the areas that need re-testing after an ESO
update.

## Dependencies and startup gate

Trading features use either or both of these optional data providers:

- `Tamriel Trade Centre` (TTC) for TTC price data;
- `Arkadius Trade Tools` (ATT) for ATT sales data and guild colors.

`KelaPadUI_OnLoaded()` checks for at least one provider and the master setting:

```lua
local hasTradingProvider = TamrielTradeCentre ~= nil or ArkadiusTradeTools ~= nil
if hasTradingProvider and IsFeatureEnabled(KELA_SETTING_PANEL_TRADE_ENABLED) then
    KelaInitializeTradingHistory()
    KelaSetupTradingHouse()
    KelaSetupCraftingStation()
elseif not hasTradingProvider then
    KelaSetSetting(SETTING_TYPE_KELA, KELA_SETTING_PANEL_TRADE_ENABLED, false)
end
```

TTC-only and ATT-only modes are supported. The trading settings panel enables
the master checkbox when at least one provider is installed, and provider-specific
settings are hidden when their provider is absent. Re-enabling trading after
installing a provider requires a `/reload`.

The other-quality price rows need valid item links for each quality. They use
the optional `LibItemLink` library to build those links; the call is guarded, and
the rows are skipped when the library is not installed. `LibItemLink` is listed
in `OptionalDependsOn` so it loads before KelaPadUI when present.

When only one provider is available, that provider supplies the recommended
price and deal rating. When both are available, the recommended price uses their
average where both have data. Tooltip columns for a missing provider show `N/A`.
ATT-only features such as the sales graph and guild statistics require ATT; with
TTC only, they are hidden and the core guild-selection dialog remains in use.
The `KPUI_Graph` control is a plain custom template that creates an ATT graph
child at runtime only when ATT is present, so the XML does not depend on ATT's
templates at load time.

## Main modules

### `kpui_compat/kpui_tradinghouse_gamepad_updated.lua`

- Replaces or hooks the gamepad trading-house search-result filtering.
- Adds the known-item filter and price-effect/deal rating.
- Adds TTC/ATT-enhanced tooltips in the guild store, bank, vendors, and crafting
  stations.
- Adds ATT statistics, guild statistics, listing rows, quality rows, production
  rows, and crafting-component rows to tooltips.
- Tracks buying, listing, and removal history through the copied confirmation
  dialogs; core dialog text and narration remain ZOS-owned.
- Restores normal paginated search behavior; the old one-page search experiment
  was removed.

#### Confirmation dialogs

KelaPadUI keeps copies of `TRADING_HOUSE_CONFIRM_BUY_ITEM`,
`TRADING_HOUSE_CONFIRM_SELL_ITEM`, and `TRADING_HOUSE_CONFIRM_REMOVE_LISTING`
because their confirmation actions call C API functions that cannot be hooked
for history updates. The copies mirror the current core fields, and the sell
callback uses the current four-argument `RequestPostItemOnTradingHouse`
signature.

`ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog` remains core-owned,
so `mainTextParams`, `mainTextNarrationParams`, display quality, and icon
handling stay intact. Core's `TRADING_HOUSE_CONFIRM_BUY_GUILD_SPECIFIC_ITEM` and
`TRADING_HOUSE_DISPLAY_ERROR` dialogs are not copied; guild-specific-store
purchases are not added to Kela buying history. This is intentional: the core
guild-specific item data has no item unique ID to key a history row.

### `kpui_compat/kpui_trading_history.lua`

- Owns `kpuiSavedVariables.buyingData` and `kpuiSavedVariables.listingData`.
- Tracks purchased items and player listings.
- Reconstructs sales from ATT when available and records sold/recalled results.
- Builds `KELA_ATT_GUILD_STAT`, the guild/category statistics used by the tooltip when ATT is available.
- Runs retention cleanup when trading history is initialized.

### `KelaSetupCraftingStation()`

Adds the same price and component data to crafting-station tooltips when the
trading master setting is enabled and at least one provider is available. ATT
crafting-component rows require ATT.

## Settings

| ID | Purpose |
| --- | --- |
| `7501` | Master trading-interface toggle. Disabled without TTC or ATT. |
| `7502` | ATT analysis period in days, range 1-30, default 15. Visible only with ATT. |
| `7504` | Guild-store tooltips. |
| `7505` | Bank tooltips. |
| `7506` | Vendor/store tooltips. |
| `7507` | Crafting tooltips. |
| `7508` | Guild statistics module. Visible only with ATT. |
| `7509` | ATT price information module. Visible only with ATT. |
| `7510` | Player listing rows. |
| `7511` | Quality/price comparison rows. |
| `7512` | Production/result rows. |
| `7513` | Crafting-component rows. Visible only with ATT. |

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

Test the same flows with TTC only, ATT only, both providers, and neither
provider installed:

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
- Hover an armor, weapon, or glyph in the bank and guild store and confirm the
  other-quality rows appear without a Lua error when LibItemLink is installed;
  confirm they are skipped cleanly when it is absent.
- With TTC only, confirm TTC prices and ratings appear, ATT rows show `N/A`, and
  no ATT graph or guild-stat section is created.
- With ATT only, confirm ATT prices and ratings appear, TTC and average rows show
  `N/A`, and the ATT graph and guild statistics work.
- With both, confirm the average recommendation appears when both providers have
  data and falls back to the available provider otherwise.
- Change the ATT analysis period when ATT is installed and confirm the
  guild-stat period changes.
- Disable each tooltip module and confirm only that section disappears.
- Remove both providers, reload, and confirm trading is forced off with no Lua
  errors.

## Known deferred work

See `OPTIMIZATION_TODO.md` for the trading-house backlog. The `KPUI_*` XML
templates are bespoke gamepad tooltip layouts. `KPUI_Graph` no longer inherits an
ATT template: it creates an ATT graph child at runtime only when ATT is present.
The remaining work is to:

- re-test all price, sales, category, and graph data after each ESO update;
- keep the ATT graph child creation under review if ATT adds a supported
  extension point;
- replace other core overrides only where a supported hook exists.

The old one-page search code was removed rather than repaired. If it is ever
reintroduced, design it as an explicit opt-in feature with its own tested search
path; do not reuse setting ID `7503` without migrating old values.
