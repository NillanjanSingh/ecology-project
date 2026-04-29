# Exact Communication Protocol (End-to-End)

This document defines the exact JSON payloads for the robust architecture described in `GAME_ARCHITECTURE.md`. 
For implementation alignment rules (validation, reconnect prompt restoration, strict type support), see `ARCHITECTURE_ALIGNMENT.md`.
For source gameplay datasets and unresolved mechanics, see `GAME_DATA_MODEL.md`.

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
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "ready": true
  }
}
```

After the ESP32 accepts this ready signal, it should respond directly to that same device with `player_assignment` so the app can bind the UUID to the assigned faction before the game starts.

### `action_purchase`
Response to a `prompt_purchase` from the ESP32.
```json
{
  "type": "action_purchase",
  "payload": {
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "infrastructure_name": "Solar Power Plant",
    "action": "provider" // or "taker" or "skip"
  }
}
```

### `action_card_choice`
Response to a `prompt_card_choice` (e.g., choosing between Policy A or B).
```json
{
  "type": "action_card_choice",
  "payload": {
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
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
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "target_device_id": "0f9e8d7c-6b5a-4321-aaaa-bbccccddeeff",
    "target_faction": "Natural",
    "amount": 20
  }
}
```

`target_device_id` should be treated as the authoritative transfer target. `target_faction` is retained as a readable fallback and audit field.

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
      { "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890", "faction": "Natural", "is_ready": true },
      { "device_id": "0f9e8d7c-6b5a-4321-aaaa-bbccccddeeff", "faction": "Technological", "is_ready": true },
      { "device_id": "11223344-5566-7788-99aa-bbccddeeff00", "faction": "Manufacturing", "is_ready": false }
    ]
  }
}
```

### `player_assignment`
Sent directly to one phone after the ESP32 confirms that device's ready state and faction assignment. This is the first authoritative faction confirmation for the app.
```json
{
  "type": "player_assignment",
  "payload": {
    "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "faction": "Technological",
    "ready_confirmed": true
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
    "active_faction": "Technological",
    "active_device_id": "0f9e8d7c-6b5a-4321-aaaa-bbccccddeeff"
  }
}
```

### `move_result`
Broadcasted after the ESP32 reads the rotary encoder and resolves physical movement.
```json
{
  "type": "move_result",
  "payload": {
    "faction": "Technological",
    "device_id": "0f9e8d7c-6b5a-4321-aaaa-bbccccddeeff",
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
Sent to the active player when they land on an infrastructure tile. Starts a 60-second timer.
```json
{
  "type": "prompt_purchase",
  "payload": {
    "name": "Solar Power Plant",
    "location": 1,
    "budget": 100000000,
    "base_balance": 60,
    "provider_option": {
      "cost_points": 100000000,
      "future_income_model": "service_usage_based"
    },
    "taker_option": {
      "cost_points": 25000000,
      "benefit_model": "25_percent_for_3_rounds"
    },
    "immediate_scores": {
      "sustainability": 8,
      "smart": 7,
      "livability": 6,
      "economy": 4
    },
    "future_scores": {
      "rounds_until_activation": 3,
      "sustainability": 10,
      "smart": 8,
      "livability": 7,
      "economy": 8
    },
    "secondary_metrics": {
      "emission": 2,
      "happiness_index": 6,
      "pollution_index": 2,
      "biodiversity_health": 5,
      "community_trust": 7
    }
  }
}
```

Notes:
- `budget` comes from `Infrastructure_Tiles.csv`.
- `provider_option.cost_points` equals the `budget`.
- `taker_option.cost_points` equals `25%` of the provider cost for the next `3` rounds.
- Every player starts with a base of `60cr`.

### `prompt_card_choice`
Sent to the active player after they scan a choice-based card from `Policy` or `Event-1`. Starts a 60-second timer.
```json
{
  "type": "prompt_card_choice",
  "payload": {
    "category": "Policy",
    "card_title": "Carbon Tax",
    "choice_a": {
      "name": "Aggressive",
      "effects": {
        "sustainability": 9,
        "smart": 8,
        "livability": 4,
        "economy": 3,
        "emission": 2,
        "happiness_index": 4,
        "pollution_index": 2,
        "biodiversity_health": 7,
        "community_trust": 5
      }
    },
    "choice_b": {
      "name": "Moderate",
      "effects": {
        "sustainability": 6,
        "smart": 6,
        "livability": 6,
        "economy": 6,
        "emission": 5,
        "happiness_index": 6,
        "pollution_index": 5,
        "biodiversity_health": 6,
        "community_trust": 6
      }
    }
  }
}
```

### `card_resolved`
Broadcasted when a forced card from `Disaster` or `Event-2` is resolved. The ESP32 calculates the final impact itself and tells everyone the result.
```json
{
  "type": "card_resolved",
  "payload": {
    "category": "Disaster",
    "card_title": "Flood",
    "target_faction": "Manufacturing",
    "target_device_id": "11223344-5566-7788-99aa-bbccddeeff00",
    "selected_outcome": "Standing Water",
    "severity_basis": {
      "sustainability": 32,
      "pollution_index": 74
    },
    "effects_applied": {
      "sustainability": 2,
      "smart": 2,
      "livability": 1,
      "economy": 1,
      "emission": 7,
      "happiness_index": 1,
      "pollution_index": 8,
      "biodiversity_health": 2,
      "community_trust": 3
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
    "message": "Technological City took too long. Auto-skipping their action."
  }
}
```

### `game_state`
The master state payload. Broadcasted after ANY mathematical change (metrics, points, infrastructure decisions, synergies, eliminations, etc.). This ensures all 4 phones always display identical data.
```json
{
  "type": "game_state",
  "payload": {
    "lap": 3,
    "game_phase": "in_progress", // or "ended"
    "base_balance": 60,
    "players": [
      {
        "device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "faction": "Natural",
        "is_eliminated": false,
        "bank_balance": 1500,
        "metrics": {
          "sustainability": 650.0,
          "smart": 500.0,
          "livability": 720.0,
          "economy": 580.0
        },
        "secondary_metrics": {
          "emission": 32.0,
          "happiness_index": 71.0,
          "pollution_index": 28.0,
          "biodiversity_health": 63.0,
          "community_trust": 75.0
        },
        "infrastructure": [
          {
            "name": "Solar Power Plant",
            "location": 1,
            "role": "provider"
          },
          {
            "name": "Desalination Plant",
            "location": 5,
            "role": "taker",
            "provider_faction": "Natural"
          }
        ],
        "active_synergies": [
          {
            "id": 1,
            "name": "Solar Power Plant + Desalination Plant"
          }
        ],
        "future_effect_queue": [
          {
            "source": "Solar Power Plant",
            "rounds_remaining": 2,
            "effects": {
              "sustainability": 10,
              "smart": 8,
              "livability": 7,
              "economy": 8
            }
          }
        ],
        "last_resolution": {
          "type": "infrastructure",
          "name": "Solar Power Plant"
        }
      },
      // ... (Includes the other 3 factions in the array)
    ]
  }
}
```

Notes:
- `Emission` and `Pollution Index` are burden metrics where lower values are better.
- Synergy points are added directly to the player's current total points when the ESP32 confirms a same-city ownership match.

Valid faction values in all payloads are `Natural`, `Manufacturing`, `Tourism`, and `Technological`.

`device_id` is the authoritative unique player identifier. Any message that references a specific player should include that player's `device_id` whenever possible, even if a faction label is also present for readability.

### `full_sync`
Sent ONLY in response to a `reconnect` message from a crashed app.
```json
{
  "type": "full_sync",
  "payload": {
    "my_device_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "my_faction": "Natural",
    "current_turn_faction": "Technological",
    "game_state": {
      // (Exact same object as the standard `game_state` payload above)
    },
    "pending_prompt": null // If they disconnected during a prompt, this contains the exact `prompt_card_choice` or `prompt_purchase` object.
  }
}
```
