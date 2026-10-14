import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact chip that shows whether a community report is an on-bus
/// ('bus') or station/road ('road') issue.
///
/// Purely presentational — pass [category] and it renders the appropriate
/// icon and label.
class ReportCategoryChip extends StatelessWidget {
  const ReportCategoryChip({
    super.key,
    required this.category,
    this.fontSize = 12,
  });

  /// Either 'bus' or 'road'.
  final String category;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isBus = category == 'bus';
    final icon = isBus ? Icons.directions_bus_rounded : Icons.train_rounded;
    final label = isBus ? 'On the bus' : 'Station / road';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize + 2,
        vertical: fontSize * 0.35,
      ),
      decoration: BoxDecoration(
        color: AppTheme.teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 2, color: AppTheme.teal),
          SizedBox(width: fontSize * 0.4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.teal,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
