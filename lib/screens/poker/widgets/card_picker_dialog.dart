import 'package:flutter/material.dart';
import 'package:poker_local_game/models/playing_card.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';
import 'package:poker_local_game/screens/poker/widgets/casino_card_widget.dart';

class CardPickerDialog extends StatefulWidget {
  final String title;
  final List<PlayingCard> initialSelection;
  final List<PlayingCard> unavailableCards; // Cards already picked by others
  final int maxSelection;
  final Function(List<PlayingCard> selectedCards) onConfirm;

  const CardPickerDialog({
    super.key,
    required this.title,
    this.initialSelection = const [],
    this.unavailableCards = const [],
    this.maxSelection = 2,
    required this.onConfirm,
  });

  @override
  State<CardPickerDialog> createState() => _CardPickerDialogState();
}

class _CardPickerDialogState extends State<CardPickerDialog> {
  late List<PlayingCard> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelection);
  }

  void _toggleCard(PlayingCard card) {
    setState(() {
      final existingIndex = _selected.indexWhere(
        (c) => c.suit == card.suit && c.rank == card.rank,
      );
      if (existingIndex >= 0) {
        _selected.removeAt(existingIndex);
      } else {
        if (_selected.length < widget.maxSelection) {
          _selected.add(card);
        } else if (widget.maxSelection == 1) {
          _selected = [card];
        }
      }
    });
  }

  bool _isUnavailable(PlayingCard card) {
    return widget.unavailableCards.any(
      (c) => c.suit == card.suit && c.rank == card.rank,
    );
  }

  bool _isSelected(PlayingCard card) {
    return _selected.any((c) => c.suit == card.suit && c.rank == card.rank);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.style_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '${_selected.length}/${widget.maxSelection} Kartu',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Selection Preview bar
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Text(
                    'Pilihan:',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: List.generate(widget.maxSelection, (index) {
                        final card = index < _selected.length
                            ? _selected[index]
                            : null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: CasinoCardWidget(
                            card: card,
                            isFaceUp: card != null,
                            width: 28,
                            height: 42,
                          ),
                        );
                      }),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.clear_all_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => setState(() => _selected.clear()),
                      tooltip: 'Clear',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card Grid grouped by Suits (♠, ♥, ♦, ♣)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: CardSuit.values.map((suit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              suit.symbol,
                              style: TextStyle(
                                fontSize: 18,
                                color: suit.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: CardRank.values.map((rank) {
                                  final card = PlayingCard(
                                    suit: suit,
                                    rank: rank,
                                  );
                                  final selected = _isSelected(card);
                                  final disabled = _isUnavailable(card);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: InkWell(
                                      onTap: disabled
                                          ? null
                                          : () => _toggleCard(card),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Opacity(
                                        opacity: disabled ? 0.25 : 1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? AppColors.gold
                                                  : Colors.transparent,
                                              width: selected ? 2 : 0,
                                            ),
                                            boxShadow: selected
                                                ? [
                                                    BoxShadow(
                                                      color: AppColors.gold
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                      blurRadius: 6,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: CasinoCardWidget(
                                            card: card,
                                            isFaceUp: true,
                                            width: 30,
                                            height: 44,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_selected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'SIMPAN KARTU',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
