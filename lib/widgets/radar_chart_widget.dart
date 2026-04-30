import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../theme/app_chrome.dart';

/// A premium radar chart that displays the four core metrics.
/// Adapts its accent color based on the player's faction.
class MetricsRadarChart extends StatelessWidget {
  final PlayerMetrics metrics;
  final FactionType? faction;

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
    final accentColor = faction?.color ?? const Color(0xFF78909C);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppChrome.panelDecoration(
        color: AppChrome.panelSoft,
        border: accentColor,
        radius: 28,
        glow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppChrome.sectionTitle(
                  'CITY METRICS',
                  subtitle: 'Real-time strategic posture across the four civic pillars.',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accentColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '${metrics.totalScore} TOTAL',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  // Invisible dummy dataset to lock the center at 0
                  RadarDataSet(
                    fillColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    entryRadius: 0,
                    dataEntries: const [
                      RadarEntry(value: 0),
                      RadarEntry(value: 0),
                      RadarEntry(value: 0),
                      RadarEntry(value: 0),
                    ],
                  ),
                  // Actual player metrics
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
                titleTextStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppChrome.text,
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
                  color: accentColor.withValues(alpha: 0.15),
                  width: 1,
                ),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(
                        text: 'SUS ${metrics.sustainability.round()}',
                      );
                    case 1:
                      return RadarChartTitle(
                        text: 'SMT ${metrics.smart.round()}',
                      );
                    case 2:
                      return RadarChartTitle(
                        text: 'LIV ${metrics.livability.round()}',
                      );
                    case 3:
                      return RadarChartTitle(
                        text: 'ECO ${metrics.economy.round()}',
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
            spacing: 10,
            runSpacing: 10,
            children: [
              _legendPill('Sustainability', metrics.sustainability.round(), accentColor),
              _legendPill('Smart', metrics.smart.round(), accentColor),
              _legendPill('Livability', metrics.livability.round(), accentColor),
              _legendPill('Economy', metrics.economy.round(), accentColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendPill(String label, int value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppChrome.bgAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label  $value',
        style: const TextStyle(
          fontSize: 11,
          color: AppChrome.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
