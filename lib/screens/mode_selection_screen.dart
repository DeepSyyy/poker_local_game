import 'package:flutter/material.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/controllers/poker_game_controller.dart';
import 'package:poker_local_game/screens/poker/setup_screen.dart';
import 'package:poker_local_game/screens/poker/join_game_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  late final PokerGameController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PokerGameController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // App Title & Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(
                      Icons.casino_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEXAS HOLD\'EM POKER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Local Shared Table & Companion Controller',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'PILIH PERAN PERANGKAT INI:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),

              // Responsive Cards Container (Adapts to screen height/width)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 450;
                  if (isNarrow) {
                    return Column(
                      children: [
                        _buildHostCard(),
                        const SizedBox(height: 12),
                        _buildJoinCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildHostCard()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildJoinCard()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetupScreen(controller: _controller),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2E38), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.table_restaurant_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'BUAT MEJA (HOST GAME)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jadikan perangkat ini sebagai Meja Poker Utama di tengah meja (Tampilan Pot, Kartu Meja & Server QR).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JoinGameScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2E38), Color(0xFF0F172A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smartphone_rounded,
                size: 36,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'GABUNG MEJA (JOIN GAME)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Jadikan perangkat ini sebagai Kontroler Rahasia Pemain untuk mengintip kartu saku & bertaruh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
