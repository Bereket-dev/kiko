// Pigeon IDL — AlarmManager scheduling
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/alarms_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/AlarmsApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// Descriptor for a single AlarmManager alarm.
class ScheduledAlarm {
  /// Unique identifier for this alarm (UUID string).
  late String alarmId;

  /// Unix epoch milliseconds at which the alarm should fire.
  late int triggerAtMs;

  /// Deep-link URI to navigate to when the user taps the notification.
  ///
  /// Example: "/leads/abc123" or "/call-plan/xyz456".
  late String routeUri;

  /// Short notification title shown to the user.
  late String title;

  /// Notification body text shown to the user.
  late String body;
}

@HostApi()
abstract class AlarmsApi {
  /// Schedule (or reschedule) the alarm described by [alarm].
  ///
  /// If an alarm with the same [alarmId] already exists it is replaced.
  /// Uses setAlarmClock() on API 21+ for exact delivery.
  void scheduleAlarm(ScheduledAlarm alarm);

  /// Cancel the alarm identified by [alarmId], if it exists.
  void cancelAlarm(String alarmId);

  /// Cancel all alarms registered by Kiko.
  void cancelAllAlarms();
}
