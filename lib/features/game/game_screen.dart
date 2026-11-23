import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/ad_service.dart';
import '../../core/theme.dart';
import '../../data/models/puzzle.dart';
import '../../data/services/streak_service.dart';
import '../premium/premium_notifier.dart';
import 'game_notifier.dart';
import 'group_reveal_row.dart';
import 'word_tile.dart';

class GameArgs {
  const GameArgs({
    required this.puzzle,
    required this.gameSource,
    this.packName,
  });

  final Puzzle puzzle;
  final GameSource gameSource;
  final String? packName;
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({
    super.key,
    required this.puzzle,
    required this.gameSource,
    this.packName,
  });

  final Puzzle puzzle;
  final GameSource gameSource;
  final String? packName;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).loadPuzzle(widget.puzzle);
    });
    AdService.instance.loadRewarded();
    AdService.instance.loadInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final isDark = AppColors.isDark(context);

    ref.listen<GameState>(gameProvider, (prev, next) async {
      if (!(prev?.shouldShake ?? false) && next.shouldShake) {
        HapticFeedback.heavyImpact();
        if (next.isOneAway) {
          HapticFeedback.selectionClick();
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) ref.read(gameProvider.notifier).clearShake();
      } else if (!(prev?.isOneAway ?? false) && next.isOneAway) {
        HapticFeedback.selectionClick();
      }
    });

    ref.listen<GameState>(gameProvider, (prev, next) async {
      final wasTerminal =
          prev?.phase == GamePhase.solved || prev?.phase == GamePhase.failed;
      final isTerminal =
          next.phase == GamePhase.solved || next.phase == GamePhase.failed;

      if (!wasTerminal && isTerminal) {
        await StreakService.instance.markPuzzlePlayed(
          widget.puzzle.id,
          won: next.phase == GamePhase.solved,
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!context.mounted) return;
        final result = ref
            .read(gameProvider.notifier)
            .buildResult(
              gameSource: widget.gameSource,
              packName: widget.packName,
            );
        context.go('/results', extra: result);
      }
    });

    final int mistakesLeft = (4 - (gameState.mistakeCount as num)).toInt();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.arrowLeft,
            color: Theme.of(context).colorScheme.onSurface,
            size: 22,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'CLUSTER',
          style: TextStyle(
            fontFamily: AppFonts.display,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  children: [
                    Text(
                      'Find four groups of four',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        color: AppColors.mutedColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (gameState.isOneAway)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.diff3.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.diff3.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                PhosphorIconsFill.flame,
                                color: AppColors.diff3,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'One away!',
                                style: TextStyle(
                                  color: AppColors.diff3,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    ...gameState.revealedGroups.map(
                      (group) => Padding(
                        key: ValueKey(group.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RepaintBoundary(
                          child: GroupRevealRow(group: group),
                        ),
                      ),
                    ),

                    if (gameState.remainingWords.isNotEmpty)
                      RepaintBoundary(
                        child: _WordGrid(gameState: gameState),
                      ),

                    const SizedBox(height: 16),

                    _ProgressBar(
                      groupsFound: gameState.groupsFound,
                      mistakesLeft: mistakesLeft,
                      mistakeCount: gameState.mistakeCount,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            _BottomBar(gameState: gameState),
          ],
        ),
      ),
    );
  }
}

// -- Word grid -----------------------------------------------------------------

class _WordGrid extends ConsumerWidget {
  const _WordGrid({required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final words = gameState.remainingWords;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: words.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final word = words[index];
        final isSelected = gameState.selectedWords.contains(word);
        final shake = gameState.shouldShake && isSelected;
        final clearingIndex = gameState.clearingWords.indexOf(word);

        Widget tile = _SpringScaleTile(
          isSelected: isSelected,
          child: WordTile(
            key: ValueKey(word),
            word: word,
            isSelected: isSelected,
            shake: shake,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.toggleTile(word);
            },
          ),
        );

        if (clearingIndex >= 0) {
          tile = _ClearingTile(
            index: clearingIndex,
            child: tile,
          );
        }

        return tile;
      },
    );
  }
}

// -- Progress bar + mistakes caption ------------------------------------------

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.groupsFound,
    required this.mistakesLeft,
    required this.mistakeCount,
    required this.isDark,
  });

  final int groupsFound;
  final int mistakesLeft;
  final int mistakeCount;
  final bool isDark;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _scale = 1.0;
  int? _justLostDotIndex;

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.groupsFound == 4 && oldWidget.groupsFound != 4) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _scale = 1.02);
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _scale = 1.0);
        });
      });
    }

    // When mistakesLeft drops, the dot at index (4 - widget.mistakeCount) was just lost
    if (widget.mistakeCount > oldWidget.mistakeCount) {
      setState(() {
        _justLostDotIndex = 4 - widget.mistakeCount;
      });
    } else {
      _justLostDotIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.groupsFound} / 4 groups',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(widget.groupsFound / 4 * 100).round()}%',
              style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.groupsFound / 4),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              final colorProgress = ((value - 0.5) * 2).clamp(0.0, 1.0);
              final barColor =
                  Color.lerp(
                    AppColors.accent,
                    AppColors.accentLight,
                    colorProgress,
                  ) ??
                  AppColors.accent;

              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: widget.isDark
                      ? const Color(0xFF2A2723)
                      : AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // "Mistakes left" caption with dots
        Row(
          children: [
            ...List.generate(4, (i) {
              final isLost = i >= widget.mistakesLeft;
              final shouldPop = _justLostDotIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 5),
                child: _MistakeDot(
                  isLost: isLost,
                  isDark: widget.isDark,
                  shouldPop: shouldPop,
                ),
              );
            }),
            const SizedBox(width: 6),
            Text(
              '${widget.mistakesLeft} mistake${widget.mistakesLeft == 1 ? '' : 's'} left',
              style: const TextStyle(
                color: AppColors.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// -- Bottom action bar --------------------------------------------------------

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.gameState});
  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final canSubmit = gameState.canSubmit;
    final isDark = AppColors.isDark(context);
    final isPremium = ref
        .watch(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF332F28) : AppColors.hairline,
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (isPremium) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hints are free for Cluster Pro members!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final earned = await AdService.instance.showRewarded();
                if (!context.mounted) return;

                if (earned) {
                  final gs = ref.read(gameProvider);
                  final revealedIds = gs.revealedGroups
                      .map((g) => g.id)
                      .toSet();
                  final unrevealed = gs.puzzle?.groups
                      .where((g) => !revealedIds.contains(g.id))
                      .toList();
                  if (unrevealed != null && unrevealed.isNotEmpty) {
                    final category = unrevealed.first.category;
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: AppColors.cardBg(context),
                          icon: PhosphorIcon(
                            PhosphorIconsFill.lightbulb,
                            color: AppColors.mustard,
                            size: 32,
                          ),
                          title: Text(
                            'Hint',
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              color: AppColors.textColor(context),
                            ),
                          ),
                          content: Text(
                            'One group is:\n"$category"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.ui,
                              color: AppColors.textColor(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No ad available -- try again in a moment'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: PhosphorIcon(
                PhosphorIconsRegular.lightbulb,
                size: 17,
                color: isDark ? AppColors.darkMustard : const Color(0xFF8C6412),
              ),
              label: Text(
                'Hint',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  color: isDark ? AppColors.darkInk : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? const Color(0xFF453E34) : AppColors.hairline,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: AnimatedOpacity(
              opacity: canSubmit ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () => notifier.submitGuess(
                          disableAnimations:
                              MediaQuery.of(context).disableAnimations,
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: canSubmit ? 3 : 0,
                  shadowColor: AppColors.accent.withValues(alpha: 0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Animations ---------------------------------------------------------------

class _MistakeDot extends StatefulWidget {
  const _MistakeDot({
    required this.isLost,
    required this.isDark,
    required this.shouldPop,
  });

  final bool isLost;
  final bool isDark;
  final bool shouldPop;

  @override
  State<_MistakeDot> createState() => _MistakeDotState();
}

class _MistakeDotState extends State<_MistakeDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _dimmed = false;

  @override
  void initState() {
    super.initState();
    _dimmed = widget.isLost;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_ctrl);

    if (widget.shouldPop) {
      _triggerPop();
    }
  }

  @override
  void didUpdateWidget(covariant _MistakeDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPop && !oldWidget.shouldPop) {
      _triggerPop();
    } else if (widget.isLost != oldWidget.isLost && !widget.shouldPop) {
      _dimmed = widget.isLost;
    }
  }

  void _triggerPop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        setState(() => _dimmed = true);
        return;
      }
      _dimmed = false;
      _ctrl.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() => _dimmed = true);
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.accent;
    final dimmedColor = widget.isDark
        ? const Color(0xFF2B251E)
        : const Color(0xFFDED7C8);
    final activeBorder = AppColors.accent;
    final dimmedBorder = widget.isDark
        ? const Color(0xFF4A4032)
        : const Color(0xFFB8B0A0);

    final color = _dimmed ? dimmedColor : activeColor;
    final border = _dimmed ? dimmedBorder : activeBorder;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: border, width: 1.5),
        ),
      ),
    );
  }
}

class _ClearingTile extends StatefulWidget {
  const _ClearingTile({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_ClearingTile> createState() => _ClearingTileState();
}

class _ClearingTileState extends State<_ClearingTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
        return;
      }
      Future.delayed(Duration(milliseconds: widget.index * 40), () {
        if (mounted) _ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _SpringScaleTile extends StatefulWidget {
  const _SpringScaleTile({required this.isSelected, required this.child});
  final bool isSelected;
  final Widget child;

  @override
  State<_SpringScaleTile> createState() => _SpringScaleTileState();
}

class _SpringScaleTileState extends State<_SpringScaleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    upperBound: double.infinity,
    lowerBound: double.negativeInfinity,
    value: widget.isSelected ? 1.04 : 1.0,
  );

  @override
  void didUpdateWidget(_SpringScaleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      final target = widget.isSelected ? 1.04 : 1.0;
      const spring = SpringDescription(
        mass: 1.0,
        stiffness: 400.0,
        damping: 5.0,
      );
      final simulation = SpringSimulation(spring, _controller.value, target, 0);
      _controller.animateWith(simulation);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Transform.scale(scale: _controller.value, child: child),
      child: widget.child,
    );
  }
}
