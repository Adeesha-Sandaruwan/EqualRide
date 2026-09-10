import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/accessibility_preferences.dart';

void main() {
  test('defaults to English when no language is stored', () {
    final preferences = AccessibilityPreferences.fromMap({});

    expect(preferences.language, AppLanguage.english);
  });

  test('restores Sinhala from saved preferences', () {
    final preferences = AccessibilityPreferences.fromMap({
      'language': 'sinhala',
      'textScale': 1.2,
    });

    expect(preferences.language, AppLanguage.sinhala);
    expect(preferences.textScale, 1.2);
  });

  test('stores selected language in Firestore map data', () {
    const preferences = AccessibilityPreferences(
      language: AppLanguage.sinhala,
    );

    expect(preferences.toMap()['language'], 'sinhala');
  });
}
