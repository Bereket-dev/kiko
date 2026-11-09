// Pigeon IDL — Native pending-events queue drain
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/pending_events.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/PendingEvents.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// A call event that was enqueued by Kotlin while Flutter was not running.
class PendingCallEvent {
  /// E.164-normalised phone number of the other party.
  late String e164;

  /// Direction / outcome: one of "INCOMING", "OUTGOING", or "MISSED".
  late String callType;

  /// Unix epoch milliseconds when the call started.
  late int startedAtMs;

  /// Duration in whole seconds (0 for missed calls).
  late int durationSec;

  /// Status code that was applied during/after the call, if any.
  String? statusCode;

  /// True when the number was not found in the lookup index at call time.
  late bool isUnknown;
}

@HostApi()
abstract class PendingEventsApi {
  /// Return all pending events without removing them from the queue.
  ///
  /// Dart should call [clearPendingEvents] after successfully persisting
  /// the returned events to the Drift database.
  @async
  List<PendingCallEvent> drainPendingEvents();

  /// Remove all events from the native pending-events queue.
  void clearPendingEvents();
}
