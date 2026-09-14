import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundCard = Color(0xFF12121A);
  static const Color cardColor = Color(0xFF1A1A26);
  static const Color cardColorLight = Color(0xFF22223A);
  static const Color neonPink = Color(0xFFFF2D78);
  static const Color neonPurple = Color(0xFF9B4DCA);
  static const Color neonPinkLight = Color(0xFFFF6B9D);
  static const Color textPrimary = Color(0xFFF8F0FF);
  static const Color textSecondary = Color(0xFF8B7FA8);
  static const Color textMuted = Color(0xFF4A4468);
  static const Color dividerColor = Color(0xFF2A2040);

  static const LinearGradient neonGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFF2A1A2E), Color(0xFF1A1A26)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration neonCardDecoration({
    double borderWidth = 1.0,
    double borderOpacity = 0.25,
    double glowOpacity = 0.12,
    double radius = 20,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1830), Color(0xFF12121A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: neonPink.withOpacity(borderOpacity),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: neonPink.withOpacity(glowOpacity),
          blurRadius: 20,
          spreadRadius: -4,
        ),
        BoxShadow(
          color: neonPurple.withOpacity(glowOpacity * 0.6),
          blurRadius: 40,
          spreadRadius: -8,
        ),
      ],
    );
  }

  static const String _fontFamily = 'SpaceGrotesk';

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: neonPink,
        secondary: neonPurple,
        surface: cardColor,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 72,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
        ),
        displayMedium: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: _fontFamily,
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          fontFamily: _fontFamily,
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: _fontFamily,
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
