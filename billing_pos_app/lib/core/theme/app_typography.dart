import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.dmSansTextTheme(
      const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.1),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
    );
  }
}

