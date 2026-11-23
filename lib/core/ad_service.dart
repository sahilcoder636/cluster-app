import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/services/streak_service.dart';

/// Plain singleton that owns all AdMob ad objects and controls frequency caps.
///
/// Using a singleton ensures ad objects are never recreated on provider rebuilds.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad unit IDs (Google test IDs) ──────────────────────────────────────────
  static const _bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // ── Frequency Cap State ────────────────────────────────────────────────────
  static const String _keyCompletedGamesCount = 'completed_games_since_interstitial';

  /// Session counter: reset when the app process starts.
  int _sessionCompletedGames = 0;

  // ── Ad State ───────────────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _bannerLoaded = false;
  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  bool get isBannerLoaded => _bannerLoaded && _bannerAd != null;
  bool get isInterstitialLoaded => _interstitialLoaded && _interstitialAd != null;
  bool get isRewardedLoaded => _rewardedLoaded && _rewardedAd != null;

  // ── Banner ─────────────────────────────────────────────────────────────────

  Future<void> loadBanner({VoidCallback? onLoaded}) async {
    try {
      _bannerAd?.dispose();
      _bannerAd = null;
      _bannerLoaded = false;

      _bannerAd = BannerAd(
        adUnitId: _bannerUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _bannerLoaded = true;
            onLoaded?.call();
          },
          onAdFailedToLoad: (ad, error) {
            dev.log('Banner failed to load: $error', name: 'AdService');
            _bannerLoaded = false;
            ad.dispose();
            _bannerAd = null;
            onLoaded?.call();
          },
        ),
      )..load();
    } catch (e) {
      dev.log('Banner load error: $e', name: 'AdService');
      _bannerLoaded = false;
      _bannerAd = null;
      onLoaded?.call();
    }
  }

  /// Returns the banner widget if loaded, or an empty SizedBox (zero blank space).
  Widget bannerWidget() {
    if (_bannerLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Interstitial ───────────────────────────────────────────────────────────

  Future<void> loadInterstitial() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoaded = true;
          },
          onAdFailedToLoad: (error) {
            dev.log('Interstitial failed to load: $error', name: 'AdService');
            _interstitialLoaded = false;
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      dev.log('Interstitial load error: $e', name: 'AdService');
      _interstitialLoaded = false;
      _interstitialAd = null;
    }
  }

  /// Handles completed games with frequency cap:
  /// - Never on the first game of a session
  /// - At most once every 3 completed games (persisted in Hive)
  /// - Never if the user is premium
  Future<void> onGameCompleted({required bool isPremium}) async {
    if (isPremium) return;

    _sessionCompletedGames++;

    final box = Hive.box(StreakService.boxName);
    final count = (box.get(_keyCompletedGamesCount, defaultValue: 0) as int) + 1;
    await box.put(_keyCompletedGamesCount, count);

    dev.log(
      'Game completed: sessionGame=$_sessionCompletedGames, persistentCount=$count',
      name: 'AdService',
    );

    // Rule 1: Never on the first game of a session
    if (_sessionCompletedGames <= 1) {
      dev.log('Interstitial skipped: first game of session', name: 'AdService');
      return;
    }

    // Rule 2: At most once every 3 completed games
    if (count >= 3) {
      dev.log('Interstitial threshold reached ($count). Showing ad...', name: 'AdService');
      await showInterstitial();
      await box.put(_keyCompletedGamesCount, 0);
    } else {
      dev.log('Interstitial skipped: $count/3 completed games', name: 'AdService');
    }
  }

  Future<void> showInterstitial() async {
    if (!_interstitialLoaded || _interstitialAd == null) {
      dev.log('Interstitial not ready or offline; skipping.', name: 'AdService');
      unawaited(loadInterstitial());
      return;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _interstitialLoaded = false;
          unawaited(loadInterstitial());
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          dev.log('Interstitial failed to show: $error', name: 'AdService');
          ad.dispose();
          _interstitialAd = null;
          _interstitialLoaded = false;
          unawaited(loadInterstitial());
        },
      );

      await _interstitialAd!.show();
    } catch (e) {
      dev.log('Interstitial show error: $e', name: 'AdService');
      _interstitialLoaded = false;
      _interstitialAd = null;
      unawaited(loadInterstitial());
    }
  }

  // ── Rewarded ───────────────────────────────────────────────────────────────

  Future<void> loadRewarded() async {
    try {
      await RewardedAd.load(
        adUnitId: _rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoaded = true;
          },
          onAdFailedToLoad: (error) {
            dev.log('Rewarded failed to load: $error', name: 'AdService');
            _rewardedLoaded = false;
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      dev.log('Rewarded load error: $e', name: 'AdService');
      _rewardedLoaded = false;
      _rewardedAd = null;
    }
  }

  /// Shows the rewarded ad and returns [true] if the user earned the reward.
  ///
  /// Returns [false] if no ad is loaded, device is offline, or user dismisses.
  Future<bool> showRewarded() async {
    if (!_rewardedLoaded || _rewardedAd == null) return false;

    final completer = Completer<bool>();

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedLoaded = false;
          _rewardedAd = null;
          unawaited(loadRewarded());
          if (!completer.isCompleted) completer.complete(false);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          dev.log('Rewarded failed to show: $error', name: 'AdService');
          ad.dispose();
          _rewardedLoaded = false;
          _rewardedAd = null;
          unawaited(loadRewarded());
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (_, _) {
          if (!completer.isCompleted) completer.complete(true);
        },
      );
    } catch (e) {
      dev.log('Rewarded show error: $e', name: 'AdService');
      _rewardedLoaded = false;
      _rewardedAd = null;
      unawaited(loadRewarded());
      if (!completer.isCompleted) completer.complete(false);
    }

    return completer.future;
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
