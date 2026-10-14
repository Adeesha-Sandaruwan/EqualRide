// File: insights_dashboard_page.dart
//
// Insights dashboard screen (reached from the Home banner). Shows the
// headline, KPI cards, trend chart, top issues, problem hotspots with place
// names, the live map preview and the share action. Read-only: it never
// writes reports.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/community_report.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/equal_ride_background.dart';
import '../../../models/accessibility_preferences.dart';
import '../models/insight_summary.dart';
import '../services/insight_headline.dart';
import '../services/insights_calculator.dart';
import '../services/insights_service.dart';
import '../services/insights_strings.dart';
import '../services/place_name_resolver.dart';
import '../widgets/hotspot_list.dart';
import '../widgets/insight_palette.dart';
import '../widgets/insight_states.dart';
import '../widgets/issue_bar_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/live_hotspot_map.dart';
import 'insights_map_page.dart';
import '../widgets/range_selector.dart';
import '../widgets/share_summary_sheet.dart';
import '../widgets/trend_chart.dart';

/// Analytics view of accessibility conditions. Unlike Community Reports it
/// shows no individual reports: only totals, trends and ranked hotspots.
class InsightsDashboardPage extends StatefulWidget {
  const InsightsDashboardPage({
    super.key,
    this.service,
    this.places,
    this.language = AppLanguage.english,
  });

  final AppLanguage language;

  /// Injectable for tests. Defaults to the live Firestore-backed service.
  final InsightsService? service;

  /// Injectable for tests. Defaults to the live place-name lookup.
  final PlaceNameResolver? places;

  @override
  State<InsightsDashboardPage> createState() => _InsightsDashboardPageState();
}

class _InsightsDashboardPageState extends State<InsightsDashboardPage> {
  late final InsightsService _service = widget.service ?? InsightsService();
  late final PlaceNameResolver _places =
      widget.places ?? (_ownedPlaces = PlaceNameResolver());
  PlaceNameResolver? _ownedPlaces;
  String _lastLookupKey = '';

  StreamSubscription<List<CommunityReport>>? _subscription;
  List<CommunityReport>? _reports;
  DateTime? _updatedAt;
  Object? _error;
  InsightRange _range = InsightRange.days30;

  @override
  void initState() {
    super.initState();
    _places.addListener(_onPlacesChanged);
    _subscribe();
  }

  void _onPlacesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _places.removeListener(_onPlacesChanged);
    _ownedPlaces?.dispose();
    super.dispose();
  }

  void _subscribe() {
    _subscription?.cancel();
    if (_error != null) setState(() => _error = null);

    _subscription = _service.watchReports().listen(
      (reports) {
        if (!mounted) return;
        setState(() {
          _reports = reports;
          _updatedAt = DateTime.now();
          _error = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _error = error);
      },
    );
  }

  Future<void> _refresh() async {
    _subscribe();
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  /// Names the coordinate-only hotspots. Runs once per distinct set of labels.
  void _lookUpPlaceNames(InsightSummary summary) {
    final labels = summary.topHotspots.map((e) => e.label).toList();
    final key = labels.join('|');
    if (key == _lastLookupKey) return;
    _lastLookupKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_places.resolve(labels));
    });
  }

  String _t(String key, [Map<String, Object> params = const {}]) =>
      InsightsStrings.text(widget.language, key, params);

  InsightSummary? get _summary {
    final reports = _reports;
    if (reports == null || reports.isEmpty) return null;
    return InsightsCalculator.summarize(reports, range: _range);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: RefreshIndicator(
                color: AppTheme.teal,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    _Header(
                      title: _t('title'),
                      backLabel: _t('back'),
                      shareLabel: _t('share'),
                      onBack: () => Navigator.of(context).maybePop(),
                      onShare: _summary == null
                          ? null
                          : () => showShareSummarySheet(
                              context,
                              summary: _summary!,
                              language: widget.language,
                              nameOf: _places.display,
                            ),
                    ),
                    const SizedBox(height: 16),
                    ..._body(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    final reports = _reports;

    if (reports == null && _error != null) {
      return [
        InsightsErrorState(message: _error.toString(), onRetry: _subscribe),
      ];
    }
    if (reports == null) return const [InsightsSkeleton()];
    if (reports.isEmpty) return const [InsightsEmptyState()];

    final summary = InsightsCalculator.summarize(reports, range: _range);
    final backlogDays = oldestOpenDays(summary);
    _lookUpPlaceNames(summary);

    return [
      if (_error != null) ...[const _StaleBanner(), const SizedBox(height: 12)],
      _HeadlinePanel(
        text: buildInsightHeadline(summary, language: widget.language),
      ),
      const SizedBox(height: 16),
      RangeSelector(
        selected: _range,
        onChanged: (range) => setState(() => _range = range),
      ),
      const SizedBox(height: 20),
      _SectionTitle(_t('overview')),
      const SizedBox(height: 12),
      _KpiGrid(
        children: [
          KpiCard(
            icon: Icons.flag_rounded,
            label: _t('totalReports'),
            value: summary.totalReports,
            caption: _t('busRoad', {
              'bus': summary.busCount,
              'road': summary.roadCount,
            }),
          ),
          KpiCard(
            icon: Icons.check_circle_rounded,
            label: _t('resolved'),
            value: summary.resolutionRate * 100,
            suffix: '%',
            caption: _t('resolvedCount', {'n': summary.resolvedCount}),
            accent: InsightPalette.good,
          ),
          KpiCard(
            icon: Icons.priority_high_rounded,
            label: _t('criticalOpen'),
            value: summary.criticalOpenCount,
            caption: _t('blockAccess'),
            accent: InsightPalette.critical,
          ),
          KpiCard(
            icon: Icons.schedule_rounded,
            label: _t('oldestOpen'),
            value: backlogDays ?? 0,
            suffix: backlogDays == null ? '' : ' d',
            caption: backlogDays == null ? _t('nothingOpen') : _t('backlogAge'),
            accent: InsightPalette.moderate,
          ),
        ],
      ),
      const SizedBox(height: 24),
      _SectionTitle(_t('liveMapTitle')),
      const SizedBox(height: 12),
      LiveHotspotMap(
        reports: reports,
        lastUpdated: _updatedAt,
        places: _places,
        onExpand: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                InsightsMapPage(service: widget.service, places: _places),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _SectionTitle(_t('topIssues')),
      const SizedBox(height: 12),
      IssueBarChart(entries: summary.topIssueTypes),
      const SizedBox(height: 24),
      _SectionTitle(_t('hotspots')),
      const SizedBox(height: 4),
      Text(
        _t('hotspotsHint'),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      const SizedBox(height: 12),
      HotspotList(entries: summary.topHotspots, nameOf: _places.display),
      const SizedBox(height: 24),
      _SectionTitle(_t('trend')),
      const SizedBox(height: 12),
      TrendChart(points: summary.trend),
      const SizedBox(height: 12),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.backLabel,
    required this.shareLabel,
    required this.onBack,
    required this.onShare,
  });

  final String title;
  final String backLabel;
  final String shareLabel;
  final VoidCallback onBack;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: backLabel,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        IconButton(
          tooltip: shareLabel,
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
    );
  }
}

class _HeadlinePanel extends StatelessWidget {
  const _HeadlinePanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF117A8B), Color(0xFF1B4F8F)],
        ),
        border: Border.all(color: AppTheme.aqua.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_graph_rounded, color: AppTheme.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InsightPalette.moderate.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: InsightPalette.moderate.withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: InsightPalette.moderate),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connection problem. Showing the last data received.',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// Two-column grid that keeps cards in a row the same height.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}
