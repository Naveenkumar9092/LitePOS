import "dart:ui";
import "package:flutter/material.dart";

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? glowColor;
  final double glowOpacity;
  final double blurSigma;
  final Color? backgroundColor;
  final Border? customBorder;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.borderRadius = 16,
    this.glowColor,
    this.glowOpacity = 0.15,
    this.blurSigma = 10,
    this.backgroundColor,
    this.customBorder,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.85);

    final effectiveBorder = customBorder ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.9),
          width: 1.2,
        );

    final List<BoxShadow> shadows = [];
    if (glowColor != null) {
      shadows.add(
        BoxShadow(
          color: glowColor!.withValues(alpha: glowOpacity),
          blurRadius: 24,
          spreadRadius: -2,
          offset: const Offset(0, 4),
        ),
      );
    }
    shadows.add(
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFF64748B).withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    );

    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? (backgroundColor ?? defaultBg) : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: effectiveBorder,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      cardBody = Padding(padding: margin!, child: cardBody);
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardBody,
        ),
      );
    }

    return cardBody;
  }
}
