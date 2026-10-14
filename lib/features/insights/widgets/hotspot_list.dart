import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_panel.dart';
import '../models/insight_summary.dart';
import 'insight_palette.dart';

/// Ranked list of the routes and places with the most severe open problems.
/// Rows are informational only; they do not open the Community Reports list.
class HotspotList extends StatelessWidget {
  const HotspotList({super.key, required this.entries});

  final List<InsightEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const GlassPanel(
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: InsightPalette.good),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No open problems in this period. Nice work!',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    final maxSeverity =
        entries.map((e) => e.severityScore).reduce((a, b) => a > b ? a : b);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            _HotspotRow(
              entry: entries[i],
              rank: i + 1,
              share: maxSeverity == 0 ? 0 : entries[i].severityScore / maxSeverity,
            ),
          ],
        ],
      ),
    );
  }
}

class _HotspotRow extends StatelessWidget {
  const _HotspotRow({
    required this.entry,
    required this.rank,
    required this.share,
  });

  final InsightEntry entry;
  final int rank;
  final double share;

  @override
  Widget build(BuildContext context) {
    final color = InsightPalette.forSeverityShare(share);

    return Semantics(
      label: 'Rank $rank, ${entry.label}. ${entry.openCount} open problems, '
          'severity score ${entry.severityScore}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.6)),
              ),
              child: Text(
                '$rank',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      children: [
                        Container(height: 6, color: InsightPalette.track),
                        FractionallySizedBox(
                          widthFactor: share.clamp(0.05, 1.0),
                          child: Container(height: 6, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.openCount} open',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
