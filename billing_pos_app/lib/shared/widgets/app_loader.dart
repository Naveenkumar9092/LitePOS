import "dart:math" as math;
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "../../core/theme/app_colors.dart";

/// A high-performance, ultra-smooth modern loader with dual neon teal spinning rings,
/// glowing ambient halo, and DM Sans typography.
class AppLoader extends StatefulWidget {
  final String? message;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGlow;

  const AppLoader({
    super.key,
    this.message,
    this.size = 46.0,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryDark,
    this.showGlow = true,
  });

  const AppLoader.small({
    super.key,
    this.message,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryDark,
  })  : size = 26.0,
        showGlow = false;

  const AppLoader.fullscreen({
    super.key,
    this.message = "Loading PulsePOS...",
    this.size = 54.0,
    this.primaryColor = AppColors.primary,
    this.secondaryColor = AppColors.primaryDark,
    this.showGlow = true,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _DualRingPainter(
            progress: _controller.value,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
            showGlow: widget.showGlow,
          ),
        );
      },
    );

    if (widget.message == null || widget.message!.isEmpty) {
      return Center(child: RepaintBoundary(child: ring));
    }

    return Center(
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ring,
            const SizedBox(height: 14),
            Text(
              widget.message!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DualRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final bool showGlow;

  _DualRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.68;

    // Ambient glow halo
    if (showGlow) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(center, outerRadius * 0.85, glowPaint);
    }

    // Outer track
    final outerTrackPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, size.width * 0.07);
    canvas.drawCircle(center, outerRadius - outerTrackPaint.strokeWidth / 2, outerTrackPaint);

    // Outer spinning arc
    final outerArcPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.8, size.width * 0.075);

    final outerStartAngle = progress * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: outerRadius - outerArcPaint.strokeWidth / 2,
      ),
      outerStartAngle,
      1.3 * math.pi,
      false,
      outerArcPaint,
    );

    // Inner reverse-spinning arc
    final innerArcPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.0, size.width * 0.055);

    final innerStartAngle = -progress * 2 * math.pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: innerRadius - innerArcPaint.strokeWidth / 2,
      ),
      innerStartAngle,
      math.pi,
      false,
      innerArcPaint,
    );

    // Center focal point
    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, math.max(1.8, size.width * 0.045), dotPaint);
  }

  @override
  bool shouldRepaint(covariant _DualRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor;
  }
}

