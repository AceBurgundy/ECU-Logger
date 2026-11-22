import 'package:flutter/material.dart';

class GitHubTheme {
  // GitHub Dark Primer Color Palette
  static const Color canvasDefault = Color(0xFF0D1117);
  static const Color canvasSubtle = Color(0xFF161B22);
  static const Color canvasInset = Color(0xFF010409);
  
  static const Color borderDefault = Color(0xFF30363D);
  static const Color borderMuted = Color(0xFF21262D);
  
  static const Color fgDefault = Color(0xFFC9D1D9);
  static const Color fgMuted = Color(0xFF8B949E);
  static const Color fgSubtle = Color(0xFF6E7681);
  
  static const Color accent = Color(0xFF58A6FF);
  static const Color accentEmphasis = Color(0xFF1F6FEB);
  
  static const Color success = Color(0xFF238636);
  static const Color successFg = Color(0xFF3FB950);
  
  static const Color danger = Color(0xFFDA3633);
  static const Color dangerFg = Color(0xFFF85149);
  
  static const Color warning = Color(0xFFD29922);
  static const Color warningFg = Color(0xFFE3B341);

  // Font family names configured in pubspec.yaml
  static const String fontCanela = 'Canela';
  static const String fontGoogleSans = 'Google Sans';
  static const String fontGoogleSansCode = 'Google Sans Code';

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvasDefault,
      primaryColor: accent,
      fontFamily: fontGoogleSans,
      cardColor: canvasSubtle,
      dividerColor: borderDefault,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvasSubtle,
        elevation: 0,
        iconTheme: IconThemeData(color: fgDefault),
        titleTextStyle: TextStyle(
          fontFamily: fontCanela,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: fgDefault,
          letterSpacing: 0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: successFg,
        surface: canvasSubtle,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: fgDefault,
        onError: Colors.white,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: fontGoogleSans, color: fgDefault),
        displayMedium: TextStyle(fontFamily: fontGoogleSans, color: fgDefault),
        displaySmall: TextStyle(fontFamily: fontGoogleSans, color: fgDefault),
        headlineMedium: TextStyle(fontFamily: fontGoogleSans, color: fgDefault),
        headlineSmall: TextStyle(fontFamily: fontGoogleSans, color: fgDefault),
        titleLarge: TextStyle(fontFamily: fontCanela, color: fgDefault, fontSize: 20),
        titleMedium: TextStyle(fontFamily: fontGoogleSans, color: fgDefault, fontSize: 16),
        titleSmall: TextStyle(fontFamily: fontGoogleSans, color: fgMuted, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: fontGoogleSans, color: fgDefault, fontSize: 14),
        bodyMedium: TextStyle(fontFamily: fontGoogleSans, color: fgMuted, fontSize: 12),
        bodySmall: TextStyle(fontFamily: fontGoogleSansCode, color: fgSubtle, fontSize: 11),
      ),
    );
  }
}
