import 'package:flutter/material.dart';

abstract final class AppColors {
  static const teal = Color(0xFF0F766E);
  static const tealDeep = Color(0xFF0B5F58);
  static const tealLight = Color(0xFF14B8A6);
  static const emerald = Color(0xFF10B981);
  static const mint = Color(0xFFCCFBF1);
  static const mintSoft = Color(0xFFECFDF5);
  static const amber = Color(0xFFF59E0B);
  static const amberDeep = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFEF3C7);
  static const orange = Color(0xFFEA580C);
  static const orangeSoft = Color(0xFFFFEDD5);
  static const coral = Color(0xFFF43F5E);
  static const coralSoft = Color(0xFFFFE4E9);
  static const income = Color(0xFF15803D);
  static const incomeSoft = Color(0xFFDCFCE7);
  static const violet = Color(0xFF8B5CF6);
  static const sky = Color(0xFF38BDF8);
  static const background = Color(0xFFF6FAF9);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F2937);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const track = Color(0xFFEEF2F5);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, emerald],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealDeep, teal, emerald],
    stops: [0.0, 0.4, 1.0],
  );

  static const softShadow = [
    BoxShadow(color: Color(0x170F766E), blurRadius: 22, offset: Offset(0, 6)),
  ];
}
