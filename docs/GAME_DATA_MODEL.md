# Game Data Model

This document captures the current gameplay data contract derived from:
- `Infrastructure_Tiles.csv`
- `Special_Tiles.csv`
- `Synergy.txt`
- the current architecture/protocol docs
- the user-provided gameplay description in this task

The PDF report (`Ecology_team16.pdf`) is an older project snapshot. It still describes 48 tiles and the older city set. Where it conflicts with the CSV/TXT files or the rules below, the CSV/TXT files and this document take precedence.

This file is the source of truth for what is currently specified in structured data versus what still needs explicit rule decisions.

## 1. Infrastructure Dataset

`Infrastructure_Tiles.csv` currently defines `34` infrastructure tiles.

Each row contains:
- `Name`
- `location`
- `img`
- `Budget`
- `Synergy`
- immediate score deltas for `Sustainability`, `Smart`, `Livability`, `Economy`
- future score timing via `Future Score-Round`
- future score deltas for `Sustainability`, `Smart`, `Livability`, `Economy`
- secondary metric values for `Emission`, `Happiness Index`, `Pollution Index (incl. AQI)`, `Biodiversity health`, `Community Trust`

Infrastructure budgets are the economy cost:
- the `Budget` value is deducted as the cost against the economy resource
- all city types use the same economy weight for this deduction
- every player starts with a base of `60cr`

Observed dataset properties:
- Minimum budget: `10,000,000`
- Maximum budget: `2,000,000,000`
- Average budget: about `277,941,176`

Infrastructure rows already encode:
- immediate strategic impact
- deferred strategic impact
- secondary environmental/social metrics
- synergy grouping id

Infrastructure rows do not encode:
- service revenue payout rules
- ownership caps
- monopoly or exclusivity rules

## 2. Infrastructure Decision Model

Based on the gameplay description, landing on an infrastructure tile is not a simple buy/skip decision. It is a role-selection decision with three outcomes:
- `provider`: the player funds/deploys the infrastructure and becomes the service provider
- `taker`: the player uses the infrastructure as a service taker with lower upfront cost and lower reward
- `skip`: the player declines both

The ESP32 should be authoritative for all infrastructure economics:
- provider cost = the `Budget` value from `Infrastructure_Tiles.csv`
- taker cost = `25%` of provider cost for the next `3` rounds
- cost deduction
- future payout scheduling
- service fee transfer between cities
- provider/taker eligibility
- whether a tile is already provider-owned
- whether multiple takers can attach to the same provider
- taker cost rounding is an ESP32 rules-engine decision if required

## 3. Synergy Dataset

`Synergy.txt` defines `13` named synergy combinations.

The combinations are:
1. `Solar Power Plant` + `Desalination Plant`
2. `Wind Farm` + `Smart Energy Grid` + `EV Charging Network`
3. `Hydroelectric Dam` + `Reservoir System` + `Fire Control Station`
4. `Water Treatment Plant` + `Vertical Farming Center` + `Vertical Farm`
5. `Urban Forest` + `Urban Cooling System` + `Green Roof Initiative`
6. `Wetland Restoration` + `Eco Tourism Park`
7. `City Park Network` + `Mass Transit System` + `BRT System`
8. `Recycling Plant` + `Industrial Park` + `Waste-to-Energy Plant` + `Carbon Capture Plant`
9. `Green Housing Complex` + `Biomass Power Plant`
10. `Highway Expansion` + `High-Speed Rail`
11. `Research & Innovation Center` + `Data Center`
12. `Smart Traffic Lights` + `Autonomous Vehicle Hub` + `Smart Streetlights`
13. `Geothermal Plant` + `Microgrid Network`

What is specified:
- exact membership of each synergy combination

What is not specified in data:
- the numeric synergy reward
- whether the reward is granted once or every round

Current recommendation:
- ESP32 should evaluate synergies after every infrastructure state change
- the app should only render `active_synergies` and the awarded deltas supplied by ESP32
- a synergy activates only when all listed infrastructure tiles are owned by the same city
- synergy points are added directly to the player’s current total points

## 4. Special Tile Dataset

`Special_Tiles.csv` contains `40` rows:
- `10` Policy rows
- `10` Event-1 rows
- `10` Disaster rows
- `10` Event-2 rows

These `40` rows represent `20` unique cards, each with `2` outcomes/options:
- `5` unique Policy cards, each with `Choice A` and `Choice B`
- `5` unique Event-1 cards, each with `Choice A` and `Choice B`
- `5` unique Disaster cards, each with `Outcome A` and `Outcome B`
- `5` unique Event-2 cards, each with `Outcome A` and `Outcome B`

Each special-tile row contains deltas for:
- `Sustainability`
- `Smart`
- `Livability`
- `Economy`
- `Emission`
- `Happiness Index`
- `Pollution Index (incl. AQI)`
- `Biodiversity health`
- `Community Trust`

## 5. Special Tile Semantics

Based on the gameplay description and the current dataset split:
- `Policy` and `Event-1` are choice-based cards
- `Disaster` and `Event-2` are ESP-resolved cards
- `Mandate` is the forced-resolution set containing `Disaster` and `Event-2`

Recommended mapping:
- `Initiative` block: player-facing choice flow using `Policy` or `Event-1`
- `Mandate` block: forced resolution flow using `Disaster` or `Event-2`

Recommended resolution behavior:
- for `Policy` and `Event-1`, ESP32 sends both options to the app and waits for a player choice
- for `Disaster` and `Event-2`, ESP32 chooses the final outcome using current game state and applies the result directly

## 6. Game State Responsibilities

The ESP32 should be authoritative for all long-lived state, including:
- city identity and turn order
- bank balance / spendable points
- core scores: `Sustainability`, `Smart`, `Livability`, `Economy`
- secondary metrics: `Emission`, `Happiness Index`, `Pollution Index`, `Biodiversity health`, `Community Trust`
- all deployed infrastructure
- provider/taker relationships
- future score schedules
- active synergies
- discard / already-used special cards
- forced outcome resolution for `Disaster` and `Event-2`
- severity amplification or reduction based on current game state
- `Emission` and `Pollution Index` are burden metrics where lower values are better

The Flutter app should be a rendering client for this state.

## 7. Gaps Requiring Rule Decisions

The following mechanics are not encoded in the current CSV/TXT files and must be finalized explicitly:
- provider revenue formula when another city consumes a service
- taker reward formula
- whether service-provider payouts are immediate, recurring, or triggered by later usage
- exact synergy reward values and grant timing
- exact severity logic for `Disaster` and `Event-2`

## 8. Implementation Direction

Recommended implementation direction:
- keep CSV/TXT as design data sources
- load/compile them into ESP-side lookup tables
- have ESP32 calculate all economic outcomes and all severity outcomes
- send the app normalized state snapshots and prompt payloads only
- keep the app free of gameplay math beyond local display formatting
