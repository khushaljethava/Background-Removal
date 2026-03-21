import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/admob_service.dart';
import '../services/app_state_service.dart';
import '../services/image_processing_service.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/toggle_tab.dart';
import '../widgets/image_compare_slider.dart';
import '../widgets/background_picker.dart';
import '../widgets/checkerboard_painter.dart';

/// Result screen with before/after comparison, background options, and export.
class ResultScreen extends StatefulWidget {
  final File originalFile;
  final Uint8List resultPngBytes;
  final int processingTimeMs;

  const ResultScreen({
    super.key,
    required this.originalFile,
    required this.resultPngBytes,
    this.processingTimeMs = 0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _showOriginal = false;
  late AnimationController _entryController;
  late Animation<double> _entryAnimation;

  String _selectedBackground = 'transparent';
  Color _customColor = Colors.blue;
  Uint8List? _processedImageBytes;
  Uint8List? _customBackgroundImageBytes;
  final List<_BackgroundState> _undoStack = [];
  static const int _maxUndo = 5;

  @override
  void initState() {
    super.initState();
    _processedImageBytes = widget.resultPngBytes;
    _entryController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: AppConstants.longAnimationMs),
    );
    _entryAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  void _pushUndoState() {
    if (_undoStack.length >= _maxUndo) _undoStack.removeLast();
    _undoStack.insert(
      0,
      _BackgroundState(
        selectedBackground: _selectedBackground,
        customColor: _customColor,
        customBackgroundImageBytes: _customBackgroundImageBytes != null
            ? Uint8List.fromList(_customBackgroundImageBytes!)
            : null,
      ),
    );
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final state = _undoStack.removeAt(0);
    setState(() {
      _selectedBackground = state.selectedBackground;
      _customColor = state.customColor;
      _customBackgroundImageBytes = state.customBackgroundImageBytes;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _saveImage({bool asJpeg = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      Uint8List bytesToSave;
      if (asJpeg) {
        Uint8List composite;
        if (_selectedBackground == 'transparent') {
          final fg = img.decodePng(_processedImageBytes!);
          if (fg == null) {
            bytesToSave = _processedImageBytes!;
          } else {
            final bg = img.Image(width: fg.width, height: fg.height);
            img.fill(bg, color: img.ColorRgba8(255, 255, 255, 255));
            final composed = img.compositeImage(bg, fg);
            bytesToSave =
                Uint8List.fromList(img.encodeJpg(composed, quality: 95));
          }
        } else {
          composite = await _compositeWithBackground();
          final decoded = img.decodePng(composite);
          if (decoded != null) {
            bytesToSave =
                Uint8List.fromList(img.encodeJpg(decoded, quality: 95));
          } else {
            bytesToSave = composite;
          }
        }
      } else if (_selectedBackground == 'transparent') {
        bytesToSave = _processedImageBytes!;
      } else {
        bytesToSave = await _compositeWithBackground();
      }

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = asJpeg ? 'jpg' : 'png';
      final file = File('${dir.path}/bg_removed_$timestamp.$ext');
      await file.writeAsBytes(bytesToSave);

      await Gal.putImage(file.path, album: 'BG Remover');
      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(
                        asJpeg ? 'Saved as JPEG to Photos' : 'Saved to Photos')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppSpacing.borderRadiusMd,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyToClipboard() async {
    try {
      final bytes = _selectedBackground == 'transparent'
          ? _processedImageBytes!
          : await _compositeWithBackground();

      // Save to temp file and share as a workaround since Flutter clipboard
      // doesn't support image bytes natively on all platforms.
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/bg_removed_clipboard_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image ready to share'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null || !mounted) return;
    final bytes = await xFile.readAsBytes();
    if (mounted) {
      _pushUndoState();
      setState(() {
        _selectedBackground = 'image';
        _customBackgroundImageBytes = bytes;
      });
    }
  }

  Future<void> _shareImage() async {
    try {
      final bytesToShare = _selectedBackground == 'transparent'
          ? _processedImageBytes!
          : await _compositeWithBackground();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bg_removed_share.png');
      await file.writeAsBytes(bytesToShare);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Background removed with AI Background Remover',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            HapticFeedback.lightImpact();
            context.pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Result', style: theme.textTheme.titleLarge),
        centerTitle: true,
        actions: [
          if (widget.processingTimeMs > 0)
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
                    const Icon(
                      Icons.timer,
                      size: 14,
                      color: AppColors.tertiaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(widget.processingTimeMs / 1000).toStringAsFixed(2)}s',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: AppColors.tertiaryContainer,
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
            const SizedBox(height: AppSpacing.sm),

            // View toggle
            _buildViewToggle(theme, colorScheme),

            const SizedBox(height: AppSpacing.sm),

            // Main image
            Expanded(
              child: Padding(
                padding: ResponsiveSize.of(context).horizontalPadding,
                child: ClipRRect(
                  borderRadius: AppSpacing.borderRadiusXl,
                  child: _showOriginal
                      ? _buildOriginalView()
                      : _buildResultView(),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Action buttons
            _buildActionButtons(theme, colorScheme),

            const SizedBox(height: AppSpacing.sm),

            // Re-process and Process new
            Padding(
              padding: ResponsiveSize.of(context).horizontalPadding,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        RouteNames.processing,
                        extra: widget.originalFile,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('TRY AGAIN'),
                      style: OutlinedButton.styleFrom(
                        padding: ResponsiveSize.of(context).buttonPaddingCompact,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RouteNames.home),
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 18),
                      label: const Text('NEW IMAGE'),
                      style: OutlinedButton.styleFrom(
                        padding: ResponsiveSize.of(context).buttonPaddingCompact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (AdMobService().isRewardedReady) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: () async {
                  final earned =
                      await AdMobService().showRewardedAd();
                  if (earned && mounted) {
                    await AppStateService().setSkipNextInterstitial(true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Next result ad skipped'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('WATCH AD TO SKIP NEXT AD'),
              ),
            ],

            const SizedBox(height: AppSpacing.xs),

            // Single ad only — removed duplicate NativeAdWidget
            const BannerAdWidget(),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: AppSpacing.paddingHorizontalXl,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: ToggleTab(
              label: 'Split View',
              icon: Icons.compare,
              isSelected: !_showOriginal,
              onTap: () => setState(() => _showOriginal = false),
            ),
          ),
          Expanded(
            child: ToggleTab(
              label: 'Original',
              icon: Icons.image,
              isSelected: _showOriginal,
              onTap: () => setState(() => _showOriginal = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalView() {
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
      ),
      child: Image.file(
        widget.originalFile,
        fit: BoxFit.contain,
        cacheWidth: AppConstants.imageCacheWidth,
        cacheHeight: AppConstants.imageCacheHeight,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _buildResultView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundLayer(),
        Image.memory(
          _processedImageBytes!,
          fit: BoxFit.contain,
          cacheWidth: AppConstants.imageCacheWidth,
          cacheHeight: AppConstants.imageCacheHeight,
          filterQuality: FilterQuality.medium,
        ),
      ],
    );
  }

  Widget _buildBackgroundLayer() {
    switch (_selectedBackground) {
      case 'white':
        return Container(color: Colors.white);
      case 'black':
        return Container(color: Colors.black);
      case 'blur':
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              widget.originalFile,
              fit: BoxFit.cover,
              cacheWidth: 512,
              cacheHeight: 512,
              filterQuality: FilterQuality.low,
            ),
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ],
        );
      case 'custom':
        return Container(color: _customColor);
      case 'image':
        if (_customBackgroundImageBytes != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                _customBackgroundImageBytes!,
                fit: BoxFit.cover,
              ),
            ],
          );
        }
        return Container(color: Colors.grey);
      case 'transparent':
      default:
        return const CheckerboardBackground();
    }
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    final rs = ResponsiveSize.of(context);
    final iconSize = rs.isCompact ? 18.0 : 20.0;
    final btnPadding = rs.isCompact
        ? const EdgeInsets.all(10)
        : const EdgeInsets.all(AppSpacing.md);

    return Padding(
      padding: rs.horizontalPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Background + Save PNG
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showBackgroundPicker,
                  icon: Icon(Icons.format_color_fill, size: iconSize),
                  label: const Text('Background'),
                  style: ElevatedButton.styleFrom(padding: rs.buttonPaddingCompact),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : () => _saveImage(asJpeg: false),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background,
                          ),
                        )
                      : Icon(Icons.download, size: iconSize),
                  label: Text(_isSaving ? 'SAVING...' : 'SAVE PNG'),
                  style: FilledButton.styleFrom(padding: rs.buttonPaddingCompact),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Row 2: JPEG + Copy + Share + Undo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleAction(
                icon: Icons.image,
                label: 'JPEG',
                onTap: _isSaving ? null : () => _saveImage(asJpeg: true),
                colorScheme: colorScheme,
                padding: btnPadding,
              ),
              const SizedBox(width: AppSpacing.md),
              _CircleAction(
                icon: Icons.copy,
                label: 'Copy',
                onTap: _copyToClipboard,
                colorScheme: colorScheme,
                padding: btnPadding,
              ),
              const SizedBox(width: AppSpacing.md),
              _CircleAction(
                icon: Icons.share,
                label: 'Share',
                onTap: _shareImage,
                colorScheme: colorScheme,
                padding: btnPadding,
              ),
              if (_undoStack.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                _CircleAction(
                  icon: Icons.undo,
                  label: 'Undo',
                  onTap: _undo,
                  colorScheme: colorScheme,
                  padding: btnPadding,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showBackgroundPicker() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackgroundPicker(
        selectedBackground: _selectedBackground,
        onBackgroundSelected: (bg) {
          Navigator.pop(context);
          if (bg != _selectedBackground) _pushUndoState();
          setState(() => _selectedBackground = bg);
          if (bg == 'custom') _showColorPicker();
          if (bg == 'image') _pickBackgroundImage();
        },
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PICK A COLOR'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              Colors.red,
              Colors.pink,
              Colors.purple,
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
              Colors.lightBlue,
              Colors.cyan,
              Colors.teal,
              Colors.green,
              Colors.lightGreen,
              Colors.lime,
              Colors.yellow,
              Colors.amber,
              Colors.orange,
              Colors.deepOrange,
              Colors.brown,
              Colors.grey,
              Colors.blueGrey,
            ]
                .map((color) => GestureDetector(
                      onTap: () {
                        setState(() => _customColor = color);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppSpacing.borderRadiusSm,
                          border: Border.all(
                            color: _customColor == color
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _compositeWithBackground() async {
    if (_selectedBackground == 'image' &&
        _customBackgroundImageBytes != null &&
        _customBackgroundImageBytes!.isNotEmpty) {
      return await ImageProcessingService.compositeForegroundOnImage(
        foregroundPngBytes: _processedImageBytes!,
        backgroundImageBytes: _customBackgroundImageBytes!,
      );
    }

    Uint8List? originalBytes;
    if (_selectedBackground == 'blur') {
      try {
        originalBytes = await widget.originalFile.readAsBytes();
      } catch (_) {}
    }

    return await compute(
        _compositeInIsolate,
        _CompositeParams(
          foregroundBytes: _processedImageBytes!,
          backgroundType: _selectedBackground,
          customColor: _customColor,
          originalBytes: originalBytes,
        ));
  }

  static Uint8List _compositeInIsolate(_CompositeParams params) {
    final foreground = img.decodePng(params.foregroundBytes)!;
    final width = foreground.width;
    final height = foreground.height;

    img.Image background;

    switch (params.backgroundType) {
      case 'white':
        background = img.Image(width: width, height: height);
        img.fill(background, color: img.ColorRgba8(255, 255, 255, 255));
        break;
      case 'black':
        background = img.Image(width: width, height: height);
        img.fill(background, color: img.ColorRgba8(0, 0, 0, 255));
        break;
      case 'custom':
        background = img.Image(width: width, height: height);
        final c = params.customColor;
        img.fill(background,
            color: img.ColorRgba8(c.red, c.green, c.blue, 255));
        break;
      case 'blur':
        if (params.originalBytes != null) {
          var original = img.decodeImage(params.originalBytes!);
          if (original != null) {
            original =
                img.copyResize(original, width: width, height: height);
            background = img.gaussianBlur(original, radius: 25);
          } else {
            background = img.Image(width: width, height: height);
          }
        } else {
          background = img.Image(width: width, height: height);
        }
        break;
      default:
        return Uint8List.fromList(img.encodePng(foreground));
    }

    final result = img.compositeImage(background, foreground);
    return Uint8List.fromList(img.encodePng(result));
  }
}

class _BackgroundState {
  final String selectedBackground;
  final Color customColor;
  final Uint8List? customBackgroundImageBytes;

  _BackgroundState({
    required this.selectedBackground,
    required this.customColor,
    this.customBackgroundImageBytes,
  });
}

/// Parameters for background compositing in isolate.
class _CompositeParams {
  final Uint8List foregroundBytes;
  final String backgroundType;
  final Color customColor;
  final Uint8List? originalBytes;

  _CompositeParams({
    required this.foregroundBytes,
    required this.backgroundType,
    required this.customColor,
    this.originalBytes,
  });
}

/// Circular icon button with label, used in the result action row.
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final ColorScheme colorScheme;
  final EdgeInsets padding;

  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainer,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: AppColors.outlineVariant.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
