import 'package:flutter/material.dart';

import 'apex_colors.dart';
import 'apex_shapes.dart';

abstract final class ApexTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: ApexColors.primaryNeon,
      onPrimary: ApexColors.canvas,
      secondary: ApexColors.secondaryEmerald,
      onSecondary: ApexColors.canvas,
      error: ApexColors.danger,
      onError: ApexColors.canvas,
      surface: ApexColors.surface,
      onSurface: ApexColors.textPrimary,
    );
    const baseText = TextTheme(
      bodyLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: ApexColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'PlusJakartaSans',
        color: ApexColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w700,
        color: ApexColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w600,
        color: ApexColors.textPrimary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ApexColors.canvas,
      fontFamily: 'PlusJakartaSans',
      textTheme: baseText,
      appBarTheme: const AppBarTheme(
        backgroundColor: ApexColors.canvas,
        foregroundColor: ApexColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: ApexColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: ApexColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ApexShapes.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ApexColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
          borderSide: const BorderSide(color: ApexColors.primaryNeon),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ApexColors.primaryNeon,
          foregroundColor: ApexColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ApexShapes.inputRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: ApexColors.primaryNeon,
        foregroundColor: ApexColors.canvas,
      ),
      dividerColor: ApexColors.surfaceHigh,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ApexColors.surfaceHigh,
        contentTextStyle: baseText.bodyMedium?.copyWith(
          color: ApexColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ApexShapes.badgeRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ApexColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ApexShapes.cardRadius),
        ),
      ),
    );
  }
}
