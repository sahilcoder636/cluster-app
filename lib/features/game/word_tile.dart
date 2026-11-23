import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// A single word tile in the 4x4 game grid.
///
/// Selected state: solid ink fill with paper-coloured text.
/// Unselected state: paper fill with ink text.
/// Horizontal shake feedback on incorrect submission.
///
/// Survives large text scales without overflowing by using
/// FittedBox(scaleDown) with min font size protection.
class WordTile extends StatefulWidget {
  final String word;
  final bool isSelected;
  final bool shake;
  final VoidCallback onTap;

  const WordTile({
    super.key,
    required this.word,
    required this.isSelected,
    required this.shake,
    required this.onTap,
  });

  @override
  State<WordTile> createState() => _WordTileState();
}

class _WordTileState extends State<WordTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(WordTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  /// Dampened sine-wave shake offset in pixels.
  double _offsetX(double t) => sin(t * pi * 6) * (1 - t) * 8.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Selected: ink fill, paper text. Unselected: paper/tile fill, ink text.
    final Color tileBg;
    final Color tileTextColor;
    final Color borderColor;

    if (widget.isSelected) {
      tileBg = isDark ? AppColors.darkInk : AppColors.ink;
      tileTextColor = isDark ? AppColors.darkBg : AppColors.paper;
      borderColor = isDark ? AppColors.darkInk : AppColors.ink;
    } else {
      tileBg = isDark ? const Color(0xFF25211B) : const Color(0xFFFAF6EE);
      tileTextColor = isDark ? const Color(0xFFEDE5D5) : AppColors.ink;
      borderColor = isDark ? const Color(0xFF3D362C) : const Color(0xFFD6CEBD);
    }

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
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                if (!widget.isSelected)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: MediaQuery.textScalerOf(context).clamp(
                      minScaleFactor: 10.0 / 14.0, // min font size floor (10pt)
                      maxScaleFactor: 2.5,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.word,
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        color: tileTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
