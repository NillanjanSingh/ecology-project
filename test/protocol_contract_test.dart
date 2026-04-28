import 'dart:convert';

import 'package:ecology_project/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Protocol contract', () {
    test('encodes documented client intents', () {
      expect(
        ProtocolMessage(
          type: MessageType.joinLobby,
          payload: {'device_id': 'abc'},
        ).toJsonString(),
        contains('"type":"join_lobby"'),
      );

      expect(
        ProtocolMessage(
          type: MessageType.reconnect,
          payload: {'device_id': 'abc'},
        ).toJsonString(),
        contains('"type":"reconnect"'),
      );

      expect(
        ProtocolMessage(
          type: MessageType.setReady,
          payload: {'ready': true},
        ).toJsonString(),
        contains('"type":"set_ready"'),
      );

      expect(
        ProtocolMessage(
          type: MessageType.actionPurchase,
          payload: {'action': 'buy'},
        ).toJsonString(),
        contains('"type":"action_purchase"'),
      );

      expect(
        ProtocolMessage(
          type: MessageType.actionCardChoice,
          payload: {'choice': 'A'},
        ).toJsonString(),
        contains('"type":"action_card_choice"'),
      );

      expect(
        ProtocolMessage(
          type: MessageType.actionTransferFunds,
          payload: {'target_faction': 'Natural', 'amount': 20},
        ).toJsonString(),
        contains('"type":"action_transfer_funds"'),
      );
    });

    test('decodes documented server truths', () {
      final samples = <String, MessageType>{
        'lobby_state': MessageType.lobbyState,
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
      };

      for (final entry in samples.entries) {
        final msg = ProtocolMessage.fromJsonString(
          jsonEncode({'type': entry.key, 'payload': {}}),
        );
        expect(msg.type, entry.value, reason: 'failed for ${entry.key}');
      }
    });

    test('legacy message aliases are not accepted as official contract', () {
      final legacy = [
        'sync_state',
        'purchase_prompt',
        'purchase_response',
        'card_decision_prompt',
        'card_decision_response',
        'player_ready',
      ];

      for (final type in legacy) {
        final msg = ProtocolMessage.fromJsonString(
          jsonEncode({'type': type, 'payload': {}}),
        );
        expect(msg.type, MessageType.unknown, reason: 'legacy type $type');
      }
    });
  });
}
