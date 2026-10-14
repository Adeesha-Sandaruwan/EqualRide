import '../models/community_report.dart';

/// Defines the available sort orders for the community-reports list.
enum ReportSortOrder {
  /// Newest reports first (default).
  newest,

  /// Oldest reports first.
  oldest,

  /// Reports with the most helpful-votes first.
  mostUpvoted,

  /// Critical → High → Moderate → Low impact level order.
  highestImpact,
}

/// Human-readable label for each [ReportSortOrder] value.
extension ReportSortOrderLabel on ReportSortOrder {
  String get label {
    switch (this) {
      case ReportSortOrder.newest:
        return 'Newest first';
      case ReportSortOrder.oldest:
        return 'Oldest first';
      case ReportSortOrder.mostUpvoted:
        return 'Most helpful';
      case ReportSortOrder.highestImpact:
        return 'Highest impact';
    }
  }
}

/// Sorts [reports] in-place according to [order] and returns the same list.
List<CommunityReport> sortReports(
  List<CommunityReport> reports,
  ReportSortOrder order,
) {
  switch (order) {
    case ReportSortOrder.newest:
      reports.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
    case ReportSortOrder.oldest:
      reports.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return a.createdAt!.compareTo(b.createdAt!);
      });
    case ReportSortOrder.mostUpvoted:
      reports.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
    case ReportSortOrder.highestImpact:
      const order = ['Critical', 'High', 'Moderate', 'Low'];
      reports.sort((a, b) {
        final ai = order.indexOf(a.impactLevel);
        final bi = order.indexOf(b.impactLevel);
        // Unknown values go to end
        return (ai == -1 ? order.length : ai)
            .compareTo(bi == -1 ? order.length : bi);
      });
  }
  return reports;
}
