import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Coming soon — RevenueCat wires in Phase 2',
                      ),
                    ),
                  );
                },
                child: const Text('Upgrade now'),
              ),
              const SizedBox(height: 32),
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
