import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../network.dart';
import '../widgets/radar_chart_widget.dart';
import '../widgets/status_log.dart';
import '../widgets/modals/purchase_dialog.dart';
import '../widgets/modals/card_decision_dialog.dart';
import '../widgets/trade_drawer.dart';

/// The Mayor's Terminal — main game dashboard.
///
/// Displays:
///   - Faction header with bank balance
///   - Ascension progress bar (total score / 4000)
///   - Radar chart for the 4 core metrics
///   - Active effects and event log
///
/// Reacts to incoming ESP32 messages via [GameStateProvider]
/// and shows modal dialogs for purchase and card decisions.
class GamePage extends StatefulWidget {
  final NetworkManager network;

  const GamePage({super.key, required this.network});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  String _networkStatus = "Connected";

  @override
  void initState() {
    super.initState();
    widget.network.onStatusUpdate = (status) {
      if (mounted) setState(() => _networkStatus = status);
    };
  }

  // --- Modal launchers ---

  void _showPurchaseDialog(BuildContext ctx, GameStateProvider gs) {
    final p = gs.pendingPurchase;
    if (p == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => PurchaseDialog(
        infrastructureName: p.infrastructureName,
        description: p.description,
        cost: p.cost,
        currentBalance: gs.bankBalance,
        effects: p.effects,
        onBuy: () {
          gs.sendPurchaseResponse(true);
          Navigator.of(ctx).pop();
        },
        onSkip: () {
          gs.sendPurchaseResponse(false);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showCardDecisionDialog(BuildContext ctx, GameStateProvider gs) {
    final d = gs.pendingDecision;
    if (d == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => CardDecisionDialog(
        cardTitle: d.cardTitle,
        description: d.description,
        choiceA: d.choiceA,
        choiceADescription: d.choiceADescription,
        choiceB: d.choiceB,
        choiceBDescription: d.choiceBDescription,
        onChoiceSelected: (choice) {
          gs.sendCardDecisionResponse(choice);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gs, _) {
        // Auto-show modals when prompts arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (gs.pendingPurchase != null) {
            _showPurchaseDialog(context, gs);
          }
          if (gs.pendingDecision != null) {
            _showCardDecisionDialog(context, gs);
          }
        });

        final faction = gs.faction;
        final metrics = gs.metrics;
        final progress =
            (metrics.totalScore / GameStateProvider.ascensionTarget).clamp(
              0.0,
              1.0,
            );

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E14),
          endDrawer: const TradeDrawer(),
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // ─── Header ───
                    _buildHeader(context, faction, gs.bankBalance, gs.currentLap),
                    // ─── Turn Indicator ───
                    _buildTurnIndicator(gs),
                    // ─── Ascension Progress ───
                    _buildProgressBar(progress, metrics.totalScore),
                    // ─── Body ───
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            MetricsRadarChart(metrics: metrics, faction: faction),
                            const SizedBox(height: 20),
                            StatusLog(
                              activeCards: gs.activeCards,
                              logEntries: gs.logEntries,
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (gs.isPromptingScan) _buildScanOverlay(gs),
            ],
          ),
          // ─── Connection Status Bar ───
          bottomNavigationBar: _buildBottomBar(),
          // ─── Simulation FAB (for testing) ───
          floatingActionButton: _buildSimulationFab(gs),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Scan Overlay
  // ─────────────────────────────────────────────

  Widget _buildScanOverlay(GameStateProvider gs) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.nfc_rounded,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                gs.scanPromptMessage ?? 'Please scan a card...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hold the physical card over the board reader',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, FactionType faction, int bank, int lap) {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: faction.color.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(color: faction.color.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: faction.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(faction.icon, color: faction.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MAYOR'S TERMINAL",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      faction.displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: faction.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Bank balance badge & Trade drawer trigger
              GestureDetector(
                onTap: () => Scaffold.of(context).openEndDrawer(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            'LAP $lap',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.people_outline, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: Color(0xFFFFCA28),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '¤$bank',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFCA28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // ─────────────────────────────────────────────
  // Turn Indicator
  // ─────────────────────────────────────────────

  Widget _buildTurnIndicator(GameStateProvider gs) {
    if (gs.currentTurnFaction == null) return const SizedBox.shrink();

    final isMyTurn = gs.currentTurnFaction == gs.faction;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isMyTurn ? gs.faction.color.withValues(alpha: 0.8) : Colors.black45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMyTurn ? Icons.play_arrow_rounded : Icons.hourglass_empty_rounded,
            color: isMyTurn ? Colors.white : gs.currentTurnFaction!.color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isMyTurn 
                ? "IT's YOUR TURN! Spin the encoder." 
                : "Waiting for ${gs.currentTurnFaction!.displayName}...",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isMyTurn ? Colors.white : gs.currentTurnFaction!.color,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Progress bar
  // ─────────────────────────────────────────────

  Widget _buildProgressBar(double progress, int totalScore) {
    final color = progress < 0.5
        ? Color.lerp(
            const Color(0xFFEF5350),
            const Color(0xFFFFA726),
            progress * 2,
          )!
        : Color.lerp(
            const Color(0xFFFFA726),
            const Color(0xFF66BB6A),
            (progress - 0.5) * 2,
          )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASCENSION PROGRESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '$totalScore / ${GameStateProvider.ascensionTarget}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Bottom status bar
  // ─────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _networkStatus.contains('Connected')
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFEF5350),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_networkStatus.contains('Connected')
                              ? const Color(0xFF66BB6A)
                              : const Color(0xFFEF5350))
                          .withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _networkStatus,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Simulation FAB (dev/testing only)
  // ─────────────────────────────────────────────

  Widget _buildSimulationFab(GameStateProvider gs) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'sync':
            gs.simulateSyncState();
            break;
          case 'purchase':
            gs.simulatePurchasePrompt();
            break;
          case 'decision':
            gs.simulateCardDecisionPrompt();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'sync',
          child: ListTile(
            leading: Icon(Icons.sync, color: Color(0xFF66BB6A)),
            title: Text('Simulate Sync State'),
          ),
        ),
        const PopupMenuItem(
          value: 'purchase',
          child: ListTile(
            leading: Icon(Icons.shopping_cart, color: Color(0xFF42A5F5)),
            title: Text('Simulate Purchase'),
          ),
        ),
        const PopupMenuItem(
          value: 'decision',
          child: ListTile(
            leading: Icon(Icons.gavel, color: Color(0xFFFFA726)),
            title: Text('Simulate Card Decision'),
          ),
        ),
      ],
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.science_rounded, color: Colors.white),
      ),
    );
  }
}
