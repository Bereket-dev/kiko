// Pigeon IDL — Recent calls from the system call log
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/call_log_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/CallLogApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// A single entry from the Android system call log.
class CallLogEntry {
  /// E.164-normalised phone number (best-effort; may be raw if parsing fails).
  late String e164;

  /// Contact display name from the system; null when not in contacts.
  String? name;

  /// Direction / outcome: one of "INCOMING", "OUTGOING", or "MISSED".
  late String callType;

  /// Unix epoch milliseconds when the call started.
  late int timestampMs;

  /// Duration in whole seconds (0 for missed/rejected calls).
  late int durationSec;
}

@HostApi()
abstract class CallLogApi {
  /// Fetch up to [limit] call-log entries starting after [sinceTimestampMs].
  ///
  /// Results are ordered newest-first.  Only calls whose timestamp is strictly
  /// greater than [sinceTimestampMs] are included.
  @async
  List<CallLogEntry> getRecentCalls(int sinceTimestampMs, int limit);
}
