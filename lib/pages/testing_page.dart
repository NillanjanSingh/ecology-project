import 'package:flutter/material.dart';
import '../network.dart';
import 'game_page.dart';

class TestingModePage extends StatefulWidget {
  final NetworkManager network;

  const TestingModePage({super.key, required this.network});

  @override
  State<TestingModePage> createState() => _TestingModePageState();
}

class _TestingModePageState extends State<TestingModePage> {
  String _status = "Ready to connect";
  bool _isConnecting = false;

  Future<void> _connectToEsp() async {
    setState(() {
      _isConnecting = true;
      _status = "Starting connection...";
    });

    widget.network.onStatusUpdate = (status) {
      if (mounted) setState(() => _status = status);
    };

    String? ip = await widget.network.connect();

    if (mounted) {
      setState(() => _isConnecting = false);
      if (ip != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GamePage(network: widget.network),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Testing Mode Setup")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              "Status: $_status",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connectToEsp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: _isConnecting
                  ? const CircularProgressIndicator()
                  : const Text(
                      "Connect to ESP32 Board",
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
