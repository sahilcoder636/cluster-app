import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ad_service.dart';
import '../../core/theme.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/services/streak_service.dart';
import '../game/game_notifier.dart';
import '../premium/premium_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load banner only for free users; premium check is best-effort here.
    final isPremium =
        ref.read(premiumProvider).maybeWhen(data: (v) => v, orElse: () => false);
    if (!isPremium) {
      AdService.instance.loadBanner(onLoaded: () { if (mounted) setState(() {}); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todaysPuzzleProvider);
    final streak = StreakService.instance.getStreak();
    final todayLabel = _formatDate(DateTime.now());
    final isPremium = ref.watch(premiumProvider).maybeWhen(data: (v) => v, orElse: () => false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Title section ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ).createShader(bounds),
                      child: const Text(
                        'CLUSTER',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'One puzzle. Every day.',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Streak card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StreakCard(streak: streak),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Daily challenge card ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DailyCard(
                  dateLabel: todayLabel,
                  todayAsync: todayAsync,
                  onPlay: (puzzle) {
                    ref.read(gameProvider.notifier).loadPuzzle(puzzle);
                    context.go('/game', extra: puzzle);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Section header ────────────────────────────────────────────
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

            // ── Practice packs grid ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _PackCard(
                    emoji: '🎬',
                    title: 'Movies',
                    isLocked: false,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Movies pack — coming soon!')),
                    ),
                  ),
                  _PackCard(
                    emoji: '⚽',
                    title: 'Sports',
                    isLocked: false,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Sports pack — coming soon!')),
                    ),
                  ),
                  _PackCard(
                    emoji: '🎵',
                    title: 'Music',
                    isLocked: true,
                    onTap: () => context.go('/premium'),
                  ),
                  _PackCard(
                    emoji: '🍕',
                    title: 'Food',
                    isLocked: true,
                    onTap: () => context.go('/premium'),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── AdMob banner (free users only) ────────────────────────────
            SliverToBoxAdapter(
              child: isPremium
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AdService.instance.bannerWidget(),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    return '$dayName, $monthName ${dt.day}';
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current streak',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak ${streak == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.dateLabel,
    required this.todayAsync,
    required this.onPlay,
  });

  final String dateLabel;
  final AsyncValue<dynamic> todayAsync;
  final void Function(dynamic puzzle) onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.dailyGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: AppColors.accentLight, size: 16),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Daily Challenge',
            style: TextStyle(
              color: AppColors.onBackground,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '16 words · 4 groups · 4 mistakes allowed',
            style: TextStyle(color: AppColors.onSurface, fontSize: 12),
          ),
          const SizedBox(height: 16),
          todayAsync.when(
            loading: () => ElevatedButton(
              onPressed: null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Loading puzzle…'),
                ],
              ),
            ),
            error: (e, _) => ElevatedButton(
              onPressed: null,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.diff4),
              child: const Text('No puzzle for today'),
            ),
            data: (puzzle) {
              if (puzzle == null) {
                return ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.diff4),
                  child: const Text('No puzzle scheduled'),
                );
              }
              return ElevatedButton.icon(
                onPressed: () => onPlay(puzzle),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text("Play today's puzzle"),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.emoji,
    required this.title,
    required this.isLocked,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceElevated, width: 1),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                if (isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 10, color: AppColors.onSurface),
                        SizedBox(width: 3),
                        Text(
                          'PRO',
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.onBackground,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


