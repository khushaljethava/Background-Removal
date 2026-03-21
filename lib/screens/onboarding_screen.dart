import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../core/theme/app_spacing.dart';

/// Single-screen onboarding shown on first launch.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // App icon with pulsing border
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: AppSpacing.borderRadiusRound,
                      border: Border.all(
                        color: AppColors.primaryContainer
                            .withOpacity(0.3 * _pulseController.value),
                        width: 4,
                      ),
                    ),
                    child: Center(child: child),
                  );
                },
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppDecorations.thermalGradientOf(context),
                    borderRadius: AppSpacing.borderRadiusRound,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withOpacity(0.3),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_fix_high,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'BG REMOVER',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Remove backgrounds instantly\nwith on-device AI',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.huge),

              // Feature list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.surfaceCardOf(context, radius: 16),
                child: _FeatureRow(
                  icon: Icons.bolt,
                  color: AppColors.primaryContainer,
                  title: 'Fast & Private',
                  subtitle: 'Everything runs on your device',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.surfaceCardOf(context, radius: 16),
                child: _FeatureRow(
                  icon: Icons.high_quality,
                  color: AppColors.secondary,
                  title: 'High Quality',
                  subtitle: 'AI-powered edge detection',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppDecorations.surfaceCardOf(context, radius: 16),
                child: _FeatureRow(
                  icon: Icons.palette,
                  color: AppColors.tertiaryContainer,
                  title: 'Custom Backgrounds',
                  subtitle: 'Transparent, solid, blur & more',
                ),
              ),

              const Spacer(flex: 3),

              // Get started button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onComplete();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: AppDecorations.thermalGradientOf(context),
                      borderRadius: AppSpacing.borderRadiusXl,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryContainer.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      'GET STARTED',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
