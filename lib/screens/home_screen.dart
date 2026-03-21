import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../core/routing/app_router.dart';
import '../core/routing/route_names.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';
import '../services/admob_service.dart';
import '../services/onnx_inference_service.dart';
import '../services/result_cache.dart';
import '../widgets/animated_upload_zone.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/recent_images_strip.dart';
import '../widgets/gradient_mesh_background.dart';
import '../widgets/status_badge.dart';

/// Premium home screen with animated gradient background,
/// drag-drop upload zone, and recent images strip.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  List<File> _recentImages = [];
  bool _isModelReady = false;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initModel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _retrieveLostData());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _retrieveLostData();
    }
  }

  Future<void> _initModel() async {
    final service = OnnxInferenceService();
    try {
      await service.initSession();
      if (mounted) {
        setState(() => _isModelReady = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isModelReady = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Recover image when app was killed by Android while camera was open
  /// (e.g. low memory). Call at startup and on resume.
  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || !mounted) return;
      final XFile? single = response.file;
      final List<XFile>? multiple = response.files;
      final XFile? xFile = single ?? (multiple != null && multiple.isNotEmpty ? multiple.first : null);
      if (xFile == null || !mounted) return;
      final File? copied = await _copyToAppStorage(xFile);
      if (copied != null && mounted) {
        _navigateToProcessing(copied);
      } else if (mounted) {
        _navigateToProcessing(File(xFile.path));
      }
    } on UnimplementedError {
      // retrieveLostData is Android-only
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: AppConstants.maxImageDimension.toDouble(),
      maxHeight: AppConstants.maxImageDimension.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (image != null && mounted) {
      _navigateToProcessing(File(image.path));
    }
  }

  Future<void> _pickMultipleFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: AppConstants.maxImageDimension.toDouble(),
      maxHeight: AppConstants.maxImageDimension.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (images.isNotEmpty && mounted) {
      final files = images.map((x) => File(x.path)).toList();
      setState(() {
        for (final f in files) {
          _recentImages.insert(0, f);
        }
        if (_recentImages.length > AppConstants.maxRecentImages) {
          _recentImages =
              _recentImages.sublist(0, AppConstants.maxRecentImages);
        }
      });

      if (files.length == 1) {
        _navigateToProcessing(files.first);
      } else {
        context.push(RouteNames.batch, extra: files);
      }
    }
  }

  /// Copies [xFile] to app temp directory so the file remains readable
  /// (camera capture on Android often returns a path that gets cleaned up).
  static Future<File?> _copyToAppStorage(XFile xFile) async {
    try {
      final bytes = await xFile.readAsBytes();
      final dir = await getTemporaryDirectory();
      final name =
          'camera_${DateTime.now().millisecondsSinceEpoch}.${xFile.name.split('.').lastOrNull ?? 'jpg'}';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: AppConstants.maxImageDimension.toDouble(),
      maxHeight: AppConstants.maxImageDimension.toDouble(),
      imageQuality: AppConstants.imageQuality,
    );

    if (image == null || !mounted) return;

    final File? copied = await _copyToAppStorage(image);
    if (copied != null && mounted) {
      _navigateToProcessing(copied);
    } else if (mounted) {
      _navigateToProcessing(File(image.path));
    }
  }

  void _showTips() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'How to get the best results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              _tipRow(
                Icons.contrast,
                'Use photos with clear contrast between subject and background.',
              ),
              _tipRow(
                Icons.face,
                'Portraits and product shots work best; avoid busy backgrounds.',
              ),
              _tipRow(
                Icons.high_quality,
                'Higher resolution (Settings > Quality) improves edges but takes longer.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProcessing(File imageFile) {
    HapticFeedback.mediumImpact();

    setState(() {
      _recentImages.insert(0, imageFile);
      if (_recentImages.length > AppConstants.maxRecentImages) {
        _recentImages = _recentImages.sublist(0, AppConstants.maxRecentImages);
      }
    });

    // Check cache first
    final cache = ResultCache();
    if (cache.contains(imageFile.path)) {
      final cachedResult = cache.get(imageFile.path)!;
      if (mounted) {
        context.push(
          RouteNames.result,
          extra: ResultScreenArgs(
            originalFile: imageFile,
            resultPngBytes: cachedResult,
            processingTimeMs: 0,
          ),
        );
      }
      return;
    }

    context.push(RouteNames.processing, extra: imageFile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rs = ResponsiveSize.of(context);
    final logoSize = rs.isCompact ? 32.0 : 40.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
          switch (index) {
            case 1:
              HapticFeedback.lightImpact();
              context.push(RouteNames.history);
            case 2:
              _showTips();
            case 3:
              HapticFeedback.lightImpact();
              context.push(RouteNames.settings);
            default:
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'HOME',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'HISTORY',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'TIPS',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'SETTINGS',
          ),
        ],
      ),
      body: Stack(
        children: [
          const GradientMeshBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: rs.horizontalPadding.horizontal / 2,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        // Logo
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            gradient: AppDecorations.coldGradientOf(context),
                            borderRadius: AppSpacing.borderRadiusMd,
                          ),
                          child: Icon(
                            Icons.auto_fix_high,
                            color: Colors.white,
                            size: rs.isCompact ? 18 : 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'BG REMOVER',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: rs.isCompact ? 18 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      children: [
                        const Spacer(flex: 1),

                        // Upload zone
                        RepaintBoundary(
                          child: AnimatedUploadZone(
                            onPickGallery: _pickFromGallery,
                            onPickCamera: _pickFromCamera,
                            onPickBatch: _pickMultipleFromGallery,
                            isModelReady: _isModelReady,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxxl),

                        // Recent images strip
                        if (_recentImages.isNotEmpty) ...[
                          Text(
                            'RECENT WORK',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          RecentImagesStrip(
                            images: _recentImages,
                            onImageTap: _navigateToProcessing,
                          ),
                        ],

                        const SizedBox(height: AppSpacing.lg),

                        // Native ad
                        const NativeAdWidget(),

                        const SizedBox(height: AppSpacing.sm),

                        // Banner ad
                        const BannerAdWidget(),

                        const SizedBox(height: AppSpacing.sm),

                        const Spacer(flex: 1),

                        // Model status badge
                        ValueListenableBuilder<double>(
                          valueListenable:
                              OnnxInferenceService().downloadProgress,
                          builder: (context, progress, child) {
                            final isDownloading =
                                progress > 0 && progress < 1.0;
                            if (_isModelReady) {
                              return StatusBadge.modelReady();
                            } else if (isDownloading) {
                              return StatusBadge.downloading(progress);
                            } else {
                              return StatusBadge.initializing();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
