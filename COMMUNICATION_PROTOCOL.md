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

### Supported Message Types

#### 1. RFID Card Read (`rfid`)
Sent by the ESP32 when an RFID card is placed on one of the readers.

**Example:**
```json
{
  "type": "rfid",
  "payload": {
    "uid": "04A1B2C3D4E5F6",
    "board_id": 1 // identify which of the 4 boards read the card
  }
}
```

#### 2. Rotary Encoder Event (`encoder`)
Sent by the ESP32 when the user interacts with the rotary encoder.

**Example:**
```json
{
  "type": "encoder",
  "payload": {
    "direction": 1, // 1 for clockwise, -1 for counter-clockwise
    "value": 15     // The current absolute value or step count of the encoder
  }
}
```

#### 3. Game State Update (`game_state`)
Can be used to sync the overall state of the game between devices or boards.

**Example:**
```json
// This needs to be defined properly
{
  "type": "game_state",
  "payload": {
    "status": "in_progress",
    "active_city": "Natural",
    "eliminated_cities": ["Tech"]
  }
}
```
