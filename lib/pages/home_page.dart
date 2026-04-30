import 'package:flutter/material.dart';

import '../network.dart';
import '../theme/app_chrome.dart';
import 'lobby_page.dart';

class HomePage extends StatelessWidget {
  final NetworkManager network;

  const HomePage({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compact = size.width < 420;

    return Scaffold(
      body: Container(
        decoration: AppChrome.screenBackground(),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                right: -40,
                child: _glowOrb(220, AppChrome.cyan.withValues(alpha: 0.14)),
              ),
              Positioned(
                bottom: -80,
                left: -20,
                child: _glowOrb(260, AppChrome.mint.withValues(alpha: 0.12)),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Container(
                      padding: EdgeInsets.all(compact ? 22 : 32),
                      decoration: AppChrome.panelDecoration(
                        color: AppChrome.bgAlt,
                        radius: 32,
                        glow: true,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: compact ? 58 : 72,
                                height: compact ? 58 : 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [AppChrome.cyan, AppChrome.mint],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.hub_rounded,
                                  color: AppChrome.bg,
                                  size: 34,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppChrome.sectionTitle(
                                  'MAYOR\'S TERMINAL',
                                  subtitle:
                                      'Smart-city command interface for the physical strategy board.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Ecology',
                            style: TextStyle(
                              fontSize: compact ? 38 : 56,
                              height: 0.96,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.5,
                              color: AppChrome.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppChrome.panelSoft.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppChrome.cyan.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              'Urban resilience • economy • livability • sustainability',
                              style: TextStyle(
                                color: AppChrome.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: AppChrome.panelDecoration(
                              color: AppChrome.panelSoft,
                              border: AppChrome.cyan,
                              radius: 24,
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Board-linked gameplay',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Connect to the ESP32 board, join the live lobby, and drive city decisions from a responsive tactical dashboard.',
                                  style: TextStyle(
                                    color: AppChrome.textMuted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('ENTER LOBBY'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LobbyPage(network: network),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
