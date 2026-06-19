import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors (Neon Palette)
  static const Color bgDark = Color(0xFF08080C);
  static const Color panelDark = Color(0x12FFFFFF); // Glass surface overlay
  static const Color panelBorder = Color(0x1AFFFFFF); // Glass border accent
  
  static const Color neonPurple = Color(0xFF9F3FFF);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF2E93);
  static const Color neonGreen = Color(0xFF00FF87);
  
  static const Color textPrimary = Color(0xFFF5F5FA);
  static const Color textSecondary = Color(0xFF8E9AA8);
  
  static const LinearGradient purpleCyanGradient = LinearGradient(
    colors: [neonPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkPurpleGradient = LinearGradient(
    colors: [neonPink, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: neonPurple,
      
      colorScheme: const ColorScheme.dark(
        primary: neonPurple,
        secondary: neonCyan,
        tertiary: neonPink,
        background: bgDark,
        surface: Color(0xFF12121A),
        error: Color(0xFFFF4D4D),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
      ),

      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: const TextStyle(color: textPrimary, height: 1.5),
          bodyMedium: const TextStyle(color: textSecondary, height: 1.4),
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF161622),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: panelBorder, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: panelBorder,
        thickness: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101018),
        hintStyle: const TextStyle(color: textSecondary),
        labelStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4D4D)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonCyan,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
