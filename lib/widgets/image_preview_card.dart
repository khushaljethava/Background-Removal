import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A Material 3 card that displays an image preview with a label.
/// Shows a checkerboard background when displaying transparent images.
class ImagePreviewCard extends StatelessWidget {
  final String label;
  final File? imageFile;
  final Uint8List? imageBytes;
  final bool showCheckerboard;
  final VoidCallback? onTap;
  final double? height;

  const ImagePreviewCard({
    super.key,
    required this.label,
    this.imageFile,
    this.imageBytes,
    this.showCheckerboard = false,
    this.onTap,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Row(
                children: [
                  Icon(
                    _getLabelIcon(),
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Image content
            SizedBox(
              height: height ?? 280,
              child: _buildImageContent(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLabelIcon() {
    if (label.toLowerCase().contains('original')) return Icons.image_outlined;
    if (label.toLowerCase().contains('result')) return Icons.auto_fix_high;
    return Icons.image_outlined;
  }

  Widget _buildImageContent(ColorScheme colorScheme) {
    Widget? imageWidget;

    if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        cacheWidth: 1024,
        cacheHeight: 1024,
        filterQuality: FilterQuality.medium,
      );
    } else if (imageFile != null && !kIsWeb) {
      imageWidget = Image.file(
        imageFile!,
        fit: BoxFit.contain,
        cacheWidth: 1024,
        cacheHeight: 1024,
        filterQuality: FilterQuality.medium,
      );
    }

    if (imageWidget == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No image',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    if (showCheckerboard) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Checkerboard pattern to show transparency
          CustomPaint(
            painter: _CheckerboardPainter(
              color1: colorScheme.surfaceContainerLowest,
              color2: colorScheme.surfaceContainerLow,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: imageWidget,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: imageWidget,
    );
  }
}

/// Paints a checkerboard pattern to indicate transparency areas.
class _CheckerboardPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  static const double cellSize = 12.0;

  _CheckerboardPainter({required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

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
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.color1 != color1 || oldDelegate.color2 != color2;
  }
}
