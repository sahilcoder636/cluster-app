import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// A single tappable word tile in the 4×4 puzzle grid.
///
/// Supports:
///   - Normal / Selected visual states (animated with [AnimatedContainer])
///   - Shake animation when [shake] flips from false → true
///   - Press scale animation for tactile feedback
class WordTile extends StatefulWidget {
  const WordTile({
    super.key,
    required this.word,
    required this.isSelected,
    required this.shake,
    required this.onTap,
  });

  final String word;
  final bool isSelected;

  /// Setting this to true triggers a dampened-sine shake animation.
  final bool shake;

  final VoidCallback onTap;

  @override
  State<WordTile> createState() => _WordTileState();
}

class _WordTileState extends State<WordTile>
    with SingleTickerProviderStateMixin {
  // ── Shake controller ─────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  // ── Press scale ───────────────────────────────────────────────────────────
  bool _pressed = false;

  @override
  void didUpdateWidget(WordTile old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) {
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // Dampened sine wave: x(t) = A·sin(2π·f·t)·e^(−k·t)
  double _offsetX(double t) =>
      8 * sin(2 * pi * 3 * t) * exp(-4 * t);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final dx = _shakeCtrl.isAnimating ? _offsetX(_shakeCtrl.value) : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? AppColors.tileSelected
                  : AppColors.surfaceTile,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? AppColors.tileSelectedBorder
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  widget.word,
                  style: const TextStyle(
                    color: AppColors.onTile,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
