import '../../core/pigeon/api_shims.dart';
import '../../core/db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecordingMatchEngine
// ─────────────────────────────────────────────────────────────────────────────
//
// Scores a [RecordingFileShim] against a [CallEvent] using three signals:
//
//   Signal                              Weight
//   ────────────────────────────────────────────
//   Timestamp within 5 minutes          0.40
//   Duration within 15 seconds          0.40
//   Display name contains last 9 digits 0.20
//   ─────────────────────────────────────
//   Maximum                             1.00
//
// Thresholds:
//   score >= 0.85  → auto-attach (no confirmation needed)
//   score >= 0.60  → possible match (show confirm UI)
//   score <  0.60  → no match
// ─────────────────────────────────────────────────────────────────────────────

class RecordingMatchResult {
  const RecordingMatchResult({
    required this.file,
    required this.score,
  });

  final RecordingFileShim file;

  /// 0.0 – 1.0 composite score.
  final double score;

  bool get isAutoMatch => score >= 0.85;
  bool get isPossibleMatch => score >= 0.60;
  bool get isNoMatch => score < 0.60;
}

class RecordingMatchEngine {
  const RecordingMatchEngine();

  static const double _timestampWeight = 0.40;
  static const double _durationWeight = 0.40;
  static const double _nameWeight = 0.20;
  static const Duration _timestampTolerance = Duration(minutes: 5);
  static const int _durationToleranceSec = 15;

  /// Scores a single [file] against a [callEvent].
  RecordingMatchResult score(RecordingFileShim file, CallEvent callEvent) {
    double s = 0.0;

    // ── Timestamp signal ───────────────────────────────────────────────────
    final diffMs =
        (file.startedAtMs - callEvent.startedAt).abs();
    if (diffMs <= _timestampTolerance.inMilliseconds) {
      // Linear decay: full score at 0ms, 0 at tolerance boundary.
      final ratio = 1.0 - (diffMs / _timestampTolerance.inMilliseconds);
      s += _timestampWeight * ratio;
    }

    // ── Duration signal ────────────────────────────────────────────────────
    final fileDurSec = file.durationMs ~/ 1000;
    final callDurSec = callEvent.durationSec;
    final durDiff = (fileDurSec - callDurSec).abs();
    if (durDiff <= _durationToleranceSec) {
      final ratio = 1.0 - (durDiff / _durationToleranceSec);
      s += _durationWeight * ratio;
    }

    // ── Display name signal ────────────────────────────────────────────────
    final digits = callEvent.e164.replaceAll(RegExp(r'\D'), '');
    final last9 = digits.length >= 9 ? digits.substring(digits.length - 9) : digits;
    if (last9.isNotEmpty &&
        file.displayName.replaceAll(RegExp(r'\D'), '').contains(last9)) {
      s += _nameWeight;
    }

    return RecordingMatchResult(file: file, score: s.clamp(0.0, 1.0));
  }

  /// Finds the best-scoring file from [files] for [callEvent].
  ///
  /// Returns null if no file scores at or above the possible-match threshold.
  RecordingMatchResult? findBestMatch(
      List<RecordingFileShim> files, CallEvent callEvent) {
    if (files.isEmpty) return null;

    final results = files
        .map((f) => score(f, callEvent))
        .where((r) => r.isPossibleMatch)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return results.isNotEmpty ? results.first : null;
  }
}
