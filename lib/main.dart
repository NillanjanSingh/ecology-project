import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:multicast_dns/multicast_dns.dart';

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
  WebSocketChannel? channel;
  String status = "Not connected";
  String receivedMessage = "";

  final TextEditingController controller = TextEditingController();
  final String mDnsHostname =
      "gigachad-esp.local"; 

  // --- NEW: Helper method to resolve mDNS ---
  Future<String?> resolveMdns(String hostname) async {
    setState(() => status = "Resolving $hostname...");

    final MDnsClient client = MDnsClient();
    await client.start();

    String? resolvedIp;

    try {
      // Look up the IPv4 address for the given hostname
      await for (final IPAddressResourceRecord record
          in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(hostname),
          )) {
        resolvedIp = record.address.address;
        break; // Stop after finding the first match
      }
    } catch (e) {
      print("mDNS Lookup failed: $e");
    } finally {
      client.stop();
    }

    return resolvedIp;
  }

  Future<void> connect() async {
    try {
      // 1. Resolve the hostname to an IP address first
      String? ipAddress = await resolveMdns(mDnsHostname);

      if (ipAddress == null) {
        setState(() => status = "Failed to resolve $mDnsHostname");
        return;
      }

      setState(() => status = "Connecting to $ipAddress...");

      // 2. Connect using the resolved IP address
      channel = WebSocketChannel.connect(Uri.parse('ws://$ipAddress/ws'));

      channel!.stream.listen(
        (message) {
          print("RECEIVED: $message");
          setState(() {
            receivedMessage = message.toString();
          });
        },
        onError: (error) {
          print("WS ERROR: $error");
          setState(() => status = "Error: $error");
        },
        onDone: () {
          print("WS CLOSED");
          setState(() => status = "Connection closed");
        },
      );

      setState(() => status = "Connected via $ipAddress");
    } catch (e) {
      setState(() => status = "Connection failed: $e");
    }
  }

  void sendMessage() {
    if (channel != null && controller.text.isNotEmpty) {
      channel!.sink.add(controller.text);
      controller.clear();
    }
  }

  @override
  void dispose() {
    channel?.sink.close();
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
