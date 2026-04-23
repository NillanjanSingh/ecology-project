import 'package:ecology_project/log.dart';
import 'dart:convert';

/// All message types understood by the app ↔ ESP32 protocol.
///
/// To add a new message type:
///   1. Add the enum value here.
///   2. Add the case in [ProtocolMessage.fromJsonString] (string → enum).
///   3. Add the case in [ProtocolMessage.toJsonString] (enum → string).
///   4. Optionally create a payload class below.
enum MessageType {
  rfid,
  encoder,
  gameState, // Global game state (status, phase, etc.)
  syncState, // Per-player metrics sync from ESP32
  purchasePrompt, // ESP32 offers an infrastructure tile
  purchaseResponse, // App responds buy/skip
  cardDecisionPrompt, // ESP32 asks for A/B policy/event choice
  cardDecisionResponse, // App sends chosen option
  unknown,
}

/// A generic protocol message with a [type] tag and arbitrary [payload].
class ProtocolMessage {
  final MessageType type;
  final Map<String, dynamic> payload;

  ProtocolMessage({required this.type, required this.payload});

  // ---- String ↔ Enum mapping tables ----
  // Kept as a static map so adding new types is a single-line change.

  static const Map<String, MessageType> _typeFromString = {
    'rfid': MessageType.rfid,
    'encoder': MessageType.encoder,
    'game_state': MessageType.gameState,
    'sync_state': MessageType.syncState,
    'purchase_prompt': MessageType.purchasePrompt,
    'purchase_response': MessageType.purchaseResponse,
    'card_decision_prompt': MessageType.cardDecisionPrompt,
    'card_decision_response': MessageType.cardDecisionResponse,
  };

  static const Map<MessageType, String> _typeToString = {
    MessageType.rfid: 'rfid',
    MessageType.encoder: 'encoder',
    MessageType.gameState: 'game_state',
    MessageType.syncState: 'sync_state',
    MessageType.purchasePrompt: 'purchase_prompt',
    MessageType.purchaseResponse: 'purchase_response',
    MessageType.cardDecisionPrompt: 'card_decision_prompt',
    MessageType.cardDecisionResponse: 'card_decision_response',
    MessageType.unknown: 'unknown',
  };

  factory ProtocolMessage.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String typeStr = data['type'] ?? 'unknown';
      final payload = data['payload'] ?? {};

      final MessageType type = _typeFromString[typeStr] ?? MessageType.unknown;

      return ProtocolMessage(
        type: type,
        payload: payload as Map<String, dynamic>,
      );
    } catch (e) {
      logger.e("Failed to parse message: $e");
      return ProtocolMessage(type: MessageType.unknown, payload: {});
    }
  }

  String toJsonString() {
    final typeStr = _typeToString[type] ?? 'unknown';
    return jsonEncode({'type': typeStr, 'payload': payload});
  }
}

// ---------------------------------------------------------
// Specific Payload Parsers
// ---------------------------------------------------------

class RfidPayload {
  final String uid;
  final int? boardId;

  RfidPayload({required this.uid, this.boardId});

  factory RfidPayload.fromMap(Map<String, dynamic> map) {
    return RfidPayload(
      uid: map['uid']?.toString() ?? '',
      boardId: map['board_id'],
    );
  }
}

class EncoderPayload {
  final int direction; // 1 for clockwise, -1 for counter-clockwise
  final int value;

  EncoderPayload({required this.direction, required this.value});

  factory EncoderPayload.fromMap(Map<String, dynamic> map) {
    return EncoderPayload(
      direction: map['direction'] ?? 0,
      value: map['value'] ?? 0,
    );
  }
}
