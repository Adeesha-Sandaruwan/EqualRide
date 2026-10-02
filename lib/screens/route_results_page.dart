import 'package:flutter/material.dart';

import '../data/demo_route_details.dart';
import '../data/demo_routes.dart';
import '../localization/app_strings.dart';
import '../models/accessibility_preferences.dart';
import '../models/route_recommendation.dart';
import '../models/transport_route.dart';
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
  final Set<String> comparisonRouteIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesRoute(TransportRoute route, String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;

    final title = '${route.transportType} ${route.routeNumber}'.toLowerCase();
    final reverseTitle = '${route.routeNumber} ${route.transportType}'.toLowerCase();
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
    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.length > 1) {
      final combined = '$title $id $desc $crowding ${route.isStepFree ? "step free" : ""}';
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
    final routes = DemoRoutes.routes
        .where((route) => _matchesRoute(route, _searchQuery))
        .toList();

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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteComparisonSheet(
        first: selectedRoutes[0],
        second: selectedRoutes[1],
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
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            tooltip: t('clearSearch'),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
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
                      Text(
                        '${sortedRoutes.length} ${sortedRoutes.length == 1 ? "route" : "routes"} found',
                        style: const TextStyle(
                          color: AppTheme.aqua,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Text(
                          t('clearSearch'),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
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
                                    color: AppTheme.teal.withOpacity(0.12),
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
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  label: Text(t('clearSearch')),
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
                            );
                          }

                          final routeIndex =
                              recommendation == null ? index : index - 1;
                          final route = sortedRoutes[routeIndex];

                          return _RouteCard(
                            route: route,
                            isRecommended:
                                recommendation?.route.id == route.id,
                            isSelectedForComparison:
                                comparisonRouteIds.contains(route.id),
                            viewRouteLabel: t('viewRoute'),
                            compareLabel: t('compare'),
                            from: widget.from,
                            destination: widget.destination,
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
      color: selected ? AppTheme.teal : Colors.white.withOpacity(0.10),
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
    required this.onToggleComparison,
    this.from,
    this.destination,
  });

  final TransportRoute route;
  final bool isRecommended;
  final bool isSelectedForComparison;
  final String viewRouteLabel;
  final String compareLabel;
  final VoidCallback onToggleComparison;
  final String? from;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final transportIcon = route.transportType == 'Train'
        ? Icons.train_rounded
        : Icons.directions_bus_rounded;

    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRecommended)
            Align(
              alignment: Alignment.centerRight,
              child: _TopBadge(label: 'MOST ACCESSIBLE'),
            ),
          if (isRecommended) const SizedBox(height: 10),
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppTheme.teal.withOpacity(0.16),
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openRouteDetails(context),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(viewRouteLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onToggleComparison,
                  icon: Icon(
                    isSelectedForComparison
                        ? Icons.check_rounded
                        : Icons.compare_arrows_rounded,
                    size: 17,
                  ),
                  label: Text(
                    isSelectedForComparison ? 'Selected' : compareLabel,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openRouteDetails(BuildContext context) {
    final details = DemoRouteDetails.getDetailsForRoute(
      route,
      from: from,
      destination: destination,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteDetailsPage(routeDetails: details),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
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
  });

  final TransportRoute first;
  final TransportRoute second;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF102B47),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.teal.withOpacity(0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows_rounded, color: AppTheme.aqua),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Compare accessible routes',
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
              label: 'Accessibility score',
              firstValue: '${first.accessibilityScore}/100',
              secondValue: '${second.accessibilityScore}/100',
            ),
            _ComparisonRow(
              label: 'Journey time',
              firstValue: '${first.durationMinutes} min',
              secondValue: '${second.durationMinutes} min',
            ),
            _ComparisonRow(
              label: 'Transfers',
              firstValue: '${first.transfers}',
              secondValue: '${second.transfers}',
            ),
            _ComparisonRow(
              label: 'Step-free',
              firstValue: first.isStepFree ? 'Available' : 'Limited',
              secondValue: second.isStepFree ? 'Available' : 'Limited',
            ),
            _ComparisonRow(
              label: 'Priority seating',
              firstValue: first.hasPrioritySeating ? 'Available' : 'Limited',
              secondValue: second.hasPrioritySeating ? 'Available' : 'Limited',
            ),
            _ComparisonRow(
              label: 'Crowding',
              firstValue: first.crowding,
              secondValue: second.crowding,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${first.transportType} ${first.routeNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.aqua,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${second.transportType} ${second.routeNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.aqua,
                      fontWeight: FontWeight.w800,
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
  });

  final String label;
  final String firstValue;
  final String secondValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              firstValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              secondValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}