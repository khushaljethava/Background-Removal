import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Animated upload zone with pulse animation, dashed border,
/// and drag-drop area styling.
class AnimatedUploadZone extends StatefulWidget {
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback? onPickBatch;
  final bool isModelReady;

  const AnimatedUploadZone({
    super.key,
    required this.onPickGallery,
    required this.onPickCamera,
    this.onPickBatch,
    required this.isModelReady,
  });

  @override
  State<AnimatedUploadZone> createState() => _AnimatedUploadZoneState();
}

class _AnimatedUploadZoneState extends State<AnimatedUploadZone>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showSourceSelector() {
    HapticFeedback.lightImpact();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choose Image Source',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an image to remove its background',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            // Gallery option
            _SourceOption(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              subtitle: 'Pick from your photo library',
              color: AppColors.primaryContainer,
              onTap: () {
                Navigator.pop(context);
                widget.onPickGallery();
              },
            ),
            // Camera option
            _SourceOption(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              subtitle: 'Take a new photo',
              color: AppColors.secondaryContainer,
              onTap: () {
                Navigator.pop(context);
                widget.onPickCamera();
              },
            ),
            // Batch option
            if (widget.onPickBatch != null)
              _SourceOption(
                icon: Icons.photo_library,
                label: 'Batch',
                subtitle: 'Select multiple images at once',
                color: AppColors.tertiaryContainer,
                onTap: () {
                  Navigator.pop(context);
                  widget.onPickBatch!();
                },
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rs = ResponsiveSize.of(context);
    final zonePadding = rs.uploadZonePadding;
    final iconSize = rs.isCompact ? 36.0 : 48.0;
    final iconPadding = rs.isCompact ? 16.0 : 24.0;
    final isReady = widget.isModelReady;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: isReady
              ? (_) {
                  setState(() => _isPressed = true);
                  HapticFeedback.lightImpact();
                }
              : null,
          onTapUp: isReady
              ? (_) {
                  setState(() => _isPressed = false);
                  _showSourceSelector();
                }
              : null,
          onTapCancel: () => setState(() => _isPressed = false),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..scale(_isPressed ? 0.98 : (_isHovering ? 1.02 : 1.0)),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isReady ? 1.0 : 0.5,
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: _isHovering
                        ? AppColors.primaryContainer
                        : AppColors.outlineVariant.withOpacity(0.3),
                    progress: _pulseAnimation.value,
                    isActive: _isHovering,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(zonePadding),
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? colorScheme.surfaceContainer.withOpacity(0.8)
                          : colorScheme.surfaceContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon container
                        Container(
                          padding: EdgeInsets.all(iconPadding),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryContainer.withOpacity(
                                    _isHovering ? 0.3 : 0.2),
                                AppColors.primaryFixedDim.withOpacity(
                                    _isHovering ? 0.2 : 0.1),
                              ],
                            ),
                          ),
                          child: isReady
                              ? Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: iconSize,
                                  color: _isHovering
                                      ? AppColors.primaryContainer
                                      : colorScheme.onSurface.withOpacity(0.7),
                                )
                              : SizedBox(
                                  width: iconSize,
                                  height: iconSize,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isReady
                              ? 'Drop or Tap to Upload'
                              : 'Loading AI Model...',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: rs.isCompact ? 18 : null,
                            color: _isHovering
                                ? AppColors.primaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isReady
                              ? 'Supports JPG, PNG, WEBP up to 10MB'
                              : 'Please wait while the model initializes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: rs.isCompact ? 12 : null,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (isReady) ...[
                          const SizedBox(height: 16),
                          // Action chips
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionChip(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onTap: widget.onPickGallery,
                              ),
                              const SizedBox(width: 12),
                              _ActionChip(
                                icon: Icons.camera_alt_outlined,
                                label: 'Camera',
                                isAccent: true,
                                onTap: widget.onPickCamera,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for animated dashed border.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double progress;
  final bool isActive;

  _DashedBorderPainter({
    required this.color,
    required this.progress,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        paint.strokeWidth / 2,
        paint.strokeWidth / 2,
        size.width - paint.strokeWidth,
        size.height - paint.strokeWidth,
      ),
      const Radius.circular(28),
    );

    // Create dashed path effect
    const dashWidth = 10.0;
    const dashSpace = 6.0;
    
    // Calculate total perimeter
    final offset = progress * (dashWidth + dashSpace);

    // Draw dashed border manually
    _drawDashedPath(canvas, rRect, paint, dashWidth, dashSpace, offset);
  }

  void _drawDashedPath(
    Canvas canvas,
    RRect rRect,
    Paint paint,
    double dashWidth,
    double dashSpace,
    double offset,
  ) {
    // Top edge
    final topLeft = Offset(rRect.left + rRect.tlRadiusX, rRect.top);
    final topRight = Offset(rRect.right - rRect.trRadiusX, rRect.top);
    
    // Right edge
    final rightTop = Offset(rRect.right, rRect.top + rRect.trRadiusY);
    final rightBottom = Offset(rRect.right, rRect.bottom - rRect.brRadiusY);
    
    // Bottom edge
    final bottomRight = Offset(rRect.right - rRect.brRadiusX, rRect.bottom);
    final bottomLeft = Offset(rRect.left + rRect.blRadiusX, rRect.bottom);
    
    // Left edge
    final leftBottom = Offset(rRect.left, rRect.bottom - rRect.blRadiusY);
    final leftTop = Offset(rRect.left, rRect.top + rRect.tlRadiusY);

    // Draw all edges with dashes
    _drawDashedLine(canvas, topLeft, topRight, paint, dashWidth, dashSpace, offset);
    _drawDashedLine(canvas, rightTop, rightBottom, paint, dashWidth, dashSpace, offset + 50);
    _drawDashedLine(canvas, bottomRight, bottomLeft, paint, dashWidth, dashSpace, offset + 100);
    _drawDashedLine(canvas, leftBottom, leftTop, paint, dashWidth, dashSpace, offset + 150);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashSpace,
    double offset,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distanceSquared = dx * dx + dy * dy;
    final distance = distanceSquared > 0 ? _sqrt(distanceSquared) : 0.0;
    
    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDistance = offset % (dashWidth + dashSpace);
    bool isDrawing = currentDistance < dashWidth;

    while (currentDistance < distance) {
      final segmentStart = Offset(
        start.dx + unitX * currentDistance,
        start.dy + unitY * currentDistance,
      );
      
      final segmentEndDistance = ((currentDistance + (isDrawing ? dashWidth : dashSpace))
          .clamp(0.0, distance) as double);
      final segmentEnd = Offset(
        start.dx + unitX * segmentEndDistance,
        start.dy + unitY * segmentEndDistance,
      );

      if (isDrawing) {
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance = segmentEndDistance;
      isDrawing = !isDrawing;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      isActive != oldDelegate.isActive ||
      (progress - oldDelegate.progress).abs() > 0.02;
}

/// Source option tile for bottom sheet.
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.4),
      ),
      onTap: onTap,
    );
  }
}

/// Action chip for quick actions.
class _ActionChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = widget.isAccent
        ? AppColors.secondaryContainer.withOpacity(0.15)
        : AppColors.primaryContainer.withOpacity(0.15);
    final fgColor = widget.isAccent
        ? AppColors.secondaryContainer
        : AppColors.primaryContainer;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: fgColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 18, color: fgColor),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  if (x == 1) return 1;
  double guess = x;
  for (int i = 0; i < 10; i++) {
    guess = 0.5 * (guess + x / guess);
  }
  return guess;
}
