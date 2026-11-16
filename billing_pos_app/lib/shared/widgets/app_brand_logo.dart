import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "../../core/theme/app_colors.dart";

/// Premium modern brand logo for PulsePOS with gradient glow and pulse accent.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;
  final String? subtitle;
  final bool isDark;

  const AppBrandLogo({
    super.key,
    this.size = 44,
    this.showText = true,
    this.showSubtitle = true,
    this.subtitle,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D9488), // Deep Teal
            Color(0xFF10B981), // Emerald Pulse
            Color(0xFF059669), // Rich Green
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: size > 40 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: size * 0.54,
          ),
          Positioned(
            right: size * 0.14,
            top: size * 0.14,
            child: Container(
              padding: EdgeInsets.all(size * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300), // Amber pulse
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: size * 0.24,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showText) return iconWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pulse",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.44,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  "POS",
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.44,
                    letterSpacing: -0.5,
                    color: const Color(0xFF0D9488),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 3, top: 4),
                  width: size * 0.12,
                  height: size * 0.12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFB300),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            if (showSubtitle && (subtitle == null || subtitle!.isNotEmpty))
              Text(
                subtitle ?? "Smart POS & Retail Suite",
                style: GoogleFonts.dmSans(
                  fontSize: (size * 0.24).clamp(10.0, 13.0),
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                  letterSpacing: 0.1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
