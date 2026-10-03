import 'package:flutter/material.dart';

import '../services/accessibility_report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/equal_ride_background.dart';
import '../widgets/glass_panel.dart';

class AccessibilityReportPage extends StatefulWidget {
  const AccessibilityReportPage({super.key});

  @override
  State<AccessibilityReportPage> createState() =>
      _AccessibilityReportPageState();
}

class _AccessibilityReportPageState extends State<AccessibilityReportPage> {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final reportService = AccessibilityReportService();

  String? issueType;
  bool isSubmitting = false;

  static const issueTypes = [
    'Wheelchair access',
    'Ramp unavailable',
    'Lift unavailable',
    'Step-free access issue',
    'Crowding',
    'Accessibility information incorrect',
    'Other',
  ];

  static const issueGuidance = {
    'Wheelchair access': (
      descriptionHint: 'Describe the access available and any barriers.',
      descriptionHelp: 'Mention ramps, door width, or step-free access.',
      locationHint: 'For example, the station entrance or platform',
    ),
    'Ramp unavailable': (
      descriptionHint: 'Describe when and where the ramp was unavailable.',
      descriptionHelp: 'Include the route or vehicle and what happened.',
      locationHint: 'For example, Bus 138 at Central Station',
    ),
    'Lift unavailable': (
      descriptionHint: 'Describe which lift was unavailable.',
      descriptionHelp:
          'Include the station, platform, and any alternative route.',
      locationHint: 'For example, Central Station platform 2',
    ),
    'Step-free access issue': (
      descriptionHint: 'Describe where the step-free route was blocked.',
      descriptionHelp: 'Mention steps, slopes, or barriers along the route.',
      locationHint: 'For example, the entrance to platform 2',
    ),
    'Crowding': (
      descriptionHint: 'Describe how crowding affected access or boarding.',
      descriptionHelp: 'Include the time and how it affected your journey.',
      locationHint: 'For example, the 8 AM bus stop on Main Street',
    ),
    'Accessibility information incorrect': (
      descriptionHint: 'Explain what information is inaccurate.',
      descriptionHelp: 'Compare the information with what you found on site.',
      locationHint: 'For example, the station or route shown in the app',
    ),
    'Other': (
      descriptionHint: 'Describe the accessibility issue you encountered.',
      descriptionHelp: 'Share what happened and how it affected your journey.',
      locationHint: 'For example, a route, stop, or station',
    ),
  };

  ({String descriptionHint, String descriptionHelp, String locationHint})
  get selectedIssueGuidance =>
      issueGuidance[issueType] ?? issueGuidance['Other']!;

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> submitReport() async {
    if (isSubmitting) return;

    descriptionController.text = descriptionController.text.trim();
    locationController.text = locationController.text.trim();

    if (!(formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await reportService.submitReport(
        issueType: issueType!,
        description: descriptionController.text,
        location: locationController.text,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      descriptionController.clear();
      locationController.clear();
      formKey.currentState?.reset();
      setState(() => issueType = null);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Accessibility report submitted successfully.'),
        ),
      );
    } on AccessibilityReportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not submit your report. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EqualRideBackground(
        child: SafeArea(
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                        'Report Accessibility Issue',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Help us make every journey more accessible by sharing what you found.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 28),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: issueType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Issue type',
                          prefixIcon: Icon(Icons.report_problem_outlined),
                        ),
                        items: issueTypes
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => issueType = value);
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select an issue type.'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: descriptionController,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 4,
                        maxLines: 7,
                        textCapitalization: TextCapitalization.sentences,
                        decoration:
                            const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.notes_rounded),
                            ).copyWith(
                              hintText: selectedIssueGuidance.descriptionHint,
                              helperText: selectedIssueGuidance.descriptionHelp,
                            ),
                        validator: (value) {
                          final description = value?.trim() ?? '';
                          if (description.isEmpty) {
                            return 'Please describe the accessibility issue.';
                          }
                          if (description.length < 20) {
                            return 'Please add a little more detail (20 characters minimum).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: locationController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(
                              labelText: 'Route / station location',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ).copyWith(
                              hintText: selectedIssueGuidance.locationHint,
                            ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Please enter the route or station location.'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : submitReport,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: AppTheme.navy,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    isSubmitting ? 'Checking report...' : 'Submit report',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
