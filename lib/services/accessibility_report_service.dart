import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccessibilityReportException implements Exception {
  const AccessibilityReportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccessibilityReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String issueType,
    required String description,
    required String location,
  }) async {
    final authorId = FirebaseAuth.instance.currentUser?.uid;

    if (authorId == null) {
      throw const AccessibilityReportException(
        'You must be signed in to submit a report.',
      );
    }

    try {
      await _firestore.collection('accessibility_reports').add({
        'issueType': issueType,
        'description': description,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': authorId,
      });
    } on FirebaseException {
      throw const AccessibilityReportException(
        'We could not submit your report. Please try again.',
      );
    }
  }
}