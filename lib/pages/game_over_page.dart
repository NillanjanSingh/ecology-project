import 'package:flutter/material.dart';
import '../models/game_state.dart';

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
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(title: const Text('Game Over')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            if (sorted.isNotEmpty)
              Text(
                'Winner: ${sorted.first.faction.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w700,
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.faction.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: p.faction.color.withValues(alpha: 0.25),
                          child: Icon(p.faction.icon, color: p.faction.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.faction.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${p.metrics.totalScore}',
                          style: const TextStyle(
                            color: Color(0xFFFFCA28),
                            fontWeight: FontWeight.bold,
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
    );
  }
}
