import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/equal_ride_background.dart';
import '../../../widgets/glass_panel.dart';

/// Insights dashboard shell. Data, charts and the live map are added in
/// later steps; this page only provides the layout and states.
class InsightsDashboardPage extends StatelessWidget {
  const InsightsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Accessibility Insights',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'A city-wide view of accessibility conditions, built from '
                'what commuters report.',
                style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Overview'),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(child: _KpiPlaceholder(icon: Icons.flag_rounded)),
                  SizedBox(width: 12),
                  Expanded(
                    child: _KpiPlaceholder(icon: Icons.check_circle_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Expanded(
                    child: _KpiPlaceholder(icon: Icons.priority_high_rounded),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _KpiPlaceholder(icon: Icons.schedule_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Live hotspot map'),
              const SizedBox(height: 12),
              const _ComingSoonPanel(
                icon: Icons.map_rounded,
                title: 'Hotspot map',
                message: 'Live accessibility conditions will appear here as '
                    'colour-coded hotspots.',
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Trends'),
              const SizedBox(height: 12),
              const _ComingSoonPanel(
                icon: Icons.show_chart_rounded,
                title: 'Trends and top issues',
                message: 'Charts for the most common problems and the routes '
                    'that need attention most.',
              ),
            ],
          ),
        ),
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

class _KpiPlaceholder extends StatelessWidget {
  const _KpiPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.aqua, size: 22),
            const SizedBox(height: 14),
            _bar(width: 56, height: 22),
            const SizedBox(height: 8),
            _bar(width: 84, height: 10),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.teal, size: 40),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
