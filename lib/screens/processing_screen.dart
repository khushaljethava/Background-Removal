import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/admob_service.dart';
import '../services/app_state_service.dart';
import '../services/onnx_inference_service.dart';
import '../services/image_processing_service.dart';
import '../services/history_service.dart';
import '../services/result_cache.dart';
import '../widgets/animated_progress_bar.dart';

/// Processing screen with split view, step progress pipeline,
/// and real-time inference timer.
class ProcessingScreen extends StatefulWidget {
  final File imageFile;

  const ProcessingScreen({super.key, required this.imageFile});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  final OnnxInferenceService _onnxService = OnnxInferenceService();

  String _statusText = 'Preparing...';
  double _progress = 0.0;
  int _currentStep = 0;
  bool _isError = false;
  String _errorMessage = '';
  bool _isCancelled = false;
  int _elapsedMs = 0;

  late AnimationController _timerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Stopwatch _stopwatch;

  final List<_ProcessStep> _steps = [
    _ProcessStep('Download', Icons.cloud_download_outlined, 'AI Model'),
    _ProcessStep('Load', Icons.memory, 'ONNX Session'),
    _ProcessStep('Preprocess', Icons.crop_rotate, 'Image'),
    _ProcessStep('Inference', Icons.auto_fix_high, 'Neural Network'),
    _ProcessStep('Postprocess', Icons.image_outlined, 'Result'),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _stopwatch = Stopwatch();
    _stopwatch.start();

    _timerController.addListener(() {
      if (mounted && !_isCancelled) {
        setState(() {
          _elapsedMs = _stopwatch.elapsedMilliseconds;
        });
      }
    });

    _runPipeline();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timerController.dispose();
    _stopwatch.stop();
    _isCancelled = true;
    super.dispose();
  }

  Future<void> _runPipeline({bool isRetry = false}) async {
    final maxDimension = isRetry
        ? 512
        : AppStateService().resolutionMaxDimension;
    try {
      await Future.delayed(Duration.zero);

      _updateStep(0, 'Loading AI model...');
      await _onnxService.initSession();
      if (_isCancelled) return;
      setState(() => _progress = 0.25);

      await Future.delayed(Duration.zero);
      if (_isCancelled) return;

      _updateStep(1, 'Preparing session...');
      setState(() => _progress = 0.4);

      await Future.delayed(Duration.zero);
      if (_isCancelled) return;

      _updateStep(2, 'Preprocessing image...');
      final originalImage = await ImageProcessingService.loadImage(
          widget.imageFile, maxDimension: maxDimension);
      if (_isCancelled) return;

      final inputTensor =
          await ImageProcessingService.preprocessImage(originalImage);
      if (_isCancelled) return;

      setState(() => _progress = 0.5);

      await Future.delayed(Duration.zero);
      if (_isCancelled) return;

      _updateStep(3, 'Running neural network...');
      final maskData = await _onnxService.runInference(inputTensor);
      if (_isCancelled) return;

      setState(() => _progress = 0.85);

      await Future.delayed(Duration.zero);
      if (_isCancelled) return;

      _updateStep(4, 'Generating result...');
      final resultPngBytes = await ImageProcessingService.postprocessMask(
        originalImage: originalImage,
        maskData: maskData,
        edgeFeatherRadius: AppConstants.edgeFeatherRadius,
      );
      if (_isCancelled) return;

      setState(() => _progress = 1.0);

      await Future.delayed(Duration.zero);
      if (_isCancelled) return;

      // Increment process counter and show ads based on frequency
      final appState = AppStateService();
      await appState.incrementProcessCount();

      final shownRewarded =
          await AdMobService().showRewardedInterstitialIfDue();
      if (!shownRewarded) {
        await AdMobService().showInterstitialIfDue();
      }
      if (_isCancelled) return;

      // Save result to cache and history
      ResultCache().put(widget.imageFile.path, resultPngBytes);
      await HistoryService().addResult(
        originalPath: widget.imageFile.path,
        resultPngBytes: resultPngBytes,
        processingTimeMs: _stopwatch.elapsedMilliseconds,
      );

      // Auto-save to gallery if enabled
      if (appState.autoSaveToGallery) {
        try {
          final dir = await Directory.systemTemp.createTemp('bg_remover');
          final file = File(
              '${dir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
          await file.writeAsBytes(resultPngBytes);
          await Gal.putImage(file.path);
        } catch (_) {}
      }

      HapticFeedback.heavyImpact();

      // Prompt review after 5 successful removals (once)
      if (appState.shouldPromptReview) {
        await appState.setReviewPrompted();
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          Future.delayed(const Duration(seconds: 2), () {
            inAppReview.requestReview();
          });
        }
      }

      // Navigate to result
      if (mounted) {
        _stopwatch.stop();
        context.pushReplacement(
          RouteNames.result,
          extra: ResultScreenArgs(
            originalFile: widget.imageFile,
            resultPngBytes: resultPngBytes,
            processingTimeMs: _elapsedMs,
          ),
        );
      }
    } catch (e) {
      if (mounted && !_isCancelled) {
        if (!isRetry && maxDimension > 512) {
          setState(() {
            _isError = false;
            _errorMessage = '';
            _progress = 0.0;
            _currentStep = 0;
          });
          _runPipeline(isRetry: true);
          return;
        }
        setState(() {
          _isError = true;
          _errorMessage = _friendlyError(e);
        });
      }
    }
  }

  /// Maps raw exceptions to user-friendly messages.
  static String _friendlyError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('out of memory') || raw.contains('oom')) {
      return 'Not enough memory to process this image. Try a smaller image or close other apps.';
    }
    if (raw.contains('file') && raw.contains('not found')) {
      return 'The image file could not be found. It may have been deleted or moved.';
    }
    if (raw.contains('permission')) {
      return 'Storage permission is required. Please grant access in Settings.';
    }
    if (raw.contains('decode') || raw.contains('codec') || raw.contains('format')) {
      return 'This image format is not supported. Please try a JPG or PNG file.';
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }
    if (raw.contains('timeout')) {
      return 'Processing took too long. Try a smaller image or lower resolution in Settings.';
    }
    if (raw.contains('onnx') || raw.contains('inference') || raw.contains('session')) {
      return 'AI model error. Please restart the app and try again.';
    }
    if (raw.contains('encode_error') || raw.contains('muxer')) {
      return 'Failed to encode the result. Please try again with a different image.';
    }
    // Fallback: show a trimmed message
    final msg = e.toString();
    if (msg.length > 120) return '${msg.substring(0, 120)}...';
    return msg;
  }

  void _updateStep(int step, String status) {
    if (mounted && !_isCancelled) {
      setState(() {
        _currentStep = step;
        _statusText = status;
      });
    }
  }

  String _formatElapsedTime(int ms) {
    final seconds = (ms / 1000).floor();
    final remainingMs = ms % 1000;
    return '${seconds.toString().padLeft(2, '0')}.${remainingMs.toString().padLeft(3, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            _isCancelled = true;
            HapticFeedback.mediumImpact();
            context.pop();
          },
          icon: const Icon(Icons.close),
        ),
        title: Text('Processing', style: theme.textTheme.titleLarge),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: AppSpacing.borderRadiusXl,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 14,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatElapsedTime(_elapsedMs),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Image preview
            Padding(
              padding: AppSpacing.paddingHorizontalXl,
              child: _ImagePreview(imageFile: widget.imageFile),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            if (_isError)
              _buildErrorState(theme, colorScheme)
            else
              _buildProgressState(theme, colorScheme),

            const Spacer(),

            // Pipeline progress indicator
            Padding(
              padding: AppSpacing.paddingHorizontalXl,
              child: AnimatedProgressBar(
                steps: _steps,
                currentStep: _currentStep,
                progress: _progress,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
            // Bottom info section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer.withOpacity(0.3),
                borderRadius: AppSpacing.borderRadiusLg,
                border: Border(
                  top: BorderSide(color: AppColors.outlineVariant.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _InfoItem(label: 'MODEL', value: 'ORMBG'),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant.withOpacity(0.2)),
                  _InfoItem(label: 'LATENCY', value: _formatElapsedTime(_elapsedMs)),
                  Container(width: 1, height: 24, color: AppColors.outlineVariant.withOpacity(0.2)),
                  _InfoItem(label: 'PRECISION', value: 'FP32'),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryContainer
                        .withOpacity(0.3 * _pulseAnimation.value),
                    AppColors.primaryContainer.withOpacity(0),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainer,
                    border: Border.all(
                      color: AppColors.primaryContainer.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _steps[_currentStep].icon,
                    size: 28,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          _statusText.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${(_progress * 100).toInt()}%',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: AppSpacing.paddingAllXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.error.withOpacity(0.1),
          ),
          child: Icon(
            Icons.error_outline,
            size: 40,
            color: colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Processing Failed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go Back'),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isError = false;
                  _progress = 0;
                  _currentStep = 0;
                });
                _runPipeline();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Image preview card for processing screen.
class _ImagePreview extends StatelessWidget {
  final File imageFile;

  const _ImagePreview({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Container(
        height: ResponsiveSize.of(context).imagePreviewHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: AppSpacing.borderRadiusXl,
          border: Border.all(
            color: AppColors.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusXl,
        child: Image.file(
          imageFile,
          fit: BoxFit.contain,
          cacheWidth: AppConstants.imageCacheWidth ~/ 2,
          cacheHeight: AppConstants.imageCacheHeight ~/ 2,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Process step data.
class _ProcessStep {
  final String label;
  final IconData icon;
  final String subtitle;

  const _ProcessStep(this.label, this.icon, this.subtitle);
}

/// Bottom info row item for the processing screen.
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
