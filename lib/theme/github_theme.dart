// fg = foreground
import 'package:flutter/material.dart';

/// Provides the GitHub Primer dark theme palette and typography configuration.
class GitHubTheme {
  /// Default dark canvas background color.
  static const Color canvasDefault = Color(0xFF0D1117);

  /// Subtle dark canvas background color for cards and panels.
  static const Color canvasSubtle = Color(0xFF161B22);

  /// Inset dark background color for embedded consoles and badges.
  static const Color canvasInset = Color(0xFF010409);
  
  /// Default border color matching Primer specification.
  static const Color borderDefault = Color(0xFF30363D);

  /// Muted border color for secondary dividers.
  static const Color borderMuted = Color(0xFF21262D);
  
  /// Default foreground text color.
  static const Color fgDefault = Color(0xFFC9D1D9);

  /// Muted foreground text color.
  static const Color fgMuted = Color(0xFF8B949E);

  /// Subtle foreground text color for secondary labels.
  static const Color fgSubtle = Color(0xFF6E7681);
  
  /// Accent blue color for active states and primary indicators.
  static const Color accent = Color(0xFF58A6FF);

  /// Emphasis accent blue color for focused elements.
  static const Color accentEmphasis = Color(0xFF1F6FEB);
  
  /// Success green color for connected status and badges.
  static const Color success = Color(0xFF238636);

  /// Success green foreground text and icon color.
  static const Color successFg = Color(0xFF3FB950);
  
  /// Danger red color for disconnect actions and alerts.
  static const Color danger = Color(0xFFDA3633);

  /// Danger red foreground text and indicator color.
  static const Color dangerFg = Color(0xFFF85149);
  
  /// Warning amber color for scanning and high RPM indicators.
  static const Color warning = Color(0xFFD29922);

  /// Warning amber foreground text and indicator color.
  static const Color warningFg = Color(0xFFE3B341);

  /// Canela font family name for elegant headings.
  static const String fontCanela = 'Canela';

  /// Google Sans font family name for primary UI typography.
  static const String fontGoogleSans = 'Google Sans';

  /// Google Sans Code font family name for numeric readouts and telemetry logs.
  static const String fontGoogleSansCode = 'Google Sans Code';

  /// Generates the complete [ThemeData] adhering to GitHub Primer dark mode.
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
        elevation: 0.0,
        iconTheme: IconThemeData(color: fgDefault),
        titleTextStyle: TextStyle(
          fontFamily: fontCanela,
          fontSize: 22.0,
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
        titleLarge: TextStyle(fontFamily: fontCanela, color: fgDefault, fontSize: 20.0),
        titleMedium: TextStyle(fontFamily: fontGoogleSans, color: fgDefault, fontSize: 16.0),
        titleSmall: TextStyle(fontFamily: fontGoogleSans, color: fgMuted, fontSize: 14.0),
        bodyLarge: TextStyle(fontFamily: fontGoogleSans, color: fgDefault, fontSize: 14.0),
        bodyMedium: TextStyle(fontFamily: fontGoogleSans, color: fgMuted, fontSize: 12.0),
        bodySmall: TextStyle(fontFamily: fontGoogleSansCode, color: fgSubtle, fontSize: 11.0),
      ),
    );
  }
}
