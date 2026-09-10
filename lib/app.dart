import 'package:flutter/material.dart';
import 'package:belajar_flutter/core/theme/app_theme.dart';
import 'package:belajar_flutter/controllers/poker_game_controller.dart';
import 'package:belajar_flutter/screens/poker/setup_screen.dart';

/// Root Widget aplikasi Texas Hold'em Poker Chip Simulator
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final PokerGameController _pokerController;

  @override
  void initState() {
    super.initState();
    _pokerController = PokerGameController();
  }

  @override
  void dispose() {
    _pokerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Hold\'em Chip Simulator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: SetupScreen(controller: _pokerController),
    );
  }
}
