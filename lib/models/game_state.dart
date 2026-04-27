import 'dart:convert';
import 'package:flutter/material.dart';
import '../protocol.dart';
import '../network.dart';
import '../log.dart';
import 'dart:async';

// --- Data Enums & Classes ---

/// The four factions/cities a player can control.
enum FactionType { naturalResources, software, industrial, financial }

extension FactionTypeExtension on FactionType {
  String get displayName {
    switch (this) {
      case FactionType.naturalResources:
        return 'Natural Resources';
      case FactionType.software:
        return 'Software';
      case FactionType.industrial:
        return 'Industrial';
      case FactionType.financial:
        return 'Financial';
    }
  }

  Color get color {
    switch (this) {
      case FactionType.naturalResources:
        return const Color(0xFF2E7D32); // Forest Green
      case FactionType.software:
        return const Color(0xFF1565C0); // Tech Blue
      case FactionType.industrial:
        return const Color(0xFFE65100); // Industrial Orange
      case FactionType.financial:
        return const Color(0xFF6A1B9A); // Finance Purple
    }
  }

  IconData get icon {
    switch (this) {
      case FactionType.naturalResources:
        return Icons.park;
      case FactionType.software:
        return Icons.code;
      case FactionType.industrial:
        return Icons.factory;
      case FactionType.financial:
        return Icons.account_balance;
    }
  }
}

class PlayerData {
  final FactionType faction;
  final bool isEliminated;
  final int bankBalance;
  final PlayerMetrics metrics;

  PlayerData({
    required this.faction,
    required this.isEliminated,
    required this.bankBalance,
    required this.metrics,
  });

  factory PlayerData.fromMap(Map<String, dynamic> map, FactionType defaultFaction) {
    return PlayerData(
      faction: _parseFactionStatic(map['faction']) ?? defaultFaction,
      isEliminated: map['is_eliminated'] == true,
      bankBalance: map['bank_balance'] ?? 0,
      metrics: PlayerMetrics.fromMap(map['metrics'] ?? {}),
    );
  }

  static FactionType? _parseFactionStatic(dynamic value) {
    final s = value?.toString().toLowerCase() ?? '';
    if (s.contains('natural')) return FactionType.naturalResources;
    if (s.contains('software') || s.contains('tech')) return FactionType.software;
    if (s.contains('industrial')) return FactionType.industrial;
    if (s.contains('financial') || s.contains('finance') || s.contains('cultural')) return FactionType.financial; // map cultural to financial for now if needed
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
  final int cost;
  final Map<String, dynamic> effects;

  PurchasePrompt({
    required this.infrastructureName,
    this.description = '',
    required this.cost,
    this.effects = const {},
  });

  factory PurchasePrompt.fromMap(Map<String, dynamic> map) {
    return PurchasePrompt(
      infrastructureName: map['name']?.toString() ?? 'Unknown',
      description: map['description']?.toString() ?? '',
      cost: map['cost'] ?? 0,
      effects: map['effects'] ?? {},
    );
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
    return CardDecisionPrompt(
      cardId: map['card_id']?.toString() ?? '',
      cardTitle: map['card_title']?.toString() ?? 'Decision Required',
      description: map['description']?.toString() ?? '',
      choiceA: map['choice_a']?.toString() ?? 'Option A',
      choiceADescription: map['choice_a_desc']?.toString() ?? '',
      choiceB: map['choice_b']?.toString() ?? 'Option B',
      choiceBDescription: map['choice_b_desc']?.toString() ?? '',
    );
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

  // --- Player Identity ---
  FactionType _faction = FactionType.naturalResources;
  FactionType get faction => _faction;

  // --- Metrics ---
  PlayerMetrics _metrics = const PlayerMetrics();
  PlayerMetrics get metrics => _metrics;

  // --- Bank ---
  int _bankBalance = 1000;
  int get bankBalance => _bankBalance;

  // --- Active Cards ---
  List<ActiveCard> _activeCards = [];
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
  
  List<PlayerData> get opponents => _allPlayers.where((p) => p.faction != _faction).toList();

  // --- Pending Prompts (for modals) ---
  PurchasePrompt? _pendingPurchase;
  PurchasePrompt? get pendingPurchase => _pendingPurchase;

  CardDecisionPrompt? _pendingDecision;
  CardDecisionPrompt? get pendingDecision => _pendingDecision;

  // Ascension target
  static const int ascensionTarget = 4000;

  GameStateProvider({required this.network}) {
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
        _handleSyncState(msg.payload);
        break;
      case MessageType.gameState:
        _handleGameState(msg.payload);
        break;
      case MessageType.turnUpdate:
        _handleTurnUpdate(msg.payload);
        break;
      case MessageType.moveResult:
        _handleMoveResult(msg.payload);
        break;
      case MessageType.cardResolved:
        _handleCardResolved(msg.payload);
        break;
      case MessageType.promptPurchase:
        _handlePurchasePrompt(msg.payload);
        break;
      case MessageType.promptCardChoice:
        _handleCardDecisionPrompt(msg.payload);
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
        // Lobby events are handled by the lobby screen; ignore in in-game state.
        break;
      default:
        _addLog('Unknown message received', severity: 'warning');
        break;
    }
  }

  void _handleSyncState(Map<String, dynamic> payload) {
    if (payload['my_faction'] != null) {
      _faction = _parseFaction(payload['my_faction']);
    }
    if (payload['current_turn_faction'] != null) {
      _currentTurnFaction = _parseFaction(payload['current_turn_faction']);
    }
    if (payload['game_state'] != null) {
      _handleGameState(payload['game_state'] as Map<String, dynamic>);
    }
    
    _addLog('Full state synced.', severity: 'success');
  }

  void _handleGameState(Map<String, dynamic> payload) {
    _currentLap = payload['lap'] ?? _currentLap;
    _gamePhase = payload['game_phase'] ?? payload['status']?.toString() ?? _gamePhase;
    
    final playersList = payload['players'] as List<dynamic>?;
    if (playersList != null) {
      _allPlayers = playersList.map((p) => PlayerData.fromMap(p as Map<String, dynamic>, FactionType.naturalResources)).toList();
      
      // Update my own metrics from the allPlayers list
      try {
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

  void _handleTurnUpdate(Map<String, dynamic> payload) {
    if (payload['active_faction'] != null) {
      _currentTurnFaction = _parseFaction(payload['active_faction']);
      _addLog('Turn updated to ${_currentTurnFaction?.displayName ?? "Unknown"}', severity: 'info');
      notifyListeners();
    }
  }

  void _handleMoveResult(Map<String, dynamic> payload) {
    final f = _parseFaction(payload['faction']);
    final spaces = payload['spaces_moved'];
    _addLog('${f.displayName} moved $spaces spaces', severity: 'info');
    notifyListeners();
  }

  void _handleCardResolved(Map<String, dynamic> payload) {
    final title = payload['card_title'];
    final target = _parseFaction(payload['target_faction']);
    final impact = payload['impact_level'];
    _addLog('$title ($impact impact) resolved on ${target.displayName}', severity: 'warning');
    notifyListeners();
  }

  void _handlePurchasePrompt(Map<String, dynamic> payload) {
    _pendingPurchase = PurchasePrompt.fromMap(payload);
    _addLog(
      'Purchase available: ${_pendingPurchase!.infrastructureName}',
      severity: 'info',
    );
    notifyListeners();
  }

  void _handleCardDecisionPrompt(Map<String, dynamic> payload) {
    _pendingDecision = CardDecisionPrompt.fromMap(payload);
    _addLog(
      'Decision required: ${_pendingDecision!.cardTitle}',
      severity: 'warning',
    );
    notifyListeners();
  }

  // -------------------------------------------------------
  // Outgoing actions (App → ESP32)
  // -------------------------------------------------------

  /// Respond to a purchase prompt.
  void sendPurchaseResponse(bool buy) {
    final msg = ProtocolMessage(
      type: MessageType.actionPurchase,
      payload: {'action': buy ? 'buy' : 'skip'},
    );
    network.sendMessage(msg.toJsonString());
    _pendingPurchase = null;
    _addLog(buy ? 'Purchased!' : 'Skipped purchase.', severity: 'success');
    notifyListeners();
  }

  /// Respond to a card decision prompt.
  void sendCardDecisionResponse(String choice) {
    final msg = ProtocolMessage(
      type: MessageType.actionCardChoice,
      payload: {'card_id': _pendingDecision?.cardId ?? '', 'choice': choice},
    );
    network.sendMessage(msg.toJsonString());
    _pendingDecision = null;
    _addLog('Choice made: $choice', severity: 'success');
    notifyListeners();
  }

  // -------------------------------------------------------
  // Simulation helpers (for prototyping / testing without ESP32)
  // -------------------------------------------------------

  /// Injects a fake sync_state message for UI testing.
  void simulateSyncState({
    double sustainability = 650,
    double smart = 500,
    double livability = 720,
    double economy = 580,
    int bankBalance = 1500,
    int lap = 3,
  }) {
    final payload = {
      'type': 'sync_state',
      'payload': {
        'metrics': {
          'sustainability': sustainability,
          'smart': smart,
          'livability': livability,
          'economy': economy,
        },
        'bank_balance': bankBalance,
        'current_lap': lap,
        'active_cards': [
          {
            'id': 'disaster_01',
            'name': 'Earthquake',
            'type': 'disaster',
            'description': 'Infrastructure damage -15% Economy',
            'remaining_laps': 2,
          },
          {
            'id': 'policy_01',
            'name': 'Green Initiative',
            'type': 'policy',
            'description': '+10% Sustainability per lap',
            'remaining_laps': 4,
          },
          {
            'id': 'event_01',
            'name': 'Tech Summit',
            'type': 'event',
            'description': 'Temporary +5% Smart boost',
            'remaining_laps': 1,
          },
        ],
      },
    };
    _onRawMessage(jsonEncode(payload));
  }

  /// Injects a fake purchase prompt.
  void simulatePurchasePrompt() {
    final payload = {
      'type': 'purchase_prompt',
      'payload': {
        'name': 'Solar Farm',
        'description':
            'A large solar panel array. Boosts sustainability and economy.',
        'cost': 350,
        'effects': {'sustainability': 50, 'economy': 20},
      },
    };
    _onRawMessage(jsonEncode(payload));
  }

  /// Injects a fake card decision prompt.
  void simulateCardDecisionPrompt() {
    final payload = {
      'type': 'card_decision_prompt',
      'payload': {
        'card_id': 'policy_02',
        'card_title': 'Carbon Tax Regulation',
        'description':
            'The city council proposes a new carbon tax. Choose your stance.',
        'choice_a': 'Implement Strict Tax',
        'choice_a_desc':
            '+80 Sustainability, -40 Economy. Heavy penalties for polluters.',
        'choice_b': 'Relaxed Guidelines',
        'choice_b_desc':
            '+20 Sustainability, +30 Economy. Voluntary compliance only.',
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

  FactionType _parseFaction(dynamic value) {
    final s = value.toString().toLowerCase();

    if (s.contains('natural')) {
      return FactionType.naturalResources;
    }

    if (s.contains('software') || s.contains('tech')) {
      return FactionType.software;
    }

    if (s.contains('industrial')) {
      return FactionType.industrial;
    }

    if (s.contains('financial') || s.contains('finance')) {
      return FactionType.financial;
    }

    return _faction; // Keep current if unrecognized
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
