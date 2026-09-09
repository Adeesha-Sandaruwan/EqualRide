class AccessibilityPreferences {
  final bool stepFreeRoutes;
  final bool lowCrowding;
  final bool prioritySeating;
  final bool accessibilityAlerts;
  final bool highContrast;
  final double textScale;

  const AccessibilityPreferences({
    this.stepFreeRoutes = true,
    this.lowCrowding = false,
    this.prioritySeating = true,
    this.accessibilityAlerts = true,
    this.highContrast = false,
    this.textScale = 1.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepFreeRoutes': stepFreeRoutes,
      'lowCrowding': lowCrowding,
      'prioritySeating': prioritySeating,
      'accessibilityAlerts': accessibilityAlerts,
      'highContrast': highContrast,
      'textScale': textScale,
    };
  }

  factory AccessibilityPreferences.fromMap(Map<String, dynamic> map) {
    final savedTextScale = map['textScale'];

    return AccessibilityPreferences(
      stepFreeRoutes: map['stepFreeRoutes'] ?? true,
      lowCrowding: map['lowCrowding'] ?? false,
      prioritySeating: map['prioritySeating'] ?? true,
      accessibilityAlerts: map['accessibilityAlerts'] ?? true,
      highContrast: map['highContrast'] ?? false,
      textScale: savedTextScale is num
          ? savedTextScale.toDouble()
          : 1.0,
    );
  }
}