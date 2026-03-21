import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent app state for tracking usage counters, onboarding, and preferences.
class AppStateService {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  static const String _keyProcessCount = 'process_count';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyReviewPrompted = 'review_prompted';
  static const String _keyAutoSaveToGallery = 'auto_save_gallery';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyFavoriteIds = 'favorite_ids';
  static const String _keySkipNextInterstitial = 'skip_next_interstitial';
  static const String _keyResolutionPreset = 'resolution_preset';
  static const String _keyTipsSeen = 'tips_seen';

  SharedPreferences? _prefs;

  static final ValueNotifier<String> themeModeNotifier = ValueNotifier<String>('system');

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    themeModeNotifier.value = _prefs?.getString(_keyThemeMode) ?? 'system';
  }

  // --- Process counter (for smart ad frequency) ---

  int get processCount => _prefs?.getInt(_keyProcessCount) ?? 0;

  Future<void> incrementProcessCount() async {
    await init();
    await _prefs!.setInt(_keyProcessCount, processCount + 1);
  }

  /// Returns true every 3rd processing (1-indexed: 3, 6, 9...) unless user skipped.
  bool get shouldShowInterstitial {
    if (skipNextInterstitial) return false;
    return processCount > 0 && processCount % 3 == 0;
  }

  /// Returns true every 5th processing (1-indexed: 5, 10, 15...)
  /// Offset from interstitial so they don't overlap.
  bool get shouldShowRewardedInterstitial =>
      processCount > 0 && processCount % 5 == 0;

  // --- Onboarding ---

  bool get isOnboardingDone => _prefs?.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone() async {
    await init();
    await _prefs!.setBool(_keyOnboardingDone, true);
  }

  // --- Review prompt ---

  bool get hasPromptedReview => _prefs?.getBool(_keyReviewPrompted) ?? false;

  /// Should prompt review after 5 successful removals, only once.
  bool get shouldPromptReview => processCount >= 5 && !hasPromptedReview;

  Future<void> setReviewPrompted() async {
    await init();
    await _prefs!.setBool(_keyReviewPrompted, true);
  }

  // --- Auto-save to gallery ---

  bool get autoSaveToGallery => _prefs?.getBool(_keyAutoSaveToGallery) ?? false;

  Future<void> setAutoSaveToGallery(bool value) async {
    await init();
    await _prefs!.setBool(_keyAutoSaveToGallery, value);
  }

  // --- Theme ---

  String get themeMode => _prefs?.getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String value) async {
    await init();
    await _prefs!.setString(_keyThemeMode, value);
    themeModeNotifier.value = value;
  }

  ThemeMode get effectiveThemeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // --- Favorites (history entry ids) ---

  Set<String> get favoriteIds {
    final raw = _prefs?.getString(_keyFavoriteIds);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      return list?.map((e) => e.toString()).toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> setFavoriteIds(Set<String> ids) async {
    await init();
    await _prefs!.setString(_keyFavoriteIds, jsonEncode(ids.toList()));
  }

  Future<void> toggleFavorite(String id) async {
    final set = favoriteIds.toSet();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await setFavoriteIds(set);
  }

  bool isFavorite(String id) => favoriteIds.contains(id);

  // --- Skip next interstitial (rewarded ad) ---

  bool get skipNextInterstitial =>
      _prefs?.getBool(_keySkipNextInterstitial) ?? false;

  Future<void> setSkipNextInterstitial(bool value) async {
    await init();
    await _prefs!.setBool(_keySkipNextInterstitial, value);
  }

  // --- Resolution preset (fast 512, balanced 1024, quality 2048) ---

  static const String resolutionFast = 'fast';
  static const String resolutionBalanced = 'balanced';
  static const String resolutionQuality = 'quality';

  String get resolutionPreset =>
      _prefs?.getString(_keyResolutionPreset) ?? resolutionBalanced;

  Future<void> setResolutionPreset(String value) async {
    await init();
    await _prefs!.setString(_keyResolutionPreset, value);
  }

  int get resolutionMaxDimension {
    switch (resolutionPreset) {
      case resolutionFast:
        return 512;
      case resolutionQuality:
        return 2048;
      default:
        return 1024;
    }
  }

  // --- Tips (first-time / how to use) ---

  bool get tipsSeen => _prefs?.getBool(_keyTipsSeen) ?? false;

  Future<void> setTipsSeen(bool value) async {
    await init();
    await _prefs!.setBool(_keyTipsSeen, value);
  }
}
