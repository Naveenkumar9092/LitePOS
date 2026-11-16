import "dart:async";
import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "../../core/theme/app_colors.dart";

enum ToastType {
  success,
  error,
  info,
  warning,
}

class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2400)}) {
    show(context, message: message, type: ToastType.success, duration: duration);
  }

  static void showError(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 3000)}) {
    show(context, message: message, type: ToastType.error, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2200)}) {
    show(context, message: message, type: ToastType.info, duration: duration);
  }

  static void showWarning(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2600)}) {
    show(context, message: message, type: ToastType.warning, duration: duration);
  }

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        message: message,
        type: type,
        onDismiss: dismiss,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnim = Tween<Offset>(
      begin: const Offset(0.0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color get _accentColor {
    switch (widget.type) {
      case ToastType.success:
        return AppColors.success; // #047857 Dark Emerald
      case ToastType.error:
        return AppColors.error; // #DC2626
      case ToastType.warning:
        return AppColors.warning; // #D97706
      case ToastType.info:
        return AppColors.primary; // #24B1B1 Teal
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top > 0 ? mediaQuery.padding.top + 8 : 16.0;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: _offsetAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: GestureDetector(
                onTap: _handleDismiss,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta != null && details.primaryDelta! < -4) {
                    _handleDismiss();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.6),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _handleDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

