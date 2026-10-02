import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  const AppTheme._();

  static const fontFamily = 'Poppins';

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.teal,
          onPrimary: Colors.white,
          primaryContainer: AppColors.mint,
          onPrimaryContainer: AppColors.tealDeep,
          secondary: AppColors.amber,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.amberSoft,
          onSecondaryContainer: AppColors.amberDeep,
          error: AppColors.coral,
          onError: Colors.white,
          errorContainer: AppColors.coralSoft,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.muted,
          outline: AppColors.line,
          outlineVariant: AppColors.line,
        );

    return _build(
      brightness: Brightness.light,
      scheme: scheme,
      background: AppColors.background,
      surface: AppColors.surface,
      ink: AppColors.ink,
      line: AppColors.line,
      accent: AppColors.teal,
      focus: AppColors.tealLight,
      switchOff: const Color(0xFFCBD5E1),
      snackBackground: AppColors.ink,
      snackText: Colors.white,
    );
  }

  static ThemeData get dark {
    const background = Color(0xFF0B1A1C);
    const surface = Color(0xFF132629);
    const ink = Color(0xFFE6F2F1);
    const line = Color(0xFF24403F);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.tealLight,
          onPrimary: const Color(0xFF042F2E),
          primaryContainer: const Color(0xFF0F3B3A),
          onPrimaryContainer: AppColors.mint,
          secondary: AppColors.amber,
          onSecondary: Colors.black,
          error: AppColors.coral,
          onError: Colors.white,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: const Color(0xFF9FB5B4),
          outline: line,
          outlineVariant: line,
        );

    return _build(
      brightness: Brightness.dark,
      scheme: scheme,
      background: background,
      surface: surface,
      ink: ink,
      line: line,
      accent: AppColors.tealLight,
      focus: AppColors.tealLight,
      switchOff: const Color(0xFF3B5352),
      snackBackground: ink,
      snackText: background,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color background,
    required Color surface,
    required Color ink,
    required Color line,
    required Color accent,
    required Color focus,
    required Color switchOff,
    required Color snackBackground,
    required Color snackText,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final t = base.textTheme;
    final textTheme = t
        .copyWith(
          headlineMedium: t.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: t.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: t.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: t.titleSmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: t.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
          bodyMedium: t.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
          bodySmall: t.bodySmall?.copyWith(fontSize: 12),
          labelLarge: t.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: t.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          labelSmall: t.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        )
        .apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(AppSpacing.minTap, AppSpacing.buttonHeight),
          foregroundColor: accent,
          side: BorderSide(color: AppColors.tealLight, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: focus, width: 1.6),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.tealLight
              : switchOff,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBackground,
        contentTextStyle: TextStyle(color: snackText, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: brightness == Brightness.light
            ? AppColors.track
            : line,
      ),
    );
  }
}
