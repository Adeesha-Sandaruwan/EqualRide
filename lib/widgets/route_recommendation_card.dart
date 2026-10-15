// Shows a recommended route and why it was selected.
import 'package:flutter/material.dart';

import '../models/route_recommendation.dart';
import '../theme/app_theme.dart';

// Presents route details and recommendation reasons.
class RouteRecommendationCard extends StatelessWidget {
  const RouteRecommendationCard({
    super.key,
    required this.recommendation,
    this.onViewRoute,
    this.onToggleComparison,
    this.isSelectedForComparison = false,
  });

  final RouteRecommendation recommendation;
  final VoidCallback? onViewRoute;
  final VoidCallback? onToggleComparison;
  final bool isSelectedForComparison;

  @override
  Widget build(BuildContext context) {
    final route = recommendation.route;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF135B68), Color(0xFF1D3E5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.teal, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onViewRoute,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.aqua),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'RECOMMENDED FOR YOU',
                        style: TextStyle(
                          color: AppTheme.aqua,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _MatchBadge(score: recommendation.matchScore),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.teal.withValues(alpha: 0.50),
                        ),
                      ),
                      child: Icon(
                        route.transportType == 'Train'
                            ? Icons.train_rounded
                            : Icons.directions_bus_rounded,
                        color: AppTheme.teal,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${route.transportType} ${route.routeNumber}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${route.durationMinutes} min • '
                            '${route.transfers == 0 ? 'Direct route' : '${route.transfers} transfer(s)'}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.teal.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Score',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${route.accessibilityScore}',
                            style: const TextStyle(
                              color: AppTheme.teal,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Quick Accessibility Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (route.isStepFree)
                      _MiniTag(
                        icon: Icons.accessible_forward_rounded,
                        label: 'Step-free',
                        color: AppTheme.teal,
                      ),
                    if (route.hasPrioritySeating)
                      _MiniTag(
                        icon: Icons.event_seat_rounded,
                        label: 'Priority Seat',
                        color: AppTheme.aqua,
                      ),
                    _MiniTag(
                      icon: Icons.groups_rounded,
                      label: '${route.crowding} Crowd',
                      color: route.crowding == 'Low'
                          ? AppTheme.teal
                          : const Color(0xFFFFC46B),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Why this route suits you',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...recommendation.reasons.take(3).map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.aqua,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: onViewRoute,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.teal,
                          foregroundColor: AppTheme.navy,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text(
                          'View Route Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (onToggleComparison != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: onToggleComparison,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isSelectedForComparison
                                  ? AppTheme.aqua
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                            backgroundColor: isSelectedForComparison
                                ? AppTheme.aqua.withValues(alpha: 0.18)
                                : Colors.transparent,
                            foregroundColor: isSelectedForComparison
                                ? AppTheme.aqua
                                : AppTheme.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            isSelectedForComparison
                                ? Icons.check_rounded
                                : Icons.compare_arrows_rounded,
                            size: 16,
                          ),
                          label: Text(
                            isSelectedForComparison ? 'Selected' : 'Compare',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$score% match',
        style: const TextStyle(
          color: AppTheme.aqua,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}