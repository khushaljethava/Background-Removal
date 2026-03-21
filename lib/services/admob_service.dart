import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_state_service.dart';

/// AdMob service for managing banner, interstitial, rewarded,
/// native, and rewarded interstitial ads.
///
/// Ad strategy:
/// - Banner: Home screen + Result screen (always)
/// - Native: Settings, History, Result screens (in-feed)
/// - Interstitial: Every 3rd image processed
/// - Rewarded Interstitial: Every 5th image processed (offset from interstitial)
/// - Rewarded: User-initiated to unlock HD export
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;
  int _rewardedInterstitialLoadAttempts = 0;
  static const int _maxFailedLoadAttempts = 3;

  // --- Ad Unit IDs ---

  String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return _isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return 'ca-app-pub-5206098172306110/2536757594';
  }

  String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return _isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return _isAndroid
        ? 'ca-app-pub-5206098172306110/XXXXXXXXXX'
        : 'ca-app-pub-5206098172306110/XXXXXXXXXX';
  }

  String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return _isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return _isAndroid
        ? 'ca-app-pub-5206098172306110/XXXXXXXXXX'
        : 'ca-app-pub-5206098172306110/XXXXXXXXXX';
  }

  String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return _isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986624511';
    }
    return 'ca-app-pub-5206098172306110/6870101304';
  }

  String get rewardedInterstitialAdUnitId {
    if (kIsWeb) return '';
    if (kDebugMode) {
      return _isAndroid
          ? 'ca-app-pub-3940256099942544/5354046379'
          : 'ca-app-pub-3940256099942544/6978759866';
    }
    return 'ca-app-pub-5206098172306110/1908914084';
  }

  // --- Initialize ---

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;

    loadInterstitialAd();
    loadRewardedAd();
    loadRewardedInterstitialAd();
  }

  // --- Banner ---

  BannerAd createBannerAd({BannerAdListener? listener}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
          listener?.onAdLoaded?.call(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          listener?.onAdFailedToLoad?.call(ad, error);
          ad.dispose();
        },
      ),
    );
  }

  // --- Interstitial (smart frequency: every 3rd use) ---

  void loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialLoadAttempts++;
          if (_interstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  /// Shows interstitial only if the process count warrants it (every 3rd use).
  /// If user earned "skip next" via rewarded ad, this show is skipped and flag is cleared.
  Future<bool> showInterstitialIfDue() async {
    if (kIsWeb) return false;
    final appState = AppStateService();
    if (appState.skipNextInterstitial) {
      await appState.setSkipNextInterstitial(false);
      return false;
    }
    if (!appState.shouldShowInterstitial) return false;
    return await _showInterstitial();
  }

  Future<bool> _showInterstitial() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      return true;
    }
    loadInterstitialAd();
    return false;
  }

  // --- Rewarded Ad (user-initiated for HD export) ---

  void loadRewardedAd() {
    if (kIsWeb) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _rewardedLoadAttempts++;
          if (_rewardedLoadAttempts < _maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  bool get isRewardedReady => !kIsWeb && _rewardedAd != null;

  /// Shows a rewarded ad. Returns true if user earned the reward.
  Future<bool> showRewardedAd() async {
    if (kIsWeb || _rewardedAd == null) return false;

    bool rewarded = false;
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );
    _rewardedAd = null;
    return rewarded;
  }

  // --- Rewarded Interstitial Ad (every 5th use, offset from interstitial) ---

  void loadRewardedInterstitialAd() {
    if (kIsWeb) return;
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _rewardedInterstitialLoadAttempts = 0;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadRewardedInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              loadRewardedInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _rewardedInterstitialLoadAttempts++;
          if (_rewardedInterstitialLoadAttempts < _maxFailedLoadAttempts) {
            loadRewardedInterstitialAd();
          }
        },
      ),
    );
  }

  bool get isRewardedInterstitialReady =>
      !kIsWeb && _rewardedInterstitialAd != null;

  /// Shows rewarded interstitial if the process count warrants it (every 5th use).
  Future<bool> showRewardedInterstitialIfDue() async {
    if (kIsWeb) return false;
    final appState = AppStateService();
    if (!appState.shouldShowRewardedInterstitial) return false;
    return await _showRewardedInterstitial();
  }

  Future<bool> _showRewardedInterstitial() async {
    if (_rewardedInterstitialAd != null) {
      bool rewarded = false;
      await _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewarded = true;
        },
      );
      _rewardedInterstitialAd = null;
      return rewarded;
    }
    loadRewardedInterstitialAd();
    return false;
  }

  // --- Cleanup ---

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }
}

/// Widget that displays a banner ad with proper sizing.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (kIsWeb) return;
    _bannerAd = AdMobService().createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
