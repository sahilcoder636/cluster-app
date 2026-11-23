import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ad_service.dart';
import '../../core/theme.dart';
import '../../data/services/streak_service.dart';
import '../game/game_notifier.dart';
import '../game/group_reveal_row.dart';
import '../premium/premium_notifier.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.resultData});

  final GameResultData resultData;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  static const _teaserKey = 'premium_teaser_shown';

  late AnimationController _entryController;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  late AnimationController _badgeController;
  double _badgeScale = 0.7;

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _badgeController = AnimationController(vsync: this);
    _badgeController.addListener(() {
      setState(() {
        _badgeScale = _badgeController.value;
      });
    });

    // Ticking countdown timer to midnight (updated every second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    final isPremium = ref
        .read(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    if (widget.resultData.won) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.lightImpact();
      });
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      // Record game completed and show interstitial respecting frequency cap:
      // never on 1st game of session, then at most once every 3 completed games
      AdService.instance.onGameCompleted(isPremium: isPremium);
      _entryController.forward();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        const spring = SpringDescription(mass: 1, stiffness: 350, damping: 18);
        final simulation = SpringSimulation(spring, 0.7, 1.0, 0);
        _badgeController.animateWith(simulation);
      });
    });

    _maybeShowPremiumTeaser();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _entryController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _maybeShowPremiumTeaser() {
    if (widget.resultData.gameSource != GameSource.daily) return;

    final isPremium = ref
        .read(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);
    if (isPremium) return;

    final box = Hive.box(StreakService.boxName);
    final alreadyShown = (box.get(_teaserKey) as bool?) ?? false;
    if (alreadyShown) return;

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      box.put(_teaserKey, true);
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Enjoying Cluster?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Remove ads and unlock 50+ more puzzles with one tap.',
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        AppColors.muted,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      context.push('/premium');
                    },
                    child: const Text('See Premium'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Maybe later'),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  /// One line of serif italic text replacing the pill badge.
  Widget _performanceText() {
    final label = switch (widget.resultData.mistakeCount) {
      0 => 'Flawless',
      1 => 'Sharp',
      2 => 'Solid',
      _ => 'Got there',
    };
    final isDark = AppColors.isDark(context);
    return Transform.scale(
      scale: _badgeScale,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.display,
          fontStyle: FontStyle.italic,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkInk : AppColors.ink,
          height: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _shareResult() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final now = DateTime.now();
    final dateStr = '${months[now.month - 1]} ${now.day}';
    final buffer = StringBuffer();
    buffer.writeln('Cluster \u00B7 $dateStr');
    for (final group in widget.resultData.solveSequence) {
      final emoji = AppColors.difficultyEmoji(group.difficulty);
      buffer.writeln('$emoji$emoji$emoji$emoji');
    }
    if (!widget.resultData.won) {
      buffer.writeln('Failed with ${widget.resultData.mistakeCount} mistakes.');
    }
    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.isAfter(now)
        ? tomorrow.difference(now)
        : Duration.zero;
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(
            PhosphorIconsRegular.house,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    widget.resultData.won ? 'Great job!' : 'Next time!',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 32,
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.resultData.won
                        ? 'You solved the puzzle.'
                        : (widget.resultData.gameSource == GameSource.daily
                              ? "You'll get it tomorrow."
                              : "Keep practicing!"),
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.muted,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Performance text (wins only) -- one serif italic line, no pill
                  if (widget.resultData.won) ...[
                    const SizedBox(height: 12),
                    _performanceText(),
                  ],
                  const SizedBox(height: 16),
                  // Animated streak counter + pulsing flame
                  _ResultsStreak(won: widget.resultData.won),
                  const SizedBox(height: 20),
                  // Reveal all 4 category rows (solid muted fills, staggered 90ms apart)
                  ...widget.resultData.puzzle.groups.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RepaintBoundary(
                        child: _StaggeredGroupRow(
                          key: ValueKey(entry.value.id),
                          index: entry.key,
                          child: GroupRevealRow(
                            group: entry.value,
                            animate: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Wordle-style emoji share grid (kept as-is -- Wordle squares)
                  Column(
                    children: widget.resultData.solveSequence.map((group) {
                      final emoji = AppColors.difficultyEmoji(group.difficulty);
                      return Text(
                        '$emoji$emoji$emoji$emoji',
                        style: const TextStyle(fontSize: 24, letterSpacing: 4),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _shareResult,
                    icon: PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 18),
                    label: const Text('Share result'),
                  ),
                  const SizedBox(height: 24),
                  if (widget.resultData.gameSource == GameSource.daily)
                    Text(
                      'Play again tomorrow\nNext puzzle in $hours:$mins:$secs',
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.muted,
                        fontSize: 14,
                        height: 1.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        ref.read(gameProvider.notifier).reset();
                        context.go('/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Play again'),
                    ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => context.push('/premium'),
                    child: const Text(
                      'Remove ads',
                      style: TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StaggeredGroupRow extends StatefulWidget {
  const _StaggeredGroupRow({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<_StaggeredGroupRow> createState() => _StaggeredGroupRowState();
}

class _StaggeredGroupRowState extends State<_StaggeredGroupRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
        return;
      }
      Future.delayed(Duration(milliseconds: widget.index * 90), () {
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
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(0, _slide.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ResultsStreak extends StatefulWidget {
  const _ResultsStreak({
    required this.won,
  });

  final bool won;

  @override
  State<_ResultsStreak> createState() => _ResultsStreakState();
}

class _ResultsStreakState extends State<_ResultsStreak>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pulseScale = TweenSequence<double>([
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
    ]).animate(_pulseCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) return;
      // Pulse the flame icon once over the count-up duration
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _pulseCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = StreakService.instance.getStreak();
    final previousStreak =
        widget.won && currentStreak > 0 ? currentStreak - 1 : currentStreak;
    final disable = MediaQuery.of(context).disableAnimations;
    final isDark = AppColors.isDark(context);
    final inkColor = isDark ? AppColors.darkInk : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: previousStreak, end: currentStreak),
      duration: disable ? Duration.zero : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontFamily: AppFonts.display,
                color: inkColor,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'day streak',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                color: mutedColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _pulseScale,
              child: PhosphorIcon(
                PhosphorIconsFill.flame,
                color: AppColors.accent,
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}
