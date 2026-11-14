import 'package:flutter/material.dart';

import 'pace_colors.dart';

/// Calm Material 3 themes. No red for user states: the error colour is kept
/// for real failures only, which the UI never shows for missed routines.
abstract final class PaceTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PaceColors.moss,
      primary: PaceColors.moss,
      surface: PaceColors.sand,
      onSurface: PaceColors.ink,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: PaceColors.moss,
      brightness: Brightness.dark,
      primary: PaceColors.mossLight,
      surface: PaceColors.ink,
      onSurface: PaceColors.sand,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) => ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: const SwitchThemeData(),
    visualDensity: VisualDensity.standard,
  );
}
