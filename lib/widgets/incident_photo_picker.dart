import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Optional photo section of the report form: add from camera or gallery,
/// preview, replace or remove.
class IncidentPhotoPicker extends StatelessWidget {
  const IncidentPhotoPicker({
    super.key,
    required this.photoBytes,
    required this.enabled,
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final bool enabled;
  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = photoBytes;
    final canAct = enabled && !isBusy;

    if (bytes == null) {
      return Row(
        children: [
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              onPressed: canAct ? onCamera : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose photo',
              onPressed: canAct ? onGallery : null,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          image: true,
          label: 'Selected incident photo',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Replace',
                onPressed: canAct ? onGallery : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                onPressed: canAct ? onRemove : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppTheme.aqua,
        side: BorderSide(color: AppTheme.teal.withValues(alpha: 0.50)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

/// Read-only photo shown on a report. Tapping opens a zoomable full view.
class IncidentPhotoView extends StatelessWidget {
  const IncidentPhotoView({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: 'Incident photo. Double tap to enlarge.',
      child: GestureDetector(
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => Dialog.fullscreen(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Center(child: Image.memory(bytes)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
      ),
    );
  }
}
