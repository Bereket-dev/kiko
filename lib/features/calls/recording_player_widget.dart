import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecordingPlayerWidget
// ─────────────────────────────────────────────────────────────────────────────
//
// Displays metadata and playback controls for a single call recording.
//
// Playback: launches the recording URI in an external player via url_launcher
// (audioplayers is not in the current pubspec; this is the correct fallback
// per the implementation plan).
//
// When a recording file is missing:
//   - Shows a "Re-attach" action (triggers onReattach callback).
//   - Shows a "Remove link" action (triggers onRemove callback).
// ─────────────────────────────────────────────────────────────────────────────

class RecordingPlayerWidget extends StatefulWidget {
  const RecordingPlayerWidget({
    super.key,
    required this.uri,
    required this.displayName,
    required this.durationMs,
    this.isMissing = false,
    this.onReattach,
    this.onRemove,
  });

  /// SAF content URI or file URI.
  final String uri;

  /// Human-readable filename shown in the UI.
  final String displayName;

  /// Recording duration in milliseconds. 0 if unknown.
  final int durationMs;

  /// True when the file can no longer be found at [uri].
  final bool isMissing;

  /// Called when the user taps "Re-attach" (file missing).
  final VoidCallback? onReattach;

  /// Called when the user taps "Remove link".
  final VoidCallback? onRemove;

  @override
  State<RecordingPlayerWidget> createState() => _RecordingPlayerWidgetState();
}

class _RecordingPlayerWidgetState extends State<RecordingPlayerWidget> {
  bool _launching = false;

  String _formatDuration(int ms) {
    if (ms <= 0) return '--:--';
    final total = ms ~/ 1000;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _openExternal() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final uri = Uri.parse(widget.uri);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No app found to play this recording.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open recording: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.isMissing) {
      return _MissingRecordingCard(
        displayName: widget.displayName,
        onReattach: widget.onReattach,
        onRemove: widget.onRemove,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Play button
            IconButton.filled(
              icon: _launching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              onPressed: _launching ? null : _openExternal,
              tooltip: 'Open in external player',
              style: IconButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(widget.durationMs),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.open_in_new_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'External player',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove action
            if (widget.onRemove != null)
              IconButton(
                icon: Icon(Icons.link_off_outlined, color: cs.error),
                tooltip: 'Remove link',
                onPressed: widget.onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MissingRecordingCard
// ─────────────────────────────────────────────────────────────────────────────

class _MissingRecordingCard extends StatelessWidget {
  const _MissingRecordingCard({
    required this.displayName,
    this.onReattach,
    this.onRemove,
  });

  final String displayName;
  final VoidCallback? onReattach;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      color: cs.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.broken_image_outlined, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onErrorContainer,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Text(
                    'File not found',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.error),
                  ),
                ],
              ),
            ),
            if (onReattach != null)
              TextButton(
                onPressed: onReattach,
                child: const Text('Re-attach'),
              ),
            if (onRemove != null)
              TextButton(
                style:
                    TextButton.styleFrom(foregroundColor: cs.error),
                onPressed: onRemove,
                child: const Text('Remove'),
              ),
          ],
        ),
      ),
    );
  }
}
