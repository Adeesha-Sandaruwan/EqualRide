import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../screens/insights_dashboard_page.dart';

/// Featured Home entry for the Insights dashboard. Deliberately styled as a
/// gradient banner so it reads as analytics, not as another report list tile.
class InsightsEntryCard extends StatelessWidget {
  const InsightsEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Accessibility Insights. See problem hotspots and trends.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InsightsDashboardPage(),
              ),
            );
          },
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF117A8B), Color(0xFF1B4F8F)],
              ),
              border: Border.all(color: AppTheme.aqua.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.teal.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF7CFFB2),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'LIVE MAP',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Accessibility Insights',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 20,
                                ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Problem hotspots, trends and live conditions',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppTheme.textPrimary,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
