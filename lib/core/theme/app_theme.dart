import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final scheme = const ColorScheme.dark(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryBlue,
      onSecondary: Colors.white,
      surface: AppColors.background,
      onSurface: Colors.white70,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.outfit().fontFamily,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x40000000),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rMd),
          borderSide: const BorderSide(
              color: AppColors.secondaryBlueBorder57, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rMd),
          borderSide: const BorderSide(
              color: AppColors.secondaryBlueBorder57, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.rMd),
          borderSide:
              const BorderSide(color: AppColors.secondaryBlue, width: 1.6),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.rMd)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.primary.withValues(alpha: .30);
            }
            return scheme.primary; // AppColors.primaryBlue
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onPrimary.withValues(alpha:  .38);
            }
            return scheme.onPrimary;
          }),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(AppTextStyles.button),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.rMd)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.secondaryBlueBorder57, width: 1.2),
          ),
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.secondaryBlueFill07),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.withValues(alpha: .38);
            }
            return Colors.white;
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            AppTextStyles.body.copyWith(decoration: TextDecoration.underline),
          ),
          foregroundColor: const WidgetStatePropertyAll(Colors.white70),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
