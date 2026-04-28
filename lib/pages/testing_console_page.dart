import 'dart:async';
import 'package:flutter/material.dart';
import '../network.dart';
import '../protocol.dart';

class LogEntry {
  final ProtocolMessage message;
  final bool isIncoming;
  final DateTime timestamp;
  final String rawString;

  LogEntry({
    required this.message,
    required this.isIncoming,
    required this.timestamp,
    required this.rawString,
  });
}

class TestingConsolePage extends StatefulWidget {
  final NetworkManager network;
  const TestingConsolePage({super.key, required this.network});

  @override
  State<TestingConsolePage> createState() => _TestingConsolePageState();
}

class _TestingConsolePageState extends State<TestingConsolePage> {
  final List<LogEntry> _logs = [];
  late StreamSubscription<String> _sub;
  String _networkStatus = "Connected";

  MessageType _selectedType = MessageType.gameState;

  // Form Controllers
  final _uidController = TextEditingController(text: "04A1B2C3D4E5F6");
  final _boardIdController = TextEditingController(text: "1");
  final _directionController = TextEditingController(text: "1");
  final _valueController = TextEditingController(text: "15");
  final _statusController = TextEditingController(text: "in_progress");
  final _activeCityController = TextEditingController(text: "Natural");
  final _eliminatedCitiesController = TextEditingController(
    text: "Technological",
  );
  final _actionController = TextEditingController(text: "implement_policy");
  final _policyIdController = TextEditingController(text: "air_policy_A");
  final _costController = TextEditingController(text: "50");

  @override
  void initState() {
    super.initState();
    widget.network.onStatusUpdate = (s) {
      if (mounted) setState(() => _networkStatus = s);
    };
    _sub = widget.network.messageStream.listen((rawMsg) {
      final msg = ProtocolMessage.fromJsonString(rawMsg);
      _addLog(msg, true, rawMsg);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _uidController.dispose();
    _boardIdController.dispose();
    _directionController.dispose();
    _valueController.dispose();
    _statusController.dispose();
    _activeCityController.dispose();
    _eliminatedCitiesController.dispose();
    _actionController.dispose();
    _policyIdController.dispose();
    _costController.dispose();
    super.dispose();
  }

  void _addLog(ProtocolMessage msg, bool isIncoming, String raw) {
    if (!mounted) return;
    setState(() {
      _logs.insert(
        0,
        LogEntry(
          message: msg,
          isIncoming: isIncoming,
          timestamp: DateTime.now(),
          rawString: raw,
        ),
      );
    });
  }

  void _sendMessage() {
    Map<String, dynamic> payload = {};

    switch (_selectedType) {
      case MessageType.rfid:
        payload = {
          "uid": _uidController.text,
          "board_id": int.tryParse(_boardIdController.text) ?? 1,
        };
        break;
      case MessageType.encoder:
        payload = {
          "direction": int.tryParse(_directionController.text) ?? 1,
          "value": int.tryParse(_valueController.text) ?? 15,
        };
        break;
      case MessageType.gameState:
        payload = {
          "status": _statusController.text,
          "active_city": _activeCityController.text,
          "eliminated_cities": _eliminatedCitiesController.text
              .split(",")
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList(),
        };
        break;
      case MessageType.cardAction:
        payload = {
          "action": _actionController.text,
          "policy_id": _policyIdController.text,
          "cost": int.tryParse(_costController.text) ?? 50,
        };
        break;
      case MessageType.unknown:
      case MessageType.reconnect:
      case MessageType.actionTransferFunds:
      case MessageType.fullSync:
      case MessageType.turnUpdate:
      case MessageType.moveResult:
      case MessageType.promptScan:
      case MessageType.promptPurchase:
      case MessageType.actionPurchase:
      case MessageType.promptCardChoice:
      case MessageType.actionCardChoice:
      case MessageType.errorMsg:
      case MessageType.cardResolved:
      case MessageType.timeoutWarning:
      case MessageType.joinLobby:
      case MessageType.setReady:
      case MessageType.lobbyState:
      case MessageType.gameStart:
        payload = {};
        break;
    }

    final msg = ProtocolMessage(type: _selectedType, payload: payload);
    final rawString = msg.toJsonString();
    widget.network.sendMessage(rawString);
    _addLog(msg, false, rawString);
  }

  void _showLogDetails(LogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "${log.isIncoming ? 'Received' : 'Sent'} ${log.message.type.name}",
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            log.rawString,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildPayloadFields() {
    switch (_selectedType) {
      case MessageType.rfid:
        return Column(
          children: [
            TextField(
              controller: _uidController,
              decoration: const InputDecoration(labelText: "UID"),
            ),
            TextField(
              controller: _boardIdController,
              decoration: const InputDecoration(labelText: "Board ID"),
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case MessageType.encoder:
        return Column(
          children: [
            TextField(
              controller: _directionController,
              decoration: const InputDecoration(
                labelText: "Direction (1 or -1)",
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _valueController,
              decoration: const InputDecoration(labelText: "Value"),
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case MessageType.gameState:
        return Column(
          children: [
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: "Status (e.g. in_progress)",
              ),
            ),
            TextField(
              controller: _activeCityController,
              decoration: const InputDecoration(
                labelText: "Active City (e.g. Natural)",
              ),
            ),
            TextField(
              controller: _eliminatedCitiesController,
              decoration: const InputDecoration(
                labelText: "Eliminated Cities (comma separated)",
              ),
            ),
          ],
        );
      case MessageType.cardAction:
        return Column(
          children: [
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: "Action (e.g. implement_policy)",
              ),
            ),
            TextField(
              controller: _policyIdController,
              decoration: const InputDecoration(labelText: "Policy ID"),
            ),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(labelText: "Cost"),
              keyboardType: TextInputType.number,
            ),
          ],
        );
      case MessageType.unknown:
      case MessageType.reconnect:
      case MessageType.actionTransferFunds:
      case MessageType.fullSync:
      case MessageType.turnUpdate:
      case MessageType.moveResult:
      case MessageType.promptScan:
      case MessageType.promptPurchase:
      case MessageType.actionPurchase:
      case MessageType.promptCardChoice:
      case MessageType.actionCardChoice:
      case MessageType.errorMsg:
      case MessageType.cardResolved:
      case MessageType.timeoutWarning:
      case MessageType.joinLobby:
      case MessageType.setReady:
      case MessageType.lobbyState:
      case MessageType.gameStart:
        return const Text("Unknown payload");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Testing Console"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_networkStatus),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Send Form
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<MessageType>(
                  value: _selectedType,
                  isExpanded: true,
                  items: MessageType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
                const SizedBox(height: 8),
                _buildPayloadFields(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  label: const Text("Send Message"),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Logs list
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return ListTile(
                  leading: Icon(
                    log.isIncoming ? Icons.download : Icons.upload,
                    color: log.isIncoming ? Colors.green : Colors.blue,
                  ),
                  title: Text(log.message.type.name.toUpperCase()),
                  subtitle: Text(
                    "${log.timestamp.toLocal().toString().split('.').first}\n${log.message.payload}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  onTap: () => _showLogDetails(log),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
