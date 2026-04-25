import 'package:flutter/material.dart';
import '../models/game_state.dart';

class StatusLog extends StatelessWidget {
  final List<ActiveCard> activeCards;
  final List<GameLogEntry> logEntries;

  const StatusLog({
    super.key,
    required this.activeCards,
    required this.logEntries,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeCards.isNotEmpty) ...[
          _sectionHeader('ACTIVE EFFECTS', Icons.layers),
          const SizedBox(height: 8),
          ...activeCards.map(_buildActiveCardTile),
          const SizedBox(height: 20),
        ],
        _sectionHeader('EVENT LOG', Icons.receipt_long),
        const SizedBox(height: 8),
        if (logEntries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No events yet. Waiting for game data…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ...logEntries.take(20).map(_buildLogTile),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCardTile(ActiveCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: card.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: card.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(card.icon, color: card.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (card.description.isNotEmpty)
                  Text(
                    card.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: card.color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.loop, size: 13, color: card.color),
                const SizedBox(width: 4),
                Text(
                  '${card.remainingLaps}',
                  style: TextStyle(
                    color: card.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(GameLogEntry entry) {
    Color dotColor;
    switch (entry.severity) {
      case 'success':
        dotColor = const Color(0xFF66BB6A);
        break;
      case 'warning':
        dotColor = const Color(0xFFFFA726);
        break;
      case 'error':
        dotColor = const Color(0xFFEF5350);
        break;
      default:
        dotColor = const Color(0xFF78909C);
    }
    final t = entry.timestamp;
    final timeStr =
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$timeStr  ',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  TextSpan(
                    text: entry.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
