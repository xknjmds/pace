import 'package:flutter/material.dart';

/// Brand palette from branding/GUIDELINES.md, plus the tones the UI derives
/// from it. Nothing here is red: missed routines are never a failure state.
abstract final class PaceColors {
  // Brand (logo) colours.
  static const Color moss = Color(0xFF35665A);
  static const Color mossLight = Color(0xFF9CC3B4);
  static const Color sand = Color(0xFFF3EEE6);
  static const Color ink = Color(0xFF1C2622);

  // Light UI tones.
  static const Color paper = Color(0xFFFBF8F3); // cards, lifted off Sand
  static const Color sandDeep = Color(0xFFEAE3D8); // sunken / tracks
  static const Color sandHigh = Color(0xFFE2DACD);
  static const Color mossMist = Color(0xFFDCEAE3); // hero / primary container
  static const Color mossDeep = Color(0xFF14322A); // text on mossMist
  static const Color dawn = Color(0xFF9A6B1F); // warm accent (text-safe)
  static const Color dawnMist = Color(0xFFF6E7CB);

  // Dark UI tones.
  static const Color inkLow = Color(0xFF232E2A);
  static const Color inkMid = Color(0xFF2A3732);
  static const Color inkHigh = Color(0xFF32403A);
  static const Color inkHighest = Color(0xFF3A4943);
  static const Color mossNight = Color(0xFF2D4C43); // hero on dark
  static const Color mossPale = Color(0xFFD3E8DE);
  static const Color dawnLight = Color(0xFFE9C58C);
  static const Color dawnNight = Color(0xFF4A3818);
}
