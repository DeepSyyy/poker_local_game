import 'package:flutter/material.dart';
import 'package:belajar_flutter/core/constants/app_colors.dart';
import 'package:belajar_flutter/controllers/poker_game_controller.dart';
import 'package:belajar_flutter/screens/poker/table_screen.dart';

class SetupScreen extends StatefulWidget {
  final PokerGameController controller;

  const SetupScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _playerCount = 4;
  int _initialChips = 1000;
  bool _blindsEnabled = true;
  int _smallBlind = 10;
  int _bigBlind = 20;

  late List<TextEditingController> _nameControllers;

  @override
  void initState() {
    super.initState();
    _initNameControllers();
  }

  void _initNameControllers() {
    _nameControllers = List.generate(8, (i) {
      return TextEditingController(text: 'Player ${i + 1}');
    });
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startGame() {
    final names = List.generate(_playerCount, (i) => _nameControllers[i].text.trim());

    widget.controller.initializeGame(
      playerNames: names,
      initialChips: _initialChips,
      smallBlind: _smallBlind,
      bigBlind: _bigBlind,
      blindsEnabled: _blindsEnabled,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TableScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar / Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.casino_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEXAS HOLD\'EM CHIP SIMULATOR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Shared Table Mode • Taruh HP/Tablet di tengah meja untuk simulasi chip',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _startGame,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('MULAI MEJA POKER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Setup Columns (Landscape: Left & Right)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Table & Chip Settings
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Jumlah Pemain
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Jumlah Pemain:',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$_playerCount Orang',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [2, 3, 4, 5, 6, 7, 8].map((count) {
                                  final isSelected = count == _playerCount;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: InkWell(
                                        onTap: () => setState(() => _playerCount = count),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.cardSurfaceElevated,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.borderSubtle,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$count',
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : Colors.white70,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),

                              // 2. Chip Awal
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Chip / Saldo Awal per Pemain:',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '$_initialChips Chip',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [500, 1000, 2000, 5000].map((chipVal) {
                                  final isSelected = chipVal == _initialChips;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: OutlinedButton(
                                        onPressed: () => setState(() => _initialChips = chipVal),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: isSelected
                                              ? AppColors.gold.withValues(alpha: 0.2)
                                              : AppColors.cardSurfaceElevated,
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.gold
                                                : AppColors.borderSubtle,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        child: Text(
                                          '$chipVal',
                                          style: TextStyle(
                                            color: isSelected ? AppColors.gold : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 14),

                              // 3. Pengaturan Blinds
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Gunakan Blinds (SB / BB):',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Switch(
                                    value: _blindsEnabled,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) => setState(() => _blindsEnabled = val),
                                  ),
                                ],
                              ),
                              if (_blindsEnabled) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildBlindInput(
                                        label: 'Small Blind (SB)',
                                        value: _smallBlind,
                                        onChanged: (val) {
                                          setState(() {
                                            _smallBlind = val;
                                            _bigBlind = val * 2;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildBlindInput(
                                        label: 'Big Blind (BB)',
                                        value: _bigBlind,
                                        onChanged: (val) => setState(() => _bigBlind = val),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Right Column: Player Names
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Pemain:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _playerCount,
                                separatorBuilder: (context, index) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.cardSurfaceElevated,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.borderSubtle),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _nameControllers[index],
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Nama Player ${index + 1}',
                                            filled: true,
                                            fillColor: AppColors.cardSurfaceElevated,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            isDense: true,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: AppColors.borderSubtle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlindInput({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [10, 20, 50, 100].map((b) {
            final isSelected = b == value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => onChanged(b),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.cardSurfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$b',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
