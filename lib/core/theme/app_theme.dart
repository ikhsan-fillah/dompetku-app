import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.ink,
          onPrimary: AppColors.paper,
          primaryContainer: AppColors.paper2,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.accent,
          onSecondary: AppColors.paper,
          secondaryContainer: AppColors.accentSoft,
          onSecondaryContainer: AppColors.accent,
          tertiary: AppColors.earn,
          onTertiary: AppColors.paper,
          error: AppColors.spend,
          onError: Colors.white,
          errorContainer: AppColors.spendSoft,
          onErrorContainer: AppColors.spend,
          surface: AppColors.card,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.ink2,
          surfaceContainerLowest: AppColors.card,
          surfaceContainerLow: AppColors.card,
          surfaceContainer: AppColors.paper2,
          surfaceContainerHigh: AppColors.paper2,
          surfaceContainerHighest: AppColors.paper2,
          outline: AppColors.line,
          outlineVariant: AppColors.line2,
          shadow: Colors.transparent,
          scrim: AppColors.ink,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    );
    final t = base.textTheme;
    final textTheme = t
        .copyWith(
          headlineMedium: AppText.display(size: 26),
          headlineSmall: AppText.display(size: 24, height: 1.15),
          titleLarge: AppText.display(size: 26),
          titleMedium: AppText.body(size: 14, weight: FontWeight.w700),
          titleSmall: AppText.body(size: 13, weight: FontWeight.w700),
          bodyLarge: AppText.body(size: 14, height: 1.45),
          bodyMedium: AppText.body(size: 13, height: 1.45),
          bodySmall: AppText.body(size: 11, color: AppColors.mut),
          labelLarge: AppText.body(size: 14, weight: FontWeight.w700),
          labelMedium: AppText.body(size: 12, weight: FontWeight.w600),
          labelSmall: AppText.body(
            size: 10.5,
            weight: FontWeight.w700,
            color: AppColors.mut,
          ),
        )
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      dividerColor: AppColors.line2,
      dividerTheme: const DividerThemeData(
        color: AppColors.line2,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppText.display(size: 26),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppText.body(size: 14, weight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppText.body(size: 14, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppText.body(size: 11.5, weight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppText.body(size: 12.5, color: AppColors.mut),
        labelStyle: AppText.body(size: 11, color: AppColors.mut),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: const BorderSide(color: AppColors.ink),
        ),
      ),
      // Semua lembar bawah memakai gaya lembar Catat Keuangan: latar kartu,
      // garis tipis, tanpa bayangan.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.card,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.line,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.line),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.line,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(size: 12, color: AppColors.paper),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.smallButton),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.ink,
        linearTrackColor: AppColors.paper2,
      ),
    );
  }
}
