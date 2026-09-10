import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
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
  late AppLanguage language;

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
    language = widget.initialPreferences.language;
  }

  String t(String key) => AppStrings.text(language, key);

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
          language: language,
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
                      t('preferences'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t('languageHint'),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),

              _SectionTitle(
                icon: Icons.language_rounded,
                title: t('language'),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('languageHint'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<AppLanguage>(
                      segments: [
                        ButtonSegment(
                          value: AppLanguage.english,
                          icon: const Icon(Icons.language_rounded),
                          label: Text(t('english')),
                        ),
                        ButtonSegment(
                          value: AppLanguage.sinhala,
                          icon: const Icon(Icons.translate_rounded),
                          label: Text(t('sinhala')),
                        ),
                      ],
                      selected: {language},
                      onSelectionChanged: isSaving
                          ? null
                          : (selected) {
                              setState(() => language = selected.first);
                            },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.accessible_rounded,
                title: t('accessibilityRouting'),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PreferenceToggle(
                      icon: Icons.elevator_rounded,
                      title: t('stepFree'),
                      subtitle: t('stepFreeHint'),
                      value: stepFreeRoutes,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => stepFreeRoutes = value),
                    ),
                    const _Divider(),
                    _PreferenceToggle(
                      icon: Icons.directions_transit_rounded,
                      title: t('avoidCrowding'),
                      subtitle: t('avoidCrowdingHint'),
                      value: lowCrowding,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => lowCrowding = value),
                    ),
                    const _Divider(),
                    _PreferenceToggle(
                      icon: Icons.chair_alt_rounded,
                      title: t('prioritySeating'),
                      subtitle: t('prioritySeatingHint'),
                      value: prioritySeating,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => prioritySeating = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _SectionTitle(
                icon: Icons.visibility_rounded,
                title: t('displayReadability'),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _PreferenceToggle(
                      icon: Icons.contrast_rounded,
                      title: t('highContrast'),
                      subtitle: t('highContrastHint'),
                      value: highContrast,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                              setState(() => highContrast = value),
                    ),
                    const _Divider(),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.format_size_rounded,
                                color: AppTheme.aqua,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('textSize'),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t('textSizeHint'),
                            style: const TextStyle(
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
                                label: t('standard'),
                                scale: 1.0,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () =>
                                    setState(() => textScale = 1.0),
                              ),
                              _TextSizeChoice(
                                label: t('large'),
                                scale: 1.2,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () =>
                                    setState(() => textScale = 1.2),
                              ),
                              _TextSizeChoice(
                                label: t('extraLarge'),
                                scale: 1.4,
                                selectedScale: textScale,
                                enabled: !isSaving,
                                onSelected: () =>
                                    setState(() => textScale = 1.4),
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
              _SectionTitle(
                icon: Icons.notifications_none_rounded,
                title: t('journeyUpdates'),
              ),
              const SizedBox(height: 12),
              GlassPanel(
                padding: EdgeInsets.zero,
                child: _PreferenceToggle(
                  icon: Icons.notifications_paused_rounded,
                  title: t('alerts'),
                  subtitle: t('alertsHint'),
                  value: accessibilityAlerts,
                  onChanged: isSaving
                      ? null
                      : (value) =>
                          setState(() => accessibilityAlerts = value),
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
                    : Text(t('savePreferences')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

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