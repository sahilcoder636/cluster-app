import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/game/game_notifier.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/results/results_screen.dart';

CustomTransitionPage<void> _buildFadeSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06), // 6% upward slide
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage<void> _buildBottomSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.0),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      );
    },
  );
}

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _buildFadeSlidePage(
        key: state.pageKey,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final args = state.extra as GameArgs;
        return _buildFadeSlidePage(
          key: state.pageKey,
          child: GameScreen(
            puzzle: args.puzzle,
            gameSource: args.gameSource,
            packName: args.packName,
          ),
        );
      },
    ),
    GoRoute(
      path: '/results',
      pageBuilder: (context, state) {
        final resultData = state.extra as GameResultData;
        return _buildFadeSlidePage(
          key: state.pageKey,
          child: ResultsScreen(resultData: resultData),
        );
      },
    ),
    GoRoute(
      path: '/premium',
      pageBuilder: (context, state) => _buildBottomSlidePage(
        key: state.pageKey,
        child: const PremiumScreen(),
      ),
    ),
  ],
);
