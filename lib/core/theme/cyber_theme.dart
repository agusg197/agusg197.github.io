import 'package:flutter/material.dart';

import 'cyber_colors.dart';
import 'cyber_typography.dart';

ThemeData buildCyberTheme() {
  const scheme = ColorScheme.dark(
    primary: CyberColors.cyan,
    onPrimary: CyberColors.bg0,
    secondary: CyberColors.yellow,
    onSecondary: CyberColors.bg0,
    tertiary: CyberColors.magenta,
    onTertiary: CyberColors.bg0,
    surface: CyberColors.bg1,
    onSurface: CyberColors.text0,
    error: CyberColors.magenta,
    onError: CyberColors.bg0,
    outline: CyberColors.grid,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
  );

  return base.copyWith(
    scaffoldBackgroundColor: CyberColors.bg0,
    canvasColor: CyberColors.bg0,
    textTheme: CyberType.textTheme(),
    splashFactory: NoSplash.splashFactory,
    dividerColor: CyberColors.grid,
    iconTheme: const IconThemeData(color: CyberColors.text1, size: 20),
    sliderTheme: SliderThemeData(
      activeTrackColor: CyberColors.cyan,
      inactiveTrackColor: CyberColors.grid,
      thumbColor: CyberColors.cyan,
      overlayColor: CyberColors.cyan.withValues(alpha: 0.15),
      trackHeight: 2,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CyberColors.cyan
            : CyberColors.text2,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CyberColors.cyan.withValues(alpha: 0.25)
            : CyberColors.bg2,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(CyberColors.grid),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: CyberColors.grid),
        ),
        textStyle: WidgetStatePropertyAll(CyberType.mono(size: 12)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? CyberColors.bg0
              : CyberColors.text1,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? CyberColors.cyan
              : Colors.transparent,
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: CyberColors.bg2,
        border: Border.all(color: CyberColors.cyan.withValues(alpha: 0.4)),
      ),
      textStyle: CyberType.mono(size: 12, color: CyberColors.text0),
    ),
  );
}
