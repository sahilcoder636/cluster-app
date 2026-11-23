import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
          const SnackBar(content: Text('Welcome to Cluster Pro!')),
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
    final isDark = AppColors.isDark(context);
    final inkColor = isDark ? AppColors.darkInk : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final hairline = isDark ? AppColors.darkHairline : AppColors.hairline;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Close button (top-left) ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.x,
                    color: mutedColor,
                    size: 22,
                  ),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Left-aligned serif headline ─────────────────────────
                    Text(
                      'Unlock the\nFull Experience',
                      style: TextStyle(
                        color: inkColor,
                        fontSize: 34,
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      // Left-aligned -- no textAlign center
                    ),
                    const SizedBox(height: 10),

                    // ── Subheadline ─────────────────────────────────────────
                    Text(
                      'One-time purchase. No subscription, ever.',
                      style: TextStyle(color: mutedColor, fontSize: 14),
                    ),

                    const SizedBox(height: 36),

                    // ── Three plain rows separated by hairlines ─────────────
                    _BenefitRow(
                      icon: PhosphorIconsRegular.prohibit,
                      title: 'Remove All Ads',
                      subtitle: 'Play without interruptions',
                      inkColor: inkColor,
                      mutedColor: mutedColor,
                    ),
                    Divider(color: hairline, thickness: 0.75, height: 1),
                    _BenefitRow(
                      icon: PhosphorIconsRegular.musicNote,
                      title: 'Unlock Music Pack',
                      subtitle: '25 puzzles themed around music',
                      inkColor: inkColor,
                      mutedColor: mutedColor,
                    ),
                    Divider(color: hairline, thickness: 0.75, height: 1),
                    _BenefitRow(
                      icon: PhosphorIconsRegular.forkKnife,
                      title: 'Unlock Food Pack',
                      subtitle: '25 puzzles themed around food',
                      inkColor: inkColor,
                      mutedColor: mutedColor,
                    ),

                    const SizedBox(height: 40),

                    // ── CTA section ─────────────────────────────────────────
                    if (isPremium) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsFill.sealCheck,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "You're already a Pro member",
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
                      // Vermilion accent CTA button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPurchasing ? null : _onUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: AppFonts.ui,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
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
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Billed once. Restore purchases below.',
                        style: TextStyle(color: mutedColor, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),

                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isPurchasing ? null : _onRestore,
                          child: const Text('Restore Purchases'),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Payment charged to Google Play account on purchase confirmation.',
                        style: TextStyle(color: mutedColor, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Plain benefit row (no icon tile background) ------------------------------

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.inkColor,
    required this.mutedColor,
  });

  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final Color inkColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PhosphorIcon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppFonts.ui,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                    fontFamily: AppFonts.ui,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
