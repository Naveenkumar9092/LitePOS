import "package:flutter/material.dart";

enum ScreenType { mobile, tablet, desktop, posTerminal }

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMaxWidth &&
      MediaQuery.sizeOf(context).width < tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMaxWidth;

  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < mobileMaxWidth) {
      return ScreenType.mobile;
    } else if (width < tabletMaxWidth) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletMaxWidth) {
          return desktop;
        } else if (constraints.maxWidth >= mobileMaxWidth) {
          return tablet ?? desktop;
        } else {
          return mobile;
        }
      },
    );
  }
}

