import 'package:flutter/material.dart';

import '../models/accessibility_preferences.dart';
import '../services/voice_assistant_service.dart';
import '../theme/app_theme.dart';
import 'glass_panel.dart';

/// Shows the accessible EqualRide Voice Assistant interactive sheet
void showVoiceAssistantSheet(BuildContext context) {
  final targetContext =
      VoiceAssistantService.instance.navigatorKey?.currentContext ?? context;
  showModalBottomSheet(
    context: targetContext,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const VoiceAssistantSheet(),
  );
}

class VoiceAssistantSheet extends StatefulWidget {
  const VoiceAssistantSheet({super.key});

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  final voiceService = VoiceAssistantService.instance;
  final TextEditingController _textCommandController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    voiceService.addListener(_onServiceUpdate);

    // Auto-prompt greeting for elderly/blind user upon opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !voiceService.isSpeaking && !voiceService.isListening) {
        _greetUser();
      }
    });
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _greetUser() {
    final screenName = voiceService.currentScreen?.name ?? 'Home';
    final lang = voiceService.language;
    final greeting = lang == AppLanguage.sinhala
        ? 'EqualRide හඬ සහායකයා සූදානම්. ඔබ සිටින්නේ $screenName පිටුවේය. මයික්‍රෆෝනය ඔබා විධානය පවසන්න.'
        : 'EqualRide voice assistant is ready. You are on $screenName. Tap the microphone to speak, or choose a quick option.';
    voiceService.speak(greeting);
  }

  @override
  void dispose() {
    voiceService.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    _textCommandController.dispose();
    super.dispose();
  }

  void _sendManualCommand(String text) {
    if (text.trim().isEmpty) return;
    _textCommandController.clear();
    FocusScope.of(context).unfocus();
    voiceService.executeVoiceCommand(text, context: context);
  }

  @override
  Widget build(BuildContext context) {
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.isSpeaking;
    final lang = voiceService.language;
    final screen = voiceService.currentScreen;

    return Semantics(
      label: 'EqualRide Voice Assistant Dialog',
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppTheme.teal.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.teal.withValues(alpha: 0.25),
              blurRadius: 32,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppTheme.teal,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == AppLanguage.sinhala
                              ? 'EqualRide හඬ සහායකයා'
                              : 'EqualRide Voice Assistant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (screen != null)
                          Text(
                            'Active Screen: ${screen.name}',
                            style: const TextStyle(
                              color: AppTheme.teal,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    tooltip: 'Close voice assistant',
                    onPressed: () {
                      voiceService.stopSpeaking();
                      voiceService.stopListening();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Animated Big Microphone Button for Blind & Elderly Users
              Center(
                child: Semantics(
                  button: true,
                  label: isListening
                      ? 'Listening. Tap to stop.'
                      : 'Microphone. Tap to start speaking voice command.',
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = (isListening || isSpeaking)
                          ? 1.0 + (_pulseController.value * 0.12)
                          : 1.0;
                      final glowColor = isListening
                          ? Colors.redAccent
                          : isSpeaking
                              ? AppTheme.aqua
                              : AppTheme.teal;

                      return GestureDetector(
                        onTap: () => voiceService.toggleListening(context: context),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing outer ripple
                            if (isListening || isSpeaking)
                              Container(
                                width: 110 * scale,
                                height: 110 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: glowColor.withValues(alpha: 0.22),
                                ),
                              ),
                            // Core tactile button
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isListening
                                      ? [Colors.redAccent, Colors.deepOrange]
                                      : isSpeaking
                                          ? [AppTheme.aqua, AppTheme.teal]
                                          : [AppTheme.teal, const Color(0xFF0D9488)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: glowColor.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isListening
                                    ? Icons.mic_rounded
                                    : isSpeaking
                                        ? Icons.volume_up_rounded
                                        : Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Status message
              Center(
                child: Text(
                  voiceService.statusMessage,
                  style: TextStyle(
                    color: isListening
                        ? Colors.redAccent
                        : isSpeaking
                            ? AppTheme.aqua
                            : AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transcript & Spoken Response Card
              if (voiceService.lastWords.isNotEmpty ||
                  voiceService.lastResponse.isNotEmpty)
                GlassPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (voiceService.lastWords.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.person_pin_rounded,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang == AppLanguage.sinhala
                                  ? 'ඔබ පැවසූ දේ:'
                                  : 'You said:',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${voiceService.lastWords}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20, color: Colors.white12),
                      ],
                      if (voiceService.lastResponse.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.smart_toy_rounded,
                              size: 18,
                              color: AppTheme.teal,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lang == AppLanguage.sinhala
                                  ? 'EqualRide පිළිතුර:'
                                  : 'EqualRide response:',
                              style: const TextStyle(
                                color: AppTheme.teal,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          voiceService.lastResponse,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Action buttons (Stop, Repeat, Read Screen, Where am I)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _QuickActionButton(
                    icon: Icons.location_searching_rounded,
                    label: lang == AppLanguage.sinhala
                        ? 'මම කොහේද?'
                        : 'Where am I?',
                    color: AppTheme.teal,
                    onTap: voiceService.announceCurrentScreen,
                  ),
                  _QuickActionButton(
                    icon: Icons.menu_book_rounded,
                    label: lang == AppLanguage.sinhala
                        ? 'තිරය කියවන්න'
                        : 'Read Screen',
                    color: AppTheme.aqua,
                    onTap: voiceService.readCurrentScreenContent,
                  ),
                  if (isSpeaking)
                    _QuickActionButton(
                      icon: Icons.stop_circle_rounded,
                      label: lang == AppLanguage.sinhala
                          ? 'හඬ නවත්වන්න'
                          : 'Stop Speaking',
                      color: Colors.redAccent,
                      onTap: voiceService.stopSpeaking,
                    ),
                  _QuickActionButton(
                    icon: Icons.replay_rounded,
                    label: lang == AppLanguage.sinhala ? 'නැවත' : 'Repeat',
                    color: Colors.amber,
                    onTap: () {
                      if (voiceService.lastResponse.isNotEmpty) {
                        voiceService.speak(voiceService.lastResponse);
                      } else {
                        voiceService.announceCurrentScreen();
                      }
                    },
                  ),
                  _QuickActionButton(
                    icon: Icons.help_outline_rounded,
                    label: lang == AppLanguage.sinhala ? 'උපකාර' : 'Help',
                    color: Colors.blueAccent,
                    onTap: voiceService.provideVoiceHelp,
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Quick voice suggestion chips (easy for seniors)
              Text(
                lang == AppLanguage.sinhala
                    ? 'නිතර භාවිත වන විධාන:'
                    : 'Quick Voice Suggestions:',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SuggestionChip(
                    text: 'Find route to Colombo Fort',
                    onTap: () => _sendManualCommand('Find route to Colombo Fort'),
                  ),
                  _SuggestionChip(
                    text: 'Turn on high contrast',
                    onTap: () => _sendManualCommand('Turn on high contrast'),
                  ),
                  _SuggestionChip(
                    text: 'Bigger text',
                    onTap: () => _sendManualCommand('Bigger text'),
                  ),
                  _SuggestionChip(
                    text: 'Go home',
                    onTap: () => _sendManualCommand('Go home'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fallback text input for noisy environment
              TextField(
                controller: _textCommandController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: lang == AppLanguage.sinhala
                      ? 'විධානය ලියන්න (උදා. කොළඹට මාර්ග)...'
                      : 'Or type voice command (e.g. Find route to Pettah)...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  prefixIcon: const Icon(Icons.keyboard_rounded, color: AppTheme.teal),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppTheme.teal),
                    onPressed: () => _sendManualCommand(_textCommandController.text),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                ),
                onSubmitted: _sendManualCommand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: onTap,
    );
  }
}
