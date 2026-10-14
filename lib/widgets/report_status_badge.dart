import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A small pill-shaped badge that displays a report status string
/// (Pending / In Progress / Resolved) with the appropriate colour.
///
/// This is a pure display widget — it does not handle taps or mutations.
/// Use it anywhere a compact, read-only status indicator is needed.
class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
    this.showIcon = true,
  });

  final String status;
  final double fontSize;
  final bool showIcon;

  static Color colorFor(String status) {
    switch (status) {
      case 'Resolved':
        return const Color(0xFF66BB6A);
      case 'In Progress':
        return const Color(0xFF64B5F6);
      default: // Pending
        return const Color(0xFFFFB74D);
    }
  }

  static IconData iconFor(String status) {
    switch (status) {
      case 'Resolved':
        return Icons.check_circle_rounded;
      case 'In Progress':
        return Icons.autorenew_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize + 2,
        vertical: fontSize * 0.4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(iconFor(status), color: color, size: fontSize + 2),
            SizedBox(width: fontSize * 0.4),
          ],
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
