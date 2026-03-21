import 'dart:math' show pi;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Animated step-by-step pipeline progress indicator.
class AnimatedProgressBar extends StatelessWidget {
  final List<dynamic> steps;
  final int currentStep;
  final double progress;

  const AnimatedProgressBar({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Horizontal step indicators
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    // Step circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.tertiaryContainer
                            : isCurrent
                                ? AppColors.primaryContainer.withOpacity(0.2)
                                : colorScheme.surfaceContainerHigh,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.tertiaryContainer
                              : isCurrent
                                  ? AppColors.primaryContainer
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: AppColors.background,
                              )
                            : isCurrent
                                ? _PulsingDot()
                                : Text(
                                    '${index + 1}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                      ),
                    ),
                    // Connector line (except for last item)
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: index < currentStep
                                ? AppColors.tertiaryContainer
                                : colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Step labels
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: Text(
                  step.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCompleted || isCurrent
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Pulsing dot animation for current step.
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.4 + 0.6 * (1 - _controller.value);
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryContainer,
        ),
      ),
    );
  }
}
