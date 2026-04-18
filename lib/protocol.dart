import 'package:ecology_project/log.dart';
import 'dart:convert';

enum MessageType { rfid, encoder, gameState, unknown }

class ProtocolMessage {
  final MessageType type;
  final Map<String, dynamic> payload;

  ProtocolMessage({required this.type, required this.payload});

  factory ProtocolMessage.fromJsonString(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final String typeStr = data['type'] ?? 'unknown';
      final payload = data['payload'] ?? {};

      MessageType type = MessageType.unknown;
      switch (typeStr) {
        case 'rfid':
          type = MessageType.rfid;
          break;
        case 'encoder':
          type = MessageType.encoder;
          break;
        case 'game_state':
          type = MessageType.gameState;
          break;
      }

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
    String typeStr;
    switch (type) {
      case MessageType.rfid:
        typeStr = 'rfid';
        break;
      case MessageType.encoder:
        typeStr = 'encoder';
        break;
      case MessageType.gameState:
        typeStr = 'game_state';
        break;
      case MessageType.unknown:
        typeStr = 'unknown';
    }

    return jsonEncode({'type': typeStr, 'payload': payload});
  }
}

// Specific Payload Parsers

class RfidPayload {
  final String uid;
  RfidPayload({required this.uid});

  factory RfidPayload.fromMap(Map<String, dynamic> map) {
    return RfidPayload(uid: map['uid']?.toString() ?? '');
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
