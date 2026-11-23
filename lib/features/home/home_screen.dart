import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/ad_service.dart';
import '../../core/theme.dart';
import '../../data/repositories/pack_repository.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/streak_service.dart';
import '../game/game_notifier.dart';
import '../game/game_screen.dart';
import '../premium/premium_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PackRepository _packRepo = PackRepository();

  static const String _notificationAskedKey = 'notification_asked';

  @override
  void initState() {
    super.initState();
    final isPremium = ref
        .read(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);
    if (!isPremium) {
      AdService.instance.loadBanner(
        onLoaded: () {
          if (mounted) setState(() {});
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestNotificationPermission();
    });
  }

  Future<void> _maybeRequestNotificationPermission() async {
    final box = Hive.box(StreakService.boxName);
    final alreadyAsked =
        box.get(_notificationAskedKey, defaultValue: false) as bool;
    if (alreadyAsked) return;

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final granted = await NotificationService.instance.requestPermission(
      context,
    );
    if (granted) {
      await NotificationService.instance.scheduleDailyReminder();
    }

    await box.put(_notificationAskedKey, true);
  }

  // -- Pack tap handlers ----------------------------------------------------

  Future<void> _onPackTap(
    String packName, {
    required bool isPremiumPack,
  }) async {
    final isPremium = ref
        .read(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    if (isPremiumPack && !isPremium) {
      context.go('/premium');
      return;
    }

    final isCompleted = await ref.read(packCompletedProvider(packName).future);
    if (!mounted) return;

    if (isCompleted) {
      final playAgain = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text(
            'Pack Completed',
            style: TextStyle(color: AppColors.onBackground),
          ),
          content: const Text(
            'You have completed all puzzles in this pack. Do you want to play it again?',
            style: TextStyle(color: AppColors.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Play again'),
            ),
          ],
        ),
      );

      if (playAgain != true) return;
      await _packRepo.resetPack(packName);
      ref.invalidate(packCompletedProvider(packName));
    }

    final playedIds = await _packRepo.getPlayedIds(packName);
    final puzzle = await _packRepo.getNextUnplayedPuzzle(packName, playedIds);

    if (!mounted) return;

    if (puzzle == null) {
      final displayName = packName[0].toUpperCase() + packName.substring(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You've completed all $displayName puzzles! More coming soon.",
          ),
        ),
      );
      return;
    }

    ref.read(gameProvider.notifier).loadPuzzle(puzzle);
    context.go(
      '/game',
      extra: GameArgs(
        puzzle: puzzle,
        gameSource: GameSource.pack,
        packName: packName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todaysPuzzleProvider);
    final todayLabel = _formatDate(DateTime.now());
    final isPremium = ref
        .watch(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Hive.box(StreakService.boxName).listenable(),
          builder: (context, box, _) {
            final streak = StreakService.instance.getStreak();
            final hasShield = StreakService.instance.hasShield();
            return CustomScrollView(
              slivers: [
                // -- Title section --------------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ShimmerTitle(),
                        const SizedBox(height: 4),
                        Text(
                          'One puzzle. Every day.',
                          style: TextStyle(
                            fontFamily: AppFonts.ui,
                            color: AppColors.mutedColor(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),

                // -- Streak row -----------------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _StreakRow(
                      streak: streak,
                      hasShield: hasShield,
                      isPremium: isPremium,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // -- Daily challenge card -------------------------------------------------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DailyCard(
                      dateLabel: todayLabel,
                      todayAsync: todayAsync,
                      onPlay: (puzzle) {
                        ref.read(gameProvider.notifier).loadPuzzle(puzzle);
                        context.go(
                          '/game',
                          extra: GameArgs(
                            puzzle: puzzle,
                            gameSource: GameSource.daily,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // -- Section header -------------------------------------------------------
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'PRACTICE PACKS',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),

                // -- Practice packs grid --------------------------------------------------
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _PackCard(
                        packName: 'movies',
                        icon: PhosphorIconsRegular.filmSlate,
                        title: 'Movies',
                        isLocked: false,
                        onTap: () => _onPackTap('movies', isPremiumPack: false),
                      ),
                      _PackCard(
                        packName: 'sports',
                        icon: PhosphorIconsRegular.soccerBall,
                        title: 'Sports',
                        isLocked: false,
                        onTap: () => _onPackTap('sports', isPremiumPack: false),
                      ),
                      _PackCard(
                        packName: 'music',
                        icon: PhosphorIconsRegular.musicNote,
                        title: 'Music',
                        isLocked: !isPremium,
                        onTap: () => _onPackTap('music', isPremiumPack: true),
                      ),
                      _PackCard(
                        packName: 'food',
                        icon: PhosphorIconsRegular.forkKnife,
                        title: 'Food',
                        isLocked: !isPremium,
                        onTap: () => _onPackTap('food', isPremiumPack: true),
                      ),
                    ],
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // -- AdMob banner (free users only) ---------------------------------------
                SliverToBoxAdapter(
                  child: isPremium || !AdService.instance.isBannerLoaded
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AdService.instance.bannerWidget(),
                        ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }
}

// --------------------------------------------------------------------------
// Sub-widgets
// --------------------------------------------------------------------------

/// Flat streak row: large numeral + "day streak" + small flame icon.
class _StreakRow extends StatelessWidget {
  const _StreakRow({
    required this.streak,
    required this.hasShield,
    required this.isPremium,
  });

  final int streak;
  final bool hasShield;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final inkColor = isDark ? AppColors.darkInk : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large numeral
        Text(
          '$streak',
          style: TextStyle(
            fontFamily: AppFonts.display,
            color: inkColor,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        // Label column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'day streak',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  color: mutedColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasShield)
                Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.shieldCheck,
                      color: Colors.blue,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Streak protected',
                      style: TextStyle(color: Colors.blue, fontSize: 11),
                    ),
                  ],
                )
              else if (isPremium)
                GestureDetector(
                  onTap: () => StreakService.instance.activateShield(),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.shield,
                        color: AppColors.accent,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Activate shield',
                        style: TextStyle(color: AppColors.accent, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text(
                          'Protect your streak \u2192',
                          style: TextStyle(color: AppColors.onBackground),
                        ),
                        content: const Text(
                          'Watch a short ad to protect your streak for one missed day.',
                          style: TextStyle(color: AppColors.onSurface),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              final rewarded = await AdService.instance
                                  .showRewarded();
                              if (rewarded) {
                                await StreakService.instance.activateShield();
                              }
                            },
                            child: const Text('Watch ad'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.shield,
                        color: mutedColor,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Protect your streak \u2192',
                        style: TextStyle(color: mutedColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Small flame icon
        PhosphorIcon(
          PhosphorIconsFill.flame,
          color: AppColors.accent,
          size: 22,
        ),
      ],
    );
  }
}

class _DailyCard extends StatefulWidget {
  const _DailyCard({
    required this.dateLabel,
    required this.todayAsync,
    required this.onPlay,
  });

  final String dateLabel;
  final AsyncValue<dynamic> todayAsync;
  final void Function(dynamic puzzle) onPlay;

  @override
  State<_DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<_DailyCard> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.isAfter(now)
        ? tomorrow.difference(now)
        : Duration.zero;
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final puzzle = widget.todayAsync.asData?.value;
    final isPlayed =
        puzzle != null &&
        StreakService.instance.isPuzzlePlayed(puzzle.id as String);
    final countdownStr = _formatCountdown();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          // hairline border
          color: isDark ? AppColors.darkHairline : AppColors.hairline,
          width: 0.75,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.calendar,
                    color: AppColors.accentLight,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.dateLabel,
                    style: const TextStyle(
                      color: AppColors.accentLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (isPlayed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.diff2.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsBold.check,
                        size: 11,
                        color: isDark ? AppColors.darkSage : AppColors.sage,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Solved today',
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          color: isDark ? AppColors.darkSage : AppColors.sage,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Serif (Fraunces) title -- always cream ink in dark mode
          Text(
            'Daily Challenge',
            style: TextStyle(
              fontFamily: AppFonts.display,
              color: isDark ? AppColors.darkInk : AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPlayed
                ? 'Next puzzle in $countdownStr'
                : '16 words \u00B7 4 groups \u00B7 4 mistakes allowed',
            style: TextStyle(
              color: isPlayed
                  ? (isDark ? AppColors.darkMuted : AppColors.muted)
                  : AppColors.onSurface,
              fontSize: 12,
              fontWeight: isPlayed ? FontWeight.w600 : FontWeight.w400,
              fontFeatures: isPlayed
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
          if (!isPlayed) ...[
            const SizedBox(height: 16),
            widget.todayAsync.when(
              loading: () => ElevatedButton(
                onPressed: null,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Loading puzzle\u2026'),
                  ],
                ),
              ),
              error: (e, _) => ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.diff4),
                child: const Text('No puzzle for today'),
              ),
              data: (p) {
                if (p == null) {
                  return ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.diff4,
                    ),
                    child: const Text('No puzzle scheduled'),
                  );
                }
                return ElevatedButton.icon(
                  onPressed: () => widget.onPlay(p),
                  icon: PhosphorIcon(
                    PhosphorIconsFill.play,
                    size: 18,
                  ),
                  label: const Text("Play today's puzzle"),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PackCard extends ConsumerWidget {
  const _PackCard({
    required this.packName,
    required this.icon,
    required this.title,
    required this.isLocked,
    required this.onTap,
  });

  final String packName;
  final PhosphorIconData icon;
  final String title;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final isCompleted = ref
        .watch(packCompletedProvider(packName))
        .maybeWhen(data: (v) => v, orElse: () => false);
    final inkColor = isDark ? AppColors.darkInk : AppColors.ink;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkHairline : AppColors.hairline,
                width: 0.75,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhosphorIcon(icon, color: inkColor, size: 26),
                    if (isLocked)
                      // Small accent-colored "PRO" text label \u2014 no pill
                      const Text(
                        'PRO',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontFamily: AppFonts.ui,
                        ),
                      ),
                  ],
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: PhosphorIcon(
                  PhosphorIconsBold.check,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShimmerTitle extends StatelessWidget {
  const _ShimmerTitle();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Text(
      'CLUSTER',
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: 4.0,
        color: isDark ? AppColors.darkInk : AppColors.ink,
      ),
    );
  }
}
