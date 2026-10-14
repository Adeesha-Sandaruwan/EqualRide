// File: issue_bar_chart.dart
//
// Horizontal bar chart of the most reported issue types, coloured by severity
// share.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_panel.dart';
import '../models/insight_summary.dart';
import 'insight_palette.dart';

/// Horizontal bars for the most frequently reported issue types.
class IssueBarChart extends StatelessWidget {
  const IssueBarChart({super.key, required this.entries});

  final List<InsightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const GlassPanel(
        child: Center(
          child: Text(
            'No issues reported in this period',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final maxCount = entries
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b);

    return GlassPanel(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _IssueBar(entry: entries[i], maxCount: maxCount, rank: i + 1),
          ],
        ],
      ),
    );
  }
}

class _IssueBar extends StatelessWidget {
  const _IssueBar({
    required this.entry,
    required this.maxCount,
    required this.rank,
  });

  final InsightEntry entry;
  final int maxCount;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : entry.count / maxCount;

    return Semantics(
      label:
          '$rank. ${entry.label}: ${entry.count} reports, '
          '${entry.openCount} still open',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.count}',
                style: const TextStyle(
                  color: AppTheme.aqua,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(height: 10, color: InsightPalette.track),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0),
                      child: Container(
                        height: 10,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.teal, AppTheme.aqua],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${entry.openCount} still open',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
