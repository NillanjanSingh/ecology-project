# Architecture Alignment Checklist (Flutter App ↔ ESP32)

This file defines the implementation requirements to keep the app perfectly aligned with:
- `docs/GAME_ARCHITECTURE.md`
- `docs/COMMUNICATION_PROTOCOL.md`
- `docs/GAME_DATA_MODEL.md`

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

## 4. Economy and Tile Rules
- Infrastructure `Budget` values are the economy cost.
- Every player starts with a base of `60cr`.
- `provider` cost equals the `Budget` value.
- `taker` cost equals `25%` of provider cost for the next `3` rounds.
- Synergy activates only when all listed infrastructure tiles are owned by the same city.
- Synergy points are added directly to the player's current total points.
- `Mandate` means the forced-resolution set containing `Disaster` and `Event-2`.
- `Emission` and `Pollution Index` are burden metrics where lower values are better.

## 5. Reconnect / Full Sync Requirements
When receiving `full_sync`, app must:
1. Restore `my_faction`.
2. Restore `current_turn_faction`.
3. Apply embedded `game_state`.
4. Restore `pending_prompt` exactly:
   - `prompt_purchase` → purchase modal
   - `prompt_card_choice` → choice modal
   - `prompt_scan` → scan overlay

## 6. Validation Rules
- Validate required fields per message before applying state.
- Malformed messages should be logged and ignored (no partial apply).
- `prompt_purchase` must be treated as an infrastructure role-selection prompt, not a simple buy/skip prompt.
- `game_state` must be able to render:
  - core metrics
  - secondary metrics
  - infrastructure role assignments
  - active synergies
  - pending future effects

## 7. Lobby Transition Rules
- Transition Lobby → Game only on:
  - `game_start`
  - `full_sync`
- Do not infer start from undocumented payload conventions.

## 8. Testing Requirements
Automated tests must verify:
- Type mapping for all documented message types.
- Unknown handling for unsupported/non-contract types.
- Correct encoding of all outgoing intent types.
- Correct rendering/decoding of provider vs taker infrastructure decisions.
- Correct rendering/decoding of synergy and future-effect state supplied by ESP32.
