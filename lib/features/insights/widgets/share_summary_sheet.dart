// File: share_summary_sheet.dart
//
// Bottom sheet that shares the Insights summary by copying it, or through
// WhatsApp or email (url_launcher).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/accessibility_preferences.dart';
import '../../../theme/app_theme.dart';
import '../models/insight_summary.dart';
import '../services/insights_strings.dart';
import '../services/share_summary.dart';

/// Lets the user copy or send the text summary. Uses url_launcher so no
/// extra package is needed.
Future<void> showShareSummarySheet(
  BuildContext context, {
  required InsightSummary summary,
  required AppLanguage language,
  String Function(String label)? nameOf,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF10202B),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ShareSummarySheet(
      text: buildShareSummary(summary, language: language, nameOf: nameOf),
      language: language,
    ),
  );
}

class ShareSummarySheet extends StatelessWidget {
  const ShareSummarySheet({
    super.key,
    required this.text,
    required this.language,
    this.launch = _defaultLaunch,
  });

  final String text;
  final AppLanguage language;

  /// Injectable for tests.
  final Future<bool> Function(Uri uri) launch;

  static Future<bool> _defaultLaunch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    String t(String key) => InsightsStrings.text(language, key);

    Future<void> open(Uri uri) async {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      var ok = false;
      try {
        ok = await launch(uri);
      } catch (_) {
        ok = false;
      }
      navigator.maybePop();
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(t('shareFailed'))));
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('share'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ShareAction(
                  icon: Icons.copy_rounded,
                  label: t('copy'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    await Clipboard.setData(ClipboardData(text: text));
                    navigator.maybePop();
                    messenger.showSnackBar(
                      SnackBar(content: Text(t('copied'))),
                    );
                  },
                ),
                _ShareAction(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  onTap: () => open(Uri.https('wa.me', '/', {'text': text})),
                ),
                _ShareAction(
                  icon: Icons.email_rounded,
                  label: t('email'),
                  onTap: () => open(
                    Uri(
                      scheme: 'mailto',
                      query: _encode({'subject': t('title'), 'body': text}),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // mailto needs %20 rather than '+' for spaces.
  static String _encode(Map<String, String> params) => params.entries
      .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppTheme.teal),
      label: Text(label),
      onPressed: onTap,
      labelStyle: const TextStyle(color: AppTheme.textPrimary),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
