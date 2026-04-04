import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

abstract final class AppTheme {
  // ── Light Theme ──
  static ThemeData lightTheme(Color seedColor, {Color? backgroundColor, Color? buttonColor, double borderWidth = 0, Color? borderColor, double textIntensity = 0.5}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final bgColor = backgroundColor ?? AppColors.scaffoldLight;
    final cardColor = backgroundColor != null
        ? Color.lerp(backgroundColor, Colors.white, 0.5)!
        : AppColors.cardLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: _buildTextTheme(
        Color.lerp(AppColors.textSecondaryLight, Colors.black, textIntensity)!,
        Color.lerp(AppColors.textSecondaryLight, Colors.black54, textIntensity)!,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(color: AppColors.dividerLight.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: borderWidth > 0 ? BorderSide(color: borderColor ?? colorScheme.outline, width: borderWidth) : BorderSide.none,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor ?? colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: borderWidth > 0 ? BorderSide(color: borderColor ?? colorScheme.outline, width: borderWidth) : BorderSide.none,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor ?? colorScheme.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
          side: BorderSide(color: borderColor ?? buttonColor ?? colorScheme.primary, width: borderWidth > 0 ? borderWidth : 1),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: buttonColor ?? colorScheme.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiaryLight,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondaryLight,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundLight,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData darkTheme(Color seedColor, {Color? backgroundColor, Color? buttonColor, double borderWidth = 0, Color? borderColor, double textIntensity = 0.5}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    final bgColor = backgroundColor ?? AppColors.scaffoldDark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      textTheme: _buildTextTheme(
        Color.lerp(AppColors.textSecondaryDark, Colors.white, textIntensity)!,
        Color.lerp(AppColors.textSecondaryDark, Colors.white70, textIntensity)!,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(color: AppColors.dividerDark.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: borderWidth > 0 ? BorderSide(color: borderColor ?? colorScheme.outline, width: borderWidth) : BorderSide.none,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor ?? colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
            side: borderWidth > 0 ? BorderSide(color: borderColor ?? colorScheme.outline, width: borderWidth) : BorderSide.none,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor ?? colorScheme.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
          side: BorderSide(color: borderColor ?? buttonColor ?? colorScheme.primary, width: borderWidth > 0 ? borderWidth : 1),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: buttonColor ?? colorScheme.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textTertiaryDark,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusFull,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimaryDark,
          fontSize: 14,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.25),
      headlineSmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, color: primary),
      titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: primary),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1),
      titleSmall: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.1),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: primary, letterSpacing: 0.15),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: secondary, letterSpacing: 0.25),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, letterSpacing: 0.4),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: primary, letterSpacing: 0.1),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
    );
  }
}
