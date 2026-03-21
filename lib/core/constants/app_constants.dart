/// App-wide constants that don't belong to theme/styling.
abstract final class AppConstants {
  // --- Image processing ---
  static const int maxImageDimension = 4096;
  static const int imageQuality = 100;
  static const int maxRecentImages = 10;
  static const int maxHistoryEntries = 50;

  // --- Ad frequency ---
  static const int interstitialFrequency = 3;
  static const int rewardedInterstitialFrequency = 5;
  static const int reviewPromptThreshold = 5;

  // --- Cache ---
  static const int imageCacheWidth = 2048;
  static const int imageCacheHeight = 2048;
  static const int thumbnailCacheSize = 300;

  // --- Animation durations (ms) ---
  static const int fadeTransitionMs = 400;
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 600;

  // --- Edge refinement (mask feather radius in pixels at 1024) ---
  static const int edgeFeatherRadius = 2;
}
