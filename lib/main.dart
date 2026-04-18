import 'package:flutter/material.dart';
import 'network.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const EcologyApp());
}

class EcologyApp extends StatefulWidget {
  const EcologyApp({super.key});

  @override
  State<EcologyApp> createState() => _EcologyAppState();
}

class _EcologyAppState extends State<EcologyApp> {
  final NetworkManager network = NetworkManager();

  @override
  void dispose() {
    network.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ecology Game',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: HomePage(network: network),
    );
  }
}
