import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/models/puzzle.dart';

/// Animated colored bar revealed when a group is correctly solved.
///
/// Solid muted-color fill with ink text. No border, no shadow.
class GroupRevealRow extends StatefulWidget {
  const GroupRevealRow({
    super.key,
    required this.group,
    this.animate = true,
  });

  final PuzzleGroup group;
  final bool animate;

  @override
  State<GroupRevealRow> createState() => _GroupRevealRowState();
}

class _GroupRevealRowState extends State<GroupRevealRow>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final AnimationController _wordsCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _wordsFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOut,
    );

    _wordsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _wordsFade = CurvedAnimation(
      parent: _wordsCtrl,
      curve: Curves.easeIn,
    );

    if (widget.animate) {
      HapticFeedback.mediumImpact();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.of(context).disableAnimations) {
          _ctrl.value = 1.0;
          _wordsCtrl.value = 1.0;
          return;
        }
        _ctrl.forward();
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _wordsCtrl.forward();
          }
        });
      });
    } else {
      _ctrl.value = 1.0;
      _wordsCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _wordsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solid fill -- mustard #D9B04C, sage #A3C09B, dusty blue #8FB0CF, terracotta #D9907F
    final fillColor = AppColors.difficultyColor(widget.group.difficulty);
    // #1B1A17 ink text on all four, contrast >= 4.5:1
    const textColor = Color(0xFF1B1A17);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            // No border, no shadow -- solid fill only
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category label in serif (Fraunces)
              Text(
                widget.group.category.toUpperCase(),
                style: const TextStyle(
                  fontFamily: AppFonts.display,
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              // Words fade in 120ms later
              FadeTransition(
                opacity: _wordsFade,
                child: Text(
                  widget.group.words.join('  \u00B7  '),
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}