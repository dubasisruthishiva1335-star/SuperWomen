import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6A2CEA);
  static const Color darkPurple = Color(0xFF1F0E44);
  static const Color deepPurple = Color(0xFF13072E);
  static const Color lightPurple = Color(0xFF8C52FF);
  static const Color purpleTint = Color(0xFFF3EBFF);
  static const Color accentPink = Color(0xFFFF4F8B);
  static const Color safeGreen = Color(0xFF00C853);
  static const Color alertRed = Color(0xFFFF334B);
  static const Color goldYellow = Color(0xFFFFB800);
  static const Color ink = Color(0xFF180D2B);
  static const Color inkSoft = Color(0xFF635777);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F5FD),
      fontFamily: 'PlusJakartaSans',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: accentPink,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
