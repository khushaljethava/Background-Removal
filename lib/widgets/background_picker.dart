import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Background picker with horizontal chips for different background options.
class BackgroundPicker extends StatelessWidget {
  final String selectedBackground;
  final Function(String) onBackgroundSelected;

  const BackgroundPicker({
    super.key,
    required this.selectedBackground,
    required this.onBackgroundSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Background Options',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            // Background chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _BackgroundChip(
                    label: 'Transparent',
                    icon: Icons.grid_on,
                    isSelected: selectedBackground == 'transparent',
                    preview: const _CheckerboardPreview(),
                    onTap: () => onBackgroundSelected('transparent'),
                  ),
                  _BackgroundChip(
                    label: 'White',
                    icon: Icons.format_color_fill,
                    isSelected: selectedBackground == 'white',
                    preview: Container(color: Colors.white),
                    onTap: () => onBackgroundSelected('white'),
                  ),
                  _BackgroundChip(
                    label: 'Black',
                    icon: Icons.format_color_fill,
                    isSelected: selectedBackground == 'black',
                    preview: Container(color: Colors.black),
                    onTap: () => onBackgroundSelected('black'),
                  ),
                  _BackgroundChip(
                    label: 'Blur',
                    icon: Icons.blur_on,
                    isSelected: selectedBackground == 'blur',
                    preview: Container(
                      color: Colors.grey,
                      child: const Icon(Icons.blur_on, color: Colors.white54),
                    ),
                    onTap: () => onBackgroundSelected('blur'),
                  ),
                  _BackgroundChip(
                    label: 'Custom',
                    icon: Icons.colorize,
                    isSelected: selectedBackground == 'custom',
                    preview: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Colors.blue],
                        ),
                      ),
                    ),
                    onTap: () => onBackgroundSelected('custom'),
                  ),
                  _BackgroundChip(
                    label: 'Photo',
                    icon: Icons.photo_library,
                    isSelected: selectedBackground == 'image',
                    preview: Container(
                      color: Colors.grey.shade700,
                      child: const Icon(
                        Icons.add_photo_alternate,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                    onTap: () => onBackgroundSelected('image'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual background chip.
class _BackgroundChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Widget preview;
  final VoidCallback onTap;

  const _BackgroundChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // Preview container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.outlineVariant.withOpacity(0.2),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: preview,
              ),
            ),
            const SizedBox(height: 8),
            // Label
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.primaryContainer
                    : colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkerboard preview pattern.
class _CheckerboardPreview extends StatelessWidget {
  const _CheckerboardPreview();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PreviewCheckerboardPainter(),
      size: const Size(72, 72),
    );
  }
}

class _PreviewCheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 18.0;
    final paint1 = Paint()..color = AppColors.surfaceHigh;
    final paint2 = Paint()..color = AppColors.surfaceHighest;

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final isEven =
            ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
