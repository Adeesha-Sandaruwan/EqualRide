import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single accessibility report from the community.
class CommunityReport {
  static const defaultImpactLevel = 'Moderate';

  static const impactLevelDescriptions = {
    'Low': 'Causes minor difficulty but access remains possible.',
    'Moderate': 'Causes significant difficulty or delays.',
    'High': 'Severely limits independent access.',
    'Critical': 'Blocks access completely or leaves no safe alternative.',
  };

  const CommunityReport({
    required this.id,
    required this.issueType,
    required this.description,
    required this.location,
    required this.authorId,
    this.createdAt,
    this.status = 'Pending',
    this.upvoteCount = 0,
    this.busNumber,
    this.category = 'bus',
    this.impactLevel = defaultImpactLevel,
    this.reporterName,
    this.incidentPhotoBase64,
  });

  final String id;
  final String issueType;
  final String description;
  final String location;
  final String authorId;
  final DateTime? createdAt;
  final String status;

  /// Number of users who marked this report as helpful.
  final int upvoteCount;

  /// Optional bus route number (e.g. "138") — only set for on-bus reports.
  final String? busNumber;

  /// 'bus' for on-bus reports, 'road' for station/road reports.
  final String category;

  // ── Firestore deserialization ────────────────────────────────────────────
  final String impactLevel;

  /// Optional display name of the person who filed the report.
  /// Populated from the user's profile at submission time, if available.
  final String? reporterName;

  // ── Convenience helpers ──────────────────────────────────────────────────

  /// Returns true if [userId] is the author of this report.
  bool isAuthoredBy(String? userId) => userId != null && userId == authorId;

  /// Returns true when this report is still awaiting action.
  bool get isPending => status == 'Pending';

  /// Returns true when this report has been resolved.
  bool get isResolved => status == 'Resolved';

  /// Optional incident photo, stored as plain base64 (JPEG).
  final String? incidentPhotoBase64;

  /// Creates a [CommunityReport] from a Firestore document snapshot.
  factory CommunityReport.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;

    return CommunityReport(
      id: doc.id,
      issueType: data['issueType'] as String? ?? 'Other',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? 'Unknown location',
      authorId: data['authorId'] as String? ?? '',
      createdAt: timestamp?.toDate(),
      status: data['status'] as String? ?? 'Pending',
      upvoteCount: (data['upvoteCount'] as num?)?.toInt() ?? 0,
      busNumber: data['busNumber'] as String?,
      category: data['category'] as String? ?? 'bus',
      impactLevel: impactLevelDescriptions.containsKey(data['impactLevel'])
          ? data['impactLevel'] as String
          : defaultImpactLevel,
      reporterName: data['reporterName'] as String?,
      incidentPhotoBase64: _nonEmpty(data['incidentPhotoBase64']),
    );
  }

  static String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  // ── Firestore serialization ──────────────────────────────────────────────

  /// Converts this report to a plain map suitable for writing to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'issueType': issueType,
      'description': description,
      'location': location,
      'authorId': authorId,
      'status': status,
      'upvoteCount': upvoteCount,
      'impactLevel': impactLevel,
      if (busNumber != null && busNumber!.isNotEmpty) 'busNumber': busNumber,
      'category': category,
      if (reporterName != null && reporterName!.isNotEmpty)
        'reporterName': reporterName,
      if (incidentPhotoBase64 != null && incidentPhotoBase64!.isNotEmpty)
        'incidentPhotoBase64': incidentPhotoBase64,
      // createdAt is intentionally omitted — callers use FieldValue.serverTimestamp()
    };
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  /// Returns a copy of this report with the specified fields replaced.
  CommunityReport copyWith({
    String? id,
    String? issueType,
    String? description,
    String? location,
    String? authorId,
    DateTime? createdAt,
    String? status,
    int? upvoteCount,
    String? busNumber,
    String? category,
    String? impactLevel,
    String? reporterName,
    String? incidentPhotoBase64,
  }) {
    return CommunityReport(
      id: id ?? this.id,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      location: location ?? this.location,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      busNumber: busNumber ?? this.busNumber,
      category: category ?? this.category,
      impactLevel: impactLevel ?? this.impactLevel,
      reporterName: reporterName ?? this.reporterName,
      incidentPhotoBase64: incidentPhotoBase64 ?? this.incidentPhotoBase64,
    );
  }

  // ── Equality ─────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityReport &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommunityReport(id: $id, issueType: $issueType, status: $status, upvotes: $upvoteCount)';
}
