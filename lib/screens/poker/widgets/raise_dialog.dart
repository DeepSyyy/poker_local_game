import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/services/sound_service.dart';

class RaiseDialog extends StatefulWidget {
  final PokerPlayer player;
  final int currentBet;
  final int minRaise;
  final int maxRaise;
  final int pot;
  final Function(int targetBet) onConfirm;

  const RaiseDialog({
    super.key,
    required this.player,
    required this.currentBet,
    required this.minRaise,
    required this.maxRaise,
    required this.pot,
    required this.onConfirm,
  });

  @override
  State<RaiseDialog> createState() => _RaiseDialogState();
}

class _RaiseDialogState extends State<RaiseDialog> {
  late int _selectedBet;

  @override
  void initState() {
    super.initState();
    _selectedBet = widget.minRaise;
    if (_selectedBet > widget.maxRaise) {
      _selectedBet = widget.maxRaise;
    }
  }

  void _setBet(int amount) {
    setState(() {
      _selectedBet = amount.clamp(widget.minRaise, widget.maxRaise);
    });
  }

  @override
  Widget build(BuildContext context) {
    final additionalCost = _selectedBet - widget.player.currentRoundBet;
    final isAllIn = _selectedBet == widget.maxRaise;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Container(
        width: min(540, MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: widget.player.avatarColor,
                        child: Text(
                          widget.player.name.isNotEmpty
                              ? widget.player.name[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Raise Bet: ${widget.player.name}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Landscape 2-Column Body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Total Bet Card & Confirm Button
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAllIn
                                  ? AppColors.allInButton
                                  : AppColors.raiseButton,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '$_selectedBet CHIP',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isAllIn
                                      ? AppColors.allInButton
                                      : AppColors.raiseButton,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tambah: +$additionalCost chip\nSisa saldo: ${widget.player.chips - additionalCost}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            SoundService().playRaise();
                            widget.onConfirm(_selectedBet);
                            Navigator.pop(context);
                          },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAllIn
                                ? AppColors.allInButton
                                : AppColors.raiseButton,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            isAllIn
                                ? 'ALL-IN ($_selectedBet)'
                                : 'KONFIRMASI ($_selectedBet)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right Column: Slider & Quick Preset Buttons
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Slider & Stepper
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: _selectedBet > widget.minRaise
                                  ? () => _setBet(_selectedBet - 10)
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 26,
                                minHeight: 26,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: isAllIn
                                      ? AppColors.allInButton
                                      : AppColors.raiseButton,
                                  thumbColor: isAllIn
                                      ? AppColors.allInButton
                                      : AppColors.raiseButton,
                                  inactiveTrackColor: Colors.white12,
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                ),
                                child: Slider(
                                  value: _selectedBet.toDouble(),
                                  min: min(
                                    widget.minRaise,
                                    widget.maxRaise,
                                  ).toDouble(),
                                  max: widget.maxRaise.toDouble(),
                                  onChanged: (val) {
                                    _setBet(val.round());
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              onPressed: _selectedBet < widget.maxRaise
                                  ? () => _setBet(_selectedBet + 10)
                                  : null,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 26,
                                minHeight: 26,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Quick Preset Buttons
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildQuickButton(
                              'Min (${widget.minRaise})',
                              () => _setBet(widget.minRaise),
                            ),
                            if (widget.currentBet > 0) ...[
                              _buildQuickButton(
                                '2x (${widget.currentBet * 2})',
                                () => _setBet(widget.currentBet * 2),
                              ),
                              _buildQuickButton(
                                '3x (${widget.currentBet * 3})',
                                () => _setBet(widget.currentBet * 3),
                              ),
                            ],
                            if (widget.pot > 0) ...[
                              _buildQuickButton(
                                '½ Pot',
                                () => _setBet(
                                  widget.currentBet + (widget.pot ~/ 2),
                                ),
                              ),
                              _buildQuickButton(
                                'Pot',
                                () => _setBet(widget.currentBet + widget.pot),
                              ),
                            ],
                            _buildQuickButton(
                              'ALL-IN',
                              () => _setBet(widget.maxRaise),
                              isAccent: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton(
    String label,
    VoidCallback onTap, {
    bool isAccent = false,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: isAccent ? AppColors.allInButton : Colors.white70,
        side: BorderSide(
          color: isAccent ? AppColors.allInButton : AppColors.borderSubtle,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(32, 26),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isAccent ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}
