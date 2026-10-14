import 'package:flutter_test/flutter_test.dart';

import 'package:equal_ride/models/community_report.dart';
import 'package:equal_ride/services/report_share_service.dart';

void main() {
  final busReport = CommunityReport(
    id: 'r1',
    issueType: 'Ramp unavailable',
    description: 'The wheelchair ramp on Bus 138 could not be deployed.',
    location: 'Bus 138 – Colombo Fort to Kaduwela',
    authorId: 'user_1',
    status: 'Pending',
    upvoteCount: 3,
    busNumber: '138',
    category: 'bus',
    impactLevel: 'Critical',
  );

  final roadReport = CommunityReport(
    id: 'r2',
    issueType: 'Lift unavailable',
    description: 'The lift at Maradana station is out of order.',
    location: 'Maradana Railway Station',
    authorId: 'user_2',
    status: 'In Progress',
    upvoteCount: 8,
    category: 'road',
    impactLevel: 'High',
  );

  group('ReportShareService.buildShareText', () {
    test('includes the EqualRide header', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('EqualRide Community Report'));
    });

    test('includes issue type', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('Ramp unavailable'));
    });

    test('includes bus category label for bus reports', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('On the bus'));
    });

    test('includes station/road category label for road reports', () {
      final text = ReportShareService.buildShareText(roadReport);
      expect(text, contains('Station / road'));
    });

    test('includes bus number when present', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('Bus: 138'));
    });

    test('does not include bus number line when absent', () {
      final text = ReportShareService.buildShareText(roadReport);
      expect(text, isNot(contains('Bus:')));
    });

    test('includes the description in quotes', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('"The wheelchair ramp on Bus 138'));
    });

    test('includes status and impact level', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('Pending'));
      expect(text, contains('Critical'));
    });

    test('ends with the EqualRide tagline', () {
      final text = ReportShareService.buildShareText(busReport);
      expect(text, contains('accessible transport for everyone'));
    });
  });

  group('ReportShareService.buildShortSummary', () {
    test('contains issue type, location and status', () {
      final summary = ReportShareService.buildShortSummary(busReport);
      expect(summary, contains('Ramp unavailable'));
      expect(summary, contains('Colombo Fort'));
      expect(summary, contains('Pending'));
    });

    test('is a single line', () {
      final summary = ReportShareService.buildShortSummary(busReport);
      expect(summary.contains('\n'), isFalse);
    });
  });
}
