import 'package:ecology_project/log.dart';
import 'dart:convert';

/// All message types understood by the app ↔ ESP32 protocol.
///
/// To add a new message type:
///   1. Add the enum value here.
///   2. Add the case in [_typeFromString] (string → enum).
///   3. Add the case in [_typeToString] (enum → string).
///   4. Optionally create a payload class below.
enum MessageType {
  // Client Intents (App -> ESP32)
  joinLobby,
  reconnect,
  setReady,
  actionPurchase,
  actionCardChoice,
  actionTransferFunds,
  actionViewOwnership,

  // Server Truths (ESP32 -> App)
  lobbyState,
  playerAssignment,
  gameStart,
  fullSync,
  turnUpdate,
  moveResult,
  promptScan,
  promptPurchase,
  promptCardChoice,
  errorMsg,
  cardResolved,
  timeoutWarning,
  gameState,
  ownershipState,

  // Hardware events / Testing
  rfid,
  encoder,
  cardAction, // testing-only
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
    'join_lobby': MessageType.joinLobby,
    'reconnect': MessageType.reconnect,
    'set_ready': MessageType.setReady,
    'action_purchase': MessageType.actionPurchase,
    'action_card_choice': MessageType.actionCardChoice,
    'action_transfer_funds': MessageType.actionTransferFunds,
    'action_view_ownership': MessageType.actionViewOwnership,
    'lobby_state': MessageType.lobbyState,
    'player_assignment': MessageType.playerAssignment,
    'game_start': MessageType.gameStart,
    'full_sync': MessageType.fullSync,
    'turn_update': MessageType.turnUpdate,
    'move_result': MessageType.moveResult,
    'prompt_scan': MessageType.promptScan,
    'prompt_purchase': MessageType.promptPurchase,
    'prompt_card_choice': MessageType.promptCardChoice,
    'error': MessageType.errorMsg,
    'card_resolved': MessageType.cardResolved,
    'timeout_warning': MessageType.timeoutWarning,
    'game_state': MessageType.gameState,
    'ownership_state': MessageType.ownershipState,
    'rfid': MessageType.rfid,
    'encoder': MessageType.encoder,
    'card_action': MessageType.cardAction,
  };

  static const Map<MessageType, String> _typeToString = {
    MessageType.joinLobby: 'join_lobby',
    MessageType.reconnect: 'reconnect',
    MessageType.setReady: 'set_ready',
    MessageType.actionPurchase: 'action_purchase',
    MessageType.actionCardChoice: 'action_card_choice',
    MessageType.actionTransferFunds: 'action_transfer_funds',
    MessageType.actionViewOwnership: 'action_view_ownership',
    MessageType.lobbyState: 'lobby_state',
    MessageType.playerAssignment: 'player_assignment',
    MessageType.gameStart: 'game_start',
    MessageType.fullSync: 'full_sync',
    MessageType.turnUpdate: 'turn_update',
    MessageType.moveResult: 'move_result',
    MessageType.promptScan: 'prompt_scan',
    MessageType.promptPurchase: 'prompt_purchase',
    MessageType.promptCardChoice: 'prompt_card_choice',
    MessageType.errorMsg: 'error',
    MessageType.cardResolved: 'card_resolved',
    MessageType.timeoutWarning: 'timeout_warning',
    MessageType.gameState: 'game_state',
    MessageType.ownershipState: 'ownership_state',
    MessageType.rfid: 'rfid',
    MessageType.encoder: 'encoder',
    MessageType.cardAction: 'card_action',
    MessageType.unknown: 'unknown',
  };

  factory ProtocolMessage.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String typeStr = data['type'] ?? 'unknown';
      final dynamic rawPayload = data['payload'];
      final Map<String, dynamic> payload = rawPayload is Map<String, dynamic>
          ? rawPayload
          : Map<String, dynamic>.from(data)..remove('type');

      final MessageType type = _typeFromString[typeStr] ?? MessageType.unknown;

      return ProtocolMessage(type: type, payload: payload);
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
