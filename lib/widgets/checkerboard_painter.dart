import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Custom painter for checkerboard pattern indicating transparency.
class CheckerboardPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double cellSize;

  const CheckerboardPainter({
    this.color1 = AppColors.surfaceHigh,
    this.color2 = AppColors.surfaceHighest,
    this.cellSize = 16.0,
  });

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
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) {
    return oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.cellSize != cellSize;
  }
}

/// Widget that displays a checkerboard pattern background.
class CheckerboardBackground extends StatelessWidget {
  final Widget? child;

  const CheckerboardBackground({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const CheckerboardPainter(),
      child: child,
    );
  }
}
