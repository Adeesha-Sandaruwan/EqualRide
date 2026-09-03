import 'transport_route.dart';

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