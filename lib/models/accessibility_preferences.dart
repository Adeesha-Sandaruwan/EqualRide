class AccessibilityPreferences {
  final bool stepFreeRoutes;
  final bool lowCrowding;
  final bool prioritySeating;
  final bool accessibilityAlerts;

  const AccessibilityPreferences({
    this.stepFreeRoutes = true,
    this.lowCrowding = false,
    this.prioritySeating = true,
    this.accessibilityAlerts = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepFreeRoutes': stepFreeRoutes,
      'lowCrowding': lowCrowding,
      'prioritySeating': prioritySeating,
      'accessibilityAlerts': accessibilityAlerts,
    };
  }

  factory AccessibilityPreferences.fromMap(Map<String, dynamic> map) {
    return AccessibilityPreferences(
      stepFreeRoutes: map['stepFreeRoutes'] ?? true,
      lowCrowding: map['lowCrowding'] ?? false,
      prioritySeating: map['prioritySeating'] ?? true,
      accessibilityAlerts: map['accessibilityAlerts'] ?? true,
    );
  }
}