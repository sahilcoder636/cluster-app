import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/puzzle.dart';

/// Animated colored bar revealed when a group is correctly solved.
///
/// Appears with a vertical scale-in + fade animation when first inserted
/// into the tree.
class GroupRevealRow extends StatefulWidget {
  const GroupRevealRow({super.key, required this.group});

  final PuzzleGroup group;

  @override
  State<GroupRevealRow> createState() => _GroupRevealRowState();
}

class _GroupRevealRowState extends State<GroupRevealRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0, 0.4, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.difficultyColor(widget.group.difficulty);
    final bgColor = color.withValues(alpha: 0.18);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category label
              Text(
                widget.group.category.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 6),
              // Words
              Text(
                widget.group.words.join('  ·  '),
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
