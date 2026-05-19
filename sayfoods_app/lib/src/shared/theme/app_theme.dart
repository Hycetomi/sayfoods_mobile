import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Default text styling with Montserrat
      textTheme: GoogleFonts.montserratTextTheme(textTheme).copyWith(
        displayLarge: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.displayLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        displayMedium: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.displayMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        displaySmall: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.displaySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        headlineLarge: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        headlineMedium: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        headlineSmall: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleLarge: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleMedium: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSmall: GoogleFonts.bricolageGrotesque(
          textStyle: textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
