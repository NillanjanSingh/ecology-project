import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';

/// A premium radar chart that displays the four core metrics.
/// Adapts its accent color based on the player's faction.
class MetricsRadarChart extends StatelessWidget {
  final PlayerMetrics metrics;
  final FactionType faction;

  /// Maximum value a single metric axis can show.
  /// This should match the game's max per-category score.
  final double maxValue;

  const MetricsRadarChart({
    super.key,
    required this.metrics,
    required this.faction,
    this.maxValue = 1000,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = faction.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CITY METRICS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: accentColor.withValues(alpha: 0.18),
                    borderColor: accentColor,
                    borderWidth: 2.5,
                    entryRadius: 4,
                    dataEntries: [
                      RadarEntry(value: metrics.sustainability),
                      RadarEntry(value: metrics.smart),
                      RadarEntry(value: metrics.livability),
                      RadarEntry(value: metrics.economy),
                    ],
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                tickCount: 4,
                ticksTextStyle: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 0,
                ),
                tickBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                gridBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(
                        text: '🌿 ${metrics.sustainability.round()}',
                      );
                    case 1:
                      return RadarChartTitle(
                        text: '💡 ${metrics.smart.round()}',
                      );
                    case 2:
                      return RadarChartTitle(
                        text: '🏠 ${metrics.livability.round()}',
                      );
                    case 3:
                      return RadarChartTitle(
                        text: '💰 ${metrics.economy.round()}',
                      );
                    default:
                      return const RadarChartTitle(text: '');
                  }
                },
                radarShape: RadarShape.polygon,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _legendItem('Sustainability', '🌿'),
              _legendItem('Smart', '💡'),
              _legendItem('Livability', '🏠'),
              _legendItem('Economy', '💰'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, String emoji) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
