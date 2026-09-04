import 'package:flutter/material.dart';

import '../models/route_recommendation.dart';

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
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF176B7A),
            Color(0xFF254B6D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF43E0D2),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43E0D2).withOpacity(0.14),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF7FF7EA),
              ),
              const SizedBox(width: 8),
              const Text(
                'RECOMMENDED FOR YOU',
                style: TextStyle(
                  color: Color(0xFF7FF7EA),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C263E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recommendation.matchScore}% match',
                  style: const TextStyle(
                    color: Color(0xFF7FF7EA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${route.transportType} ${route.routeNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${route.durationMinutes} min • ${route.transfers == 0 ? 'Direct route' : '${route.transfers} transfer(s)'}',
            style: const TextStyle(
              color: Color(0xFFD0DFEA),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Why this route suits you',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...recommendation.reasons.take(3).map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF7FF7EA),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        color: Color(0xFFE4F1F7),
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