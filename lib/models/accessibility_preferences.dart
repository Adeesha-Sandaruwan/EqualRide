enum AppLanguage { english, sinhala }

class AccessibilityPreferences {
  final bool stepFreeRoutes;
  final bool lowCrowding;
  final bool prioritySeating;
  final bool accessibilityAlerts;
  final bool highContrast;
  final double textScale;
  final AppLanguage language;

  const AccessibilityPreferences({
    this.stepFreeRoutes = true,
    this.lowCrowding = false,
    this.prioritySeating = true,
    this.accessibilityAlerts = true,
    this.highContrast = false,
    this.textScale = 1.0,
    this.language = AppLanguage.english,
  });

  Map<String, dynamic> toMap() => {
        'stepFreeRoutes': stepFreeRoutes,
        'lowCrowding': lowCrowding,
        'prioritySeating': prioritySeating,
        'accessibilityAlerts': accessibilityAlerts,
        'highContrast': highContrast,
        'textScale': textScale,
        'language': language.name,
      };

  factory AccessibilityPreferences.fromMap(Map<String, dynamic> map) {
    final scale = map['textScale'];

    return AccessibilityPreferences(
      stepFreeRoutes: map['stepFreeRoutes'] ?? true,
      lowCrowding: map['lowCrowding'] ?? false,
      prioritySeating: map['prioritySeating'] ?? true,
      accessibilityAlerts: map['accessibilityAlerts'] ?? true,
      highContrast: map['highContrast'] ?? false,
      textScale: scale is num ? scale.toDouble() : 1.0,
      language: map['language'] == 'sinhala'
          ? AppLanguage.sinhala
          : AppLanguage.english,
    );
  }
}