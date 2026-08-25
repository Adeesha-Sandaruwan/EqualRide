import 'package:flutter/material.dart';

import '../data/demo_routes.dart';
import '../models/transport_route.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class RouteResultsPage extends StatefulWidget {
  const RouteResultsPage({
    super.key,
    required this.from,
    required this.destination,
  });

  final String from;
  final String destination;

  @override
  State<RouteResultsPage> createState() => _RouteResultsPageState();
}

class _RouteResultsPageState extends State<RouteResultsPage> {
  RouteSort selectedSort = RouteSort.fastest;

  List<TransportRoute> get sortedRoutes {
    final routes = [...DemoRoutes.routes];

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

  @override
  Widget build(BuildContext context) {
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
                        'Route results',
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Demo route data — a verified public-transport data source will replace this later.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'Fastest',
                        selected: selectedSort == RouteSort.fastest,
                        onTap: () {
                          setState(() => selectedSort = RouteSort.fastest);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: 'Accessible',
                        selected: selectedSort == RouteSort.accessible,
                        onTap: () {
                          setState(() => selectedSort = RouteSort.accessible);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: 'Fewest',
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
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: sortedRoutes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final route = sortedRoutes[index];

                    return _RouteCard(
                      route: route,
                      isRecommended:
                          selectedSort == RouteSort.accessible && index == 0,
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

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isRecommended,
  });

  final TransportRoute route;
  final bool isRecommended;

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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'MOST ACCESSIBLE',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
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
                icon: Icons.swap_horiz_rounded,
                label: '${route.transfers} transfers',
                color: AppTheme.aqua,
              ),
            ],
          ),
        ],
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