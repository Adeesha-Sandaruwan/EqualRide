// File: range_selector.dart
//
// Segmented control for picking the Insights time window (7, 30 or 90 days).

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../models/insight_summary.dart';

/// Segmented control for choosing the insights time window.
class RangeSelector extends StatelessWidget {
  const RangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final InsightRange selected;
  final ValueChanged<InsightRange> onChanged;

  static String labelFor(InsightRange range) => '${range.days} days';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          for (final range in InsightRange.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: range == selected,
                label: 'Last ${labelFor(range)}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(range),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: range == selected
                          ? AppTheme.teal
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      labelFor(range),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: range == selected
                            ? AppTheme.navy
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
