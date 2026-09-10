import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';
import 'package:poker_local_game/services/sound_service.dart';

class WinnerDialog extends StatefulWidget {
  final List<PokerPlayer> winners;
  final int potAmount;
  final String? handDescription;
  final VoidCallback? onDismissed;
  final int autoDismissSeconds;

  const WinnerDialog({
    super.key,
    required this.winners,
    required this.potAmount,
    this.handDescription,
    this.onDismissed,
    this.autoDismissSeconds = 3,
  });

  @override
  State<WinnerDialog> createState() => _WinnerDialogState();
}

class _WinnerDialogState extends State<WinnerDialog>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    SoundService().playWinFanfare();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();

    _timer = Timer(Duration(seconds: widget.autoDismissSeconds), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winnerNames = widget.winners.map((w) => w.name).join(' & ');
    final primaryWinner = widget.winners.isNotEmpty
        ? widget.winners.first
        : null;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.5),
                blurRadius: 25,
                spreadRadius: 4,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy Icon with Glowing Ring
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.gold, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.gold, blurRadius: 12),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.gold,
                  size: 40,
                ),
              ),
              const SizedBox(height: 12),

              // Title Header
              const Text(
                '🏆 HASIL RONDE 🏆',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),

              // Winner Name Banner
              Text(
                '$winnerNames MENANG!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),

              // Hand Description Badge
              if (widget.handDescription != null &&
                  widget.handDescription!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Text(
                    widget.handDescription!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Winner Cards Preview
              if (primaryWinner != null &&
                  primaryWinner.holeCards.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: primaryWinner.holeCards.map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: CasinoCardWidget(
                        card: c,
                        isFaceUp: true,
                        width: 32,
                        height: 46,
                        isWinningCard: true,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Pot Won Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TOTAL POT: ${widget.potAmount} CHIP',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Text(
                'Ronde berikutnya dimulai dalam 3 detik...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
