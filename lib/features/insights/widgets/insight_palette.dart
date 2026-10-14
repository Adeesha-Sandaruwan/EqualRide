import 'package:flutter/material.dart';

/// Colours used across the insights charts. Chosen to keep strong contrast on
/// the dark EqualRide background.
class InsightPalette {
  const InsightPalette._();

  static const critical = Color(0xFFFF6B6B);
  static const high = Color(0xFFFFA45C);
  static const moderate = Color(0xFFFFD166);
  static const low = Color(0xFF7CFFB2);
  static const good = Color(0xFF7CFFB2);
  static const track = Color(0x1FFFFFFF);

  static Color forSeverityShare(double share) {
    if (share >= 0.75) return critical;
    if (share >= 0.5) return high;
    if (share >= 0.25) return moderate;
    return low;
  }
}
