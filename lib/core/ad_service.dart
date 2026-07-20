import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Plain singleton that owns all AdMob ad objects.
///
/// Using a singleton (not a Riverpod provider) ensures ad objects are never
/// recreated on provider rebuilds, which would cause ad flickering / waste
/// ad impressions.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad unit IDs ────────────────────────────────────────────────────────────
  static const _bannerUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _interstitialUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const _rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // ── State ──────────────────────────────────────────────────────────────────
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _bannerLoaded = false;
  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  // ── Banner ─────────────────────────────────────────────────────────────────

  Future<void> loadBanner({VoidCallback? onLoaded}) async {
    _bannerAd?.dispose();
    _bannerLoaded = false;

    _bannerAd = BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) { _bannerLoaded = true; onLoaded?.call(); },
        onAdFailedToLoad: (ad, error) {
          dev.log('Banner failed to load: $error', name: 'AdService');
          _bannerLoaded = false;
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  /// Returns the banner widget if loaded, or an invisible 50-px fallback.
  Widget bannerWidget() {
    if (_bannerLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox(height: 50);
  }

  // ── Interstitial ───────────────────────────────────────────────────────────

  Future<void> loadInterstitial() async {
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
        },
      ),
    );
  }

  Future<void> showInterstitial() async {
    if (!_interstitialLoaded || _interstitialAd == null) return;
    await _interstitialAd!.show();
    _interstitialLoaded = false;
    _interstitialAd = null;
    unawaited(loadInterstitial()); // preload next one
  }

  // ── Rewarded ───────────────────────────────────────────────────────────────

  Future<void> loadRewarded() async {
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
        },
      ),
    );
  }

  /// Shows the rewarded ad and returns [true] if the user earned the reward.
  ///
  /// Returns [false] if no ad is loaded or the user dismisses without reward.
  Future<bool> showRewarded() async {
    if (!_rewardedLoaded || _rewardedAd == null) return false;

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        dev.log('Rewarded failed to show: $error', name: 'AdService');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, _) {
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    _rewardedLoaded = false;
    _rewardedAd = null;
    unawaited(loadRewarded()); // preload next one

    return completer.future;
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
