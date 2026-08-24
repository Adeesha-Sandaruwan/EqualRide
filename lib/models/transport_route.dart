class TransportRoute {
  const TransportRoute({
    required this.id,
    required this.routeNumber,
    required this.transportType,
    required this.durationMinutes,
    required this.transfers,
    required this.isStepFree,
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
  final String crowding;
  final int accessibilityScore;
  final String description;
}