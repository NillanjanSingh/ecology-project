# Smart City Board Game - End-to-End Architecture

This document outlines the robust, cheat-proof, and resilient architectural plan for the Ecology Smart City game. This architecture shifts all authoritative logic to the ESP32 (acting as the true "Game Master") and treats the Flutter apps as "Viewers" that render the current state and forward user intents.

For the structured gameplay dataset behind this architecture, see `GAME_DATA_MODEL.md`.

---

## 1. Core Architectural Principles

* **Authoritative Server (ESP32):** The ESP32 handles all mathematics, dice rolls, random number generation, card tracking, and timers. The Flutter app NEVER calculates outcomes or trusts client-side randomness.
* **Stateless Clients (Flutter):** If an app crashes, the player must be able to restart it, send a `reconnect` message, and immediately resume playing exactly where they left off without breaking the game loop.
* **Unique Device IDs:** Upon first connecting, the Flutter app generates a random UUID and saves it locally. It sends this ID to the ESP32. This allows the ESP32 to map a specific phone to a specific city type (e.g., Device A is always Natural City, even if it disconnects and reconnects later).
* **Economic Weighting:** Infrastructure `Budget` values are the economy cost. All city types share the same economy weight, and every player starts with a base of `60cr`.

---

## 2. Phase 1: Pre-Game Lobby & Setup

**Goal:** Ensure all 4 players are connected, assigned factions, and ready before starting.

1. **Connection:** Player opens the app and connects to the WebSocket (`ws://gigachad-esp.local:81`).
2. **Join Request:** App sends a `join_lobby` message containing its `device_id`.
3. **Faction Assignment:** The ESP32 checks if this `device_id` is known. If new, it assigns an available city type (Natural, Manufacturing, Tourism, Technological) and adds them to the lobby.
4. **Lobby Broadcast:** ESP32 broadcasts `lobby_state` to all connected phones (e.g., *"3/4 Players Connected. Natural is Ready, Technological is Not Ready"*).
5. **Ready Up:** Players tap "Ready" on their phones. The app sends `set_ready` including its `device_id`.
6. **Assignment Confirmation:** The ESP32 sends a direct `player_assignment` message back to that same device confirming the `device_id` to city mapping (for example, *"UUID abc123 is Technological"*). The Flutter app must use this server-assigned faction and must not hardcode a local default.
7. **Game Start:** Once the ESP32 registers 4 ready players, it initializes the baseline metrics, creates an empty `discard_pile` array for scanned cards, and broadcasts `game_start` followed by the initial `game_state`.
8. **Data Load:** Before or during game start, the ESP32 loads the `34` infrastructure records, the `20` special cards (`40` option rows), and the `13` synergy definitions into its authoritative rules engine.

---

## 3. Phase 2: The Robust Turn Loop

**Goal:** A strict, linear sequence controlled entirely by the ESP32, immune to race conditions.

### Step A: Turn Initialization
* The ESP32 increments the turn counter and determines the active city.
* ESP32 broadcasts `turn_update` (e.g., *"It is Technological City's Turn"*).
* Non-active apps show: *"Waiting for Technological City."* The active app shows: *"Spin the encoder on the board!"*

### Step B: Physical Movement
* The player physically spins the encoder. 
* The ESP32 reads the hardware, calculates the steps, and moves the digital position of that player. 
* ESP32 broadcasts `move_result` (e.g., *"Technological City moved 4 spaces and landed on an Infra Tile"*).
* The board's economy math is shared across all city types, so the same `Budget` deduction rules apply regardless of faction.

### Step C: Tile Resolution (The Interaction Phase)
The ESP32 looks at what tile the player landed on, enters a **"Pending State"**, and starts a **60-second hardware timer**.

* **If Infrastructure Tile:**
  * ESP32 sends `prompt_purchase` directly to the active player's phone.
  * The prompt contains the infrastructure identity plus the available roles: `provider`, `taker`, or `skip`.
  * The provider cost is the `Budget` value from the infrastructure CSV.
  * The taker cost is `25%` of the provider cost for the next `3` rounds.
  * Player selects the role. App sends `action_purchase` back to ESP32.
  * ESP32 validates affordability, ownership constraints, and service relationship rules.
* **If Initiative Block:**
  * ESP32 resolves the block into a choice-based card from `Policy` or `Event-1`.
  * ESP32 sends `prompt_scan` to the active player's phone (*"Please scan a Policy Card on the board"*).
  * Player taps an RFID card. 
  * ESP32 reads the UID and checks its internal `discard_pile` array. 
    * *If UID exists:* ESP32 ignores it and sends an `error` to the phone (*"Card already played! Scan a new one."*).
    * *If UID is valid:* ESP32 adds UID to `discard_pile`.
  * ESP32 sends `prompt_card_choice` to the phone. App sends back `action_card_choice` (Option A or B).
* **If Mandate Block:**
  * ESP32 resolves the block into a forced card from `Disaster` or `Event-2`.
  * The ESP32 calculates the final severity/outcome from current game state.
  * The ESP32 applies the result directly and broadcasts `card_resolved`.

### Step D: State Recalculation & Broadcast
* The ESP32 applies all metric changes to the active player.
* The ESP32 updates service-provider/service-taker relationships and any recurring or triggered payouts.
* The ESP32 checks whether a new infrastructure combination activates a synergy. A synergy only counts when all listed infrastructure tiles are owned by the same city, and any synergy points are added directly to that player's current total points.
* **Circular Dependency Check:** The ESP32 checks if the active player suffered a severe penalty. If so, it calculates the ripple effect and applies a penalty to the *next* city in the chain.
* **Elimination Check:** The ESP32 checks if any city dropped below their minimum thresholds. If so, it marks them as `isEliminated = true` and patches the circular dependency chain to skip them.
* ESP32 broadcasts a global `game_state` update to all phones. All dashboards update instantly.
* ESP32 loops back to Step A for the next player.

---

## 4. Phase 3: Asynchronous Actions (Trading)

**Goal:** Allow players to bail each other out without breaking the turn sequence.

* At any time, Player A can open the "Trade" tab and attempt to send 20 points to Player B.
* Player A's app sends `action_transfer_funds` (Sender `device_id`, Target `device_id`, Amount: 20). The target faction label may also be included as a readable fallback.
* The ESP32 intercepts this. It verifies Player A has `>= 20` points. 
* If valid, ESP32 deducts 20 from A, adds 20 to B, and broadcasts a fresh `game_state` with an attached notification: *"Technological City transferred 20 points to Natural City!"*
* *Crucial Benefit:* Because the ESP32 holds the state, this prevents the "double-spend" exploit where a player tries to send money they don't have.

---

## 5. Phase 4: Handling Disconnects & Timeouts (Failsafes)

### The Timeout System (Fixing the Hanging Game)
* Whenever the ESP32 asks a phone for input (`prompt_purchase` or `prompt_card_choice`), it starts a 60-second timer.
* If the timer expires and no WebSocket message was received from that phone, the ESP32 **auto-resolves** the action (e.g., defaults to "Skip Purchase" or "Option B").
* The ESP32 broadcasts a `timeout_warning` so everyone knows the player took too long, recalculates the state, and moves to the next player's turn. 
* *Physical Board Failsafe:* A physical "Override" button on the ESP32 that the Game Master (or players) can press to instantly trigger this timeout skip.

### The Reconnection Protocol
* If Player A's phone dies and they restart the app, the app connects and sends `reconnect` with their original `device_id`.
* The ESP32 recognizes the ID and replies with a `full_sync` payload. This payload contains:
  1. The complete `game_state` (metrics, money, eliminated status, infrastructure portfolio, active synergies).
  2. The `current_turn` (so the app knows whose turn it is).
  3. `pending_action` (If Player A disconnected *while* a prompt was on their screen, the ESP32 resends the exact `prompt_purchase` or `prompt_card_choice` JSON so the UI pops back up instantly).

---

## 6. Summary of the New Message Dictionary

### App -> ESP32 (Client Intents)
* `join_lobby` (Includes `device_id`)
* `reconnect` (Includes `device_id`)
* `set_ready` (Includes `device_id`, boolean)
* `action_purchase` (Includes `device_id`, `provider`, `taker`, or `skip`)
* `action_card_choice` (Includes `device_id`, "A" or "B")
* `action_transfer_funds` (Includes sender `device_id`, target `device_id`, Amount)

### ESP32 -> App (Server Truths)
* `lobby_state` (Current lobby status)
* `player_assignment` (Direct confirmation of the device's assigned faction after ready-up)
* `game_start` (Triggers UI transition)
* `full_sync` (Sent on reconnect)
* `turn_update` (Who is playing now)
* `move_result` (Encoder value + tile landed on)
* `prompt_scan` (Tells UI to show "Please tap card on board")
* `prompt_purchase` (Shows infrastructure provider/taker decision UI)
* `prompt_card_choice` (Shows A/B UI)
* `error` (e.g., "Card already used!", "Not enough funds!")
* `card_resolved` (Shows the outcome of a forced Disaster/Event calculated by ESP32)
* `game_state` (The authoritative state snapshot, including metrics, infrastructure, synergies, and balances)
