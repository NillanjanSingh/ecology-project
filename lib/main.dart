import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'network.dart';
import 'models/game_state.dart';
import 'pages/home_page.dart';
import 'theme/app_chrome.dart';

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
          scaffoldBackgroundColor: AppChrome.bg,
          primaryColor: AppChrome.cyan,
          colorScheme: const ColorScheme.dark(
            primary: AppChrome.cyan,
            secondary: AppChrome.mint,
            surface: AppChrome.panel,
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppChrome.text,
            elevation: 0,
            centerTitle: true,
          ),
          textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: AppChrome.text,
            displayColor: AppChrome.text,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppChrome.cyan,
              foregroundColor: AppChrome.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppChrome.text,
              side: const BorderSide(color: AppChrome.line),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        home: HomePage(network: network),
      ),
    );
  }
}
