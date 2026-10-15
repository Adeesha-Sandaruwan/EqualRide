// Holds transport and accessibility details for one route.
// Represents one bus, train, or other transport option.
class TransportRoute {
  const TransportRoute({
    required this.id,
    required this.routeNumber,
    required this.transportType,
    required this.durationMinutes,
    required this.transfers,
    required this.isStepFree,
    this.hasPrioritySeating = false,
    required this.crowding,
    required this.accessibilityScore,
    required this.description,
  });

  final String id;
  final String routeNumber;
  final String transportType;
  final int durationMinutes;
  final int transfers;
  final bool isStepFree;
  final bool hasPrioritySeating;
  final String crowding;
  final int accessibilityScore;
  final String description;
}