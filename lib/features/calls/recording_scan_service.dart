import 'dart:async';
import 'dart:developer' as dev;

import '../../core/db/call_events_repository.dart';
import '../../core/db/database.dart';
import '../../core/pigeon/api_shims.dart';
import 'recording_match_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScanResult — outcome of a single recording scan pass
// ─────────────────────────────────────────────────────────────────────────────

class ScanResult {
  const ScanResult({
    required this.autoAttached,
    required this.possibleMatches,
  });

  /// Call events that had a recording auto-attached (score ≥ 0.85).
  final int autoAttached;

  /// Possible matches that need user confirmation (0.60 – 0.84).
  final List<PossibleRecordingMatch> possibleMatches;
}

class PossibleRecordingMatch {
  const PossibleRecordingMatch({
    required this.callEvent,
    required this.result,
  });

  final CallEvent callEvent;
  final RecordingMatchResult result;
}

// ─────────────────────────────────────────────────────────────────────────────
// RecordingScanService
// ─────────────────────────────────────────────────────────────────────────────
//
// Scan triggers per spec §5.10:
//   1. 30 s after call ends if app is open (scheduleDelayedScan, 2 retries).
//   2. Next app launch (scanAll called from PendingDrainService / AppLifecycle).
//   3. When the user opens call history.
//   4. Pull-to-refresh in call history.
//
// No folder watchers — all scanning is on-demand.
// ─────────────────────────────────────────────────────────────────────────────

class RecordingScanService {
  RecordingScanService({
    required CallEventsRepository callEventsRepo,
  }) : _callEvents = callEventsRepo;

  final CallEventsRepository _callEvents;
  final _engine = const RecordingMatchEngine();

  // Pending delayed scans: callEventId → timer
  final _pendingTimers = <int, Timer>{};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Scan for a recording for a single [callEventId] after a 30 s delay.
  ///
  /// If no match is found on the first attempt, retries once more after
  /// another 30 s (2 retries total).
  void scheduleDelayedScan(int callEventId, {int retriesLeft = 2}) {
    _pendingTimers[callEventId]?.cancel();
    _pendingTimers[callEventId] = Timer(
      const Duration(seconds: 30),
      () async {
        _pendingTimers.remove(callEventId);
        final result = await _scanSingle(callEventId);
        if (result == null && retriesLeft > 0) {
          scheduleDelayedScan(callEventId, retriesLeft: retriesLeft - 1);
        }
      },
    );
  }

  /// Cancel any pending delayed scan for [callEventId].
  void cancelDelayedScan(int callEventId) {
    _pendingTimers[callEventId]?.cancel();
    _pendingTimers.remove(callEventId);
  }

  /// Scan all recent call events that have no attached recording.
  ///
  /// Returns aggregated [ScanResult] — callers can use [ScanResult.possibleMatches]
  /// to show a confirm UI.
  Future<ScanResult> scanAll() async {
    int autoAttached = 0;
    final possibles = <PossibleRecordingMatch>[];

    // Only scan calls from the last 30 days that have no recording yet.
    final sinceMs = DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch;

    final recentFiles = await RecordingFilesApiShim.instance
        .getRecordingsSince(sinceMs);

    if (recentFiles.isEmpty) {
      return ScanResult(autoAttached: 0, possibleMatches: []);
    }

    // Get all call events with no recording from the same window.
    // We re-use a custom query; no extra repo method needed.
    final candidates =
        await _callEvents.getCallEventsWithNoRecordingSince(sinceMs);

    for (final event in candidates) {
      final match = _engine.findBestMatch(recentFiles, event);
      if (match == null) continue;

      if (match.isAutoMatch) {
        try {
          await _callEvents.attachRecording(
            callEventId: event.id,
            uri: match.file.uri,
            displayName: match.file.displayName,
            durationMs: match.file.durationMs,
            sizeBytes: match.file.sizeBytes,
          );
          autoAttached++;
        } catch (e) {
          dev.log('Auto-attach failed for event ${event.id}: $e',
              name: 'RecordingScanService');
        }
      } else {
        possibles.add(PossibleRecordingMatch(callEvent: event, result: match));
      }
    }

    dev.log(
        'scanAll: autoAttached=$autoAttached possibles=${possibles.length}',
        name: 'RecordingScanService');

    return ScanResult(autoAttached: autoAttached, possibleMatches: possibles);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Scan for recordings for a single call event.
  ///
  /// Returns the attached [RecordingMatchResult] on success, or null if no
  /// suitable match was found.
  Future<RecordingMatchResult?> _scanSingle(int callEventId) async {
    try {
      final event = await _callEvents.getCallEventById(callEventId);
      if (event == null) return null;

      // Look for files since 1 minute before the call started.
      final sinceMs = event.startedAt - const Duration(minutes: 1).inMilliseconds;
      final files =
          await RecordingFilesApiShim.instance.getRecordingsSince(sinceMs);

      final match = _engine.findBestMatch(files, event);
      if (match == null) return null;

      if (match.isAutoMatch) {
        await _callEvents.attachRecording(
          callEventId: event.id,
          uri: match.file.uri,
          displayName: match.file.displayName,
          durationMs: match.file.durationMs,
          sizeBytes: match.file.sizeBytes,
        );
        return match;
      }

      // Possible match — caller must show confirm UI.
      return match;
    } catch (e) {
      dev.log('_scanSingle error for event $callEventId: $e',
          name: 'RecordingScanService');
      return null;
    }
  }
}
