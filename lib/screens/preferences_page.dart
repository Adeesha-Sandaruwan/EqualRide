import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({
    super.key,
    required this.initialPreferences,
    required this.onSave,
  });

  final AccessibilityPreferences initialPreferences;
  final void Function(AccessibilityPreferences preferences) onSave;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late bool stepFreeRoutes;
  late bool lowCrowding;
  late bool prioritySeating;
  late bool accessibilityAlerts;

  @override
  void initState() {
    super.initState();

    stepFreeRoutes = widget.initialPreferences.stepFreeRoutes;
    lowCrowding = widget.initialPreferences.lowCrowding;
    prioritySeating = widget.initialPreferences.prioritySeating;
    accessibilityAlerts = widget.initialPreferences.accessibilityAlerts;
  }

  void save() {
    widget.onSave(
      AccessibilityPreferences(
        stepFreeRoutes: stepFreeRoutes,
        lowCrowding: lowCrowding,
        prioritySeating: prioritySeating,
        accessibilityAlerts: accessibilityAlerts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Personalise your journeys',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'These settings will later be used when finding and comparing routes.',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Prefer step-free routes'),
            subtitle: const Text(
              'Prioritise ramps, lifts and step-free access.',
            ),
            value: stepFreeRoutes,
            onChanged: (value) {
              setState(() => stepFreeRoutes = value);
            },
          ),
          SwitchListTile(
            title: const Text('Avoid crowded transport'),
            subtitle: const Text(
              'Prioritise lower crowd-level updates when available.',
            ),
            value: lowCrowding,
            onChanged: (value) {
              setState(() => lowCrowding = value);
            },
          ),
          SwitchListTile(
            title: const Text('Show priority-seat information'),
            subtitle: const Text(
              'Include reported priority-seat availability.',
            ),
            value: prioritySeating,
            onChanged: (value) {
              setState(() => prioritySeating = value);
            },
          ),
          SwitchListTile(
            title: const Text('Accessibility alerts'),
            subtitle: const Text(
              'Receive relevant accessibility-condition alerts later.',
            ),
            value: accessibilityAlerts,
            onChanged: (value) {
              setState(() => accessibilityAlerts = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: save,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Save preferences'),
            ),
          ),
        ],
      ),
    );
  }
}