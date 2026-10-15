// Saves and loads a user?s preferences in Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/accessibility_preferences.dart';

// Stores each user?s preferences in their Firestore profile.
class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Writes the current preferences into the user profile.
  Future<void> savePreferences({
    required String userId,
    required String email,
    required AccessibilityPreferences preferences,
  }) async {
    await _firestore.collection('users').doc(userId).set(
      {
        'email': email,
        'preferences': preferences.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // Reads saved preferences from the user profile.
  Future<AccessibilityPreferences?> getPreferences(String userId) async {
    final document = await _firestore.collection('users').doc(userId).get();

    final data = document.data();
    final preferences = data?['preferences'];

    if (preferences is Map<String, dynamic>) {
      return AccessibilityPreferences.fromMap(preferences);
    }

    if (preferences is Map) {
      return AccessibilityPreferences.fromMap(
        Map<String, dynamic>.from(preferences),
      );
    }

    return null;
  }
}