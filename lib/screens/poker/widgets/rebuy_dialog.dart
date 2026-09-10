import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/models/poker_player.dart';
import 'package:poker_local_game/core/constants/app_colors.dart';

class RebuyDialog extends StatefulWidget {
  final List<PokerPlayer> players;
  final Function(String playerId, int amount) onAddChips;

  const RebuyDialog({
    super.key,
    required this.players,
    required this.onAddChips,
  });

  @override
  State<RebuyDialog> createState() => _RebuyDialogState();
}

class _RebuyDialogState extends State<RebuyDialog> {
  String? _selectedPlayerId;
  final TextEditingController _amountController = TextEditingController(text: '1000');

  @override
  void initState() {
    super.initState();
    if (widget.players.isNotEmpty) {
      _selectedPlayerId = widget.players.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Container(
        width: min(440, MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_card_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Rebuy / Tambah Chip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Dropdown Pilih Pemain
            const Text(
              'Pilih Pemain:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.cardSurfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPlayerId,
                  isExpanded: true,
                  dropdownColor: AppColors.cardSurfaceElevated,
                  items: widget.players.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} (Saldo: ${p.chips} chip)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPlayerId = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Input Jumlah Chip
            const Text(
              'Jumlah Chip Tambahan:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardSurfaceElevated,
                prefixIcon: const Icon(Icons.toll, color: AppColors.gold, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),

            // Quick Chips Buttons
            Wrap(
              spacing: 8,
              children: [500, 1000, 2000, 5000].map((amount) {
                return ActionChip(
                  label: Text('+$amount'),
                  backgroundColor: AppColors.cardSurfaceElevated,
                  labelStyle: const TextStyle(fontSize: 11, color: AppColors.gold),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  onPressed: () {
                    setState(() {
                      _amountController.text = amount.toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final amount = int.tryParse(_amountController.text) ?? 0;
                if (_selectedPlayerId != null && amount > 0) {
                  widget.onAddChips(_selectedPlayerId!, amount);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'TAMBAH CHIP SEKARANG',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
