import 'package:flutter/material.dart';

import '../models/route_recommendation.dart';
import '../theme/app_theme.dart';

class RouteRecommendationCard extends StatelessWidget {
  const RouteRecommendationCard({
    super.key,
    required this.recommendation,
  });

  final RouteRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final route = recommendation.route;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF176B7A), Color(0xFF254B6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.teal, width: 1.2),
      ),
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
          const SizedBox(height: 16),
          Text(
            '${route.transportType} ${route.routeNumber}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${route.durationMinutes} min • '
            '${route.transfers == 0 ? 'Direct route' : '${route.transfers} transfer(s)'}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Why this route suits you',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...recommendation.reasons.take(3).map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.aqua,
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
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
        color: AppTheme.navy.withOpacity(0.65),
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