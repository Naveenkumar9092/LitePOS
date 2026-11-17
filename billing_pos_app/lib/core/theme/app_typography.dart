import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppTypography {
  static const List<String> fontFallbacks = [
    "Segoe UI",
    "Roboto",
    "SF Pro Display",
    "Helvetica Neue",
    "Arial",
    "sans-serif",
  ];

  static final TextTheme textTheme = GoogleFonts.dmSansTextTheme(
    const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, fontFamilyFallback: fontFallbacks),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, fontFamilyFallback: fontFallbacks),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamilyFallback: fontFallbacks),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallbacks),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallbacks),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallbacks),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallbacks),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamilyFallback: fontFallbacks),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, fontFamilyFallback: fontFallbacks),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, fontFamilyFallback: fontFallbacks),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamilyFallback: fontFallbacks),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.1, fontFamilyFallback: fontFallbacks),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, fontFamilyFallback: fontFallbacks),
    ),
  );
}

