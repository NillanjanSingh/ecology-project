import 'package:flutter/material.dart';

class AppChrome {
  static const bg = Color(0xFF08111A);
  static const bgAlt = Color(0xFF0D1723);
  static const panel = Color(0xFF132130);
  static const panelSoft = Color(0xFF192B3D);
  static const line = Color(0xFF284056);
  static const cyan = Color(0xFF63D8FF);
  static const gold = Color(0xFFFFD166);
  static const mint = Color(0xFF6EE7B7);
  static const coral = Color(0xFFFF7B72);
  static const text = Color(0xFFF5FBFF);
  static const textMuted = Color(0xFF93A9BC);

  static BoxDecoration screenBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF061019), Color(0xFF0B1623), Color(0xFF102133)],
      ),
    );
  }

  static BoxDecoration panelDecoration({
    Color color = panel,
    Color border = line,
    double radius = 24,
    bool glow = false,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border.withValues(alpha: 0.9)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
        if (glow)
          BoxShadow(
            color: cyan.withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 4,
          ),
      ],
    );
  }

  static TextStyle get eyebrow => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.6,
    color: textMuted,
  );

  static Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: eyebrow.copyWith(color: text)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: textMuted, height: 1.35),
          ),
        ],
      ],
    );
  }
}
