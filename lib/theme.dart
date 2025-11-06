import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Cor principal
  static const Color primary = Color(0xFFFB8500);

  // Cores de fundo
  static const Color background = Color(0xFFFFFFFF);

  // Cores de texto
  static const Color text = Color(0xFF000000);
  static const Color textLight = Color(0xFF277DA1);

  // Cores de estado
  static const Color error = Color(0xFFF94144);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.background,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.background,
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme)
          .copyWith(
            bodyLarge: GoogleFonts.poppins(color: AppColors.text),
            bodyMedium: GoogleFonts.poppins(color: AppColors.text),
            bodySmall: GoogleFonts.poppins(color: AppColors.textLight),
            titleLarge: GoogleFonts.poppins(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.poppins(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: GoogleFonts.poppins(
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
      cardTheme: const CardThemeData(color: AppColors.background, elevation: 2),
      useMaterial3: true,
    );
  }
}
