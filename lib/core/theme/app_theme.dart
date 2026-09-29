import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const teal = Color(0xFF0F766E);
  static const green = Color(0xFF15803D);
  static const rose = Color(0xFFBE123C);
  static const amber = Color(0xFFD97706);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      secondary: amber,
      error: dark ? const Color(0xFFFF8FA8) : rose,
    );
    final radius = BorderRadius.circular(20);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF0E1719) : const Color(0xFFF8FAF9),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: dark ? const Color(0xFF0E1719) : const Color(0xFFF8FAF9),
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF19272A) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
