import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../theme/app_chrome.dart';

class GameOverPage extends StatelessWidget {
  final List<PlayerData> players;

  const GameOverPage({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = [...players]
      ..sort((a, b) => b.metrics.totalScore.compareTo(a.metrics.totalScore));
    final allEliminated = sorted.isNotEmpty && sorted.every((p) => p.isEliminated);
    final allInnerRing = sorted.isNotEmpty && sorted.every((p) => p.isInnerRing);

    String title = 'GAME OVER';
    if (allEliminated) {
      title = 'GLOBAL DYSTOPIA';
    } else if (allInnerRing) {
      title = 'UTOPIA ACHIEVED';
    }

    return Scaffold(
      body: Container(
        decoration: AppChrome.screenBackground(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppChrome.panelDecoration(
                    color: AppChrome.bgAlt,
                    border: AppChrome.gold,
                    radius: 30,
                    glow: true,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppChrome.sectionTitle(
                        'SESSION RESOLVED',
                        subtitle: allEliminated
                            ? 'Every city collapsed under pressure.'
                            : allInnerRing
                            ? 'Every city reached developed status.'
                            : 'Final strategic standings from the board authority.',
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppChrome.text,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (sorted.isNotEmpty)
                        Text(
                          'Winner: ${sorted.first.faction.displayName}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppChrome.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: sorted.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final p = sorted[index];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: AppChrome.panelDecoration(
                                color: AppChrome.panelSoft,
                                border: p.faction.color,
                                radius: 20,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: p.faction.color.withValues(alpha: 0.25),
                                    child: Icon(p.faction.icon, color: p.faction.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.faction.displayName,
                                          style: const TextStyle(
                                            color: AppChrome.text,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.isEliminated
                                              ? 'Eliminated'
                                              : p.isInnerRing
                                              ? 'Developed City'
                                              : 'Outer Ring',
                                          style: const TextStyle(
                                            color: AppChrome.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${p.metrics.totalScore}',
                                    style: const TextStyle(
                                      color: AppChrome.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
