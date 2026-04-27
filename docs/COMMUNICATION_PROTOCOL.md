# Exact Communication Protocol (End-to-End)

This document defines the exact JSON payloads for the robust architecture described in `GAME_ARCHITECTURE.md`. 

## Overview
* **Transport:** WebSockets (WS)
* **Format:** JSON strings using a `type` + `payload` envelope.
* **mDNS Hostname:** `gigachad-esp.local`
* **Port:** `81`
* **Connection URI:** `ws://<ESP_IP>:81/`

Every message sent over the WebSocket MUST follow this generic structure:
```json
{
  "type": "<MESSAGE_TYPE>",
  "payload": {
     // Specific data
  }
}
```

---

## 1. Client-to-Server (App → ESP32)
These are "Intents" sent by the Flutter app. The ESP32 is the ultimate validator of these intents.

### `join_lobby`
Sent immediately after the WebSocket connects to identify the device.
```json
{
  "type": "join_lobby",
  "payload": {
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

### `reconnect`
Sent instead of `join_lobby` if the app crashes and reconnects during an active game.
```json
{
  "type": "reconnect",
  "payload": {
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  }
}
```

### `set_ready`
Sent when the player taps "Ready" in the lobby.
```json
{
  "type": "set_ready",
  "payload": {
    "ready": true
  }
}
```

### `action_purchase`
Response to a `prompt_purchase` from the ESP32.
```json
{
  "type": "action_purchase",
  "payload": {
    "action": "buy" // or "skip"
  }
}
```

### `action_card_choice`
Response to a `prompt_card_choice` (e.g., choosing between Policy A or B).
```json
{
  "type": "action_card_choice",
  "payload": {
    "choice": "A" // or "B"
  }
}
```

### `action_transfer_funds`
Sent asynchronously when a player wants to trade/send points to another city.
```json
{
  "type": "action_transfer_funds",
  "payload": {
    "target_faction": "Natural",
    "amount": 20
  }
}
```

---

## 2. Server-to-Client (ESP32 → App)
These are "Truths" broadcasted or sent directly by the ESP32. The Flutter app simply renders whatever these messages dictate.

### `lobby_state`
Broadcasted whenever someone joins or changes ready status.
```json
{
  "type": "lobby_state",
  "payload": {
    "total_connected": 3,
    "ready_count": 2,
    "players": [
      { "faction": "Natural", "is_ready": true },
      { "faction": "Tech", "is_ready": true },
      { "faction": "Industrial", "is_ready": false }
    ]
  }
}
```

### `game_start`
Broadcasted when 4 players are ready. Tells the app to navigate from Lobby to the Game Dashboard.
```json
{
  "type": "game_start",
  "payload": {}
}
```

### `turn_update`
Broadcasted when the turn passes to a new player.
```json
{
  "type": "turn_update",
  "payload": {
    "active_faction": "Tech"
  }
}
```

### `move_result`
Broadcasted after the ESP32 reads the rotary encoder and resolves physical movement.
```json
{
  "type": "move_result",
  "payload": {
    "faction": "Tech",
    "spaces_moved": 4,
    "landed_on_tile_type": "infrastructure" // e.g., "policy", "disaster", "infrastructure"
  }
}
```

### `prompt_scan`
Sent directly to the active player's phone telling them to scan a card.
```json
{
  "type": "prompt_scan",
  "payload": {
    "message": "You landed on a Policy Tile. Please scan a Policy card on the board."
  }
}
```

### `prompt_purchase`
Sent to the active player when they land on an unowned infrastructure tile. Starts a 60-second timer.
```json
{
  "type": "prompt_purchase",
  "payload": {
    "name": "Solar Farm",
    "description": "A large solar panel array that generates clean energy.",
    "cost": 350,
    "effects": {
      "sustainability": 50,
      "economy": 20
    }
  }
}
```

### `prompt_card_choice`
Sent to the active player after they scan an optional Policy/Event card. Starts a 60-second timer.
```json
{
  "type": "prompt_card_choice",
  "payload": {
    "card_title": "Carbon Tax Regulation",
    "description": "The city council proposes a new carbon tax.",
    "choice_a": "Implement Strict Tax",
    "choice_a_desc": "+80 Sustainability, -40 Economy",
    "choice_b": "Relaxed Guidelines",
    "choice_b_desc": "+20 Sustainability, +30 Economy"
  }
}
```

### `card_resolved`
Broadcasted when a forced card (like a Disaster) is scanned. The ESP32 calculates the impact itself and tells everyone the result.
```json
{
  "type": "card_resolved",
  "payload": {
    "card_title": "Flood",
    "target_faction": "Industrial",
    "impact_level": "High",
    "effects_applied": {
      "liveability": -20,
      "sustainability": -10
    }
  }
}
```

### `error`
Sent to a player if they do something invalid.
```json
{
  "type": "error",
  "payload": {
    "message": "Card already played! Scan a new one." // or "Not enough points to transfer."
  }
}
```

### `timeout_warning`
Broadcasted if the 60-second timer expires while waiting for a player's choice.
```json
{
  "type": "timeout_warning",
  "payload": {
    "message": "Tech City took too long. Auto-skipping their action."
  }
}
```

### `game_state`
The master state payload. Broadcasted after ANY mathematical change (metrics, points, eliminations, etc.). This ensures all 4 phones always display identical data.
```json
{
  "type": "game_state",
  "payload": {
    "lap": 3,
    "game_phase": "in_progress", // or "ended"
    "players": [
      {
        "faction": "Natural",
        "is_eliminated": false,
        "bank_balance": 1500,
        "metrics": {
          "sustainability": 650.0,
          "smart": 500.0,
          "livability": 720.0,
          "economy": 580.0
        }
      },
      // ... (Includes the other 3 factions in the array)
    ]
  }
}
```

### `full_sync`
Sent ONLY in response to a `reconnect` message from a crashed app.
```json
{
  "type": "full_sync",
  "payload": {
    "my_faction": "Natural",
    "current_turn_faction": "Tech",
    "game_state": {
      // (Exact same object as the standard `game_state` payload above)
    },
    "pending_prompt": null // If they disconnected during a prompt, this contains the exact `prompt_card_choice` or `prompt_purchase` object.
  }
}
```
