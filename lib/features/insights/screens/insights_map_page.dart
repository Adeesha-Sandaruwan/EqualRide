import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/community_report.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/equal_ride_background.dart';
import '../services/insights_service.dart';
import '../services/place_name_resolver.dart';
import '../widgets/insight_states.dart';
import '../widgets/live_hotspot_map.dart';

/// Full-screen, pannable version of the live hotspot map.
class InsightsMapPage extends StatefulWidget {
  const InsightsMapPage({super.key, this.service, this.places});

  final InsightsService? service;

  /// Shared with the dashboard so names found there are reused.
  final PlaceNameResolver? places;

  @override
  State<InsightsMapPage> createState() => _InsightsMapPageState();
}

class _InsightsMapPageState extends State<InsightsMapPage> {
  late final InsightsService _service = widget.service ?? InsightsService();

  StreamSubscription<List<CommunityReport>>? _subscription;
  List<CommunityReport>? _reports;
  DateTime? _updated;
  Object? _error;

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
    setState(() => _error = null);
    _subscription = _service.watchReports().listen(
      (reports) {
        if (!mounted) return;
        setState(() {
          _reports = reports;
          _updated = DateTime.now();
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports;

    Widget body;
    if (reports == null && _error != null) {
      body = InsightsErrorState(message: _error.toString(), onRetry: _subscribe);
    } else if (reports == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = LiveHotspotMap(
        reports: reports,
        lastUpdated: _updated,
        expanded: true,
        places: widget.places,
      );
    }

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Live hotspot map',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  body,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
