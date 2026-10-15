// Stores accessibility, display, language, and voice choices.
enum AppLanguage { english, sinhala }

// Holds settings that guide how the app looks and recommends travel.
class AccessibilityPreferences {
  final bool stepFreeRoutes;
  final bool lowCrowding;
  final bool prioritySeating;
  final bool accessibilityAlerts;
  final bool highContrast;
  final double textScale;
  final AppLanguage language;
  final bool voiceAssistantEnabled;
  final bool voiceScreenNarration;
  final bool voiceSlowSpeech;

  const AccessibilityPreferences({
    this.stepFreeRoutes = true,
    this.lowCrowding = false,
    this.prioritySeating = true,
    this.accessibilityAlerts = true,
    this.highContrast = false,
    this.textScale = 1.0,
    this.language = AppLanguage.english,
    this.voiceAssistantEnabled = true,
    this.voiceScreenNarration = false,
    this.voiceSlowSpeech = false,
  });

  // Converts the settings into fields that can be saved.
  Map<String, dynamic> toMap() => {
        'stepFreeRoutes': stepFreeRoutes,
        'lowCrowding': lowCrowding,
        'prioritySeating': prioritySeating,
        'accessibilityAlerts': accessibilityAlerts,
        'highContrast': highContrast,
        'textScale': textScale,
        'language': language.name,
        'voiceAssistantEnabled': voiceAssistantEnabled,
        'voiceScreenNarration': voiceScreenNarration,
        'voiceSlowSpeech': voiceSlowSpeech,
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
      voiceAssistantEnabled: map['voiceAssistantEnabled'] ?? true,
      voiceScreenNarration: map['voiceScreenNarration'] ?? false,
      voiceSlowSpeech: map['voiceSlowSpeech'] ?? false,
    );
  }

  AccessibilityPreferences copyWith({
    bool? stepFreeRoutes,
    bool? lowCrowding,
    bool? prioritySeating,
    bool? accessibilityAlerts,
    bool? highContrast,
    double? textScale,
    AppLanguage? language,
    bool? voiceAssistantEnabled,
    bool? voiceScreenNarration,
    bool? voiceSlowSpeech,
  }) {
    return AccessibilityPreferences(
      stepFreeRoutes: stepFreeRoutes ?? this.stepFreeRoutes,
      lowCrowding: lowCrowding ?? this.lowCrowding,
      prioritySeating: prioritySeating ?? this.prioritySeating,
      accessibilityAlerts: accessibilityAlerts ?? this.accessibilityAlerts,
      highContrast: highContrast ?? this.highContrast,
      textScale: textScale ?? this.textScale,
      language: language ?? this.language,
      voiceAssistantEnabled:
          voiceAssistantEnabled ?? this.voiceAssistantEnabled,
      voiceScreenNarration:
          voiceScreenNarration ?? this.voiceScreenNarration,
      voiceSlowSpeech: voiceSlowSpeech ?? this.voiceSlowSpeech,
    );
  }
}