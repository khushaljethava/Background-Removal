import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'services/admob_service.dart';
import 'services/app_state_service.dart';
import 'services/history_service.dart';

/// AdMob App ID: ca-app-pub-5206098172306110~8826833778
///
/// IMPORTANT: You must add this App ID to your platform configurations:
///
/// Android - android/app/src/main/AndroidManifest.xml:
/// <meta-data
///   android:name="com.google.android.gms.ads.APPLICATION_ID"
///   android:value="ca-app-pub-5206098172306110~8826833778" />
///
/// iOS - ios/Runner/Info.plist:
/// <key>GADApplicationIdentifier</key>
/// <string>ca-app-pub-5206098172306110~8826833778</string>

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Keep native splash visible until we're ready
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize persistent state (fast, ~50ms)
  await AppStateService().init();

  // Initialize AdMob in background — don't block app startup
  AdMobService().initialize();

  // Load history index in background
  HistoryService().load();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay style — will be updated per-theme by AppBar's systemOverlayStyle

  runApp(const BackgroundRemoverApp());
}

/// Premium dark-themed background remover app.
class BackgroundRemoverApp extends StatefulWidget {
  const BackgroundRemoverApp({super.key});

  @override
  State<BackgroundRemoverApp> createState() => _BackgroundRemoverAppState();
}

class _BackgroundRemoverAppState extends State<BackgroundRemoverApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppStateService.themeModeNotifier,
      builder: (_, themeMode, __) {
        final mode = themeMode == 'light'
            ? ThemeMode.light
            : themeMode == 'dark'
                ? ThemeMode.dark
                : ThemeMode.system;
        return MaterialApp.router(
          title: 'Background Remover',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
