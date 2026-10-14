import '../models/community_report.dart';
import 'report_sort_order.dart';

/// Holds the current filter + sort state for the community-reports list.
///
/// Immutable — call [copyWith] to produce a new state, then rebuild the UI.
/// Extracted from the page widget so the same logic can be reused or tested
/// without a widget tree.
class ReportFilterState {
  const ReportFilterState({
    this.statusFilter,
    this.searchQuery = '',
    this.sortOrder = ReportSortOrder.newest,
  });

  /// Selected status, or null to show all.
  final String? statusFilter;

  /// Active search query. Empty string means no search.
  final String searchQuery;

  /// How the visible list should be ordered.
  final ReportSortOrder sortOrder;

  /// Returns true when no filter or search is active (shows all, default order).
  bool get isDefault =>
      statusFilter == null &&
      searchQuery.isEmpty &&
      sortOrder == ReportSortOrder.newest;

  /// Applies this filter state to [reports] and returns the filtered,
  /// searched, and sorted result (does not mutate the original list).
  List<CommunityReport> apply(List<CommunityReport> reports) {
    var result = reports.toList();

    // Status filter
    if (statusFilter != null) {
      result = result.where((r) => r.status == statusFilter).toList();
    }

    // Search filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (r) =>
                r.issueType.toLowerCase().contains(q) ||
                r.location.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort
    return sortReports(result, sortOrder);
  }

  ReportFilterState copyWith({
    String? statusFilter,
    bool clearStatusFilter = false,
    String? searchQuery,
    ReportSortOrder? sortOrder,
  }) {
    return ReportFilterState(
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportFilterState &&
          statusFilter == other.statusFilter &&
          searchQuery == other.searchQuery &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode =>
      Object.hash(statusFilter, searchQuery, sortOrder);
}
