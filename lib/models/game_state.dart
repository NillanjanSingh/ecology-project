import 'dart:convert';
import 'package:flutter/material.dart';
import '../protocol.dart';
import '../network.dart';
import '../device_identity.dart';
import '../log.dart';
import 'dart:async';

// --- Data Enums & Classes ---

/// The four city types a player can control.
enum FactionType { natural, manufacturing, tourism, technological }

extension FactionTypeExtension on FactionType {
  String get displayName {
    switch (this) {
      case FactionType.natural:
        return 'Natural';
      case FactionType.manufacturing:
        return 'Manufacturing';
      case FactionType.tourism:
        return 'Tourism';
      case FactionType.technological:
        return 'Technological';
    }
  }

  Color get color {
    switch (this) {
      case FactionType.natural:
        return const Color(0xFF2E7D32); // Forest Green
      case FactionType.manufacturing:
        return const Color(0xFFE65100); // Manufacturing Orange
      case FactionType.tourism:
        return const Color(0xFF00897B); // Tourism Teal
      case FactionType.technological:
        return const Color(0xFF1565C0); // Tech Blue
    }
  }

  IconData get icon {
    switch (this) {
      case FactionType.natural:
        return Icons.park;
      case FactionType.manufacturing:
        return Icons.factory;
      case FactionType.tourism:
        return Icons.flight_takeoff;
      case FactionType.technological:
        return Icons.memory;
    }
  }
}

class PlayerData {
  final String? deviceId;
  final FactionType faction;
  final bool isEliminated;
  final int bankBalance;
  final PlayerMetrics metrics;
  final List<String> ownedItems;

  PlayerData({
    this.deviceId,
    required this.faction,
    required this.isEliminated,
    required this.bankBalance,
    required this.metrics,
    this.ownedItems = const [],
  });

  factory PlayerData.fromMap(
    Map<String, dynamic> map,
    FactionType defaultFaction,
  ) {
    final metricsPayload =
        map['metrics'] as Map<String, dynamic>? ??
        map['factors'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final bank =
        _asInt(map['bank_balance']) ??
        _asInt(map['bankBalance']) ??
        _asInt(map['balance']) ??
        0;
    final eliminated =
        map['is_eliminated'] == true || map['isEliminated'] == true;

    return PlayerData(
      deviceId: map['device_id']?.toString(),
      faction: _parseFactionStatic(map['faction']) ?? defaultFaction,
      isEliminated: eliminated,
      bankBalance: bank,
      metrics: PlayerMetrics.fromMap(metricsPayload),
      ownedItems: _parseOwnedItems(map),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _parseOwnedItems(Map<String, dynamic> map) {
    const keys = [
      'owned_items',
      'owned_infrastructure',
      'purchased_items',
      'inventory',
      'assets',
    ];

    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value
            .map((e) {
              if (e is String) return e.trim();
              if (e is Map<String, dynamic>) {
                return e['name']?.toString().trim() ?? '';
              }
              return e.toString().trim();
            })
            .where((name) => name.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  static FactionType? _parseFactionStatic(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return FactionType.natural;
        case 1:
          return FactionType.manufacturing;
        case 2:
          return FactionType.tourism;
        case 3:
          return FactionType.technological;
      }
    }
    final s = value?.toString().toLowerCase() ?? '';
    if (s.contains('natural')) return FactionType.natural;
    if (s.contains('software') || s.contains('industrial')) {
      return FactionType.manufacturing;
    }
    if (s.contains('financial')) return FactionType.tourism;
    if (s.contains('manufact')) return FactionType.manufacturing;
    if (s.contains('tour')) return FactionType.tourism;
    if (s.contains('technological')) {
      return FactionType.technological;
    }
    return null;
  }
}

/// Holds the four core metric values for a player.
class PlayerMetrics {
  final double sustainability;
  final double smart;
  final double livability;
  final double economy;

  const PlayerMetrics({
    this.sustainability = 0.0,
    this.smart = 0.0,
    this.livability = 0.0,
    this.economy = 0.0,
  });

  /// Total score is the sum of all four metrics.
  int get totalScore => (sustainability + smart + livability + economy).round();

  /// Create from a JSON map payload.
  factory PlayerMetrics.fromMap(Map<String, dynamic> map) {
    return PlayerMetrics(
      sustainability: (map['sustainability'] ?? 0).toDouble(),
      smart: (map['smart'] ?? 0).toDouble(),
      livability: (map['livability'] ?? 0).toDouble(),
      economy: (map['economy'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sustainability': sustainability,
    'smart': smart,
    'livability': livability,
    'economy': economy,
  };
}

/// Represents an active card (Disaster, Policy, or Event) with a countdown.
class ActiveCard {
  final String id;
  final String name;
  final String type; // "disaster", "policy", "event"
  final String description;
  final int remainingLaps;

  ActiveCard({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    required this.remainingLaps,
  });

  factory ActiveCard.fromMap(Map<String, dynamic> map) {
    return ActiveCard(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown Card',
      type: map['type']?.toString() ?? 'event',
      description: map['description']?.toString() ?? '',
      remainingLaps: map['remaining_laps'] ?? 0,
    );
  }

  IconData get icon {
    switch (type.toLowerCase()) {
      case 'disaster':
        return Icons.warning_amber_rounded;
      case 'policy':
        return Icons.gavel;
      case 'event':
        return Icons.event;
      default:
        return Icons.help_outline;
    }
  }

  Color get color {
    switch (type.toLowerCase()) {
      case 'disaster':
        return const Color(0xFFEF5350); // Red
      case 'policy':
        return const Color(0xFF42A5F5); // Blue
      case 'event':
        return const Color(0xFFFFCA28); // Amber
      default:
        return Colors.grey;
    }
  }
}

/// Represents a purchase prompt from the ESP32.
class PurchasePrompt {
  final String infrastructureName;
  final String description;
  final int providerCost;
  final int? takerCost;
  final bool providerAvailable;
  final bool takerAvailable;
  final bool isOwned;
  final String? ownerFaction;
  final Map<String, dynamic> effects;

  PurchasePrompt({
    required this.infrastructureName,
    this.description = '',
    required this.providerCost,
    this.takerCost,
    this.providerAvailable = true,
    this.takerAvailable = true,
    this.isOwned = false,
    this.ownerFaction,
    this.effects = const {},
  });

  factory PurchasePrompt.fromMap(Map<String, dynamic> map) {
    final providerOption = map['provider_option'] as Map<String, dynamic>?;
    final takerOption = map['taker_option'] as Map<String, dynamic>?;
    final providerCost =
        _asInt(providerOption?['cost_points']) ??
        _asInt(map['cost']) ??
        _asInt(map['budget']) ??
        0;
    final takerCost =
        _asInt(takerOption?['cost_points']) ?? _asInt(map['taker_cost']);
    final immediateScores = map['immediate_scores'] as Map<String, dynamic>?;
    final providerAvailable = _asBool(providerOption?['available']) ?? true;
    final takerAvailable = _asBool(takerOption?['available']) ?? true;
    final isOwned = _asBool(map['is_owned']) ?? false;
    final ownerFaction = map['owner_faction']?.toString();

    return PurchasePrompt(
      infrastructureName: map['name']?.toString() ?? 'Unknown',
      description: map['description']?.toString() ?? '',
      providerCost: providerCost,
      takerCost: takerCost,
      providerAvailable: providerAvailable,
      takerAvailable: takerAvailable,
      isOwned: isOwned,
      ownerFaction: ownerFaction,
      effects: immediateScores ?? map['effects'] ?? {},
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}

/// Represents a card decision prompt (A/B choice) from the ESP32.
class CardDecisionPrompt {
  final String cardId;
  final String cardTitle;
  final String description;
  final String choiceA;
  final String choiceADescription;
  final String choiceB;
  final String choiceBDescription;

  CardDecisionPrompt({
    required this.cardId,
    required this.cardTitle,
    this.description = '',
    required this.choiceA,
    this.choiceADescription = '',
    required this.choiceB,
    this.choiceBDescription = '',
  });

  factory CardDecisionPrompt.fromMap(Map<String, dynamic> map) {
    final parsedA = _parseChoice(map['choice_a']);
    final parsedB = _parseChoice(map['choice_b']);

    return CardDecisionPrompt(
      cardId: map['card_id']?.toString() ?? '',
      cardTitle: map['card_title']?.toString() ?? 'Decision Required',
      description: map['description']?.toString() ?? '',
      choiceA: parsedA.$1,
      choiceADescription: parsedA.$2,
      choiceB: parsedB.$1,
      choiceBDescription: parsedB.$2,
    );
  }

  static (String, String) _parseChoice(dynamic raw) {
    if (raw is String) {
      return (raw, '');
    }
    if (raw is Map<String, dynamic>) {
      final title = raw['name']?.toString() ?? 'Option';
      final effects = raw['effects'] as Map<String, dynamic>?;
      if (effects == null || effects.isEmpty) {
        return (title, raw['description']?.toString() ?? '');
      }
      final parts = effects.entries
          .map((e) {
            final v = e.value;
            final n = v is num ? v : num.tryParse(v.toString());
            if (n == null) return null;
            final sign = n > 0 ? '+' : '';
            return '$sign${n.toString()} ${e.key}';
          })
          .whereType<String>()
          .toList();
      return (title, parts.join('  •  '));
    }
    return ('Option', '');
  }
}

/// A log entry for the status feed.
class GameLogEntry {
  final String message;
  final DateTime timestamp;
  final String severity; // "info", "warning", "success", "error"

  GameLogEntry({
    required this.message,
    DateTime? timestamp,
    this.severity = 'info',
  }) : timestamp = timestamp ?? DateTime.now();

  factory GameLogEntry.fromMap(Map<String, dynamic> map) {
    return GameLogEntry(
      message: map['message']?.toString() ?? '',
      severity: map['severity']?.toString() ?? 'info',
    );
  }
}

// --- State Management ---

/// The central game state notifier. Listens to [NetworkManager.messageStream],
/// parses incoming [ProtocolMessage]s, and updates the UI state accordingly.
///
/// This class is designed so the protocol parsing is isolated in [_handleMessage].
/// When the real ESP32 protocol is finalized, only the switch/case bodies and
/// payload classes need to change.
class GameStateProvider extends ChangeNotifier {
  // --- Connection ---
  final NetworkManager network;
  StreamSubscription<String>? _subscription;
  String? deviceId;

  // --- Player Identity ---
  FactionType? _faction;
  FactionType? get faction => _faction;
  bool get hasAssignedFaction => _faction != null;
  String get factionLabel => _faction?.displayName ?? 'Unassigned';
  Color get factionColor => _faction?.color ?? const Color(0xFF78909C);
  IconData get factionIcon => _faction?.icon ?? Icons.help_outline_rounded;

  // --- Metrics ---
  PlayerMetrics _metrics = const PlayerMetrics();
  PlayerMetrics get metrics => _metrics;

  // --- Bank ---
  int _bankBalance = 1000;
  int get bankBalance => _bankBalance;

  // --- Active Cards ---
  final List<ActiveCard> _activeCards = [];
  List<ActiveCard> get activeCards => List.unmodifiable(_activeCards);

  // --- Game Log ---
  final List<GameLogEntry> _logEntries = [];
  List<GameLogEntry> get logEntries => List.unmodifiable(_logEntries);

  // --- Turn / Round ---
  int _currentLap = 1;
  int get currentLap => _currentLap;

  FactionType? _currentTurnFaction;
  FactionType? get currentTurnFaction => _currentTurnFaction;

  String _gamePhase = 'waiting'; // waiting, playing, ended
  String get gamePhase => _gamePhase;

  // --- Players Data ---
  bool _isEliminated = false;
  bool get isEliminated => _isEliminated;

  List<PlayerData> _allPlayers = [];
  List<PlayerData> get allPlayers => List.unmodifiable(_allPlayers);

  List<PlayerData> get opponents {
    if (_faction == null) return const [];
    return _allPlayers.where((p) => p.faction != _faction).toList();
  }

  PlayerData? get myPlayerData {
    if (_faction == null) return null;
    try {
      return _allPlayers.firstWhere((p) => p.faction == _faction);
    } catch (_) {
      return null;
    }
  }

  // --- Pending Prompts (for modals) ---
  PurchasePrompt? _pendingPurchase;
  PurchasePrompt? get pendingPurchase => _pendingPurchase;

  CardDecisionPrompt? _pendingDecision;
  CardDecisionPrompt? get pendingDecision => _pendingDecision;

  bool _isPromptingScan = false;
  bool get isPromptingScan => _isPromptingScan;
  String? _scanPromptMessage;
  String? get scanPromptMessage => _scanPromptMessage;

  // Ascension target
  static const int ascensionTarget = 4000;

  GameStateProvider({required this.network}) {
    _loadDeviceId();
    _subscription = network.messageStream.listen(_onRawMessage);
  }

  // -------------------------------------------------------
  // Message handling
  // -------------------------------------------------------

  void _onRawMessage(String raw) {
    final msg = ProtocolMessage.fromJsonString(raw);
    _handleMessage(msg);
  }

  /// Central message dispatcher.
  /// When the protocol changes, update the cases here.
  void _handleMessage(ProtocolMessage msg) {
    switch (msg.type) {
      case MessageType.fullSync:
        if (!_requireMapFields(msg.payload, const ['game_state'])) return;
        _handleSyncState(msg.payload);
        break;
      case MessageType.gameState:
        _handleGameState(_normalizeGameStatePayload(msg.payload));
        break;
      case MessageType.playerAssignment:
        if (!_requireMapFields(msg.payload, const ['faction'])) return;
        _handlePlayerAssignment(msg.payload);
        break;
      case MessageType.ownershipState:
        if (!_requireMapFields(msg.payload, const ['players'])) return;
        _handleOwnershipState(msg.payload);
        break;
      case MessageType.turnUpdate:
        if (!_requireAnyMapFields(msg.payload, const [
          'active_faction',
          'active_device_id',
          'current_turn_faction',
          'current_turn_device_id',
          'faction',
          'device_id',
          'player',
        ])) {
          return;
        }
        _handleTurnUpdate(msg.payload);
        break;
      case MessageType.moveResult:
        if (!_requireMapFields(msg.payload, const ['spaces_moved']) ||
            !_requireAnyMapFields(msg.payload, const ['faction', 'device_id'])) {
          return;
        }
        _handleMoveResult(msg.payload);
        break;
      case MessageType.cardResolved:
        if (!_requireMapFields(msg.payload, const ['card_title']) ||
            !_requireAnyMapFields(msg.payload, const ['target_faction', 'target_device_id'])) {
          return;
        }
        _handleCardResolved(msg.payload);
        break;
      case MessageType.promptPurchase:
        if (!_requireMapFields(msg.payload, const ['name', 'budget', 'provider_option'])) return;
        _isPromptingScan = false;
        _handlePurchasePrompt(msg.payload);
        break;
      case MessageType.promptCardChoice:
        if (!_requireMapFields(msg.payload, const [
          'card_title',
          'choice_a',
          'choice_b',
        ])) {
          return;
        }
        _isPromptingScan = false;
        _handleCardDecisionPrompt(msg.payload);
        break;
      case MessageType.promptScan:
        _isPromptingScan = true;
        _scanPromptMessage = msg.payload['message']?.toString();
        _addLog(
          _scanPromptMessage ?? 'Please scan a card...',
          severity: 'warning',
        );
        notifyListeners();
        break;
      case MessageType.timeoutWarning:
        _isPromptingScan = false;
        _pendingDecision = null;
        _pendingPurchase = null;
        _addLog(
          msg.payload['message']?.toString() ?? 'Action timed out',
          severity: 'warning',
        );
        notifyListeners();
        break;
      case MessageType.rfid:
        _addLog('RFID scanned: ${msg.payload['uid']}', severity: 'info');
        break;
      case MessageType.encoder:
        _addLog(
          'Encoder: direction=${msg.payload['direction']}, value=${msg.payload['value']}',
          severity: 'info',
        );
        break;
      case MessageType.lobbyState:
      case MessageType.joinLobby:
      case MessageType.setReady:
      case MessageType.gameStart:
      case MessageType.actionViewOwnership:
        // Lobby events are handled by the lobby screen; ignore in in-game state.
        break;
      default:
        _addLog('Unknown message received', severity: 'warning');
        break;
    }
  }

  void _handleSyncState(Map<String, dynamic> payload) {
    if (payload['my_faction'] != null) {
      final parsedFaction = _parseFaction(payload['my_faction']);
      if (parsedFaction != null) {
        _faction = parsedFaction;
      }
    }
    if (payload['current_turn_faction'] != null) {
      _currentTurnFaction = _parseFaction(payload['current_turn_faction']);
    }
    if (payload['game_state'] != null) {
      _handleGameState(payload['game_state'] as Map<String, dynamic>);
    }
    _restorePendingPrompt(payload['pending_prompt']);

    _addLog('Full state synced.', severity: 'success');
  }

  void _handlePlayerAssignment(Map<String, dynamic> payload) {
    final parsedFaction = _parseFaction(payload['faction']);
    if (parsedFaction == null) {
      _addLog('Received unknown faction assignment', severity: 'error');
      notifyListeners();
      return;
    }

    _faction = parsedFaction;
    final deviceId = payload['device_id']?.toString();
    final assignmentText = deviceId == null
        ? _faction!.displayName
        : '${_faction!.displayName} for $deviceId';
    _addLog('Faction assigned: $assignmentText', severity: 'success');
    notifyListeners();
  }

  void _handleGameState(Map<String, dynamic> payload) {
    _currentLap = payload['lap'] ?? _currentLap;
    _gamePhase =
        payload['game_phase'] ?? payload['status']?.toString() ?? _gamePhase;
    _updateTurnFromPayload(payload);

    final playersList = payload['players'] as List<dynamic>?;
    if (playersList != null) {
      _allPlayers = playersList
          .map(
            (p) => PlayerData.fromMap(
              p as Map<String, dynamic>,
              _faction ?? FactionType.natural,
            ),
          )
          .toList();

      // Update my own metrics from the allPlayers list
      try {
        if (_faction == null) {
          throw StateError('Faction not assigned yet');
        }
        final myData = _allPlayers.firstWhere((p) => p.faction == _faction);
        _metrics = myData.metrics;
        _bankBalance = myData.bankBalance;
        _isEliminated = myData.isEliminated;
      } catch (e) {
        // I might not be in the list yet
      }
    }

    _addLog('Game state updated: $_gamePhase', severity: 'info');
    notifyListeners();
  }

  Map<String, dynamic> _normalizeGameStatePayload(Map<String, dynamic> payload) {
    final nested = payload['game_state'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    return payload;
  }

  void _handleTurnUpdate(Map<String, dynamic> payload) {
    final parsedFaction = _resolveFactionFromTurnPayload(payload);
    if (parsedFaction == null) {
      _addLog('Turn update contained unknown player reference', severity: 'error');
      notifyListeners();
      return;
    }
    _currentTurnFaction = parsedFaction;
    _addLog(
      'Turn updated to ${_currentTurnFaction?.displayName ?? "Unknown"}',
      severity: 'info',
    );
    notifyListeners();
  }

  void _handleMoveResult(Map<String, dynamic> payload) {
    final f = _resolveFaction(
      factionValue: payload['faction'],
      deviceIdValue: payload['device_id'],
    );
    if (f == null) {
      _addLog('Move result contained unknown player reference', severity: 'error');
      notifyListeners();
      return;
    }
    final spaces = payload['spaces_moved'];
    _addLog('${f.displayName} moved $spaces spaces', severity: 'info');
    notifyListeners();
  }

  void _handleCardResolved(Map<String, dynamic> payload) {
    _isPromptingScan = false;
    final title = payload['card_title'];
    final target = _resolveFaction(
      factionValue: payload['target_faction'],
      deviceIdValue: payload['target_device_id'],
    );
    if (target == null) {
      _addLog('Card resolution contained unknown target player reference', severity: 'error');
      notifyListeners();
      return;
    }
    final impact = payload['impact_level'];
    _addLog(
      '$title ($impact impact) resolved on ${target.displayName}',
      severity: 'warning',
    );
    notifyListeners();
  }

  void _handlePurchasePrompt(Map<String, dynamic> payload) {
    _pendingDecision = null;
    _pendingPurchase = PurchasePrompt.fromMap(payload);
    _addLog(
      'Purchase available: ${_pendingPurchase!.infrastructureName}',
      severity: 'info',
    );
    notifyListeners();
  }

  void _handleCardDecisionPrompt(Map<String, dynamic> payload) {
    _pendingPurchase = null;
    _pendingDecision = CardDecisionPrompt.fromMap(payload);
    _addLog(
      'Decision required: ${_pendingDecision!.cardTitle}',
      severity: 'warning',
    );
    notifyListeners();
  }

  void _handleOwnershipState(Map<String, dynamic> payload) {
    final playersList = payload['players'] as List<dynamic>?;
    if (playersList == null) return;

    if (_allPlayers.isEmpty) {
      _allPlayers = playersList
          .map(
            (p) => PlayerData.fromMap(
              p as Map<String, dynamic>,
              _faction ?? FactionType.natural,
            ),
          )
          .toList();
    } else {
      final updatedPlayers = playersList
          .map((p) => p as Map<String, dynamic>)
          .map(
            (p) => PlayerData.fromMap(
              p,
              _faction ?? FactionType.natural,
            ),
          )
          .toList();

      _allPlayers = _allPlayers.map((existing) {
        for (final candidate in updatedPlayers) {
          if (existing.deviceId != null &&
              existing.deviceId!.isNotEmpty &&
              candidate.deviceId == existing.deviceId) {
            return candidate;
          }
        }
        for (final candidate in updatedPlayers) {
          if (candidate.faction == existing.faction) {
            return candidate;
          }
        }
        return existing;
      }).toList();
    }

    _addLog('Ownership state refreshed.', severity: 'info');
    notifyListeners();
  }

  // -------------------------------------------------------
  // Outgoing actions (App → ESP32)
  // -------------------------------------------------------

  /// Respond to a purchase prompt.
  void sendPurchaseResponse(String action) {
    final msg = ProtocolMessage(
      type: MessageType.actionPurchase,
      payload: _withActorDeviceId({
        'infrastructure_name': _pendingPurchase?.infrastructureName ?? '',
        'action': action,
      }),
    );
    network.sendMessage(msg.toJsonString());
    _pendingPurchase = null;
    _isPromptingScan = false;
    _scanPromptMessage = null;
    _advanceTurnOptimisticallyIfNeeded();
    _addLog('Purchase action: $action', severity: 'success');
    notifyListeners();
  }

  /// Respond to a card decision prompt.
  void sendCardDecisionResponse(String choice) {
    final msg = ProtocolMessage(
      type: MessageType.actionCardChoice,
      payload: _withActorDeviceId({
        'choice': choice,
      }),
    );
    network.sendMessage(msg.toJsonString());
    _pendingDecision = null;
    _isPromptingScan = false;
    _scanPromptMessage = null;
    _addLog('Choice made: $choice', severity: 'success');
    notifyListeners();
  }

  String factionToProtocolValue(FactionType faction) {
    switch (faction) {
      case FactionType.natural:
        return 'Natural';
      case FactionType.manufacturing:
        return 'Manufacturing';
      case FactionType.tourism:
        return 'Tourism';
      case FactionType.technological:
        return 'Technological';
    }
  }

  Map<String, dynamic> transferFundsPayload({
    required FactionType targetFaction,
    required int amount,
    String? targetDeviceId,
  }) {
    final payload = <String, dynamic>{
      'target_faction': factionToProtocolValue(targetFaction),
      'amount': amount,
    };
    if (targetDeviceId != null && targetDeviceId.isNotEmpty) {
      payload['target_device_id'] = targetDeviceId;
    } else {
      payload['target_device_id'] = ''; // Ensure key exists even if empty, as protocol demands it. In reality, targetDeviceId should be populated if available in PlayerData.
    }
    return _withActorDeviceId(payload);
  }

  void requestOwnershipState({String scope = 'all'}) {
    final msg = ProtocolMessage(
      type: MessageType.actionViewOwnership,
      payload: _withActorDeviceId({'scope': scope}),
    );
    network.sendMessage(msg.toJsonString());
  }

  // -------------------------------------------------------
  // Simulation helpers (for prototyping / testing without ESP32)
  // -------------------------------------------------------

  /// Injects a fake full_sync message for UI testing.
  void simulateSyncState({
    double sustainability = 650,
    double smart = 500,
    double livability = 720,
    double economy = 580,
    int bankBalance = 1500,
    int lap = 3,
  }) {
    final payload = {
      'type': 'full_sync',
      'payload': {
        'my_faction': 'Natural',
        'current_turn_faction': 'Technological',
        'game_state': {
          'lap': lap,
          'game_phase': 'in_progress',
          'players': [
            {
              'faction': 'Natural',
              'is_eliminated': false,
              'bank_balance': bankBalance,
              'metrics': {
                'sustainability': sustainability,
                'smart': smart,
                'livability': livability,
                'economy': economy,
              },
            },
            {
              'faction': 'Technological',
              'is_eliminated': false,
              'bank_balance': 1200,
              'metrics': const {
                'sustainability': 500.0,
                'smart': 650.0,
                'livability': 520.0,
                'economy': 600.0,
              },
            },
          ],
        },
        'pending_prompt': null,
      },
    };
    _onRawMessage(jsonEncode(payload));
  }

  /// Injects a fake purchase prompt.
  void simulatePurchasePrompt() {
    final payload = {
      'type': 'prompt_purchase',
      'payload': {
        'name': 'Solar Farm',
        'description':
            'A large solar panel array. Boosts sustainability and economy.',
        'budget': 350,
        'is_owned': false,
        'provider_option': {'cost_points': 350, 'available': true},
        'taker_option': {'cost_points': 90, 'available': true},
        'immediate_scores': {'sustainability': 50, 'economy': 20},
      },
    };
    _onRawMessage(jsonEncode(payload));
  }

  /// Injects a fake card decision prompt.
  void simulateCardDecisionPrompt() {
    final payload = {
      'type': 'prompt_card_choice',
      'payload': {
        'card_id': 'policy_02',
        'card_title': 'Carbon Tax Regulation',
        'description':
            'The city council proposes a new carbon tax. Choose your stance.',
        'choice_a': {
          'name': 'Implement Strict Tax',
          'effects': {'sustainability': 80, 'economy': -40},
        },
        'choice_b': {
          'name': 'Relaxed Guidelines',
          'effects': {'sustainability': 20, 'economy': 30},
        },
      },
    };
    _onRawMessage(jsonEncode(payload));
  }

  // -------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------

  void _addLog(String message, {String severity = 'info'}) {
    _logEntries.insert(0, GameLogEntry(message: message, severity: severity));
    if (_logEntries.length > 100) _logEntries.removeLast();
    logger.i('[GameLog] $message');
  }

  Future<void> _loadDeviceId() async {
    deviceId = await DeviceIdentity.getDeviceId();
  }

  Map<String, dynamic> _withActorDeviceId(Map<String, dynamic> payload) {
    if (deviceId == null || deviceId!.isEmpty) {
      return payload;
    }
    return {'device_id': deviceId!, ...payload};
  }

  bool _requireMapFields(
    Map<String, dynamic> payload,
    List<String> requiredKeys,
  ) {
    for (final key in requiredKeys) {
      if (!payload.containsKey(key)) {
        _addLog(
          'Malformed payload for message: missing "$key"',
          severity: 'error',
        );
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  bool _requireAnyMapFields(
    Map<String, dynamic> payload,
    List<String> candidateKeys,
  ) {
    for (final key in candidateKeys) {
      if (payload.containsKey(key)) {
        return true;
      }
    }
    _addLog(
      'Malformed payload for message: expected one of ${candidateKeys.join(", ")}',
      severity: 'error',
    );
    notifyListeners();
    return false;
  }

  void _restorePendingPrompt(dynamic pendingPrompt) {
    _pendingPurchase = null;
    _pendingDecision = null;
    _isPromptingScan = false;
    _scanPromptMessage = null;

    if (pendingPrompt is! Map<String, dynamic>) return;
    final restored = ProtocolMessage.fromJsonString(jsonEncode(pendingPrompt));

    switch (restored.type) {
      case MessageType.promptPurchase:
        _handlePurchasePrompt(restored.payload);
        break;
      case MessageType.promptCardChoice:
        _handleCardDecisionPrompt(restored.payload);
        break;
      case MessageType.promptScan:
        _isPromptingScan = true;
        _scanPromptMessage = restored.payload['message']?.toString();
        _addLog(
          _scanPromptMessage ?? 'Please scan a card...',
          severity: 'warning',
        );
        notifyListeners();
        break;
      default:
        _addLog(
          'Ignored unsupported pending prompt from full_sync',
          severity: 'warning',
        );
        notifyListeners();
        break;
    }
  }

  FactionType? _parseFaction(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
          return FactionType.natural;
        case 1:
          return FactionType.manufacturing;
        case 2:
          return FactionType.tourism;
        case 3:
          return FactionType.technological;
      }
    }
    final s = value.toString().toLowerCase();

    if (s.contains('natural')) {
      return FactionType.natural;
    }

    if (s.contains('manufact')) {
      return FactionType.manufacturing;
    }

    if (s.contains('software') || s.contains('industrial')) {
      return FactionType.manufacturing;
    }

    if (s.contains('tour')) {
      return FactionType.tourism;
    }

    if (s.contains('financial')) {
      return FactionType.tourism;
    }

    if (s.contains('technological')) {
      return FactionType.technological;
    }

    return null;
  }

  FactionType? _resolveFaction({dynamic factionValue, dynamic deviceIdValue}) {
    final fromFaction = _parseFaction(factionValue);
    if (fromFaction != null) {
      return fromFaction;
    }

    final deviceId = deviceIdValue?.toString();
    if (deviceId == null || deviceId.isEmpty) {
      return null;
    }

    for (final player in _allPlayers) {
      if (player.deviceId == deviceId) {
        return player.faction;
      }
    }

    return null;
  }

  FactionType? _resolveFactionFromTurnPayload(Map<String, dynamic> payload) {
    return _resolveFaction(
          factionValue:
              payload['active_faction'] ??
              payload['current_turn_faction'] ??
              payload['faction'],
          deviceIdValue:
              payload['active_device_id'] ??
              payload['current_turn_device_id'] ??
              payload['device_id'],
        ) ??
        _parseFaction(payload['player']);
  }

  void _updateTurnFromPayload(Map<String, dynamic> payload) {
    final parsedFaction = _resolveFactionFromTurnPayload(payload);
    if (parsedFaction != null) {
      _currentTurnFaction = parsedFaction;
    }
  }

  void _advanceTurnOptimisticallyIfNeeded() {
    if (_currentTurnFaction == null || _allPlayers.isEmpty) return;
    if (_faction == null || _currentTurnFaction != _faction) return;

    final activeFactions = _allPlayers
        .where((p) => !p.isEliminated)
        .map((p) => p.faction)
        .toSet();
    if (activeFactions.length < 2) return;

    const order = [
      FactionType.natural,
      FactionType.manufacturing,
      FactionType.tourism,
      FactionType.technological,
    ];
    final currentIndex = order.indexOf(_currentTurnFaction!);
    if (currentIndex == -1) return;

    for (var i = 1; i <= order.length; i++) {
      final next = order[(currentIndex + i) % order.length];
      if (activeFactions.contains(next)) {
        _currentTurnFaction = next;
        return;
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
