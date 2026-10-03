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
    this.impactLevel = defaultImpactLevel,
  });

  final String id;
  final String issueType;
  final String description;
  final String location;
  final String authorId;
  final DateTime? createdAt;
  final String status;
  final String impactLevel;

  /// Creates a [CommunityReport] from a Firestore document snapshot.
  factory CommunityReport.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
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
      impactLevel: impactLevelDescriptions.containsKey(data['impactLevel'])
          ? data['impactLevel'] as String
          : defaultImpactLevel,
    );
  }
}
