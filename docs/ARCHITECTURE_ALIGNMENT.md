# Architecture Alignment Checklist (Flutter App ↔ ESP32)

This file defines the implementation requirements to keep the app perfectly aligned with:
- `docs/GAME_ARCHITECTURE.md`
- `docs/COMMUNICATION_PROTOCOL.md`

## 1. Transport and Envelope
- WebSocket URI must be `ws://<ESP_IP>:81/`.
- Every frame must be JSON with:
  - `type` (string)
  - `payload` (object)

## 2. Supported Message Types (Strict)
Only the documented types are part of production contract.

### Client → Server
- `join_lobby`
- `reconnect`
- `set_ready`
- `action_purchase`
- `action_card_choice`
- `action_transfer_funds`

### Server → Client
- `lobby_state`
- `game_start`
- `full_sync`
- `turn_update`
- `move_result`
- `prompt_scan`
- `prompt_purchase`
- `prompt_card_choice`
- `error`
- `card_resolved`
- `timeout_warning`
- `game_state`

Unsupported or undocumented message types must be rejected as `unknown`.

## 3. Faction Wire Values
On-wire faction names must match protocol exactly:
- `Natural`
- `Manufacturing`
- `Tourism`
- `Technological`

App-internal enums may differ, but serialization/deserialization must map to these values.

## 4. Reconnect / Full Sync Requirements
When receiving `full_sync`, app must:
1. Restore `my_faction`.
2. Restore `current_turn_faction`.
3. Apply embedded `game_state`.
4. Restore `pending_prompt` exactly:
   - `prompt_purchase` → purchase modal
   - `prompt_card_choice` → choice modal
   - `prompt_scan` → scan overlay

## 5. Validation Rules
- Validate required fields per message before applying state.
- Malformed messages should be logged and ignored (no partial apply).

## 6. Lobby Transition Rules
- Transition Lobby → Game only on:
  - `game_start`
  - `full_sync`
- Do not infer start from undocumented payload conventions.

## 7. Testing Requirements
Automated tests must verify:
- Type mapping for all documented message types.
- Unknown handling for unsupported/non-contract types.
- Correct encoding of all outgoing intent types.
