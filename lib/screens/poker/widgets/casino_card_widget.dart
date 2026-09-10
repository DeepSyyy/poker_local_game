import 'dart:math';
import 'package:flutter/material.dart';
import 'package:poker_local_game/models/playing_card.dart';

class CasinoCardWidget extends StatefulWidget {
  final PlayingCard? card;
  final bool isFaceUp;
  final double width;
  final double height;
  final bool allowPeek;

  const CasinoCardWidget({
    super.key,
    required this.card,
    this.isFaceUp = false,
    this.width = 44,
    this.height = 62,
    this.allowPeek = false,
  });

  @override
  State<CasinoCardWidget> createState() => _CasinoCardWidgetState();
}

class _CasinoCardWidgetState extends State<CasinoCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPeeking = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isFaceUp) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CasinoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFaceUp != oldWidget.isFaceUp) {
      if (widget.isFaceUp) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPeekStart() {
    if (!widget.allowPeek || widget.isFaceUp) return;
    setState(() => _isPeeking = true);
    _controller.forward();
  }

  void _onPeekEnd() {
    if (!widget.allowPeek || widget.isFaceUp) return;
    setState(() => _isPeeking = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    if (card == null) {
      return _buildEmptySlot();
    }

    return GestureDetector(
      onLongPressStart: (_) => _onPeekStart(),
      onLongPressEnd: (_) => _onPeekEnd(),
      onTapDown: (_) => _onPeekStart(),
      onTapUp: (_) => _onPeekEnd(),
      onTapCancel: () => _onPeekEnd(),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = angle >= (pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // 3D Perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardFront(card),
                  )
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildCardFront(PlayingCard card) {
    final suitColor = card.suit.color;

    return Container(
      width: widget.width,
      height: widget.height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          if (_isPeeking)
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Stack(
        children: [
          // Corner Rank & Suit
          Positioned(
            top: 1,
            left: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.rank.label,
                  style: TextStyle(
                    fontSize: widget.height * 0.26,
                    fontWeight: FontWeight.w900,
                    color: suitColor,
                    height: 0.9,
                  ),
                ),
                Text(
                  card.suit.symbol,
                  style: TextStyle(
                    fontSize: widget.height * 0.2,
                    color: suitColor,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),

          // Center Large Suit Symbol / Watermark
          Center(
            child: Text(
              card.suit.symbol,
              style: TextStyle(
                fontSize: widget.height * 0.42,
                color: suitColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Royal Blue Felt
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF93C5FD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.casino_rounded,
              size: widget.height * 0.35,
              color: Colors.amber.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
