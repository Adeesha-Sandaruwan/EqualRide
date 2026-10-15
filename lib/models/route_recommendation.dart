// Pairs a route with its score and matching reasons.
import 'transport_route.dart';

// Stores a route, its match score, and explanation.
class RouteRecommendation {
  const RouteRecommendation({
    required this.route,
    required this.matchScore,
    required this.reasons,
  });

  final TransportRoute route;
  final int matchScore;
  final List<String> reasons;
}