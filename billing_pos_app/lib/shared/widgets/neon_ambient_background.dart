import "package:flutter/material.dart";
import "../../core/theme/app_colors.dart";

class NeonAmbientBackground extends StatelessWidget {
  final Widget child;

  const NeonAmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Solid background base: #EBF4F6 on light, #0B1416 on dark
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.glassCanvasDark : AppColors.backgroundLight,
          ),
        ),

        // Ambient Teal Glow Orb 1 (#24B1B1 - Top Left)
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Teal Glow Orb 2 (Top Right)
        Positioned(
          top: 60,
          right: -100,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF24B1B1).withValues(alpha: isDark ? 0.18 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Soft Ice Orb 3 (Bottom Left)
        Positioned(
          bottom: 120,
          left: 100,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF24B1B1).withValues(alpha: isDark ? 0.14 : 0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
