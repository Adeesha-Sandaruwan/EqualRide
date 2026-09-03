import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/community_report.dart';

class AccessibilityReportException implements Exception {
  const AccessibilityReportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Classifies the root cause of a Firestore failure so the UI can show
/// a targeted message rather than a generic error.
enum ReportStreamErrorKind { permissionDenied, missingIndex, network, unknown }

ReportStreamErrorKind _classifyFirebaseError(FirebaseException e) {
  // PERMISSION_DENIED → security-rules block
  if (e.code == 'permission-denied') return ReportStreamErrorKind.permissionDenied;

  // The missing-index error arrives as code 'failed-precondition' and its
  // message contains a console URL the user can click to create the index.
  if (e.code == 'failed-precondition') return ReportStreamErrorKind.missingIndex;

  // Unavailable / deadline-exceeded → connectivity problems
  if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
    return ReportStreamErrorKind.network;
  }

  return ReportStreamErrorKind.unknown;
}

class AccessibilityReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('accessibility_reports');

  /// Real-time stream of community reports, newest first.
  ///
  /// Strategy:
  ///   1. Try the ordered query (requires a Firestore index on `createdAt`).
  ///   2. If that fails with a missing-index / failed-precondition error,
  ///      automatically fall back to an unordered query sorted client-side.
  ///      This keeps the feed working while the index is being built.
  ///   3. All other Firestore errors are wrapped in a typed
  ///      [AccessibilityReportException] so the UI can show a specific message.
  Stream<List<CommunityReport>> getReportsStream() {
    // Use a StreamController so we can swap streams at runtime when the
    // ordered query fails with a missing-index error.
    late StreamController<List<CommunityReport>> controller;
    StreamSubscription<List<CommunityReport>>? sub;

    void subscribeToFallback() {
      sub = _fallbackStream().listen(
        controller.add,
        onError: (Object err) {
          if (err is FirebaseException) {
            controller.addError(
              AccessibilityReportException(_friendlyMessage(err)),
            );
          } else {
            controller.addError(err);
          }
        },
        onDone: controller.close,
      );
    }

    void subscribeToOrdered() {
      sub = _orderedStream().listen(
        controller.add,
        onError: (Object err) {
          if (err is FirebaseException) {
            final kind = _classifyFirebaseError(err);
            if (kind == ReportStreamErrorKind.missingIndex) {
              // Cancel the broken ordered subscription and switch to fallback.
              sub?.cancel();
              subscribeToFallback();
              return;
            }
            controller.addError(
              AccessibilityReportException(_friendlyMessage(err)),
            );
          } else {
            controller.addError(err);
          }
        },
        onDone: controller.close,
      );
    }

    controller = StreamController<List<CommunityReport>>(
      onListen: subscribeToOrdered,
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  /// Ordered query — requires a Firestore index on `createdAt`.
  Stream<List<CommunityReport>> _orderedStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  /// Fallback unordered query, sorted in memory. Works without an index.
  Stream<List<CommunityReport>> _fallbackStream() {
    return _collection.snapshots().map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => CommunityReport.fromSnapshot(doc))
          .toList();

      // Sort newest-first client-side (nulls go to the end).
      reports.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return reports;
    });
  }

  List<CommunityReport> _mapDocs(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((doc) => CommunityReport.fromSnapshot(doc))
        .toList();
  }

  String _friendlyMessage(FirebaseException e) {
    switch (_classifyFirebaseError(e)) {
      case ReportStreamErrorKind.permissionDenied:
        return 'permission-denied';
      case ReportStreamErrorKind.missingIndex:
        return 'missing-index';
      case ReportStreamErrorKind.network:
        return 'network';
      default:
        return e.message ?? 'unknown';
    }
  }

  // ── Write operations ──────────────────────────────────────────────────────

  /// Issue types users can choose when filing a community report.
  static const List<String> issueTypes = [
    // On-bus issues
    'Ramp unavailable',
    'Wheelchair space blocked',
    'Broken seat or handrail',
    'No audio announcements',
    'Bus overcrowding',
    'Unsafe driving',
    'Driver behaviour',
    // Station / road issues
    'Lift unavailable',
    'Step-free access issue',
    'Damaged pavement / road',
    'Missing tactile paving',
    'Blocked pedestrian path',
    'Poor lighting',
    // Accessibility info
    'Wheelchair access',
    'Accessibility information incorrect',
    'Crowding',
    'Other',
  ];

  /// Cycles the status of a report: Pending → In Progress → Resolved → Pending.
  Future<void> updateReportStatus({
    required String reportId,
    required String newStatus,
  }) async {
    try {
      await _collection.doc(reportId).update({'status': newStatus});
    } on FirebaseException catch (e) {
      throw AccessibilityReportException(
        _classifyFirebaseError(e) == ReportStreamErrorKind.permissionDenied
            ? 'You don\'t have permission to update this report.'
            : 'Could not update the report status. Please try again.',
      );
    }
  }

  /// Submits a community report from the report form.
  /// [busNumber] is optional – only relevant for on-bus reports.
  Future<void> submitCommunityReport({
    required String issueType,
    required String description,
    required String location,
    String? busNumber,
  }) async {
    final authorId = FirebaseAuth.instance.currentUser?.uid;

    if (authorId == null) {
      throw const AccessibilityReportException(
        'You must be signed in to submit a report.',
      );
    }

    try {
      await _collection.add({
        'issueType': issueType,
        'description': description,
        'location': location,
        if (busNumber != null && busNumber.trim().isNotEmpty)
          'busNumber': busNumber.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': authorId,
        'status': 'Pending',
      });
    } on FirebaseException catch (e) {
      throw AccessibilityReportException(
        _classifyFirebaseError(e) == ReportStreamErrorKind.permissionDenied
            ? 'You don\'t have permission to submit reports. Please sign in again.'
            : 'We could not submit your report. Please try again.',
      );
    }
  }

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
      await _collection.add({
        'issueType': issueType,
        'description': description,
        'location': location,
        'createdAt': FieldValue.serverTimestamp(),
        'authorId': authorId,
        'status': 'Pending',
      });
    } on FirebaseException catch (e) {
      throw AccessibilityReportException(
        _classifyFirebaseError(e) == ReportStreamErrorKind.permissionDenied
            ? 'You don\'t have permission to submit reports. Please sign in again.'
            : 'We could not submit your report. Please try again.',
      );
    }
  }

  /// Seeds the Firestore collection with realistic demo reports.
  /// Only used to populate sample data for demonstration purposes.
  Future<void> seedDemoReports() async {
    final authorId = FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';
    final now = DateTime.now();

    final demoReports = [
      {
        'issueType': 'Ramp unavailable',
        'description':
            'The wheelchair ramp on Bus 138 is broken and cannot be deployed. The driver had to manually assist passengers. This has been an ongoing issue for the past week.',
        'location': 'Bus 138 - Colombo Fort to Kaduwela',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 10))),
        'authorId': authorId,
        'status': 'Pending',
      },
      {
        'issueType': 'Lift unavailable',
        'description':
            'The main elevator at Maradana Railway Station is out of service. Wheelchair users have no way to access Platform 3 and 4. A sign says "Under maintenance" but no timeline is given.',
        'location': 'Maradana Railway Station',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        'authorId': authorId,
        'status': 'Resolved',
      },
      {
        'issueType': 'Wheelchair access',
        'description':
            'The designated wheelchair space on the Colombo-Kandy intercity express was blocked with luggage. Staff did not assist in clearing the space.',
        'location': 'Colombo-Kandy Intercity Express',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 3))),
        'authorId': authorId,
        'status': 'In Progress',
      },
      {
        'issueType': 'Step-free access issue',
        'description':
            'The step-free route from the main entrance to Platform 1 at Fort Station has a broken tactile paving section near the ticket counter.',
        'location': 'Colombo Fort Railway Station',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
        'authorId': authorId,
        'status': 'Pending',
      },
      {
        'issueType': 'Crowding',
        'description':
            'Bus stop near University of Moratuwa is severely overcrowded during peak hours (7-8 AM). No accessible queuing system for mobility-impaired passengers.',
        'location': 'Bus Stop - University of Moratuwa',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'authorId': authorId,
        'status': 'Pending',
      },
      {
        'issueType': 'Accessibility information incorrect',
        'description':
            'The EqualRide app shows Bambalapitiya Station as fully accessible, but the ramp from street level to the platform is too steep for most wheelchair users.',
        'location': 'Bambalapitiya Railway Station',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'authorId': authorId,
        'status': 'In Progress',
      },
      {
        'issueType': 'Ramp unavailable',
        'description':
            'Multiple buses on route 100 (Colombo-Galle) have non-functional ramps. Checked 3 buses today and none had working ramps.',
        'location': 'Bus Route 100 - Colombo to Galle',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'authorId': authorId,
        'status': 'Resolved',
      },
    ];

    try {
      final batch = _firestore.batch();
      for (final report in demoReports) {
        batch.set(_collection.doc(), report);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw AccessibilityReportException(
        _classifyFirebaseError(e) == ReportStreamErrorKind.permissionDenied
            ? 'Permission denied — check your Firestore security rules.'
            : 'Could not write demo data. Please try again.',
      );
    }
  }
}
