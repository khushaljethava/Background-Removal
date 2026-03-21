import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// Reusable action chip with icon + label, press animation, and accent variant.
class ActionChipButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  State<ActionChipButton> createState() => _ActionChipButtonState();
}

class _ActionChipButtonState extends State<ActionChipButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fgColor =
        widget.isAccent ? AppColors.secondary : AppColors.primary;
    final bgColor = fgColor.withOpacity(0.15);

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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppSpacing.borderRadiusXxl,
          border: Border.all(
            color: fgColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 18, color: fgColor),
            const SizedBox(width: AppSpacing.sm),
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
