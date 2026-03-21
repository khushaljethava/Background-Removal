import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Horizontal strip of recent images with smooth scrolling.
class RecentImagesStrip extends StatelessWidget {
  final List<File> images;
  final Function(File) onImageTap;

  const RecentImagesStrip({
    super.key,
    required this.images,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Recent',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, index) {
              return _RecentImageTile(
                image: images[index],
                onTap: () => onImageTap(images[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Single recent image tile with hover/press effect.
class _RecentImageTile extends StatefulWidget {
  final File image;
  final VoidCallback onTap;

  const _RecentImageTile({
    required this.image,
    required this.onTap,
  });

  @override
  State<_RecentImageTile> createState() => _RecentImageTileState();
}

class _RecentImageTileState extends State<_RecentImageTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 12),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isPressed
                    ? AppColors.primaryContainer
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                widget.image,
                fit: BoxFit.cover,
                cacheWidth: 160,
                cacheHeight: 160,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
