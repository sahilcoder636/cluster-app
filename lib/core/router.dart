import 'package:go_router/go_router.dart';

import '../features/game/game_notifier.dart';
import '../features/game/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/results/results_screen.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final args = state.extra as GameArgs;
        return GameScreen(
          puzzle: args.puzzle,
          gameSource: args.gameSource,
          packName: args.packName,
        );
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final resultData = state.extra as GameResultData;
        return ResultsScreen(resultData: resultData);
      },
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
  ],
);
