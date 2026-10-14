import 'package:flutter/material.dart';

/// A compact badge that displays an accessibility impact level
/// (Low / Moderate / High / Critical) with a matching colour.
///
/// Extracted from the inline implementation in community_reports_page.dart
/// so it can be reused on the detail page and anywhere else impact level
/// needs to be shown consistently.
class ReportImpactBadge extends StatelessWidget {
  const ReportImpactBadge({
    super.key,
    required this.impactLevel,
    this.fontSize = 12,
  });

  final String impactLevel;
  final double fontSize;

  static Color colorFor(String level) {
    switch (level) {
      case 'Low':
        return const Color(0xFF66BB6A);
      case 'High':
        return const Color(0xFFFFB74D);
      case 'Critical':
        return const Color(0xFFE57373);
      default: // Moderate
        return const Color(0xFF64B5F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(impactLevel);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize + 2,
        vertical: fontSize * 0.4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, color: color, size: fontSize + 2),
          SizedBox(width: fontSize * 0.35),
          Text(
            'Impact: $impactLevel',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
