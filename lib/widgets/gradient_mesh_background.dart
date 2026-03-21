import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Animated gradient mesh background with slow-moving organic gradients.
/// Creates a premium, immersive dark background effect.
///
/// Uses a periodic Timer at ~10 fps instead of AnimationController (60 fps)
/// to drastically reduce GPU/CPU pressure on low-end devices.
class GradientMeshBackground extends StatefulWidget {
  const GradientMeshBackground({super.key});

  @override
  State<GradientMeshBackground> createState() => _GradientMeshBackgroundState();
}

class _GradientMeshBackgroundState extends State<GradientMeshBackground> {
  Timer? _timer;

  // Mesh gradient control points
  late List<_GradientPoint> _points;

  @override
  void initState() {
    super.initState();

    _points = [
      _GradientPoint(
        color: AppColors.primaryContainer.withOpacity(0.15),
        x: 0.2, y: 0.3, vx: 0.003, vy: 0.002,
      ),
      _GradientPoint(
        color: AppColors.primaryContainer.withOpacity(0.12),
        x: 0.8, y: 0.2, vx: -0.002, vy: 0.004,
      ),
      _GradientPoint(
        color: AppColors.secondary.withOpacity(0.08),
        x: 0.5, y: 0.7, vx: 0.004, vy: -0.003,
      ),
      _GradientPoint(
        color: AppColors.tertiaryContainer.withOpacity(0.06),
        x: 0.3, y: 0.8, vx: -0.003, vy: -0.002,
      ),
    ];

    // Update at ~10 fps — plenty for slow organic motion
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        _updatePoints();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updatePoints() {
    for (final point in _points) {
      point.x += point.vx;
      point.y += point.vy;

      if (point.x < 0.1 || point.x > 0.9) point.vx *= -1;
      if (point.y < 0.1 || point.y > 0.9) point.vy *= -1;

      point.x = point.x.clamp(0.1, 0.9);
      point.y = point.y.clamp(0.1, 0.9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.background : AppColors.lightBackground;

    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshGradientPainter(
          points: _points,
          baseColor: baseColor,
          isDark: isDark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// Represents a control point in the gradient mesh.
class _GradientPoint {
  Color color;
  double x;
  double y;
  double vx;
  double vy;

  _GradientPoint({
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

/// Custom painter for the mesh gradient effect.
class _MeshGradientPainter extends CustomPainter {
  final List<_GradientPoint> points;
  final Color baseColor;
  final bool isDark;

  _MeshGradientPainter({
    required this.points,
    required this.baseColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = baseColor,
    );

    // Draw gradient circles for each point
    // In light mode use lower opacity and softLight blend for subtlety
    final blendMode = isDark ? BlendMode.screen : BlendMode.softLight;
    final opacityMultiplier = isDark ? 1.0 : 0.6;

    for (final point in points) {
      final radius = size.width * 0.6;
      final center = Offset(
        size.width * point.x,
        size.height * point.y,
      );

      final adjustedColor = point.color.withOpacity(
        (point.color.opacity * opacityMultiplier).clamp(0.0, 1.0),
      );

      final paint = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [adjustedColor, adjustedColor.withOpacity(0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..blendMode = blendMode;

      canvas.drawCircle(center, radius, paint);
    }

    // Vignette overlay (subtle in light mode)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            Colors.transparent,
            baseColor.withOpacity(isDark ? 0.5 : 0.15),
          ],
          stops: const [0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}
