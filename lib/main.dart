import 'package:ecology_project/network.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: WebSocketTestPage());
  }
}

class WebSocketTestPage extends StatefulWidget {
  const WebSocketTestPage({super.key});

  @override
  State<WebSocketTestPage> createState() => _WebSocketTestPageState();
}

class _WebSocketTestPageState extends State<WebSocketTestPage> {
  String status = "Not connected";
  String receivedMessage = "";

  final TextEditingController controller = TextEditingController();
  final NetworkManager network = NetworkManager();

  Future<void> connect() async {
    await network.connect(
      onStatus: (s) => setState(() => status = s),
      onMessage: (m) => setState(() => receivedMessage = m),
      onError: (e) => setState(() => status = "Error: $e"),
      onDone: () => setState(() => status = "Connection closed"),
    );
  }

  void sendMessage() {
    if (controller.text.isNotEmpty) {
      network.sendMessage(controller.text);
      controller.clear();
    }
  }

  @override
  void dispose() {
    network.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ESP32 WebSocket Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Status: $status",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: connect,
              child: const Text("Connect via mDNS"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Enter message"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(onPressed: sendMessage, child: const Text("Send")),

            const SizedBox(height: 20),

            Text("Received: $receivedMessage"),
          ],
        ),
      ),
    );
  }
}
