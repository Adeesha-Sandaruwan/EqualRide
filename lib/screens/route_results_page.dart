import 'dart:async';
import 'package:flutter/material.dart';

import '../data/demo_route_details.dart';
import '../data/demo_routes.dart';
import '../localization/app_strings.dart';
import '../models/accessibility_preferences.dart';
import '../models/community_report.dart';
import '../models/route_recommendation.dart';
import '../models/transport_route.dart';
import '../services/accessibility_report_service.dart';
import '../services/route_recommendation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';
import '../widgets/route_recommendation_card.dart';
import 'route_details_page.dart';

class RouteResultsPage extends StatefulWidget {
  const RouteResultsPage({
    super.key,
    required this.from,
    required this.destination,
    required this.preferences,
  });

  final String from;
  final String destination;
  final AccessibilityPreferences preferences;

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  RouteSort selectedSort = RouteSort.fastest;
  final recommendationService = RouteRecommendationService();
  final reportService = AccessibilityReportService();
  final Set<String> comparisonRouteIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Quick accessibility filters
  bool _filterStepFreeOnly = false;
  bool _filterLowCrowdingOnly = false;
  bool _filterDirectOnly = false;

  StreamSubscription<List<CommunityReport>>? _reportsSubscription;
  List<CommunityReport> _reports = [];

  final List<CommunityReport> _fallbackReports = [
    CommunityReport(
      id: 'alert-1',
      issueType: 'Ramp unavailable',
      impactLevel: 'Critical',
      description:
          'Wheelchair ramp on Bus 138 is reported broken and out of order.',
      location: 'Bus 138 - Colombo to Kaduwela',
      authorId: 'system',
      busNumber: '138',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    CommunityReport(
      id: 'alert-2',
      issueType: 'Lift unavailable',
      impactLevel: 'High',
      description:
          'Elevator at Platform 2 undergoing maintenance. Step-free ramp available on East wing.',
      location: 'Line A Metro Central',
      authorId: 'system',
      busNumber: 'Line A',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reports = List.from(_fallbackReports);
    _reportsSubscription = reportService.getReportsStream().listen(
      (reports) {
        if (mounted && reports.isNotEmpty) {
          setState(() {
            _reports = reports;
          });
        }
      },
      onError: (_) {
        // Fallback reports maintained
      },
    );
  }

  @override
  void dispose() {
    _reportsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityReport> _getAlertsForRoute(TransportRoute route) {
    return _reports.where((report) {
      final routeNum = route.routeNumber.toLowerCase().trim();
      final busNum = report.busNumber?.toLowerCase().trim();
      if (busNum != null && busNum == routeNum) return true;
      final loc = report.location.toLowerCase();
      final desc = report.description.toLowerCase();
      return loc.contains('bus $routeNum') ||
          loc.contains('route $routeNum') ||
          desc.contains('bus $routeNum') ||
          desc.contains('route $routeNum');
    }).toList();
  }

  bool _matchesRoute(TransportRoute route, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    final title = '${route.transportType} ${route.routeNumber}'.toLowerCase();
    final reverseTitle =
        '${route.routeNumber} ${route.transportType}'.toLowerCase();
    final id = route.id.toLowerCase();
    final number = route.routeNumber.toLowerCase();
    final type = route.transportType.toLowerCase();
    final desc = route.description.toLowerCase();
    final crowding = route.crowding.toLowerCase();

    // Direct match check (e.g. "bus 360", "360", "line a")
    if (title.contains(clean) ||
        reverseTitle.contains(clean) ||
        id.contains(clean) ||
        number.contains(clean) ||
        type.contains(clean) ||
        desc.contains(clean)) {
      return true;
    }

    // Normalized alphanumeric match (e.g. "bus360", "bus-360")
    final cleanAlpha = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final titleAlpha = title.replaceAll(RegExp(r'[^a-z0-9]'), '');
    final idAlpha = id.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (cleanAlpha.isNotEmpty &&
        (titleAlpha.contains(cleanAlpha) || idAlpha.contains(cleanAlpha))) {
      return true;
    }

    // Multi-token match (e.g. "bus" and "360" in separate words)
    final tokens =
        clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      final combined =
          '$title $id $desc $crowding ${route.isStepFree ? "step free" : ""}';
      if (tokens.every((token) => combined.contains(token))) {
        return true;
      }
    }

    return false;
  }

  List<RouteRecommendation> get recommendations {
    return recommendationService.rankRoutes(
      routes: DemoRoutes.routes,
      preferences: widget.preferences,
    );
  }

  bool get hasRoutePreferences {
    return widget.preferences.stepFreeRoutes ||
        widget.preferences.lowCrowding ||
        widget.preferences.prioritySeating;
  }

  RouteRecommendation? get recommendedRoute {
    if (_searchQuery.trim().isNotEmpty) return null;
    if (!hasRoutePreferences) return null;
    return recommendations.firstOrNull;
  }

  List<TransportRoute> get sortedRoutes {
    var routes = DemoRoutes.routes
        .where((route) => _matchesRoute(route, _searchQuery))
        .toList();

    if (_filterStepFreeOnly) {
      routes = routes.where((r) => r.isStepFree).toList();
    }
    if (_filterLowCrowdingOnly) {
      routes = routes.where((r) => r.crowding == 'Low').toList();
    }
    if (_filterDirectOnly) {
      routes = routes.where((r) => r.transfers == 0).toList();
    }

    switch (selectedSort) {
      case RouteSort.fastest:
        routes.sort(
          (first, second) =>
              first.durationMinutes.compareTo(second.durationMinutes),
        );
      case RouteSort.accessible:
        routes.sort(
          (first, second) =>
              second.accessibilityScore.compareTo(first.accessibilityScore),
        );
      case RouteSort.fewestTransfers:
        routes.sort(
          (first, second) => first.transfers.compareTo(second.transfers),
        );
    }

    return routes;
  }

  void _openRouteDetailsForRoute(BuildContext context, TransportRoute route) {
    final alerts = _getAlertsForRoute(route);
    final details = DemoRouteDetails.getDetailsForRoute(
      route,
      from: widget.from,
      destination: widget.destination,
      activeReports: alerts,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsPage(routeDetails: details),
      ),
    );
  }

  void _toggleComparison(TransportRoute route) {
    setState(() {
      if (comparisonRouteIds.contains(route.id)) {
        comparisonRouteIds.remove(route.id);
        return;
      }

      if (comparisonRouteIds.length == 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose only two routes to compare.'),
          ),
        );
        return;
      }

      comparisonRouteIds.add(route.id);
    });
  }

  void _showComparison() {
    final selectedRoutes = DemoRoutes.routes
        .where((route) => comparisonRouteIds.contains(route.id))
        .toList();

    if (selectedRoutes.length != 2) return;

    final first = selectedRoutes[0];
    final second = selectedRoutes[1];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteComparisonSheet(
        first: first,
        second: second,
        firstAlerts: _getAlertsForRoute(first),
        secondAlerts: _getAlertsForRoute(second),
        onViewFirst: () {
          Navigator.pop(context);
          _openRouteDetailsForRoute(context, first);
        },
        onViewSecond: () {
          Navigator.pop(context);
          _openRouteDetailsForRoute(context, second);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = recommendedRoute;
    final language = widget.preferences.language;
    String t(String key) => AppStrings.text(language, key);

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        t('routeResults'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppTheme.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.from} → ${widget.destination}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t('searchRoutes'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: IconButton(
                              tooltip: t('clearSearch'),
                              icon: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTheme.teal.withValues(alpha: 0.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.teal.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppTheme.teal,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (_searchQuery.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.teal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.directions_bus_rounded,
                              size: 15,
                              color: AppTheme.teal,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${sortedRoutes.length} ${sortedRoutes.length == 1 ? "route" : "routes"} found',
                              style: const TextStyle(
                                color: AppTheme.aqua,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38E5D8), AppTheme.teal],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.teal.withValues(alpha: 0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: AppTheme.navy,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  t('clearSearch'),
                                  style: const TextStyle(
                                    color: AppTheme.navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  t('demoNotice'),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: t('fastest'),
                        selected: selectedSort == RouteSort.fastest,
                        onTap: () {
                          setState(() => selectedSort = RouteSort.fastest);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: t('accessible'),
                        selected: selectedSort == RouteSort.accessible,
                        onTap: () {
                          setState(() => selectedSort = RouteSort.accessible);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: t('fewest'),
                        selected: selectedSort == RouteSort.fewestTransfers,
                        onTap: () {
                          setState(
                            () => selectedSort = RouteSort.fewestTransfers,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Accessibility Quick Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickFilterChip(
                        icon: Icons.accessible_forward_rounded,
                        label: 'Step-Free',
                        isActive: _filterStepFreeOnly,
                        onTap: () => setState(
                            () => _filterStepFreeOnly = !_filterStepFreeOnly),
                      ),
                      const SizedBox(width: 8),
                      _QuickFilterChip(
                        icon: Icons.groups_rounded,
                        label: 'Low Crowd',
                        isActive: _filterLowCrowdingOnly,
                        onTap: () => setState(() =>
                            _filterLowCrowdingOnly = !_filterLowCrowdingOnly),
                      ),
                      const SizedBox(width: 8),
                      _QuickFilterChip(
                        icon: Icons.alt_route_rounded,
                        label: 'Direct Only',
                        isActive: _filterDirectOnly,
                        onTap: () => setState(
                            () => _filterDirectOnly = !_filterDirectOnly),
                      ),
                      if (_reports.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.teal.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: AppTheme.teal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_reports.length} live community reports',
                                style: const TextStyle(
                                  color: AppTheme.teal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (comparisonRouteIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _CompareBar(
                    selectedCount: comparisonRouteIds.length,
                    onClear: () {
                      setState(comparisonRouteIds.clear);
                    },
                    onCompare: comparisonRouteIds.length == 2
                        ? _showComparison
                        : null,
                  ),
                ),
              Expanded(
                child: sortedRoutes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: GlassPanel(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.teal.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: AppTheme.teal,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  t('noRoutesFound'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  t('noRoutesMatch'),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _filterStepFreeOnly = false;
                                      _filterLowCrowdingOnly = false;
                                      _filterDirectOnly = false;
                                    });
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.teal,
                                    foregroundColor: AppTheme.navy,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 6,
                                    shadowColor:
                                        AppTheme.teal.withValues(alpha: 0.45),
                                  ),
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 19),
                                  label: Text(
                                    t('clearSearch'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(30, 18, 30, 30),
                        itemCount: sortedRoutes.length +
                            (recommendation == null ? 0 : 1),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 18),
                        itemBuilder: (context, index) {
                          if (recommendation != null && index == 0) {
                            return RouteRecommendationCard(
                              recommendation: recommendation,
                              isSelectedForComparison: comparisonRouteIds
                                  .contains(recommendation.route.id),
                              onViewRoute: () => _openRouteDetailsForRoute(
                                context,
                                recommendation.route,
                              ),
                              onToggleComparison: () =>
                                  _toggleComparison(recommendation.route),
                            );
                          }

                          final routeIndex =
                              recommendation == null ? index : index - 1;
                          final route = sortedRoutes[routeIndex];
                          final alerts = _getAlertsForRoute(route);

                          return _RouteCard(
                            route: route,
                            alerts: alerts,
                            isRecommended:
                                recommendation?.route.id == route.id,
                            isSelectedForComparison:
                                comparisonRouteIds.contains(route.id),
                            viewRouteLabel: t('viewRoute'),
                            compareLabel: t('compare'),
                            from: widget.from,
                            destination: widget.destination,
                            onViewRoute: () =>
                                _openRouteDetailsForRoute(context, route),
                            onToggleComparison: () =>
                                _toggleComparison(route),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum RouteSort { fastest, accessible, fewestTransfers }

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.teal.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? AppTheme.teal
                  : Colors.white.withValues(alpha: 0.16),
              width: isActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppTheme.teal : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.teal : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.teal : Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.navy : AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.selectedCount,
    required this.onClear,
    required this.onCompare,
  });

  final int selectedCount;
  final VoidCallback onClear;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows_rounded, color: AppTheme.aqua),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$selectedCount of 2 routes selected',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: onCompare,
            child: const Text('Compare'),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isRecommended,
    required this.isSelectedForComparison,
    required this.viewRouteLabel,
    required this.compareLabel,
    required this.onViewRoute,
    required this.onToggleComparison,
    this.alerts = const [],
    this.from,
    this.destination,
  });

  final TransportRoute route;
  final bool isRecommended;
  final bool isSelectedForComparison;
  final String viewRouteLabel;
  final String compareLabel;
  final VoidCallback onViewRoute;
  final VoidCallback onToggleComparison;
  final List<CommunityReport> alerts;
  final String? from;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final transportIcon = route.transportType == 'Train'
        ? Icons.train_rounded
        : Icons.directions_bus_rounded;

    final hasCriticalHazard = alerts.any((a) =>
        a.impactLevel == 'Critical' ||
        a.issueType.contains('Ramp') ||
        a.issueType.contains('Lift'));

    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (alerts.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasCriticalHazard
                        ? const Color(0xFFFF5252).withValues(alpha: 0.20)
                        : const Color(0xFFFFB300).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasCriticalHazard
                          ? const Color(0xFFFF5252)
                          : const Color(0xFFFFB300),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: hasCriticalHazard
                            ? const Color(0xFFFF5252)
                            : const Color(0xFFFFB300),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${alerts.length} Hazard Alert${alerts.length == 1 ? "" : "s"}',
                        style: TextStyle(
                          color: hasCriticalHazard
                              ? const Color(0xFFFF5252)
                              : const Color(0xFFFFB300),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (isRecommended)
                const _TopBadge(label: 'MOST ACCESSIBLE'),
            ],
          ),
          if (isRecommended || alerts.isNotEmpty) const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(transportIcon, color: AppTheme.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${route.transportType} ${route.routeNumber}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '${route.durationMinutes} min',
                style: const TextStyle(
                  color: AppTheme.aqua,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            route.description,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: hasCriticalHazard
                    ? const Color(0xFFFF5252).withValues(alpha: 0.14)
                    : const Color(0xFFFFB300).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasCriticalHazard
                      ? const Color(0xFFFF5252).withValues(alpha: 0.40)
                      : const Color(0xFFFFB300).withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.report_problem_rounded,
                    size: 16,
                    color: hasCriticalHazard
                        ? const Color(0xFFFF5252)
                        : const Color(0xFFFFB300),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Commuter Report: ${alerts.first.issueType} — ${alerts.first.description}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCriticalHazard
                            ? const Color(0xFFFF8B8B)
                            : const Color(0xFFFFD580),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                icon: Icons.accessible_forward_rounded,
                label: route.isStepFree ? 'Step-free' : 'Limited access',
                color: route.isStepFree
                    ? AppTheme.teal
                    : const Color(0xFFFFC46B),
              ),
              _StatusChip(
                icon: Icons.groups_rounded,
                label: 'Crowding: ${route.crowding}',
                color: route.crowding == 'Low'
                    ? AppTheme.teal
                    : const Color(0xFFFFC46B),
              ),
              _StatusChip(
                icon: Icons.event_seat_rounded,
                label: route.hasPrioritySeating
                    ? 'Priority seating'
                    : 'No priority seating',
                color: route.hasPrioritySeating
                    ? AppTheme.aqua
                    : const Color(0xFFFFC46B),
              ),
              _StatusChip(
                icon: Icons.swap_horiz_rounded,
                label: '${route.transfers} transfers',
                color: AppTheme.aqua,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onViewRoute,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.teal,
                    foregroundColor: AppTheme.navy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(
                    viewRouteLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleComparison,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isSelectedForComparison
                          ? AppTheme.aqua
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    backgroundColor: isSelectedForComparison
                        ? AppTheme.aqua.withValues(alpha: 0.18)
                        : Colors.transparent,
                    foregroundColor: isSelectedForComparison
                        ? AppTheme.aqua
                        : AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    isSelectedForComparison
                        ? Icons.check_rounded
                        : Icons.compare_arrows_rounded,
                    size: 17,
                  ),
                  label: Text(
                    isSelectedForComparison ? 'Selected' : compareLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.teal,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.navy,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteComparisonSheet extends StatelessWidget {
  const _RouteComparisonSheet({
    required this.first,
    required this.second,
    this.firstAlerts = const [],
    this.secondAlerts = const [],
    this.onViewFirst,
    this.onViewSecond,
  });

  final TransportRoute first;
  final TransportRoute second;
  final List<CommunityReport> firstAlerts;
  final List<CommunityReport> secondAlerts;
  final VoidCallback? onViewFirst;
  final VoidCallback? onViewSecond;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0F263E),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded,
                    color: AppTheme.aqua, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Accessibility Comparison',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ComparisonRow(
              label: 'Accessibility Score',
              firstValue: '${first.accessibilityScore}/100',
              secondValue: '${second.accessibilityScore}/100',
              highlightBetter: true,
              firstNum: first.accessibilityScore,
              secondNum: second.accessibilityScore,
            ),
            _ComparisonRow(
              label: 'Journey Duration',
              firstValue: '${first.durationMinutes} min',
              secondValue: '${second.durationMinutes} min',
            ),
            _ComparisonRow(
              label: 'Transfers',
              firstValue:
                  first.transfers == 0 ? 'Direct (0)' : '${first.transfers}',
              secondValue:
                  second.transfers == 0 ? 'Direct (0)' : '${second.transfers}',
            ),
            _ComparisonRow(
              label: 'Step-Free Access',
              firstValue: first.isStepFree ? '✓ Step-Free' : '✗ Steps present',
              secondValue:
                  second.isStepFree ? '✓ Step-Free' : '✗ Steps present',
            ),
            _ComparisonRow(
              label: 'Priority Seating',
              firstValue:
                  first.hasPrioritySeating ? '✓ Dedicated' : '✗ Standard',
              secondValue:
                  second.hasPrioritySeating ? '✓ Dedicated' : '✗ Standard',
            ),
            _ComparisonRow(
              label: 'Crowding Level',
              firstValue: first.crowding,
              secondValue: second.crowding,
            ),
            _ComparisonRow(
              label: 'Live Hazards',
              firstValue: firstAlerts.isEmpty
                  ? '0 Alerts'
                  : '${firstAlerts.length} Alert(s)',
              secondValue: secondAlerts.isEmpty
                  ? '0 Alerts'
                  : '${secondAlerts.length} Alert(s)',
              isAlertRow: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onViewFirst,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      foregroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View ${first.routeNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onViewSecond,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.aqua,
                      foregroundColor: AppTheme.navy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View ${second.routeNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.firstValue,
    required this.secondValue,
    this.highlightBetter = false,
    this.firstNum = 0,
    this.secondNum = 0,
    this.isAlertRow = false,
  });

  final String label;
  final String firstValue;
  final String secondValue;
  final bool highlightBetter;
  final int firstNum;
  final int secondNum;
  final bool isAlertRow;

  @override
  Widget build(BuildContext context) {
    Color firstColor = AppTheme.textPrimary;
    Color secondColor = AppTheme.textPrimary;

    if (highlightBetter) {
      if (firstNum > secondNum) {
        firstColor = AppTheme.teal;
      } else if (secondNum > firstNum) {
        secondColor = AppTheme.teal;
      }
    }

    if (isAlertRow) {
      if (firstValue.startsWith('0')) firstColor = AppTheme.teal;
      if (secondValue.startsWith('0')) secondColor = AppTheme.teal;
      if (!firstValue.startsWith('0')) firstColor = const Color(0xFFFFB300);
      if (!secondValue.startsWith('0')) secondColor = const Color(0xFFFFB300);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              firstValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: firstColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              secondValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}