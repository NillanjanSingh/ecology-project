import 'dart:async';

import 'package:flutter/material.dart';

import '../device_identity.dart';
import '../network.dart';
import '../protocol.dart';
import 'game_page.dart';

class LobbyPage extends StatefulWidget {
  final NetworkManager network;

  const LobbyPage({super.key, required this.network});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  static const int _defaultTotalPlayers = 4;

  StreamSubscription<String>? _subscription;
  String _status = 'Not connected';
  bool _isJoining = false;
  bool _hasJoinedLobby = false;
  bool _readySent = false;

  int _joinedPlayers = 0;
  int _readyPlayers = 0;
  int _totalPlayers = _defaultTotalPlayers;

  @override
  void initState() {
    super.initState();
    widget.network.onStatusUpdate = (status) {
      if (!mounted) return;
      setState(() => _status = status);
    };

    _subscription = widget.network.messageStream.listen(_onRawMessage);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _joinLobby() async {
    if (_isJoining || _hasJoinedLobby) {
      return;
    }

    setState(() {
      _isJoining = true;
      _status = 'Connecting to ESP...';
    });

    final ip = await widget.network.connect();
    if (!mounted) {
      return;
    }

    if (ip == null) {
      setState(() {
        _isJoining = false;
      });
      return;
    }

    final deviceId = await DeviceIdentity.getDeviceId();
    final joinMessage = ProtocolMessage(
      type: MessageType.joinLobby,
      payload: {'device_id': deviceId},
    );
    widget.network.sendMessage(joinMessage.toJsonString());

    setState(() {
      _isJoining = false;
      _hasJoinedLobby = true;
      _joinedPlayers = _joinedPlayers == 0 ? 1 : _joinedPlayers;
      _status = 'Joined lobby. Waiting for other players...';
    });
  }

  Future<void> _reconnectGame() async {
    if (_isJoining || _hasJoinedLobby) return;

    setState(() {
      _isJoining = true;
      _status = 'Reconnecting to ESP...';
    });

    final ip = await widget.network.connect();
    if (!mounted) return;

    if (ip == null) {
      setState(() => _isJoining = false);
      return;
    }

    final deviceId = await DeviceIdentity.getDeviceId();
    final reconnectMsg = ProtocolMessage(
      type: MessageType.reconnect,
      payload: {'device_id': deviceId},
    );
    widget.network.sendMessage(reconnectMsg.toJsonString());

    setState(() {
      _isJoining = false;
      _hasJoinedLobby = true;
      _status = 'Sent reconnect request. Waiting for full_sync...';
    });
  }

  void _sendReady() {
    if (!_hasJoinedLobby || _readySent) {
      return;
    }

    final readyMessage = ProtocolMessage(
      type: MessageType.setReady,
      payload: const {'ready': true},
    );
    widget.network.sendMessage(readyMessage.toJsonString());

    setState(() {
      _readySent = true;
      _status = 'Ready sent. Waiting for everyone else...';
    });
  }

  void _onRawMessage(String raw) {
    final message = ProtocolMessage.fromJsonString(raw);

    if (message.type == MessageType.lobbyState) {
      _applyLobbyState(message.payload);
      return;
    }

    if (message.type == MessageType.gameStart ||
        message.type == MessageType.fullSync) {
      _goToGame();
      return;
    }

    if (message.type == MessageType.gameState) {
      final status = message.payload['status']?.toString().toLowerCase();
      if (status == 'playing' ||
          status == 'in_progress' ||
          status == 'started') {
        _goToGame();
      }
    }
  }

  void _applyLobbyState(Map<String, dynamic> payload) {
    final joined = _readInt(payload, const [
      'joined_players',
      'joined',
      'connected_players',
      'total_connected',
    ]);
    final ready = _readInt(payload, const ['ready_players', 'ready_count']);
    final total = _readInt(payload, const [
      'total_players',
      'required_players',
      'total',
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _hasJoinedLobby = true;
      if (joined != null) {
        _joinedPlayers = joined;
      }
      if (ready != null) {
        _readyPlayers = ready;
      }
      if (total != null && total > 0) {
        _totalPlayers = total;
      }

      final allJoined = _joinedPlayers >= _totalPlayers;
      final allReady = _readyPlayers >= _totalPlayers && _totalPlayers > 0;
      if (allReady) {
        _status = 'All players ready. Waiting for game start signal...';
      } else if (allJoined) {
        _status = 'All players joined. Waiting for readiness...';
      } else {
        _status = 'Waiting for players: $_joinedPlayers/$_totalPlayers joined';
      }
    });
  }

  int? _readInt(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  void _goToGame() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GamePage(network: widget.network)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Game Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              Icons.groups_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Join Lobby',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 26),
            _LobbyCounterCard(
              joinedPlayers: _joinedPlayers,
              readyPlayers: _readyPlayers,
              totalPlayers: _totalPlayers,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: (_isJoining || _hasJoinedLobby) ? null : _joinLobby,
              icon: _isJoining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_hasJoinedLobby ? 'Joined Lobby' : 'Join Lobby'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (_isJoining || _hasJoinedLobby)
                  ? null
                  : _reconnectGame,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Reconnect to Active Game'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (!_hasJoinedLobby || _readySent) ? null : _sendReady,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(_readySent ? 'Ready Sent' : "I'm Ready"),
            ),
            const Spacer(),
            Text(
              'Game starts automatically when ESP32 confirms all players are ready.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyCounterCard extends StatelessWidget {
  final int joinedPlayers;
  final int readyPlayers;
  final int totalPlayers;

  const _LobbyCounterCard({
    required this.joinedPlayers,
    required this.readyPlayers,
    required this.totalPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final joinedText = '$joinedPlayers / $totalPlayers';
    final readyText = '$readyPlayers / $totalPlayers';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildRow('Players Joined', joinedText, Icons.people_outline_rounded),
          const Divider(height: 20),
          _buildRow('Players Ready', readyText, Icons.done_all_rounded),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }
}
