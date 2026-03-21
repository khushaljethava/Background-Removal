import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Reusable status badge with icon, label, and color indicator.
class StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  /// Convenience factory for model-ready state.
  factory StatusBadge.modelReady() => const StatusBadge(
        icon: Icons.check_circle,
        label: 'AI Model Ready',
        color: AppColors.success,
      );

  /// Convenience factory for downloading state.
  factory StatusBadge.downloading(double progress) => StatusBadge(
        icon: Icons.downloading,
        label: 'Downloading Model... ${(progress * 100).toInt()}%',
        color: AppColors.secondary,
      );

  /// Convenience factory for initializing state.
  factory StatusBadge.initializing() => const StatusBadge(
        icon: Icons.memory,
        label: 'Initializing AI...',
        color: AppColors.textMuted,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
