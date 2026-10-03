import 'dart:async';

import 'package:flutter/material.dart';

import '../services/accessibility_report_draft_service.dart';
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
  final draftService = AccessibilityReportDraftService();
  final reportService = AccessibilityReportService();
  Future<void> draftWriteQueue = Future<void>.value();
  Timer? draftSaveTimer;

  String? issueType;
  bool isSubmitting = false;
  bool isDraftLoading = true;
  bool isDraftSaving = false;
  bool isDiscardingDraft = false;
  bool hasSavedDraft = false;
  bool hasShownDraftSaveError = false;

  static const minimumDescriptionLength = 20;

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

  AccessibilityReportDraft get currentDraft => AccessibilityReportDraft(
    issueType: issueType,
    description: descriptionController.text,
    location: locationController.text,
  );

  @override
  void initState() {
    super.initState();
    unawaited(restoreDraft());
  }

  @override
  void dispose() {
    if (draftSaveTimer?.isActive ?? false) {
      draftSaveTimer?.cancel();
      unawaited(enqueueDraftSave(currentDraft));
    }
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> restoreDraft() async {
    AccessibilityReportDraft? draft;
    Object? restoreError;

    try {
      draft = await draftService.loadDraft();
    } catch (error, stackTrace) {
      restoreError = error;
      debugPrint('Unable to restore accessibility report draft: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;

    if (draft != null) {
      descriptionController.text = draft.description;
      locationController.text = draft.location;
      issueType = issueTypes.contains(draft.issueType) ? draft.issueType : null;
    }
    setState(() {
      isDraftLoading = false;
      hasSavedDraft = draft != null;
    });

    if (draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your saved report draft was restored.')),
      );
    } else if (restoreError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not restore your saved report draft.'),
        ),
      );
    }
  }

  void scheduleDraftSave() {
    if (isDraftLoading || isDiscardingDraft || isSubmitting) return;
    draftSaveTimer?.cancel();
    setState(() => isDraftSaving = true);
    draftSaveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(enqueueDraftSave(currentDraft));
    });
  }

  Future<void> enqueueDraftSave(AccessibilityReportDraft draft) {
    draftWriteQueue = draftWriteQueue.then((_) async {
      try {
        await draftService.saveDraft(draft);
        if (mounted) {
          setState(() {
            hasSavedDraft = draft.hasContent;
            isDraftSaving = false;
          });
        }
        hasShownDraftSaveError = false;
      } catch (error, stackTrace) {
        debugPrint('Unable to save accessibility report draft: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) setState(() => isDraftSaving = false);
        if (mounted && !hasShownDraftSaveError) {
          hasShownDraftSaveError = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your report draft could not be saved on this device.',
              ),
            ),
          );
        }
      }
    });
    return draftWriteQueue;
  }

  Future<void> restoreSavedDraft() async {
    if (isDraftLoading || isSubmitting || isDiscardingDraft) return;
    draftSaveTimer?.cancel();
    setState(() {
      isDraftLoading = true;
      isDraftSaving = false;
    });
    await draftWriteQueue;
    await restoreDraft();
  }

  Future<void> discardSavedDraft() async {
    if (isDraftLoading || isSubmitting || isDiscardingDraft) return;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard saved draft?'),
        content: const Text(
          'This will remove the report draft saved on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (shouldDiscard != true || !mounted) return;

    draftSaveTimer?.cancel();
    setState(() {
      isDiscardingDraft = true;
      isDraftSaving = false;
    });
    try {
      await draftWriteQueue;
      await draftService.clearDraft();
      if (!mounted) return;
      descriptionController.clear();
      locationController.clear();
      formKey.currentState?.reset();
      setState(() {
        issueType = null;
        hasSavedDraft = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved report draft discarded.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Unable to discard accessibility report draft: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not discard the saved report draft.'),
        ),
      );
    } finally {
      if (mounted) setState(() => isDiscardingDraft = false);
    }
  }

  Future<void> submitReport() async {
    if (isSubmitting || isDraftLoading || isDiscardingDraft) return;

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
      draftSaveTimer?.cancel();
      await enqueueDraftSave(currentDraft);
      await reportService.submitReport(
        issueType: issueType!,
        description: descriptionController.text,
        location: locationController.text,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      String? draftCleanupWarning;
      try {
        await draftWriteQueue;
        await draftService.clearDraft();
      } catch (error, stackTrace) {
        debugPrint(
          'Unable to clear submitted accessibility report draft: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        draftCleanupWarning =
            'Report submitted, but the saved draft could not be cleared.';
      }
      if (!mounted) return;
      descriptionController.clear();
      locationController.clear();
      formKey.currentState?.reset();
      setState(() {
        issueType = null;
        hasSavedDraft = false;
      });
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            draftCleanupWarning ??
                'Accessibility report submitted successfully.',
          ),
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
                if (isDraftLoading) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (hasSavedDraft || isDraftSaving) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.teal.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.drafts_outlined,
                              color: AppTheme.teal,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isDraftSaving
                                    ? 'Saving report draft on this device...'
                                    : 'Report draft saved on this device',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasSavedDraft) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'You can restore the saved version or discard it.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    isDraftLoading ||
                                        isSubmitting ||
                                        isDraftSaving ||
                                        isDiscardingDraft
                                    ? null
                                    : restoreSavedDraft,
                                icon: const Icon(Icons.restore_rounded),
                                label: const Text('Restore draft'),
                              ),
                              TextButton.icon(
                                onPressed:
                                    isDraftLoading ||
                                        isSubmitting ||
                                        isDiscardingDraft
                                    ? null
                                    : discardSavedDraft,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Discard'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
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
                        onChanged:
                            isDraftLoading || isSubmitting || isDiscardingDraft
                            ? null
                            : (value) {
                                setState(() => issueType = value);
                                scheduleDraftSave();
                              },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select an issue type.'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: descriptionController,
                        enabled:
                            !isDraftLoading &&
                            !isSubmitting &&
                            !isDiscardingDraft,
                        onChanged: (_) => scheduleDraftSave(),
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
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) {
                              final countLabel =
                                  currentLength < minimumDescriptionLength
                                  ? '$currentLength / $minimumDescriptionLength minimum'
                                  : '$currentLength characters';
                              return Text(
                                countLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                        validator: (value) {
                          final description = value?.trim() ?? '';
                          if (description.isEmpty) {
                            return 'Please describe the accessibility issue.';
                          }
                          if (description.length < minimumDescriptionLength) {
                            return 'Please add a little more detail (20 characters minimum).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: locationController,
                        enabled:
                            !isDraftLoading &&
                            !isSubmitting &&
                            !isDiscardingDraft,
                        onChanged: (_) => scheduleDraftSave(),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(
                              labelText: 'Route / station location',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ).copyWith(
                              hintText: selectedIssueGuidance.locationHint,
                              helperText:
                                  'Required. Enter the route, stop, or station.',
                            ),
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) {
                              return Text(
                                '$currentLength characters',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
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
                  onPressed: isSubmitting || isDraftLoading || isDiscardingDraft
                      ? null
                      : submitReport,
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
                    isDraftLoading
                        ? 'Restoring draft...'
                        : isSubmitting
                        ? 'Checking report...'
                        : 'Submit report',
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
