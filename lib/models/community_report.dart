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
    );
  }

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
      if (busNumber != null && busNumber!.isNotEmpty) 'busNumber': busNumber,
      'category': category,
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
