import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Interactive before/after comparison slider with draggable divider.
class ImageCompareSlider extends StatefulWidget {
  final File beforeImage;
  final Uint8List afterImageBytes;

  const ImageCompareSlider({
    super.key,
    required this.beforeImage,
    required this.afterImageBytes,
  });

  @override
  State<ImageCompareSlider> createState() => _ImageCompareSliderState();
}

class _ImageCompareSliderState extends State<ImageCompareSlider> {
  double _sliderPosition = 0.5;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Container(
        color: colorScheme.surfaceContainer,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isDragging = true),
      onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
      onHorizontalDragUpdate: (details) {
        setState(() {
          _sliderPosition += details.delta.dx / context.size!.width;
          _sliderPosition = _sliderPosition.clamp(0.0, 1.0);
        });
      },
      onTapDown: (details) {
        setState(() {
          _sliderPosition = details.localPosition.dx / context.size!.width;
          _isDragging = true;
        });
      },
      onTapUp: (_) => setState(() => _isDragging = false),
      child: Stack(
        children: [
          // Before image (full width, clipped)
          ClipRect(
            clipper: _ImageClipper(
              widthFraction: _sliderPosition,
            ),
            child: Image.file(
              widget.beforeImage,
              fit: BoxFit.contain,
              cacheWidth: 1440,
              cacheHeight: 1440,
              filterQuality: FilterQuality.medium,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // After image (shown on right side)
          Positioned.fill(
            child: ClipRect(
              clipper: _ImageClipper(
                widthFraction: 1.0 - _sliderPosition,
                alignRight: true,
              ),
              child: Image.memory(
                widget.afterImageBytes,
                fit: BoxFit.contain,
                cacheWidth: 1440,
                cacheHeight: 1440,
                filterQuality: FilterQuality.medium,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          
          // Divider line
          Positioned(
            left: _sliderPosition * context.size!.width - 2,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          
          // Divider handle
          Positioned(
            left: _sliderPosition * context.size!.width - 24,
            top: (context.size!.height / 2) - 24,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.compare_arrows,
                color: AppColors.background,
                size: 24,
              ),
            ),
          ),
          
          // Labels
          Positioned(
            left: 16,
            top: 16,
            child: _LabelChip(
              label: 'Original',
              icon: Icons.image,
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _LabelChip(
              label: 'Result',
              icon: Icons.auto_fix_high,
              isAccent: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper for the split view.
class _ImageClipper extends CustomClipper<Rect> {
  final double widthFraction;
  final bool alignRight;

  _ImageClipper({
    required this.widthFraction,
    this.alignRight = false,
  });

  @override
  Rect getClip(Size size) {
    if (alignRight) {
      return Rect.fromLTWH(
        size.width * (1 - widthFraction),
        0,
        size.width * widthFraction,
        size.height,
      );
    }
    return Rect.fromLTWH(
      0,
      0,
      size.width * widthFraction,
      size.height,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => true;
}

/// Label chip for before/after.
class _LabelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isAccent;

  const _LabelChip({
    required this.label,
    required this.icon,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAccent
        ? AppColors.primaryContainer.withOpacity(0.2)
        : Colors.black.withOpacity(0.5);
    final fgColor = isAccent
        ? AppColors.primaryContainer
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: isAccent
            ? Border.all(color: AppColors.primaryContainer.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
