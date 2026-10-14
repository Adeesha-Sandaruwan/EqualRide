// File: live_hotspot_map.dart
//
// Live OpenStreetMap view of report hotspots: colour-coded numbered pins
// (red/orange/yellow/teal/blue/green), pulsing LIVE badge, scope and time
// filters, legend with counts and a tap-for-details bottom sheet.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/community_report.dart';
import '../../../theme/app_theme.dart';
import '../models/geo_report.dart';
import '../services/hotspot_clusterer.dart';
import '../services/insights_calculator.dart';
import '../services/place_name_resolver.dart';
import '../services/report_geo_resolver.dart';
import 'insight_palette.dart';

/// Live map of accessibility hotspots. It shows aggregated heat zones, not
/// individual reports, so it stays distinct from the Community Reports list.
class LiveHotspotMap extends StatefulWidget {
  const LiveHotspotMap({
    super.key,
    required this.reports,
    this.lastUpdated,
    this.expanded = false,
    this.onExpand,
    this.resolver,
    this.places,
    this.showTiles = true,
  });

  final List<CommunityReport> reports;
  final DateTime? lastUpdated;

  /// Full-screen mode: the map can be panned and zoomed.
  final bool expanded;
  final VoidCallback? onExpand;
  final ReportGeoResolver? resolver;

  /// Shared place-name lookup. A private one is created when omitted.
  final PlaceNameResolver? places;

  /// Disabled in tests so no network tiles are requested.
  final bool showTiles;

  @override
  State<LiveHotspotMap> createState() => _LiveHotspotMapState();
}

class _LiveHotspotMapState extends State<LiveHotspotMap> {
  static const _sriLanka = LatLng(7.8731, 80.7718);

  late final ReportGeoResolver _resolver =
      widget.resolver ?? ReportGeoResolver();
  late final PlaceNameResolver _places =
      widget.places ?? (_ownedPlaces = PlaceNameResolver());
  PlaceNameResolver? _ownedPlaces;
  final MapController _controller = MapController();

  List<GeoReport> _resolved = const [];
  MapFilter _filter = const MapFilter();
  bool _mapReady = false;
  bool _fitted = false;
  bool _resolving = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant LiveHotspotMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reports, widget.reports)) _resolve();
  }

  @override
  void dispose() {
    _generation++;
    _ownedPlaces?.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final generation = ++_generation;
    final reports = widget.reports;

    setState(() {
      _resolved = reports.map(_resolver.resolveLocal).toList();
      _resolving = true;
    });
    _fitIfNeeded();

    try {
      final cached = await _resolver.resolveAll(reports, useNetwork: false);
      if (!mounted || generation != _generation) return;
      setState(() => _resolved = cached);
      _fitIfNeeded();

      final full = await _resolver.resolveAll(reports);
      if (!mounted || generation != _generation) return;
      setState(() => _resolved = full);
      _fitIfNeeded();
    } catch (_) {
      // Offline or lookup failure: keep what was resolved locally.
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _resolving = false);
      }
    }
  }

  List<HotspotCluster> _clusters(DateTime now) =>
      HotspotClusterer.cluster(_resolved, filter: _filter, now: now);

  void _fitIfNeeded() {
    if (_fitted || !_mapReady) return;
    final clusters = _clusters(DateTime.now());
    if (clusters.isEmpty) return;
    _fitted = true;
    _recentre(clusters);
  }

  void _recentre(List<HotspotCluster> clusters) {
    if (!_mapReady || clusters.isEmpty) return;
    final points = clusters
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();
    if (points.length == 1) {
      _controller.move(points.first, 14);
      return;
    }
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 15,
      ),
    );
  }

  void _setFilter(MapFilter filter) {
    setState(() => _filter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recentre(_clusters(DateTime.now()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final clusters = _clusters(now);
    final accepted = widget.reports.where((r) => _filter.accepts(r, now));
    final mappedCount = clusters.fold<int>(0, (s, c) => s + c.count);
    final unmapped = accepted.length - mappedCount;
    final legendCounts = <Color, int>{};
    for (final c in clusters) {
      for (final r in c.reports) {
        final color = _colorForReport(r);
        legendCounts[color] = (legendCounts[color] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(filter: _filter, onChanged: _setFilter),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: widget.expanded ? 460 : 340,
            child: Stack(
              children: [
                _buildMap(clusters),
                const Positioned(left: 12, top: 12, child: _LiveBadge()),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Fit hotspots',
                        onPressed: () => _recentre(clusters),
                      ),
                      if (!widget.expanded && widget.onExpand != null) ...[
                        const SizedBox(height: 8),
                        _MapButton(
                          icon: Icons.fullscreen_rounded,
                          tooltip: 'Open full map',
                          onPressed: widget.onExpand!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_resolving)
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: _Chip(text: 'Locating reports…'),
                  ),
                if (clusters.isEmpty && !_resolving)
                  const Center(
                    child: _Chip(text: 'No hotspots match these filters'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Legend(counts: legendCounts),
        const SizedBox(height: 6),
        Text(
          _footer(unmapped),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  String _footer(int unmapped) {
    final updated = widget.lastUpdated;
    final parts = <String>[
      if (updated != null) 'Updated ${_clock(updated)}',
      if (unmapped > 0)
        '$unmapped report${unmapped == 1 ? '' : 's'} could not be placed on the map',
    ];
    return parts.join(' · ');
  }

  static String _clock(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMap(List<HotspotCluster> clusters) {
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: _sriLanka,
        initialZoom: 7,
        minZoom: 5,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          // Embedded maps stay static so the page can still scroll.
          flags: widget.expanded ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onMapReady: () {
          _mapReady = true;
          _fitIfNeeded();
        },
      ),
      children: [
        if (widget.showTiles)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.equal_drive',
          ),
        CircleLayer(
          circles: [
            for (final c in clusters)
              CircleMarker(
                point: LatLng(c.latitude, c.longitude),
                radius: _heatRadiusMetres(c),
                useRadiusInMeter: true,
                color: _colorFor(c).withValues(alpha: 0.22),
                borderColor: _colorFor(c).withValues(alpha: 0.6),
                borderStrokeWidth: 1.5,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final c in clusters)
              Marker(
                point: LatLng(c.latitude, c.longitude),
                width: 44,
                height: 44,
                child: _ClusterPin(
                  cluster: c,
                  color: _colorFor(c),
                  onTap: () => _showCluster(c),
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  static double _heatRadiusMetres(HotspotCluster c) =>
      350 + (c.openSeverity.clamp(0, 12) * 60).toDouble();

  static Color _colorFor(HotspotCluster c) {
    if (c.openSeverity == 0) return InsightPalette.good;
    if (c.allInProgress) return InsightPalette.inProgress;
    switch (c.maxWeight) {
      case 4:
        return InsightPalette.critical;
      case 3:
        return InsightPalette.high;
      case 2:
        return InsightPalette.moderate;
      default:
        return _lowColor;
    }
  }

  static const _lowColor = Color(0xFF4DD0E1);

  /// Colour of a single report, used for the legend counts.
  static Color _colorForReport(CommunityReport r) {
    final bucket = InsightsCalculator.bucketOf(r.status);
    if (bucket == ReportBucket.resolved) return InsightPalette.good;
    if (bucket == ReportBucket.inProgress) return InsightPalette.inProgress;
    switch (InsightsCalculator.severityWeight(r.impactLevel)) {
      case 4:
        return InsightPalette.critical;
      case 3:
        return InsightPalette.high;
      case 2:
        return InsightPalette.moderate;
      default:
        return _lowColor;
    }
  }

  void _showCluster(HotspotCluster cluster) {
    unawaited(_places.resolve([cluster.label]));
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF10202B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClusterSheet(
        cluster: cluster,
        color: _colorFor(cluster),
        places: _places,
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final MapFilter filter;
  final ValueChanged<MapFilter> onChanged;

  static const _windows = {
    MapWindow.all: 'All time',
    MapWindow.last24h: '24 h',
    MapWindow.last7d: '7 days',
    MapWindow.last30d: '30 days',
  };
  static const _scopes = {
    MapScope.all: 'All',
    MapScope.bus: 'Bus',
    MapScope.road: 'Road',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in _windows.entries)
            _FilterChip(
              label: e.value,
              selected: filter.window == e.key,
              onTap: () => onChanged(filter.copyWith(window: e.key)),
            ),
          const SizedBox(width: 8),
          for (final e in _scopes.entries)
            _FilterChip(
              label: e.value,
              selected: filter.scope == e.key,
              onTap: () => onChanged(filter.copyWith(scope: e.key)),
            ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Critical only',
            selected: filter.criticalOnly,
            onTap: () =>
                onChanged(filter.copyWith(criticalOnly: !filter.criticalOnly)),
          ),
          _FilterChip(
            label: 'Include resolved',
            selected: filter.includeResolved,
            onTap: () => onChanged(
              filter.copyWith(includeResolved: !filter.includeResolved),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: AppTheme.teal.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClusterPin extends StatelessWidget {
  const _ClusterPin({
    required this.cluster,
    required this.color,
    required this.onTap,
  });

  final HotspotCluster cluster;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${cluster.label}, ${cluster.count} reports',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
          ),
          alignment: Alignment.center,
          child: Text(
            '${cluster.count}',
            style: const TextStyle(
              color: Color(0xFF10202B),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClusterSheet extends StatelessWidget {
  const _ClusterSheet({
    required this.cluster,
    required this.color,
    required this.places,
  });

  final HotspotCluster cluster;
  final Color color;
  final PlaceNameResolver places;

  @override
  Widget build(BuildContext context) {
    final open = cluster.reports
        .where((r) => r.status.trim().toLowerCase() != 'resolved')
        .length;
    final latest = cluster.latest;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ListenableBuilder(
                    listenable: places,
                    builder: (_, _) => Text(
                      places.display(cluster.label),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SheetRow(label: 'Reports in this area', value: '${cluster.count}'),
            _SheetRow(label: 'Still open', value: '$open'),
            _SheetRow(label: 'Most common issue', value: cluster.topIssue),
            _SheetRow(
              label: 'Severity score',
              value: '${cluster.openSeverity}',
            ),
            if (latest != null)
              _SheetRow(label: 'Latest report', value: _ago(latest)),
          ],
        ),
      ),
    );
  }

  static String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${diff.inDays} d ago';
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
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

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Live data',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xCC10202B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.3, end: 1).animate(_pulse),
              child: const Icon(
                Icons.circle,
                size: 10,
                color: Color(0xFFFF4D4D),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC10202B),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xDD10202B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.counts});

  final Map<Color, int> counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Critical', InsightPalette.critical),
      ('High', InsightPalette.high),
      ('Moderate', InsightPalette.moderate),
      ('Low', _LiveHotspotMapState._lowColor),
      ('In progress', InsightPalette.inProgress),
      ('Resolved', InsightPalette.good),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '$label (${counts[color] ?? 0})',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
