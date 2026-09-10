import 'package:flutter/material.dart';
import 'package:poker_local_game/core/theme/app_theme.dart';
import 'package:poker_local_game/screens/mode_selection_screen.dart';

/// Root Widget aplikasi Texas Hold'em Poker Chip Simulator & Companion
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Hold\'em Poker Local & Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ModeSelectionScreen(),
    );
  }
}
