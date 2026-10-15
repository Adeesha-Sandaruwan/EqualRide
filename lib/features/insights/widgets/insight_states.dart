// File: insight_states.dart
//
// Loading skeleton, error and empty states shown by the Insights dashboard.

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/glass_panel.dart';

/// Pulsing grey blocks shown while the first data loads.
class InsightsSkeleton extends StatefulWidget {
  const InsightsSkeleton({super.key});

  @override
  State<InsightsSkeleton> createState() => _InsightsSkeletonState();
}

class _InsightsSkeletonState extends State<InsightsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading insights',
      liveRegion: true,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final alpha = 0.08 + 0.08 * _controller.value;
          Widget block(double height) => Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: alpha),
              borderRadius: BorderRadius.circular(20),
            ),
          );

          return Column(
            children: [
              block(56),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: block(130)),
                  const SizedBox(width: 12),
                  Expanded(child: block(130)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: block(130)),
                  const SizedBox(width: 12),
                  Expanded(child: block(130)),
                ],
              ),
              const SizedBox(height: 16),
              block(220),
            ],
          );
        },
      ),
    );
  }
}

/// Shown when the report stream fails.
class InsightsErrorState extends StatelessWidget {
  const InsightsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFFF8B8B),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load insights',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

/// Shown when there are no reports at all.
class InsightsEmptyState extends StatelessWidget {
  const InsightsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          const Icon(Icons.insights_rounded, color: AppTheme.teal, size: 44),
          const SizedBox(height: 12),
          Text(
            'No data to analyse yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Insights appear as soon as commuters start reporting '
            'accessibility conditions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
