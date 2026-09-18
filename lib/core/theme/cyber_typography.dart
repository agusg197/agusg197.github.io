import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cyber_colors.dart';

/// Typography roles: display (Chakra Petch), heading/body (Rajdhani), mono (Share Tech Mono).
abstract final class CyberType {
  static TextStyle display({
    double size = 64,
    Color color = CyberColors.text0,
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
  }) =>
      GoogleFonts.chakraPetch(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing ?? size * 0.02,
        height: 1.0,
      );

  static TextStyle heading({
    double size = 28,
    Color color = CyberColors.text0,
    FontWeight weight = FontWeight.w600,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: 1.2,
        height: 1.15,
      );

  static TextStyle body({
    double size = 17,
    Color color = CyberColors.text0,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.5,
      );

  static TextStyle mono({
    double size = 14,
    Color color = CyberColors.text1,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 1,
  }) =>
      GoogleFonts.shareTechMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: 1.4,
      );

  static TextTheme textTheme() {
    final base = GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: CyberColors.text0, displayColor: CyberColors.text0);
    return base.copyWith(
      displayLarge: display(size: 64),
      displayMedium: display(size: 48),
      displaySmall: display(size: 36),
      headlineLarge: heading(size: 32),
      headlineMedium: heading(size: 26),
      headlineSmall: heading(size: 22),
      titleLarge: heading(size: 20),
      titleMedium: heading(size: 18, weight: FontWeight.w500),
      bodyLarge: body(size: 18),
      bodyMedium: body(size: 16),
      bodySmall: body(size: 14, color: CyberColors.text1),
      labelLarge: mono(size: 14),
      labelMedium: mono(size: 12),
      labelSmall: mono(size: 11),
    );
  }
}
