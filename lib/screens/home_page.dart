import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class HomePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final name = email.split('@').first;

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
                    onPressed: onLogout,
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
                    _LocationField(
                      label: 'From',
                      hint: 'Use current location',
                      icon: Icons.my_location_rounded,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0x33FFFFFF)),
                    ),
                    _LocationField(
                      label: 'To',
                      hint: 'Enter destination',
                      icon: Icons.location_on_rounded,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Route search will be added in the next sprint.',
                            ),
                          ),
                        );
                      },
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
                    preferences.stepFreeRoutes
                        ? 'Step-free routes are prioritised'
                        : 'Customise your travel settings',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: onEditPreferences,
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

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.hint,
    required this.icon,
  });

  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.aqua),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.aqua,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
      ],
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