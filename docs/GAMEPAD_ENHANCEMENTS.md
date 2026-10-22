# KelaPadUI Gamepad Enhancement Research

This document records possible gamepad improvements and integrations with other
ESO addons. It is research input for `TODO.md`, not a commitment to implement
everything here.

Research snapshot: October 2026. ESOUI pages and addon status can change after
an ESO update, so re-check dependencies before starting work.

## Constraints

Any candidate must preserve the current KelaPadUI invariants:

- TTC and ATT remain independent optional providers; TTC-only, ATT-only, both,
  and neither must work.
- Keep the five tooltip types, `QUAD1*` styles, and `getStyleHeaderLine`.
- Keep the flattened settings list and retired IDs `7503` and `7100`-`7104`.
- Keep the KELAPADUI main-menu entry append-only.
- Do not add guild-specific purchases to Kela buying history.
- Do not reintroduce lazy loading, performance profiling, or caching work.
- `LibSets` stays required; `LibItemLink` stays optional and guarded.
- Do not replace the custom trading controls in the same pass as an unrelated
  feature.

## What KelaPadUI already covers

Avoid duplicating these existing features:

- Enhanced gamepad item and trading tooltips.
- Set browser and set information.
- Antiquities filters and lead information.
- Trading history, TTC/ATT price rows, deal ratings, and listing profit.
- Companion rapport information and notifications.
- Dungeon-finder pledge names and chat pledge summaries.
- Chat commands, achievement links, and player context-menu actions.
- Gamepad group rally point on the world map.

## Rating scale

Usefulness:

- **5** - broad, recurring gamepad pain point or a strong fit for the existing
  KelaPadUI feature set.
- **4** - valuable for a large group of players, but narrower than the top tier.
- **3** - useful niche or quality-of-life improvement.
- **2** - minor convenience.
- **1** - low value.

Difficulty:

- **1** - small local hook or menu entry; low regression risk.
- **2** - a few hooks or an existing pattern; moderate testing.
- **3** - new panel/scene or a third-party API; needs careful integration and
  in-game testing.
- **4** - several external addons, core gamepad UI changes, or high regression
  risk.
- **5** - blocked by API limitations or unsafe to maintain.

## Ranked candidates

| # | Candidate | Usefulness | Difficulty | Integration shape |
| --- | --- | --- | --- | --- |
| 1 | Main-menu quick shortcuts | 4 | 1 | Add append-only KelaPadUI submenu entries for Journal, Mail, Craft Bag, Sticker Book, Activity Finder, Armory, and Companions. Reuse existing scenes. |
| 2 | Gamepad narration and accessibility pass | 4 | 2 | Add narration text and predictable focus order to Kela tooltips, sets, antiquity, and trading panels. No new saved data. |
| 3 | Gamepad chat and social quick actions | 4 | 2 | Extend the existing LibCustomMenu work to gamepad chat/player menus: travel, mail, whisper, invite, and copy name. |
| 4 | Research and trait knowledge integration | 5 | 3 | Optional `LibTraitResearch`, Character Knowledge, or TraitBuddy bridge for researchable/known/in-progress/duplicate traits in inventory and tooltips. Do not restore the old dead shim or store a second research database. |
| 5 | Gamepad inventory quality-of-life badges | 5 | 3 | Mark junk, show price, set-collection state, research, ornate, and intricate badges in gamepad inventory and deconstruction views. Hook the existing list; do not replace the inventory UI. |
| 6 | Daily activities dashboard | 5 | 3 | Add a gamepad panel for pledges, writs, Endeavors, events, and companion rapport. Kela already calculates pledges; this exposes them outside chat. |
| 7 | Additional price providers | 5 | 3 | Add optional Master Merchant, ESO-Hub, or LibPrice-backed price sources alongside TTC/ATT. Use capability checks and clear source labels; never make TTC/ATT depend on the new source. |
| 8 | Trading listing assistant | 4 | 3 | Add sales velocity, undercut warning, stack-size suggestion, and source comparison to the existing listing price/profit UI. |
| 9 | Map intel panel | 4 | 3 | Read-only zone summary for surveys, treasure maps, antiquities, chests, and points of interest; optionally read Map Pins/HarvestMap data. |
| 10 | Build and gear quick-swap | 4 | 3 | Add a main-menu entry for Bandits Gear Manager, Armory, or a supported gear-manager callback. Start with read-only build names and a swap action. |
| 11 | Crafting and writ helper integration | 4 | 4 | Read-only writ requirements, craftability, and turn-in checklist in gamepad crafting/tooltips; integrate WritWorthy, Lazy Writ Crafter, or CraftStore data. No automation. |
| 12 | Guild trader kiosk intel | 4 | 4 | Show guild names at kiosks, item availability, and trader bid/activity data. GamePadHelper already demonstrates kiosk-name demand; data access is the hard part. |
| 13 | Group and combat integration | 4 | 4 | Read-only ultimate-ready, role, and combat-alert information via HodorReflexes, Code's Combat Alerts, or CrutchAlerts. Keep it optional and performance-safe. |
| 14 | Companion gear and loadout | 3 | 3 | Add companion gear comparison and quick-swap alongside the existing rapport panel. Niche, but fits the current companion feature. |
| 15 | Localization and controller glyphs | 3 | 2 | Add DE/FR/RU strings and Xbox/PS/Switch button glyph selection. String volume is the main cost. |
| 16 | Fishing and maintenance QoL | 3 | 2 | Optional fishing bite vibration/reel alert, auto-repair, and auto-charge toggles. GamePadHelper proves demand, but this overlaps an existing addon. |
| 17 | Guild roster and social tools | 3 | 3 | Sort/filter by rank, last online, and sales; quick invite, whisper, and mail from the gamepad roster. |
| 18 | Housing tools | 2 | 4 | Essential Housing Tools-style shortcuts or furnishing search. Niche and high integration cost; park unless requested. |

## Why the top candidates are recommended

### 1. Main-menu quick shortcuts (`4/1`)

The gamepad menu already exposes many top-level destinations, but players
regularly ask for faster access to Journal, Mail, Craft Bag, and collection
screens. Gamepad UI Tweaks explicitly added standalone Journal shortcuts, which
confirms the demand. This is the lowest-risk improvement because it reuses
existing scenes and the existing append-only menu pattern.

### 2. Narration and accessibility (`4/2`)

GamePadHelper advertises gamepad screen narration, and FCO Accessibility shows
that narration is a real user need. KelaPadUI's custom controls are a gap: core
gamepad screens narrate, but custom Kela scenes may not. Start with the five
tooltip types and the sets/antiquities panels; do not attempt a general
accessibility framework.

### 3. Chat and social quick actions (`4/2`)

KelaPadUI already registers player context-menu actions through LibCustomMenu,
and ControllerTweaks adds quick travel from controller chat. Extending the same
actions to the gamepad chat/player list is a natural, low-risk fit.

### 4. Research and trait knowledge (`5/3`)

Research indicators are one of the most repeated gamepad inventory requests:
BetterUI advertised a research tracker, GamePadHelper has an Inventory Trait
module, TraitBuddy supports gamepad mode, and Character Knowledge tracks traits
across characters. KelaPadUI removed its old trait block because it had no data
source; a supported optional library is the correct replacement, not a revival
of the old shim.

Recommended scope:

- Optional dependency; no Lua error when the library is absent.
- Read-only indicators in inventory and tooltips.
- No Kela-owned research saved variables.
- Respect the existing `LibItemLink` optional pattern.

### 5. Inventory quality-of-life badges (`5/3`)

BetterUI, ControllerTweaks, and GamePadHelper all converge on the same missing
gamepad conveniences: junk marking, research indicators, and price/set context.
This is a strong fit for KelaPadUI's information-first design, but it touches a
core list with many other addons. Implement it behind separate settings and test
alongside BetterUI, GamePadHelper, and Auto Category.

### 6. Daily activities dashboard (`5/3`)

KelaPadUI already computes daily pledges but prints them to chat. A gamepad
dashboard is a natural extension and matches the popularity of GamePadHelper's
Overview, CQuestTracker, and Daily Quest Tracker. Start with pledges and writs,
then add Endeavors/events only where the API is reliable.

### 7. Additional price providers (`5/3`)

TTC and ATT are the current providers. Master Merchant 3.0 remains popular and
has gamepad listing fixes; LibPrice advertises a unified MM/ATT/TTC interface,
but its manifest has lagged the live API, so it should be an optional bridge
rather than a hard dependency. ESO-Hub Trading is another current price source
worth monitoring. Keep source labels visible so users know which provider
produced a price.

## Lower-priority or parked ideas

- **Full inventory replacement**: BetterUI's full gamepad inventory is
  historically popular, but it is a large UI replacement with high conflict and
  maintenance risk. Do not copy that approach.
- **FCO ItemSaver marks**: FCO ItemSaver explicitly does not support the
  gamepad UI. Do not build a gamepad feature around FCOIS marks unless FCOIS
  adds support.
- **Lazy loading, caching, or performance profiling**: previously reverted or
  explicitly out of scope. Do not reopen.
- **Guild-specific purchase history**: intentionally excluded because the core
  guild-specific item data has no `itemUniqueId` for a history row.
- **Housing/EHT integration**: niche and expensive; park unless there is clear
  demand.

## Suggested implementation order

1. Main-menu shortcuts (`4/1`).
2. Narration/accessibility pass (`4/2`).
3. Chat/social quick actions (`4/2`).
4. Research/trait integration (`5/3`).
5. Inventory badges (`5/3`).
6. Daily dashboard (`5/3`).
7. Price providers (`5/3`).
8. Re-evaluate trading and map ideas after the trading-house split.

Each item should be a separate focused change with its own setting and in-game
validation. Do not combine inventory, trading, and accessibility work in one
commit.

## Sources reviewed

- ESOUI Game Controller category (61 addons; top downloads include LibMapPins,
  CustomCompassPins, HodorReflexes, CQuestTracker, and GamePadHelper):
  https://www.esoui.com/downloads/cat162.html
- GamePadHelper (map search, fishing, auto-repair/charge, gear comparison,
  tooltip and inventory trait features):
  https://www.esoui.com/downloads/info3268-GamePadHelper.html
- Gamepad UI Tweaks (main-menu visibility, Journal shortcuts, attribute bars,
  language, controller glyphs):
  https://www.esoui.com/downloads/info4442-GamepadUITweaks.html
- BetterUI gamepad inventory (Mark as Junk, research tracker, market pricing):
  https://esoui.com/downloads/info1272-
- ControllerTweaks (junk/research indicators, quick travel from controller
  chat):
  https://www.esoui.com/downloads/info2517-ControllerTweaks.html
- CQuestTracker (gamepad quest journal and tracker improvements):
  https://www.esoui.com/downloads/info3276-CQuestTracker.html
- LibPrice (unified Master Merchant, ATT, and TTC price access):
  https://www.esoui.com/downloads/info2204-LibPrice.html
- Master Merchant 3.0 (gamepad listing fixes and pricing data):
  https://www.esoui.com/downloads/info2753-MasterMerchant3.0.html
- BeamMeUp (gamepad fast-travel support):
  https://www.esoui.com/downloads/info2143-BeamMeUp-TeleporterFastTravel.html
- Bandits Gear Manager (gear-manager callbacks and radial menu):
  https://www.esoui.com/downloads/info2218-BanditsGearManager.html
- TraitBuddy (gamepad-supported research/motif tracking):
  https://www.esoui.com/downloads/info1058-TraitBuddy.html
- Character Knowledge (cross-character trait research tracking):
  https://www.esoui.com/downloads/info2938-CharacterKnowledge.html
- Map Pins (gamepad pin tooltips and map data):
  https://cdn.esoui.com/downloads/info1881-MapPins.html
- Auto Category - Revised (gamepad inventory categories and addon plugin API):
  https://www.esoui.com/downloads/info2300-AutoCategory-Revised.html
- FCO ItemSaver (explicitly states the gamepad UI is not supported):
  https://www.esoui.com/downloads/info630-FCOItemSaver.html
- ESO-Hub Trading (current crowdsourced price source):
  https://www.esoui.com/downloads/info4095-ESO-HubTrading
- Daily Quest Tracker (gamepad-supported daily activity overview):
  https://mods.bethesda.net/en/elderscrollsonline/details/a84f8a0c-210f-481a-b8a7-6dc95bff7664/Daily_Quest_Tracker
