# Ecology Game - Simulated Gameplay Walkthrough

This document simulates a few turns of the Ecology Game to clarify the mechanics, the flow of play, and the interactions between the players, the physical board/ESP32, and the Flutter mobile apps.

---

## ⚙️ Game Setup

**Hardware Setup:**
* 1 Physical Board representing the 4 cities and their paths/tiles.
* 1 ESP32 microcontroller managing the entire game state.
* 1 Rotary Encoder (used as the "dice" for movement).
* RFID Readers on the board to scan theme/policy/disaster cards.
* 20 Theme Cards (4 themes * 5 cards) and 5 Disaster Cards.

**Player Setup:**
* 4 Players, each with their own smartphone running the Flutter App.
* The phones connect to the ESP32 via WebSockets (`ws://gigachad-esp.local:81`).
* Each player is assigned a city: **Natural, Industrial, Cultural, Tech**.

**Initial State (Managed by ESP32):**
* Every city starts with baseline metrics (e.g., Liveability: 50, Sustainability: 50, Metric3: 50, Metric4: 50).
* Every city starts with a pool of Points (e.g., 100 Points).
* Circular Dependency is active: `Natural -> Industrial -> Cultural -> Tech -> Natural`.

---

## 🎲 Turn 1: Player 1 (Natural City)

### Phase 1: Turn Start & Movement
1. **ESP32 Action:** The ESP32 determines it is Player 1's turn. It sends a WebSocket message to all phones: `"active_city": "Natural"`.
2. **App UI:** Player 1's phone shows a big notification: **"It's your turn! Spin the Encoder to move."** The other 3 phones show: **"Waiting for Natural City to move..."**
3. **Physical Action:** Player 1 physically spins the rotary encoder on the board. 
4. **ESP32 Action:** The encoder registers a value of 4. The ESP32 sends this movement value to the app.
5. **App UI:** Player 1's phone says: **"You moved 4 spaces! Move your physical piece."**
6. **Physical Action:** Player 1 moves their physical token 4 spaces on the board. They land on an **"Optional Policy"** tile.

### Phase 2: Drawing & Scanning a Card
1. **App UI:** The app prompts: **"You landed on an Optional Policy tile. Please draw a card and scan it on the board."**
2. **Physical Action:** Player 1 draws a card from the "Air Policy" theme deck and taps it on the board's RFID reader.
3. **ESP32 Action:** The ESP32 reads the RFID UID, identifies it as "Air Policy Card", and sends a `card_action` message to Player 1's phone.

### Phase 3: Decision Making (App)
1. **App UI:** Player 1's phone displays the card details:
   * **Theme:** Air Policy
   * **Option A (Strict Emission Limits):** 
     * Cost: 30 Points
     * Effect: +15 Sustainability, -5 Metric3
   * **Option B (Subsidized Filters):**
     * Cost: 10 Points
     * Effect: +5 Sustainability, +0 Metric3
2. **Action:** Player 1 taps **"Option A"** on their Flutter app.
3. **ESP32 Action:** The app sends this choice back to the ESP32. The ESP32 deducts 30 points from Natural City, adds 15 to Sustainability, and subtracts 5 from Metric3.
4. **Broadcast:** The ESP32 broadcasts the updated `game_state` to all 4 phones.
5. **App UI:** All phones update their dashboards. Player 1's dashboard reflects their new stats.

---

## 🎲 Turn 2: Player 2 (Industrial City)

### Phase 1: Turn Start & Movement
1. **ESP32 Action:** It is now Player 2's turn. Message sent: `"active_city": "Industrial"`.
2. **Physical Action:** Player 2 spins the encoder, gets a 3, and moves their piece. They land on a **"Disaster"** tile.

### Phase 2: The Disaster Strikes
1. **App UI:** The app prompts: **"DISASTER TILE! Scan the top card of the Disaster deck."**
2. **Physical Action:** Player 2 scans a Disaster Card.
3. **ESP32 Action:** The ESP32 recognizes the card as **"Flood"**. 
4. **App Logic / ESP32 Calculation:** The ESP32 checks Industrial City's current Sustainability metric. Because it is below a certain threshold, the ESP32 determines this is a **"Very-High Impact"** flood.

### Phase 3: Applying Consequences & Circular Dependency
1. **ESP32 Action:** The ESP32 calculates the damage. 
   * **Industrial City Penalty:** -20 Liveability, -10 Sustainability.
   * **Cascading Penalty (Circular Rule):** Because Industrial City suffered a major hit, the ESP32 automatically applies a cascading penalty to the *next* city in the chain (Cultural City). 
   * **Cultural City Penalty:** -5 Liveability (due to supply chain issues from the flooded Industrial City).
2. **Broadcast:** ESP32 updates the `game_state` and broadcasts it.
3. **App UI:** 
   * Player 2's screen turns red: **"Disaster: Flood! (Very-High Impact) You lost 20 Liveability and 10 Sustainability."**
   * Player 3's (Cultural City) screen flashes: **"Ripple Effect! Industrial City's disaster caused you to lose 5 Liveability."**

---

## 🎲 Turn 3: Player 3 (Cultural City)

### Phase 1: Trade / Points Transfer (Optional Action)
1. **App UI:** It's Player 3's turn. Looking at their dashboard, they see their Liveability is dangerously close to the elimination threshold (due to the recent ripple effect). They need points to enact a good policy this turn.
2. **App Action:** Player 3 navigates to the "Other Cities" tab on their app. They see that Player 4 (Tech City) has plenty of points. Player 3 asks Player 4 (verbally) for a loan/trade.
3. **App Action (Player 4):** Player 4 agrees, uses their app to select "Transfer Points -> Cultural City -> 20 Points", and hits Send.
4. **ESP32 Action:** The ESP32 receives the transfer command, updates both cities' point balances, and broadcasts the new state.

### Phase 2: Movement & Survival
1. **Physical Action:** Player 3 spins the encoder and moves to a **"Forced Theme"** tile. 
2. **Physical Action:** Player 3 scans the required card.
3. **App UI:** The app shows the forced policy. Player 3 *must* pay the points and accept the consequences. Thanks to the trade from Tech City, they have enough points to survive the turn without dropping below their minimum threshold and being eliminated.

---

## 🔚 Elimination Rules Check (Background)
After every action, the ESP32 checks the minimum thresholds for all cities. If at any point a city's metric (e.g., Liveability) drops below their specific cap, the ESP32 broadcasts an `elimination` event. That player's app will show a "Game Over" screen, and the circular dependency chain will update to bypass them (e.g., `Industrial -> Tech`). The game continues until only one city remains.
