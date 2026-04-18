import 'dart:async';
import 'package:ecology_project/network.dart';
import 'package:ecology_project/protocol.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final NetworkManager network;

  const GamePage({super.key, required this.network});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final List<ProtocolMessage> _messages = [];
  late StreamSubscription<String> _messageSubscription;
  String _networkStatus = "Connected";

  @override
  void initState() {
    super.initState();
    widget.network.onStatusUpdate = (status) {
      if (mounted) {
        setState(() => _networkStatus = status);
      }
    };

    _messageSubscription = widget.network.messageStream.listen((rawMsg) {
      final protocolMsg = ProtocolMessage.fromJsonString(rawMsg);
      if (mounted) {
        setState(() {
          _messages.insert(0, protocolMsg);
          // Keep only the latest 50 messages
          if (_messages.length > 50) _messages.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }

  void _sendTestMessage() {
    // Sending a dummy game_state message
    final msg = ProtocolMessage(
      type: MessageType.gameState,
      payload: {"status": "started", "active_city": "Natural"},
    );
    widget.network.sendMessage(msg.toJsonString());
  }

  Widget _buildMessageItem(ProtocolMessage msg) {
    IconData icon;
    Color color;

    switch (msg.type) {
      case MessageType.rfid:
        icon = Icons.credit_card;
        color = Colors.blue;
        break;
      case MessageType.encoder:
        icon = Icons.rotate_right;
        color = Colors.orange;
        break;
      case MessageType.gameState:
        icon = Icons.videogame_asset;
        color = Colors.purple;
        break;
      case MessageType.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(msg.type.name.toUpperCase()),
      subtitle: Text(msg.payload.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Session"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                _networkStatus,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: const Text(
              "Waiting for sensor / game events...",
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _sendTestMessage,
              icon: const Icon(Icons.send),
              label: const Text("Send Test GameState"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
