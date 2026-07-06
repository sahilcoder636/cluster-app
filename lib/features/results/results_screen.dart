import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../game/game_notifier.dart';
import '../game/group_reveal_row.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.resultData});

  final GameResultData resultData;

  void _shareResult() {
    final buffer = StringBuffer();
    buffer.writeln('Cluster - ${resultData.puzzle.date}');
    for (final group in resultData.solveSequence) {
      final emoji = AppColors.difficultyEmoji(group.difficulty);
      buffer.writeln('$emoji$emoji$emoji$emoji');
    }
    if (!resultData.won) {
      buffer.writeln('Failed with ${resultData.mistakeCount} mistakes.');
    }
    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    // Show interstitial ad placeholder
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            title: const Text('AdMob Interstitial', style: TextStyle(color: AppColors.onBackground)),
            content: const Text('Placeholder for Phase 2', style: TextStyle(color: AppColors.onSurface)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    });

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
                resultData.won ? 'Great job!' : 'Next time!',
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                resultData.won ? 'You solved the puzzle.' : "You'll get it tomorrow.",
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Reveal all 4 category rows
              ...resultData.puzzle.groups.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GroupRevealRow(key: ValueKey(g.id), group: g),
                ),
              ),
              const SizedBox(height: 32),
              // Emoji share grid display
              Column(
                children: resultData.solveSequence.map((group) {
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
              Text(
                'Play again tomorrow\nNext puzzle in $hours:$mins',
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
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
