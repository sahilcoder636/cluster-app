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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Close button ────────────────────────────────────────────
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.onSurface),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ),
              const SizedBox(height: 8),

              // ── Headline ────────────────────────────────────────────────
              const Text(
                'Unlock the Full Experience',
                style: TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ── Subheadline ─────────────────────────────────────────────
              const Text(
                'One-time purchase — no subscription, ever.',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Benefit rows ────────────────────────────────────────────
              const _BenefitRow(
                icon: Icons.block_rounded,
                title: 'Remove All Ads',
                subtitle: 'Play without interruptions',
              ),
              const SizedBox(height: 20),
              const _BenefitRow(
                icon: Icons.music_note_rounded,
                title: 'Unlock Music Pack',
                subtitle: '25 puzzles themed around music',
              ),
              const SizedBox(height: 20),
              const _BenefitRow(
                icon: Icons.local_pizza_rounded,
                title: 'Unlock Food Pack',
                subtitle: '25 puzzles themed around food',
              ),

              const Spacer(),

              // ── Already Pro banner ──────────────────────────────────────
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
                // ── Primary CTA ─────────────────────────────────────────
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
                      : const Text('Unlock for \$2.99'),
                ),
                const SizedBox(height: 8),

                // ── Billed-once note ────────────────────────────────────
                const Text(
                  'Billed once. Restore purchases below.',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // ── Restore purchases ───────────────────────────────────
                TextButton(
                  onPressed: _isPurchasing ? null : _onRestore,
                  child: const Text('Restore Purchases'),
                ),
                const SizedBox(height: 12),

                // ── Legal text ──────────────────────────────────────────
                const Text(
                  'Payment charged to Google Play account on purchase confirmation.',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefit row widget
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.accent, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
