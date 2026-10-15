import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tipografi DOMPETKU_DESIGN_SPEC_v3 §2.2: Fraunces (judul/saldo), Manrope (teks), JetBrains Mono (angka).
abstract final class AppText {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle display({
    double size = 26,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) => GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );

  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.manrope(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle mono({
    double size = 12.5,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double? letterSpacing = -0.02 * 12.5,
    double? height,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    fontFeatures: _tabular,
  );

  static TextStyle label({Color color = AppColors.mut, double size = 10.5}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: size * 0.06,
      );

  static TextStyle monoLabel({
    Color color = AppColors.mut,
    double size = 10.5,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: size * 0.06,
  );
}
