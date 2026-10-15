import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/accessibility_preferences.dart';

void main() {
  // An empty saved map restores the normal English defaults.
  test('defaults to English when no language is stored', () {
    final preferences = AccessibilityPreferences.fromMap({});

    expect(preferences.language, AppLanguage.english);
  });

  // Saved language and text size are restored together.
  test('restores Sinhala from saved preferences', () {
    final preferences = AccessibilityPreferences.fromMap({
      'language': 'sinhala',
      'textScale': 1.2,
    });

    expect(preferences.language, AppLanguage.sinhala);
    expect(preferences.textScale, 1.2);
  });

  // The selected language is saved using its simple name.
  test('stores selected language in Firestore map data', () {
    const preferences = AccessibilityPreferences(
      language: AppLanguage.sinhala,
    );

    expect(preferences.toMap()['language'], 'sinhala');
  });

  // Missing values should use the model normal accessibility defaults.
  test('uses defaults for missing accessibility and voice choices', () {
    final preferences = AccessibilityPreferences.fromMap({});

    expect(preferences.stepFreeRoutes, isTrue);
    expect(preferences.lowCrowding, isFalse);
    expect(preferences.voiceAssistantEnabled, isTrue);
    expect(preferences.voiceScreenNarration, isFalse);
  });

  // Numeric text scales saved as integers should still load as doubles.
  test('converts a saved integer text scale to a double', () {
    final preferences = AccessibilityPreferences.fromMap({'textScale': 2});

    expect(preferences.textScale, 2.0);
  });

  // Changing one choice should keep all the other current choices.
  test('copyWith changes one preference and keeps the others', () {
    const preferences = AccessibilityPreferences(lowCrowding: true, highContrast: true);

    final updated = preferences.copyWith(lowCrowding: false);

    expect(updated.lowCrowding, isFalse);
    expect(updated.highContrast, isTrue);
  });
}
