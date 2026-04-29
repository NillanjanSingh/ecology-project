import 'package:flutter/material.dart';
import '../network.dart';
import 'lobby_page.dart';

class HomePage extends StatelessWidget {
  final NetworkManager network;

  const HomePage({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade900,
              Colors.green.shade800,
              Colors.lightGreen.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Title Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: 100,
                        color: Colors.greenAccent.shade100,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "ECOLOGY",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "CITY SIMULATION",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.greenAccent.shade100,
                          letterSpacing: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),

                // Action Buttons
                _buildMenuButton(
                  context: context,
                  icon: Icons.play_arrow_rounded,
                  label: "NEW GAME",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LobbyPage(network: network),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return SizedBox(
      width: 280,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white,
          foregroundColor: isSecondary ? Colors.white : Colors.teal.shade900,
          elevation: isSecondary ? 0 : 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: isSecondary
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
