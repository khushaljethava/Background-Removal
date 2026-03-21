import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/app_state_service.dart';
import '../../screens/home_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/processing_screen.dart';
import '../../screens/result_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/batch_processing_screen.dart';
import 'route_names.dart';

/// Extra data passed to the result screen via navigation.
class ResultScreenArgs {
  final File originalFile;
  final Uint8List resultPngBytes;
  final int processingTimeMs;

  const ResultScreenArgs({
    required this.originalFile,
    required this.resultPngBytes,
    this.processingTimeMs = 0,
  });
}

/// App router configuration using go_router.
final GoRouter appRouter = GoRouter(
  initialLocation:
      AppStateService().isOnboardingDone ? RouteNames.home : RouteNames.onboarding,
  routes: [
    GoRoute(
      path: RouteNames.onboarding,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: OnboardingScreen(
          onComplete: () async {
            await AppStateService().setOnboardingDone();
            if (context.mounted) context.go(RouteNames.home);
          },
        ),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: RouteNames.home,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HomeScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: RouteNames.processing,
      pageBuilder: (context, state) {
        final imageFile = state.extra as File;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ProcessingScreen(imageFile: imageFile),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),
    GoRoute(
      path: RouteNames.result,
      pageBuilder: (context, state) {
        final args = state.extra as ResultScreenArgs;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ResultScreen(
            originalFile: args.originalFile,
            resultPngBytes: args.resultPngBytes,
            processingTimeMs: args.processingTimeMs,
          ),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),
    GoRoute(
      path: RouteNames.history,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const HistoryScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: RouteNames.settings,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: _fadeTransition,
      ),
    ),
    GoRoute(
      path: RouteNames.batch,
      pageBuilder: (context, state) {
        final imageFiles = state.extra as List<File>;
        return CustomTransitionPage(
          key: state.pageKey,
          child: BatchProcessingScreen(imageFiles: imageFiles),
          transitionsBuilder: _fadeTransition,
        );
      },
    ),
  ],
);

/// Shared fade transition matching the existing visual style.
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
