import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    // Load puzzle on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).loadPuzzle(widget.puzzle);
    });
    // Preload ads for this session
    AdService.instance.loadRewarded();
    AdService.instance.loadInterstitial();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    // ── Auto-clear shake after animation ───────────────────────────────────
    ref.listen<GameState>(gameProvider, (prev, next) async {
      if (!(prev?.shouldShake ?? false) && next.shouldShake) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) ref.read(gameProvider.notifier).clearShake();
      }
    });

    // ── Navigate on terminal state ──────────────────────────────────────────
    ref.listen<GameState>(gameProvider, (prev, next) async {
      final wasTerminal =
          prev?.phase == GamePhase.solved || prev?.phase == GamePhase.failed;
      final isTerminal =
          next.phase == GamePhase.solved || next.phase == GamePhase.failed;

      if (!wasTerminal && isTerminal) {
        // Record streak
        await StreakService.instance.markPuzzlePlayed(
          widget.puzzle.id,
          won: next.phase == GamePhase.solved,
        );

        // Small delay so the last reveal animation is visible
        await Future<void>.delayed(const Duration(milliseconds: 600));

        if (!context.mounted) return;
        final result = ref.read(gameProvider.notifier).buildResult(
              gameSource: widget.gameSource,
              packName: widget.packName,
            );
        context.go('/results', extra: result);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppColors.background.withValues(alpha: 0.6),
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.onSurface, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'CLUSTER',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onBackground,
            letterSpacing: 3,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(4, (i) {
              final used = i < gameState.mistakeCount;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: used ? AppColors.mistakeUsed : AppColors.mistakeEmpty,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    // Instruction
                    Text(
                      'Find four groups of four',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // One-away banner
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.diff3.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            '🔥 One away!',
                            style: TextStyle(
                              color: AppColors.diff3,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Revealed group rows
                    ...gameState.revealedGroups.asMap().entries.map(
                      (entry) => Padding(
                        key: ValueKey(entry.value.id),
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AnimatedRevealRow(
                          index: entry.key,
                          child: GroupRevealRow(group: entry.value),
                        ),
                      ),
                    ),

                    // 4×4 word tile grid
                    if (gameState.remainingWords.isNotEmpty)
                      _WordGrid(gameState: gameState),

                    const SizedBox(height: 16),

                    // Progress bar
                    _ProgressBar(groupsFound: gameState.groupsFound),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom action row
            _BottomBar(gameState: gameState),
          ],
        ),
      ),
    );
  }
}



// ── Word grid ─────────────────────────────────────────────────────────────────

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

        return _SpringScaleTile(
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
      },
    );
  }
}

// ── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.groupsFound});

  final int groupsFound;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double _scale = 1.0;

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
              // Interpolate color from accent (0-50%) to a lighter tint (75-100%)
              final colorProgress = ((value - 0.5) * 2).clamp(0.0, 1.0);
              final barColor = Color.lerp(
                    AppColors.accent,
                    AppColors.accentLight,
                    colorProgress,
                  ) ??
                  AppColors.accent;

              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 6,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider.notifier);
    final canSubmit = gameState.canSubmit;
    final isPremium = ref
        .watch(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.surfaceElevated, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Hint button — rewarded ad for free users, free for Pro
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (isPremium) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Hints are free for Cluster Pro members! '
                        '(full hint logic in Phase 3)',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final earned = await AdService.instance.showRewarded();
                if (!context.mounted) return;

                if (earned) {
                  // Reveal the category label of the first unrevealed group
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
                          backgroundColor: AppColors.surfaceElevated,
                          icon: const Icon(
                            Icons.lightbulb,
                            color: AppColors.diff3,
                            size: 32,
                          ),
                          title: const Text(
                            'Hint',
                            style: TextStyle(color: AppColors.onBackground),
                          ),
                          content: Text(
                            'One group is:\n"$category"',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.onBackground,
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
                      content: Text('No ad available — try again in a moment'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('Hint'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: const BorderSide(color: AppColors.surfaceElevated),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Submit button
          Expanded(
            flex: 3,
            child: AnimatedOpacity(
              opacity: canSubmit ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton(
                onPressed: canSubmit ? notifier.submitGuess : null,
                child: const Text('Submit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animations ────────────────────────────────────────────────────────────────

class _AnimatedRevealRow extends StatefulWidget {
  const _AnimatedRevealRow({
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_AnimatedRevealRow> createState() => _AnimatedRevealRowState();
}

class _AnimatedRevealRowState extends State<_AnimatedRevealRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  ));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

class _SpringScaleTile extends StatefulWidget {
  const _SpringScaleTile({
    required this.isSelected,
    required this.child,
  });

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
      final simulation = SpringSimulation(
        spring,
        _controller.value,
        target,
        0,
      );
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
      builder: (context, child) {
        return Transform.scale(
          scale: _controller.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
