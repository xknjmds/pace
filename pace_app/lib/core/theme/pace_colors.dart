import 'package:flutter/material.dart';

/// Colour primitives. Components never use these directly: they read the
/// roles in the theme's [ColorScheme] (see `pace_theme.dart`) and the
/// activity colours in `PacePastels`.
///
/// The app UI is off-white (light) or soft charcoal (dark) with soft-ink
/// actions and pastel fills. Moss, the brand green, is a small accent
/// (`ColorScheme.secondary`): checks, done states, links, focus. Nothing
/// here is red: missed routines are never a failure state.
abstract final class PaceColors {
  // Brand (logo and Tuck). In the UI, Moss is the accent only.
  static const Color moss = Color(0xFF35665A);
  static const Color mossLight = Color(0xFF9CC3B4);
  static const Color sand = Color(0xFFF3EEE6);
  static const Color ink = Color(0xFF1C2622);

  // Light neutrals: warm off-white, no green in them.
  static const Color offWhite = Color(0xFFFAF8F5); // page
  static const Color white = Color(0xFFFFFFFF); // cards
  static const Color mist = Color(0xFFF5F2EE);
  static const Color sunken = Color(0xFFF1EEE9); // tracks, fields
  static const Color sunkenDeep = Color(0xFFEAE6E0);
  static const Color softInk = Color(0xFF2B2D31); // main buttons
  static const Color text = Color(0xFF26282C);
  static const Color textSoft = Color(
    0xFF64666C,
  ); // ≥ 4.5:1 on every light fill
  static const Color line = Color(0xFF86898F); // ≥ 3:1 on page and cards
  static const Color lineSoft = Color(0xFFE6E2DC);

  // Dark neutrals: soft charcoal, no green in them.
  static const Color charcoal = Color(0xFF1A1B1E); // page
  static const Color charcoalDeep = Color(0xFF141517);
  static const Color charcoalCard = Color(0xFF24262A); // cards
  static const Color charcoalMid = Color(0xFF292B2F);
  static const Color charcoalHigh = Color(0xFF2E3035); // tracks, fields
  static const Color charcoalHighest = Color(0xFF36383D);
  static const Color paper = Color(0xFFF1EEE8); // main buttons on dark
  static const Color textNight = Color(0xFFEEEBE6);
  static const Color textNightSoft = Color(0xFFA9ACB2);
  static const Color lineNight = Color(0xFF7A7D84);
  static const Color lineNightSoft = Color(0xFF3A3D42);

  // Selected states: the mint pastel.
  static const Color mint = Color(0xFFDCEAE3);
  static const Color mintNight = Color(0xFF2C3A35);

  // Warm accent for morning moments (text-safe).
  static const Color dawn = Color(0xFF8A5E14);
  static const Color dawnMist = Color(0xFFF7E8CC);
  static const Color dawnLight = Color(0xFFF0CF96);
  static const Color dawnNight = Color(0xFF3E3320);
}
