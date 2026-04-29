import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network.dart';
import 'models/game_state.dart';
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
    return ChangeNotifierProvider(
      create: (_) => GameStateProvider(network: network),
      lazy: false,
      child: MaterialApp(
        title: 'Mayor\'s Terminal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0E14),
          primaryColor: const Color(0xFF1565C0),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF42A5F5),
            secondary: Color(0xFF66BB6A),
            surface: Color(0xFF141B24),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: HomePage(network: network),
      ),
    );
  }
}
