import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({
    super.key,
    required this.initialPreferences,
    required this.onSave,
  });

  final AccessibilityPreferences initialPreferences;
  final Future<void> Function(AccessibilityPreferences preferences) onSave;

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  late bool stepFreeRoutes;
  late bool lowCrowding;
  late bool prioritySeating;
  late bool accessibilityAlerts;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    stepFreeRoutes = widget.initialPreferences.stepFreeRoutes;
    lowCrowding = widget.initialPreferences.lowCrowding;
    prioritySeating = widget.initialPreferences.prioritySeating;
    accessibilityAlerts = widget.initialPreferences.accessibilityAlerts;
  }

  Future<void> save() async {
    setState(() => isSaving = true);

    try {
      await widget.onSave(
        AccessibilityPreferences(
          stepFreeRoutes: stepFreeRoutes,
          lowCrowding: lowCrowding,
          prioritySeating: prioritySeating,
          accessibilityAlerts: accessibilityAlerts,
        ),
      );

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save preferences. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
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
            'These settings help EqualRide find routes that suit you.',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Prefer step-free routes'),
            subtitle: const Text(
              'Prioritise ramps, lifts and step-free access.',
            ),
            value: stepFreeRoutes,
            onChanged: isSaving
                ? null
                : (value) => setState(() => stepFreeRoutes = value),
          ),
          SwitchListTile(
            title: const Text('Avoid crowded transport'),
            subtitle: const Text(
              'Prioritise lower crowd-level updates when available.',
            ),
            value: lowCrowding,
            onChanged: isSaving
                ? null
                : (value) => setState(() => lowCrowding = value),
          ),
          SwitchListTile(
            title: const Text('Show priority-seat information'),
            subtitle: const Text(
              'Include reported priority-seat availability.',
            ),
            value: prioritySeating,
            onChanged: isSaving
                ? null
                : (value) => setState(() => prioritySeating = value),
          ),
          SwitchListTile(
            title: const Text('Accessibility alerts'),
            subtitle: const Text(
              'Receive relevant accessibility-condition alerts later.',
            ),
            value: accessibilityAlerts,
            onChanged: isSaving
                ? null
                : (value) => setState(() => accessibilityAlerts = value),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isSaving ? null : save,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save preferences'),
            ),
          ),
        ],
      ),
    );
  }
}