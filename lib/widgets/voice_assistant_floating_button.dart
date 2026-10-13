import 'package:flutter/material.dart';

import '../services/voice_assistant_service.dart';
import '../theme/app_theme.dart';
import 'voice_assistant_sheet.dart';

/// Accessible Floating Voice Assistant Button for blind & elderly commuters.
/// Can be dragged anywhere on screen and maintains high contrast touch targets.
class VoiceAssistantFloatingButton extends StatefulWidget {
  const VoiceAssistantFloatingButton({
    super.key,
    this.initialBottom = 92,
    this.initialRight = 18,
  });

  final double initialBottom;
  final double initialRight;

  @override
  State<VoiceAssistantFloatingButton> createState() =>
      _VoiceAssistantFloatingButtonState();
}

class _VoiceAssistantFloatingButtonState
    extends State<VoiceAssistantFloatingButton>
    with SingleTickerProviderStateMixin {
  final voiceService = VoiceAssistantService.instance;
  late AnimationController _animController;

  Offset? _position;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    voiceService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    voiceService.removeListener(_onUpdate);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!voiceService.isEnabled) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isListening = voiceService.isListening;
    final isSpeaking = voiceService.isSpeaking;

    // Default initial bottom-right position
    final defaultPos = Offset(
      screenSize.width - 76 - widget.initialRight,
      screenSize.height - 76 - widget.initialBottom,
    );

    final currentPos = _position ?? defaultPos;

    return Positioned(
      left: currentPos.dx.clamp(12.0, screenSize.width - 80.0),
      top: currentPos.dy.clamp(48.0, screenSize.height - 90.0),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              (_position?.dx ?? defaultPos.dx) + details.delta.dx,
              (_position?.dy ?? defaultPos.dy) + details.delta.dy,
            );
          });
        },
        child: Semantics(
          button: true,
          label: isListening
              ? 'Voice Assistant listening. Tap to open voice controls.'
              : 'EqualRide Voice Assistant. Tap to speak or hear voice assistance.',
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final pulse = (isListening || isSpeaking)
                  ? 1.0 + (_animController.value * 0.16)
                  : 1.0;

              final ringColor = isListening
                  ? Colors.redAccent
                  : isSpeaking
                      ? AppTheme.aqua
                      : AppTheme.teal;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Animated outer pulse ring when active
                  if (isListening || isSpeaking)
                    Transform.scale(
                      scale: pulse,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ringColor.withValues(alpha: 0.6),
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                  // Tactile Floating Voice Button
                  Material(
                    shape: const CircleBorder(),
                    elevation: 10,
                    shadowColor: ringColor.withValues(alpha: 0.5),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => showVoiceAssistantSheet(context),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isListening
                                ? [Colors.redAccent, Colors.deepOrange]
                                : isSpeaking
                                    ? [AppTheme.aqua, AppTheme.teal]
                                    : [AppTheme.teal, const Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 2.2),
                        ),
                        child: Icon(
                          isListening
                              ? Icons.mic_rounded
                              : isSpeaking
                                  ? Icons.volume_up_rounded
                                  : Icons.record_voice_over_rounded,
                          color: isListening ? Colors.white : Colors.black87,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
