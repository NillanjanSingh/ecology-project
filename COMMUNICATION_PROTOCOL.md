# Ecology Game - Communication Protocol

- Note: This is WIP until the final protocol is defined

This document outlines the JSON-based communication protocol to be used between the Flutter mobile application and the ESP32 hardware board via WebSockets.

## Overview
- **Transport**: WebSockets (WS)
- **Format**: JSON strings
- **mDNS Hostname**: `gigachad-esp.local`

The Flutter app will resolve the mDNS hostname to get the ESP32's IP address and will connect to `ws://<ESP_IP>:81`.

## Message Structure

Every message sent from the ESP32 to the app (and vice-versa) MUST follow this generic structure:

```json
{
  "type": "<MESSAGE_TYPE>",
  "payload": {
     // Specific data associated with the message type
  }
}
```

---

### Supported Message Types

#### 1. RFID Card Read (`rfid`)
Sent by the ESP32 when an RFID card is placed on one of the readers.

**Direction**: ESP32 → App

```json
{
  "type": "rfid",
  "payload": {
    "uid": "04A1B2C3D4E5F6",
    "board_id": 1
  }
}
```

#### 2. Rotary Encoder Event (`encoder`)
Sent by the ESP32 when the user interacts with the rotary encoder.

**Direction**: ESP32 → App

```json
{
  "type": "encoder",
  "payload": {
    "direction": 1,
    "value": 15
  }
}
```

#### 3. Game State Update (`game_state`)
Syncs the overall game status and phase between devices.

**Direction**: ESP32 → App

```json
{
  "type": "game_state",
  "payload": {
    "status": "in_progress",
    "faction": "natural_resources",
    "active_city": "Natural",
    "eliminated_cities": ["Tech"]
  }
}
```

#### 4. Card Action (`card_action`)
Sent from the App to ESP32 when a specific card effect is executed or chosen by the user in the app.

**Example:**
```json
{
  "type": "card_action",
  "payload": {
    "action": "implement_policy",
    "policy_id": "air_policy_A",
    "cost": 50
  }
}
```

#### 5. Player State Sync (`sync_state`)
ESP32 sends the latest computed metrics, bank balance, active cards, and lap number to the app. This is the primary data feed for the Mayor's Terminal dashboard.

**Direction**: ESP32 → App

```json
{
  "type": "sync_state",
  "payload": {
    "metrics": {
      "sustainability": 650.0,
      "smart": 500.0,
      "livability": 720.0,
      "economy": 580.0
    },
    "bank_balance": 1500,
    "current_lap": 3,
    "faction": "natural_resources",
    "active_cards": [
      {
        "id": "disaster_01",
        "name": "Earthquake",
        "type": "disaster",
        "description": "Infrastructure damage -15% Economy",
        "remaining_laps": 2
      },
      {
        "id": "policy_01",
        "name": "Green Initiative",
        "type": "policy",
        "description": "+10% Sustainability per lap",
        "remaining_laps": 4
      }
    ]
  }
}
```

#### 6. Purchase Prompt (`purchase_prompt`)
ESP32 asks the player if they want to buy an available infrastructure tile.

**Direction**: ESP32 → App

```json
{
  "type": "purchase_prompt",
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

#### 7. Purchase Response (`purchase_response`)
App tells the ESP32 whether the player chose to buy or skip.

**Direction**: App → ESP32

```json
{
  "type": "purchase_response",
  "payload": {
    "action": "buy"
  }
}
```
`action` is either `"buy"` or `"skip"`.

#### 8. Card Decision Prompt (`card_decision_prompt`)
ESP32 asks the player to make an A/B choice on a Policy or Event card.

**Direction**: ESP32 → App

```json
{
  "type": "card_decision_prompt",
  "payload": {
    "card_id": "policy_02",
    "card_title": "Carbon Tax Regulation",
    "description": "The city council proposes a new carbon tax.",
    "choice_a": "Implement Strict Tax",
    "choice_a_desc": "+80 Sustainability, -40 Economy",
    "choice_b": "Relaxed Guidelines",
    "choice_b_desc": "+20 Sustainability, +30 Economy"
  }
}
```

#### 9. Card Decision Response (`card_decision_response`)
App sends the player's selected choice back to the ESP32.

**Direction**: App → ESP32

```json
{
  "type": "card_decision_response",
  "payload": {
    "card_id": "policy_02",
    "choice": "A"
  }
}
```
`choice` is either `"A"` or `"B"`.
