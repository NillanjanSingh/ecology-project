import 'dart:async';

import 'package:flutter/material.dart';

import '../device_identity.dart';
import '../network.dart';
import '../protocol.dart';
import '../theme/app_chrome.dart';
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
  String? _assignedFaction;

  int _joinedPlayers = 0;
  int _readyPlayers = 0;
  int _totalPlayers = _defaultTotalPlayers;
  List<Map<String, dynamic>> _players = [];

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
    if (_isJoining || _hasJoinedLobby) return;

    setState(() {
      _isJoining = true;
      _status = 'Connecting to ESP...';
    });

    final ip = await widget.network.connect();
    if (!mounted) return;
    if (ip == null) {
      setState(() => _isJoining = false);
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

  Future<void> _sendReady() async {
    if (!_hasJoinedLobby || _readySent) return;

    final deviceId = await DeviceIdentity.getDeviceId();
    final readyMessage = ProtocolMessage(
      type: MessageType.setReady,
      payload: {'device_id': deviceId, 'ready': true},
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

    if (message.type == MessageType.playerAssignment) {
      _applyPlayerAssignment(message.payload);
      return;
    }

    if (message.type == MessageType.gameStart ||
        message.type == MessageType.fullSync) {
      _goToGame();
    }
  }

  void _applyPlayerAssignment(Map<String, dynamic> payload) {
    if (!mounted) return;

    final faction = payload['faction']?.toString();
    final confirmedReady = payload['ready_confirmed'] == true;

    setState(() {
      _assignedFaction = faction;
      _status = faction == null
          ? 'Ready acknowledged. Waiting for faction assignment...'
          : confirmedReady
          ? 'Ready confirmed. Assigned faction: $faction'
          : 'Faction assigned: $faction';
    });
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
    final playersList = payload['players'] as List<dynamic>?;

    if (!mounted) return;

    setState(() {
      _hasJoinedLobby = true;
      if (joined != null) _joinedPlayers = joined;
      if (ready != null) _readyPlayers = ready;
      if (total != null && total > 0) _totalPlayers = total;
      if (playersList != null) {
        _players = playersList.map((e) => e as Map<String, dynamic>).toList();
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
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  void _goToGame() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GamePage(network: widget.network)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width >= 820;

    return Scaffold(
      body: Container(
        decoration: AppChrome.screenBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _buildHeroPanel()),
                          const SizedBox(width: 18),
                          Expanded(flex: 4, child: _buildControlPanel()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildHeroPanel(),
                          const SizedBox(height: 18),
                          _buildControlPanel(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppChrome.panelDecoration(
        color: AppChrome.bgAlt,
        radius: 30,
        glow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppChrome.sectionTitle(
            'PRE-GAME LOBBY',
            subtitle: 'Connect, confirm identity, and wait for the board to arm the next session.',
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricCard(
                'Connected',
                '$_joinedPlayers / $_totalPlayers',
                Icons.hub_rounded,
                AppChrome.cyan,
              ),
              _metricCard(
                'Ready',
                '$_readyPlayers / $_totalPlayers',
                Icons.check_circle_outline_rounded,
                AppChrome.mint,
              ),
              _metricCard(
                'Assignment',
                _assignedFaction ?? 'Pending',
                Icons.verified_user_outlined,
                AppChrome.gold,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppChrome.panelDecoration(
              color: AppChrome.panelSoft,
              border: AppChrome.line,
              radius: 24,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _status.contains('Connected') ||
                            _status.contains('Joined') ||
                            _status.contains('Ready')
                        ? AppChrome.mint.withValues(alpha: 0.18)
                        : AppChrome.coral.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    _status.contains('Connected') ||
                            _status.contains('Joined') ||
                            _status.contains('Ready')
                        ? Icons.podcasts_rounded
                        : Icons.portable_wifi_off_rounded,
                    color: _status.contains('Connected') ||
                            _status.contains('Joined') ||
                            _status.contains('Ready')
                        ? AppChrome.mint
                        : AppChrome.coral,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link Status',
                        style: AppChrome.eyebrow.copyWith(color: AppChrome.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _status,
                        style: const TextStyle(
                          color: AppChrome.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connected Cities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppChrome.text,
            ),
          ),
          const SizedBox(height: 12),
          if (_players.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppChrome.panelDecoration(
                color: AppChrome.panelSoft,
                border: AppChrome.line,
                radius: 20,
              ),
              child: const Text(
                'No confirmed players yet. Join the lobby to begin synchronization.',
                style: TextStyle(color: AppChrome.textMuted),
              ),
            )
          else
            ..._players.map(_buildPlayerTile),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppChrome.panelDecoration(
        color: AppChrome.panel,
        radius: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppChrome.sectionTitle(
            'Operator Actions',
            subtitle: 'The board remains authoritative. Wait for `player_assignment` before treating your faction as confirmed.',
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: (_isJoining || _hasJoinedLobby) ? null : _joinLobby,
            icon: _isJoining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(_hasJoinedLobby ? 'JOINED LOBBY' : 'JOIN LOBBY'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: (_isJoining || _hasJoinedLobby) ? null : _reconnectGame,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('RECONNECT ACTIVE GAME'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: (!_hasJoinedLobby || _readySent) ? null : _sendReady,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: Text(_readySent ? 'READY LOCKED IN' : 'SEND READY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppChrome.gold,
              foregroundColor: AppChrome.bg,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppChrome.panelDecoration(
              color: AppChrome.bgAlt,
              border: AppChrome.line,
              radius: 22,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Launch Condition',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppChrome.text,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The app moves into gameplay only after the ESP32 confirms the live session with `game_start` or `full_sync`.',
                  style: TextStyle(color: AppChrome.textMuted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: AppChrome.panelDecoration(
        color: AppChrome.panelSoft,
        border: color,
        radius: 22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: AppChrome.eyebrow),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppChrome.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Map<String, dynamic> player) {
    final faction = player['faction']?.toString() ?? 'Unknown';
    final ready = player['is_ready'] == true || player['ready'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppChrome.panelDecoration(
        color: AppChrome.panelSoft,
        border: ready ? AppChrome.mint : AppChrome.line,
        radius: 18,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: ready
                  ? AppChrome.mint.withValues(alpha: 0.16)
                  : AppChrome.bgAlt.withValues(alpha: 0.8),
            ),
            child: Icon(
              ready ? Icons.check_rounded : Icons.schedule_rounded,
              color: ready ? AppChrome.mint : AppChrome.textMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              faction,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            ready ? 'READY' : 'WAITING',
            style: TextStyle(
              color: ready ? AppChrome.mint : AppChrome.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
