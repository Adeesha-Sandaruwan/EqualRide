import 'package:flutter_test/flutter_test.dart';

import 'package:equal_drive/models/community_report.dart';
import 'package:equal_drive/utils/report_sort_order.dart';

CommunityReport _makeReport({
  required String id,
  required String status,
  required int upvoteCount,
  required String impactLevel,
  DateTime? createdAt,
}) {
  return CommunityReport(
    id: id,
    issueType: 'Ramp unavailable',
    description: 'Test report description for testing purposes.',
    location: 'Test Location',
    authorId: 'user_1',
    status: status,
    upvoteCount: upvoteCount,
    impactLevel: impactLevel,
    createdAt: createdAt,
  );
}

void main() {
  final older = DateTime(2024, 1, 1);
  final newer = DateTime(2024, 6, 1);

  final reports = [
    _makeReport(
      id: 'a',
      status: 'Pending',
      upvoteCount: 5,
      impactLevel: 'Low',
      createdAt: older,
    ),
    _makeReport(
      id: 'b',
      status: 'Resolved',
      upvoteCount: 20,
      impactLevel: 'Critical',
      createdAt: newer,
    ),
    _makeReport(
      id: 'c',
      status: 'In Progress',
      upvoteCount: 10,
      impactLevel: 'High',
      createdAt: null, // no timestamp
    ),
  ];

  test('newest first puts newer date before older', () {
    final sorted = sortReports([...reports], ReportSortOrder.newest);
    expect(sorted.first.id, 'b');
    // Reports without a date are placed last.
    expect(sorted.last.id, 'c');
    expect(
      sorted.indexWhere((r) => r.id == 'b'),
      lessThan(sorted.indexWhere((r) => r.id == 'a')),
    );
  });

  test('oldest first puts older date before newer', () {
    final sorted = sortReports([...reports], ReportSortOrder.oldest);
    expect(sorted.first.id, 'a');
    expect(sorted[1].id, 'b');
    // null createdAt goes to end
    expect(sorted.last.id, 'c');
  });

  test('mostUpvoted puts highest upvoteCount first', () {
    final sorted = sortReports([...reports], ReportSortOrder.mostUpvoted);
    expect(sorted.first.id, 'b'); // 20 votes
    expect(sorted[1].id, 'c'); // 10 votes
    expect(sorted.last.id, 'a'); // 5 votes
  });

  test('highestImpact puts Critical before High before Low', () {
    final sorted = sortReports([...reports], ReportSortOrder.highestImpact);
    expect(sorted.first.id, 'b'); // Critical
    expect(sorted[1].id, 'c'); // High
    expect(sorted.last.id, 'a'); // Low
  });

  test('label extension returns non-empty strings', () {
    for (final order in ReportSortOrder.values) {
      expect(order.label.isNotEmpty, isTrue);
    }
  });
}
