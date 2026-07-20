import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import 'premium_notifier.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isPurchasing = false;

  Future<void> _onUpgrade() async {
    setState(() => _isPurchasing = true);
    try {
      await ref.read(premiumProvider.notifier).purchase();
      if (!mounted) return;
      final isPremium = ref
          .read(premiumProvider)
          .maybeWhen(data: (v) => v, orElse: () => false);
      if (isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Cluster Pro! 🎉')),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purchase failed: $e')));
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _onRestore() async {
    try {
      await ref.read(premiumProvider.notifier).restore();
      if (!mounted) return;
      final isPremium = ref
          .read(premiumProvider)
          .maybeWhen(data: (v) => v, orElse: () => false);
      if (isPremium) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Purchase restored!')));
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchase found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final premiumAsync = ref.watch(premiumProvider);
    final isPremium = premiumAsync.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('CLUSTER PRO'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Unlock everything.',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const _FeatureRow(icon: Icons.block, text: 'No more ads'),
              const SizedBox(height: 16),
              const _FeatureRow(icon: Icons.lightbulb, text: 'Unlimited hints'),
              const SizedBox(height: 16),
              const _FeatureRow(
                icon: Icons.grid_view,
                text: 'All practice packs',
              ),
              const SizedBox(height: 16),
              const _FeatureRow(icon: Icons.bar_chart, text: 'Detailed stats'),
              const Spacer(),

              // ── Already Pro banner ─────────────────────────────────────
              if (isPremium) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.streakGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "You're already a Pro member ✓",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                // ── Price + purchase ─────────────────────────────────────
                const Text(
                  '\$2.99 / lifetime',
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isPurchasing ? null : _onUpgrade,
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Upgrade now'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isPurchasing ? null : _onRestore,
                  child: const Text(
                    'Restore previous purchase',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 28),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
