import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

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
  late bool highContrast;
  late double textScale;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    stepFreeRoutes = widget.initialPreferences.stepFreeRoutes;
    lowCrowding = widget.initialPreferences.lowCrowding;
    prioritySeating = widget.initialPreferences.prioritySeating;
    accessibilityAlerts = widget.initialPreferences.accessibilityAlerts;
    highContrast = widget.initialPreferences.highContrast;
    textScale = widget.initialPreferences.textScale;
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
          highContrast: highContrast,
          textScale: textScale,
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
      if (mounted) setState(() => isSaving = false);
    }
  }

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
                  if (Navigator.canPop(context))
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  Expanded(
                    child: Text(
                      'Preferences',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Customise your transit experience for accessibility and ease of use.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),

              const _SectionTitle(
                icon: Icons.accessible_rounded,
                title: 'Accessibility & routing',
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PreferenceToggle(
                      icon: Icons.elevator_rounded,
                      title: 'Step-free routes',
                      subtitle: 'Avoid stairs and steep escalators',
                      value: stepFreeRoutes,
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() => stepFreeRoutes = value);
                            },
                    ),
                    const _Divider(),
                    _PreferenceToggle(
                      icon: Icons.directions_transit_rounded,
                      title: 'Avoid crowded transport',
                      subtitle: 'Prioritise lower crowd-level updates',
                      value: lowCrowding,
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() => lowCrowding = value);
                            },
                    ),
                    const _Divider(),
                    _PreferenceToggle(
                      icon: Icons.chair_alt_rounded,
                      title: 'Priority-seat information',
                      subtitle: 'Show reported seat availability',
                      value: prioritySeating,
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() => prioritySeating = value);
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const _SectionTitle(
                icon: Icons.visibility_rounded,
                title: 'Display & readability',
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PreferenceToggle(
                      icon: Icons.contrast_rounded,
                      title: 'High contrast',
                      subtitle: 'Increase contrast for clearer visibility',
                      value: highContrast,
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() => highContrast = value);
                            },
                    ),
                    const _Divider(),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.format_size_rounded,
                                color: AppTheme.aqua,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Text size',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Choose a comfortable reading size',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TextSizeChoice(
                                label: 'Standard',
                                scale: 1.0,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () {
                                  setState(() => textScale = 1.0);
                                },
                              ),
                              _TextSizeChoice(
                                label: 'Large',
                                scale: 1.2,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () {
                                  setState(() => textScale = 1.2);
                                },
                              ),
                              _TextSizeChoice(
                                label: 'Extra large',
                                scale: 1.4,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () {
                                  setState(() => textScale = 1.4);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const _SectionTitle(
                icon: Icons.notifications_none_rounded,
                title: 'Journey updates',
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: _PreferenceToggle(
                  icon: Icons.notifications_paused_rounded,
                  title: 'Accessibility alerts',
                  subtitle: 'Receive relevant travel-condition updates',
                  value: accessibilityAlerts,
                  onChanged: isSaving
                      ? null
                      : (value) {
                          setState(() => accessibilityAlerts = value);
                        },
                ),
              ),

              const SizedBox(height: 28),
              FilledButton(
                onPressed: isSaving ? null : save,
                child: isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.navy,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Save preferences'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.aqua, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.aqua,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _PreferenceToggle extends StatelessWidget {
  const _PreferenceToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      secondary: Icon(icon, color: AppTheme.aqua),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: AppTheme.teal,
      onChanged: onChanged,
    );
  }
}

class _TextSizeChoice extends StatelessWidget {
  const _TextSizeChoice({
    required this.label,
    required this.scale,
    required this.selectedScale,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final double scale;
  final double selectedScale;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = scale == selectedScale;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      selectedColor: AppTheme.teal,
      backgroundColor: Colors.white.withOpacity(0.08),
      labelStyle: TextStyle(
        color: selected ? AppTheme.navy : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: Colors.white.withOpacity(0.12),
    );
  }
}