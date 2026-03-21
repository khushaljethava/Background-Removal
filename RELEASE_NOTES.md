# BG Remover - Release Notes

## v1.0.0+4 (March 2026)

### What's New

**History Gallery**
- View all your processed images in one place
- Tap any result to re-open it with full editing options (save, share, change background)
- Long-press to select and delete multiple images
- Results persist across app restarts

**Batch Processing**
- Select multiple images at once from your gallery
- All images are processed sequentially and auto-saved to Photos
- Progress ring shows real-time completion count

**Save to Photos**
- Images now save directly to your device's Photos/Gallery app
- No more hunting for files in hidden app folders
- Optional auto-save: enable in Settings to automatically save every result

**Smarter Ads**
- Interstitial ads now only appear every 3rd image processed (was every single time)
- No more ad when tapping "Process New Image" on the result screen
- Rewarded ad support added for future premium features

**Blur Background Fix**
- Choosing "Blur" background now correctly saves with a blurred version of your original image
- Previously saved as a black background — now fixed

**Faster App Startup**
- Splash screen loads instantly — AdMob now initializes in the background
- Native splash properly preserved and removed once UI is ready

**App Icon**
- Custom app icon now displays correctly (was showing default Flutter icon)
- Generated for Android, iOS, Web, Windows, and macOS

**First Launch Onboarding**
- Clean single-screen welcome with feature highlights
- Only shown once on first install

**In-App Review**
- After 5 successful background removals, a native review prompt appears (once)

**Image Picker Fix**
- Gallery now opens immediately on first tap
- Removed redundant permission dialog that was causing a double-pick issue

### Settings Additions
- Auto-save to Gallery toggle
- Images Processed counter in About section

### Technical
- Added packages: `gal`, `shared_preferences`, `in_app_review`, `flutter_native_splash`
- Persistent history stored in app documents with JSON index (max 50 entries)
- Smart ad frequency via `AppStateService` process counter
