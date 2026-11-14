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
        // Solid background base
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.glassCanvasDark : const Color(0xFFF1F5F9),
          ),
        ),

        // Ambient Neon Orb 1 (Top Left - Cyan / Teal)
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.neonCyan.withValues(alpha: isDark ? 0.18 : 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Neon Orb 2 (Top Right - Cyber Violet)
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
                  AppColors.neonViolet.withValues(alpha: isDark ? 0.16 : 0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Ambient Neon Orb 3 (Bottom Left - Emerald)
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
                  AppColors.neonEmerald.withValues(alpha: isDark ? 0.12 : 0.08),
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

