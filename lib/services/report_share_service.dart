import '../models/community_report.dart';

/// Builds a plain-text summary of a [CommunityReport] suitable for
/// sharing via the platform share sheet (e.g. share_plus).
///
/// Kept as a pure function with no Flutter dependency so it can be tested
/// without a widget tree.
class ReportShareService {
  const ReportShareService._();

  /// Returns a formatted text block that can be passed to
  /// `Share.share()` from the share_plus package.
  ///
  /// Example output:
  /// ```
  /// 🚌 EqualRide Community Report
  ///
  /// Issue: Ramp unavailable
  /// Category: On the bus
  /// Location: Bus 138 – Colombo Fort to Kaduwela
  /// Status: Pending
  /// Impact: Critical
  ///
  /// "The wheelchair ramp could not be deployed."
  /// ```
  static String buildShareText(CommunityReport report) {
    final categoryLabel =
        report.category == 'bus' ? 'On the bus' : 'Station / road';

    final buffer = StringBuffer()
      ..writeln('🚌 EqualRide Community Report')
      ..writeln()
      ..writeln('Issue: ${report.issueType}')
      ..writeln('Category: $categoryLabel')
      ..writeln('Location: ${report.location}');

    if (report.busNumber != null && report.busNumber!.isNotEmpty) {
      buffer.writeln('Bus: ${report.busNumber}');
    }

    buffer
      ..writeln('Status: ${report.status}')
      ..writeln('Impact: ${report.impactLevel}');

    if (report.description.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('"${report.description}"');
    }

    buffer
      ..writeln()
      ..writeln('Reported via EqualRide — accessible transport for everyone.');

    return buffer.toString().trimRight();
  }

  /// Returns a short one-line summary, useful for notification previews.
  static String buildShortSummary(CommunityReport report) {
    return '${report.issueType} at ${report.location} [${report.status}]';
  }
}
