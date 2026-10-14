import 'package:flutter/material.dart';

import '../models/community_report.dart';
import '../theme/app_theme.dart';

/// A horizontal summary bar showing how many reports are in each status
/// bucket (Pending / In Progress / Resolved) for a given list.
///
/// Intended to appear near the top of [CommunityReportsPage] to give
/// users an instant overview without having to scroll.
class ReportStatsBar extends StatelessWidget {
  const ReportStatsBar({super.key, required this.reports});

  final List<CommunityReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const SizedBox.shrink();

    final pending =
        reports.where((r) => r.status == 'Pending').length;
    final inProgress =
        reports.where((r) => r.status == 'In Progress').length;
    final resolved =
        reports.where((r) => r.status == 'Resolved').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatTile(
            label: 'Pending',
            count: pending,
            color: const Color(0xFFFFB74D),
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'In Progress',
            count: inProgress,
            color: const Color(0xFF64B5F6),
            icon: Icons.autorenew_rounded,
          ),
          const SizedBox(width: 10),
          _StatTile(
            label: 'Resolved',
            count: resolved,
            color: const Color(0xFF66BB6A),
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
