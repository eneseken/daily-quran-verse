import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'subscription_service.dart';

class AdMobService {
  AdMobService._();

  static final instance = AdMobService._();

  static const _iosInterstitialAdUnitId =
      'ca-app-pub-8699787159986323/1635885951';
  static const _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';

  InterstitialAd? _interstitialAd;
  bool _initialized = false;
  bool _loadingInterstitial = false;
  DateTime? _lastShownAt;

  bool get isSupported => !kIsWeb && Platform.isIOS;

  String get _interstitialAdUnitId =>
      kReleaseMode ? _iosInterstitialAdUnitId : _iosTestInterstitialAdUnitId;

  Future<void> initialize() async {
    if (_initialized || !isSupported) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(loadInterstitial());
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  Future<void> loadInterstitial() async {
    if (!_initialized || !isSupported || _loadingInterstitial) return;
    if (_interstitialAd != null) return;

    _loadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              unawaited(loadInterstitial());
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              unawaited(loadInterstitial());
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  Future<bool> showInterstitialIfAvailable() async {
    if (!_initialized || !isSupported) return false;
    if (SubscriptionService.instance.isPremium) return false;

    final now = DateTime.now();
    final lastShownAt = _lastShownAt;
    if (lastShownAt != null && now.difference(lastShownAt).inMinutes < 2) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      unawaited(loadInterstitial());
      return false;
    }

    _interstitialAd = null;
    _lastShownAt = now;
    await ad.show();
    return true;
  }
}
