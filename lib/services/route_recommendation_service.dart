import '../models/accessibility_preferences.dart';
import '../models/route_recommendation.dart';
import '../models/transport_route.dart';

class RouteRecommendationService {
  List<RouteRecommendation> rankRoutes({
    required List<TransportRoute> routes,
    required AccessibilityPreferences preferences,
  }) {
    final recommendations = routes.map((route) {
      var score = route.accessibilityScore;
      final reasons = <String>[];

      if (preferences.stepFreeRoutes) {
        if (route.isStepFree) {
          score += 20;
          reasons.add('Step-free access matches your preference');
        } else {
          score -= 30;
          reasons.add('Limited step-free access');
        }
      }

      if (preferences.lowCrowding) {
        if (route.crowding == 'Low') {
          score += 15;
          reasons.add('Low crowding matches your preference');
        } else if (route.crowding == 'High') {
          score -= 15;
          reasons.add('High crowding may not suit your preference');
        }
      }

      if (route.transfers == 0) {
        score += 10;
        reasons.add('Direct route with no transfers');
      } else if (route.transfers == 1) {
        score += 5;
        reasons.add('Only one transfer required');
      }

      return RouteRecommendation(
        route: route,
        matchScore: score.clamp(0, 100).toInt(),
        reasons: reasons,
      );
    }).toList();

    recommendations.sort(
      (first, second) => second.matchScore.compareTo(first.matchScore),
    );

    return recommendations;
  }
}