import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  static const _teaserKey = 'premium_teaser_shown';

  @override
  void initState() {
    super.initState();
    final isPremium = ref
        .read(premiumProvider)
        .maybeWhen(data: (v) => v, orElse: () => false);
    if (!isPremium) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) AdService.instance.showInterstitial();
      });
    }
    _maybeShowPremiumTeaser();
  }

  void _maybeShowPremiumTeaser() {
    // Only trigger for daily games
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
      // Mark shown before displaying so it never shows twice
      box.put(_teaserKey, true);
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Enjoying Cluster?',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Remove ads and unlock 50+ more puzzles with one tap.',
                  style: TextStyle(
                    color: AppColors.onSurface,
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
                    child: const Text('See Premium →'),
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

  Widget _performanceBadge() {
    final (label, color) = switch (widget.resultData.mistakeCount) {
      0 => ('✨ Flawless', Colors.amber),
      1 => ('🎯 Sharp', AppColors.accent),
      2 => ('👍 Solid', Colors.green),
      _ => ('💪 Got there', AppColors.onSurface),
    };
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _shareResult() {
    final buffer = StringBuffer();
    buffer.writeln('Cluster - ${widget.resultData.puzzle.date}');
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
    final diff = tomorrow.difference(now);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('CLUSTER'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                widget.resultData.won ? 'Great job!' : 'Next time!',
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
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
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // ── Performance badge (wins only) ──────────────────────────
              if (widget.resultData.won) _performanceBadge(),
              const SizedBox(height: 16),
              // Reveal all 4 category rows
              ...widget.resultData.puzzle.groups.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GroupRevealRow(key: ValueKey(g.id), group: g),
                ),
              ),
              const SizedBox(height: 32),
              // Emoji share grid display
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
                icon: const Icon(Icons.share),
                label: const Text('Share result'),
              ),
              const SizedBox(height: 24),
              if (widget.resultData.gameSource == GameSource.daily)
                Text(
                  'Play again tomorrow\nNext puzzle in $hours:$mins',
                  style: const TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    height: 1.5,
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
    );
  }
}
