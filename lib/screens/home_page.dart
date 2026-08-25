import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';
import 'route_results_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.email,
    required this.preferences,
    required this.onLogout,
    required this.onEditPreferences,
    required this.onReportAccessibilityIssue,
  });

  final String email;
  final AccessibilityPreferences preferences;
  final Future<void> Function() onLogout;
  final VoidCallback onEditPreferences;
  final VoidCallback onReportAccessibilityIssue;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final fromController = TextEditingController(text: 'Current location');
  final destinationController = TextEditingController();

  @override
  void dispose() {
    fromController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void findRoute() {
    final from = fromController.text.trim();
    final destination = destinationController.text.trim();

    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a destination first.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteResultsPage(
          from: from.isEmpty ? 'Current location' : from,
          destination: destination,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.email.split('@').first;

    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.accessible_forward_rounded,
                    color: AppTheme.teal,
                    size: 34,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EqualRide',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                'Where are you\ngoing, $name?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      height: 1.06,
                    ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Find a journey built around your needs.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              GlassPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: fromController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        hintText: 'Your current location',
                        prefixIcon: Icon(Icons.my_location_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: destinationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        hintText: 'Enter destination',
                        prefixIcon: Icon(Icons.location_on_rounded),
                      ),
                      onSubmitted: (_) => findRoute(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: findRoute,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Find route'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your journey settings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppTheme.teal,
                    ),
                  ),
                  title: const Text('Accessibility preferences'),
                  subtitle: Text(
                    widget.preferences.stepFreeRoutes
                        ? 'Step-free routes are prioritised'
                        : 'Customise your travel settings',
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: widget.onEditPreferences,
                ),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  leading: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.aqua.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.report_problem_outlined,
                      color: AppTheme.aqua,
                    ),
                  ),
                  title: const Text('Report an accessibility issue'),
                  subtitle: const Text('Tell us what could work better'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: onReportAccessibilityIssue,
                ),
              ),
              const SizedBox(height: 24),
              const _StatusCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: AppTheme.teal,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your profile is ready',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your accessibility preferences are securely saved.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}