import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/app_state_service.dart';
import '../services/onnx_inference_service.dart';
import '../services/image_processing_service.dart';
import '../services/history_service.dart';
import '../services/result_cache.dart';

/// Batch processing screen — processes multiple images sequentially,
/// auto-saves all results to gallery.
class BatchProcessingScreen extends StatefulWidget {
  final List<File> imageFiles;

  const BatchProcessingScreen({super.key, required this.imageFiles});

  @override
  State<BatchProcessingScreen> createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen> {
  final OnnxInferenceService _onnxService = OnnxInferenceService();
  int _completedCount = 0;
  int _failedCount = 0;
  bool _isDone = false;
  bool _isCancelled = false;
  String _statusText = 'Starting...';

  @override
  void initState() {
    super.initState();
    _processBatch();
  }

  Future<void> _processBatch() async {
    try {
      await _onnxService.initSession();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDone = true;
          _statusText = 'Failed to load AI model';
        });
      }
      return;
    }

    for (int i = 0; i < widget.imageFiles.length; i++) {
      if (_isCancelled) break;

      setState(() {
        _statusText = 'Processing ${i + 1} of ${widget.imageFiles.length}...';
      });

      try {
        final file = widget.imageFiles[i];
        final originalImage = await ImageProcessingService.loadImage(file);
        if (_isCancelled) break;

        final inputTensor =
            await ImageProcessingService.preprocessImage(originalImage);
        if (_isCancelled) break;

        final maskData = await _onnxService.runInference(inputTensor);
        if (_isCancelled) break;

        final resultPngBytes = await ImageProcessingService.postprocessMask(
          originalImage: originalImage,
          maskData: maskData,
        );
        if (_isCancelled) break;

        // Cache result and save to history
        ResultCache().put(file.path, resultPngBytes);
        await HistoryService().addResult(
          originalPath: file.path,
          resultPngBytes: resultPngBytes,
        );

        // Save to gallery
        try {
          final dir = await Directory.systemTemp.createTemp('bg_batch');
          final outFile = File(
              '${dir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
          await outFile.writeAsBytes(resultPngBytes);
          await Gal.putImage(outFile.path, album: 'BG Remover');
        } catch (_) {}

        await AppStateService().incrementProcessCount();
        setState(() => _completedCount++);
      } catch (e) {
        setState(() => _failedCount++);
      }
    }

    if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isDone = true;
        _statusText = 'Done! $_completedCount saved to Photos';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = widget.imageFiles.length;
    final progress =
        total > 0 ? (_completedCount + _failedCount) / total : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Processing', style: theme.textTheme.titleLarge),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            _isCancelled = true;
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: colorScheme.surfaceContainerHigh,
                      color: _isDone ? AppColors.success : AppColors.primary,
                    ),
                    Center(
                      child: Text(
                        '$_completedCount/$total',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              Text(
                _statusText,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              if (_failedCount > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$_failedCount failed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.huge),

              if (_isDone)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Done'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
