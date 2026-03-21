import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart' as in_app_review;
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/app_state_service.dart';
import '../services/onnx_inference_service.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/settings_card.dart';

/// Settings screen with model management, performance toggles, and export options.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _modelName = 'ormbg-ONNX';
  String _modelSize = '168 MB';
  String _inputShape = '[1, 3, 1024, 1024]';
  String _executionProvider = 'CPU';
  String _exportFormat = 'PNG';
  double _quality = 95;
  double _resolution = 1024;
  bool _autoSaveToGallery = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = OnnxInferenceService();
    final isDownloaded = await service.isModelDownloaded();
    final appState = AppStateService();
    await appState.init();
    setState(() {
      _modelName =
          isDownloaded ? 'ormbg-ONNX (Bundled)' : 'ormbg-ONNX (Missing Asset)';
      _autoSaveToGallery = appState.autoSaveToGallery;
      _themeMode = appState.themeMode;
      _resolutionPreset = appState.resolutionPreset;
    });
  }

  String _themeMode = 'system';
  String _resolutionPreset = AppStateService.resolutionBalanced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Model Management
            const SectionHeader(title: 'Model Management', icon: Icons.memory),
            SettingsCard(
              child: Column(
                children: [
                  InfoRow(label: 'Model', value: _modelName),
                  const Divider(height: 24),
                  InfoRow(label: 'Size', value: _modelSize),
                  const Divider(height: 24),
                  InfoRow(label: 'Input Shape', value: _inputShape),
                  const Divider(height: 24),
                  const InfoRow(
                    label: 'Status',
                    value: 'Active',
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Performance
            const SectionHeader(title: 'Performance', icon: Icons.speed),
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Execution Provider',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ExecutionProviderSelector(
                    value: _executionProvider,
                    onChanged: (value) {
                      setState(() => _executionProvider = value);
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Appearance
            const SectionHeader(title: 'Appearance', icon: Icons.palette_outlined),
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ThemeChip(
                        label: 'System',
                        isSelected: _themeMode == 'system',
                        onTap: () async {
                          setState(() => _themeMode = 'system');
                          await AppStateService().setThemeMode('system');
                        },
                      ),
                      _ThemeChip(
                        label: 'Light',
                        isSelected: _themeMode == 'light',
                        onTap: () async {
                          setState(() => _themeMode = 'light');
                          await AppStateService().setThemeMode('light');
                        },
                      ),
                      _ThemeChip(
                        label: 'Dark',
                        isSelected: _themeMode == 'dark',
                        onTap: () async {
                          setState(() => _themeMode = 'dark');
                          await AppStateService().setThemeMode('dark');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Save Preferences
            const SectionHeader(
                title: 'Save Preferences', icon: Icons.save_alt),
            SettingsCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-save to Gallery',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Automatically save results to Photos after processing',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoSaveToGallery,
                    onChanged: (value) async {
                      setState(() => _autoSaveToGallery = value);
                      await AppStateService().setAutoSaveToGallery(value);
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Export Settings
            const SectionHeader(title: 'Export Settings', icon: Icons.save),
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Format',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormatSelector(
                    value: _exportFormat,
                    onChanged: (value) {
                      setState(() => _exportFormat = value);
                      HapticFeedback.lightImpact();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Quality',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _quality,
                          min: 50,
                          max: 100,
                          divisions: 10,
                          onChanged: (value) =>
                              setState(() => _quality = value),
                          onChangeEnd: (_) => HapticFeedback.lightImpact(),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          '${_quality.toInt()}%',
                          style: theme.textTheme.labelMedium,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Processing quality
            const SectionHeader(
                title: 'Processing Quality', icon: Icons.tune),
            SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolution preset',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ResolutionChip(
                        label: 'Fast (512)',
                        isSelected:
                            _resolutionPreset == AppStateService.resolutionFast,
                        onTap: () async {
                          setState(() =>
                              _resolutionPreset =
                                  AppStateService.resolutionFast);
                          await AppStateService()
                              .setResolutionPreset(AppStateService.resolutionFast);
                        },
                      ),
                      _ResolutionChip(
                        label: 'Balanced (1024)',
                        isSelected: _resolutionPreset ==
                            AppStateService.resolutionBalanced,
                        onTap: () async {
                          setState(() =>
                              _resolutionPreset =
                                  AppStateService.resolutionBalanced);
                          await AppStateService().setResolutionPreset(
                              AppStateService.resolutionBalanced);
                        },
                      ),
                      _ResolutionChip(
                        label: 'Quality (2048)',
                        isSelected: _resolutionPreset ==
                            AppStateService.resolutionQuality,
                        onTap: () async {
                          setState(() =>
                              _resolutionPreset =
                                  AppStateService.resolutionQuality);
                          await AppStateService().setResolutionPreset(
                              AppStateService.resolutionQuality);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Native ad
            const NativeAdWidget(),
            const SizedBox(height: AppSpacing.xxl),

            // About
            const SectionHeader(title: 'About', icon: Icons.info_outline),
            SettingsCard(
              child: Column(
                children: [
                  const InfoRow(label: 'Version', value: '1.0.0'),
                  const Divider(height: 24),
                  const InfoRow(label: 'ONNX Runtime', value: '1.16.0'),
                  const Divider(height: 24),
                  const InfoRow(label: 'Model', value: 'ORMBG'),
                  const Divider(height: 24),
                  InfoRow(
                    label: 'Images Processed',
                    value: '${AppStateService().processCount}',
                    valueColor: AppColors.primaryContainer,
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.star_outline, color: AppColors.primaryContainer),
                    title: const Text('Rate us'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      in_app_review.InAppReview.instance.requestReview();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Privacy & Security
            const SectionHeader(title: 'Privacy & Security', icon: Icons.shield_outlined),
            SettingsCard(
              child: Column(
                children: [
                  const InfoRow(label: 'Data Processing', value: 'On-device only'),
                  const Divider(height: 24),
                  const InfoRow(label: 'Network Access', value: 'Model download only'),
                  const Divider(height: 24),
                  const InfoRow(label: 'Analytics', value: 'None'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryContainer.withOpacity(0.15),
      checkmarkColor: AppColors.primaryContainer,
    );
  }
}

class _ResolutionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResolutionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryContainer.withOpacity(0.15),
      checkmarkColor: AppColors.primaryContainer,
    );
  }
}

/// Execution provider selector.
class _ExecutionProviderSelector extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _ExecutionProviderSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final providers = ['CPU', 'NNAPI', 'CoreML'];

    return Wrap(
      spacing: AppSpacing.md,
      children: providers.map((provider) {
        final isSelected = provider == value;
        return ChoiceChip(
          label: Text(provider),
          selected: isSelected,
          onSelected: (_) => onChanged(provider),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHigh,
          selectedColor: AppColors.primaryContainer.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.primaryContainer
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }
}

/// Export format selector.
class _FormatSelector extends StatelessWidget {
  final String value;
  final Function(String) onChanged;

  const _FormatSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formats = ['PNG', 'WEBP'];

    return Wrap(
      spacing: AppSpacing.md,
      children: formats.map((format) {
        final isSelected = format == value;
        return ChoiceChip(
          label: Text(format),
          selected: isSelected,
          onSelected: (_) => onChanged(format),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHigh,
          selectedColor: AppColors.secondary.withOpacity(0.15),
          labelStyle: TextStyle(
            color: isSelected
                ? AppColors.secondary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }
}
