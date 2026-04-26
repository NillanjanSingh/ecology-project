# Smart City Board Game - WebSocket Communication Protocol

This document outlines the finalized JSON-based communication protocol between the Flutter mobile application (Mayor's Terminal) and the ESP32 hardware board via WebSockets. 

## Overview

* **Transport:** WebSockets (WS)
* **Format:** JSON strings using a `type` + `payload` envelope
* **mDNS Hostname:** `gigachad-esp.local`
* **Port:** `81`
* **Connection URI:** `ws://<ESP_IP>:81/`

---

## Pre-Game Lobby Flow (Current App Behavior)

Before gameplay starts, clients join a lobby and wait for ESP32 to signal start.

### Lobby Sequence
1. Flutter connects to ESP32 WebSocket.
2. Flutter sends `join_lobby`.
3. ESP32 broadcasts `lobby_state` updates as players join/ready.
4. Flutter sends `player_ready` when user presses ready.
5. ESP32 broadcasts `game_start` when all required players are ready.
6. Fallback start signal: `game_state.payload.status` can be `playing`, `in_progress`, or `started`.

### Lobby Messages

#### Client → Server: Join Lobby (`join_lobby`)
```json
{
  "type": "join_lobby",
  "payload": {
    "platform": "flutter"
  }
}
```

#### Client → Server: Ready Up (`player_ready`)
```json
{
  "type": "player_ready",
  "payload": {
    "ready": true
  }
}
```

#### Server → Client: Lobby State (`lobby_state`)
```json
{
  "type": "lobby_state",
  "payload": {
    "joined_players": 3,
    "ready_players": 2,
    "total_players": 4
  }
}
```
* The app also accepts aliases for compatibility: `joined`, `connected_players`, `ready_count`, `required_players`, `total`.

#### Server → Client: Start Game (`game_start`)
```json
{
  "type": "game_start",
  "payload": {}
}
```

---

## Server-to-Client (ESP32 → Flutter)

These messages are broadcasted from the ESP32 to connected Flutter clients to sync game states and prompt user interactions.

### 1. Turn Synchronization (`turn`)
Broadcasted immediately upon connection and after every completed player action to indicate whose turn it is.

```json
{
  "type": "turn",
  "player": 0 
}
```
* `player`: Integer `0-3` denoting the active player.

### 2. Game State Broadcast (`game_state`)
Sent globally whenever the mathematical state of the game changes (e.g., after recalculations). Used by the app to render dashboards.

```json
{
  "type": "game_state",
  "players": [
    {
      "faction": 0, 
      "pos": 14,
      "bankBalance": 1250.0,
      "totalScore": 2500.5,
      "isInnerRing": false,
      "isEliminated": false,
      "wonGame": false,
      "laps": 3,
      "factors": {
        "sustainability": 45.2,
        "smart": 60.0,
        "livability": 55.0,
        "economy": 70.1
      }
    }
  ]
}
```
* `faction`: Enum (`0`=Natural, `1`=Software, `2`=Industrial, `3`=Financial).
* *Note: The `players` array will contain exactly 4 objects corresponding to players 0 through 3.*

### 3. Movement Notification (`move`)
Triggered when the physical rotary encoder spins and a player lands on a tile. The Flutter app uses this to render movement and trigger action modals.

```json
{
  "type": "move",
  "player": 0,
  "tileType": 1, 
  "spin": 5,
  "infraId": 12, 
  "infraName": "Solar Power Plant", 
  "cost": 200.0 
}
```
* `tileType`: Enum (`0`=START, `1`=INFRA, `2`=POLICY_ZONE, `3`=EVENT_ZONE, `4`=DISASTER_ZONE, `5`=EMPTY).
* *Note: `infraId`, `infraName`, and `cost` are only included if `tileType == 1`.*

### 4. RFID Card Scanned (`card_scanned`)
Sent when a physical card is tapped to the RFID reader. Prompts the Flutter app to display the card details and choices.

```json
{
  "type": "card_scanned",
  "player": 0,
  "uid": "uid00",
  "cardIdx": 0,
  "cardName": "Carbon Tax",
  "cardType": "Policy", 
  "optionA": "Aggressive",
  "optionB": "Moderate"
}
```
* `cardType`: String indicating type (`"Policy"`, `"Event-1"`, `"Event-2"`, `"Disaster"`).

---

## Client-to-Server (Flutter → ESP32)

These messages are sent from the Flutter app to the ESP32 in response to prompts. **The ESP32 will pause the game loop and wait for these responses before advancing the turn.**

### 5. Infrastructure Purchase Response (`buy_infra`)
Sent after a player lands on an infrastructure tile (`tileType = 1`) and interacts with the Buy/Skip modal.

```json
{
  "type": "buy_infra",
  "player": 0, 
  "infraId": 12,
  "accept": true 
}
```
* `player`: Must match the active player's index.
* `accept`: Boolean (`true` = Buy, `false` = Skip).

### 6. Card Choice Response (`card_choice`)
Sent after the player resolves a scanned card.

> **Crucial Implementation Note for Forced Outcomes:** > For **Event-2** and **Disaster** cards, the Flutter app must **NOT** allow the user to freely pick their choice. Instead, the Flutter app must simulate a randomized outcome (e.g., rolling a digital die), display that randomized result to the user, and automatically send the corresponding `choice` back to the ESP32.

```json
{
  "type": "card_choice",
  "player": 0, 
  "cardIdx": 0,
  "choice": 0 
}
```
* `player`: Must match the active player's index.
* `choice`: Integer (`0` = Option A, `1` = Option B).
