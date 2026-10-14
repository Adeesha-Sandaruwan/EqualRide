import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/community_report.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/equal_ride_background.dart';
import '../../../widgets/glass_panel.dart';
import '../models/insight_summary.dart';
import '../services/insight_headline.dart';
import '../services/insights_calculator.dart';
import '../services/insights_service.dart';
import '../widgets/hotspot_list.dart';
import '../widgets/insight_palette.dart';
import '../widgets/insight_states.dart';
import '../widgets/issue_bar_chart.dart';
import '../widgets/kpi_card.dart';
import '../widgets/range_selector.dart';
import '../widgets/trend_chart.dart';

/// Analytics view of accessibility conditions. Unlike Community Reports it
/// shows no individual reports: only totals, trends and ranked hotspots.
class InsightsDashboardPage extends StatefulWidget {
  const InsightsDashboardPage({super.key, this.service});

  /// Injectable for tests. Defaults to the live Firestore-backed service.
  final InsightsService? service;

  @override
  State<InsightsDashboardPage> createState() => _InsightsDashboardPageState();
}

class _InsightsDashboardPageState extends State<InsightsDashboardPage> {
  late final InsightsService _service = widget.service ?? InsightsService();

  StreamSubscription<List<CommunityReport>>? _subscription;
  List<CommunityReport>? _reports;
  Object? _error;
  InsightRange _range = InsightRange.days30;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _subscription?.cancel();
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
                    _Header(onBack: () => Navigator.of(context).maybePop()),
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

    return [
      if (_error != null) ...[
        const _StaleBanner(),
        const SizedBox(height: 12),
      ],
      _HeadlinePanel(text: buildInsightHeadline(summary)),
      const SizedBox(height: 16),
      RangeSelector(
        selected: _range,
        onChanged: (range) => setState(() => _range = range),
      ),
      const SizedBox(height: 20),
      const _SectionTitle('Overview'),
      const SizedBox(height: 12),
      _KpiGrid(
        children: [
          KpiCard(
            icon: Icons.flag_rounded,
            label: 'Total reports',
            value: summary.totalReports,
            caption: '${summary.busCount} bus · ${summary.roadCount} road',
          ),
          KpiCard(
            icon: Icons.check_circle_rounded,
            label: 'Resolved',
            value: summary.resolutionRate * 100,
            suffix: '%',
            caption: '${summary.resolvedCount} resolved',
            accent: InsightPalette.good,
          ),
          KpiCard(
            icon: Icons.priority_high_rounded,
            label: 'Critical open',
            value: summary.criticalOpenCount,
            caption: 'Block access fully',
            accent: InsightPalette.critical,
          ),
          KpiCard(
            icon: Icons.schedule_rounded,
            label: 'Oldest open',
            value: backlogDays ?? 0,
            suffix: backlogDays == null ? '' : ' d',
            caption: backlogDays == null ? 'Nothing open' : 'Backlog age',
            accent: InsightPalette.moderate,
          ),
        ],
      ),
      const SizedBox(height: 24),
      const _SectionTitle('Live hotspot map'),
      const SizedBox(height: 12),
      const _MapPlaceholder(),
      const SizedBox(height: 24),
      const _SectionTitle('Most reported issues'),
      const SizedBox(height: 12),
      IssueBarChart(entries: summary.topIssueTypes),
      const SizedBox(height: 24),
      const _SectionTitle('Problem hotspots'),
      const SizedBox(height: 4),
      const Text(
        'Routes and places ranked by the severity of open problems.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
      const SizedBox(height: 12),
      HotspotList(entries: summary.topHotspots),
      const SizedBox(height: 24),
      const _SectionTitle('Trend'),
      const SizedBox(height: 12),
      TrendChart(points: summary.trend),
      const SizedBox(height: 12),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Accessibility Insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
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

/// Reserved space for the live map added in the next step.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const GlassPanel(
      child: Column(
        children: [
          Icon(Icons.map_rounded, color: AppTheme.teal, size: 40),
          SizedBox(height: 12),
          Text(
            'Hotspot map coming next',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Live accessibility conditions will appear here as '
            'colour-coded hotspots.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
