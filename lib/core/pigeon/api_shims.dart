// ─────────────────────────────────────────────────────────────────────────────
// api_shims.dart
//
// Shim interfaces that mirror the Pigeon-generated APIs.
// Replace with the real Pigeon-generated classes by running:
//   dart run pigeon --input pigeons/<name>.dart
// for each IDL file, then remove these shims.
//
// Each abstract class defines the contract; the _NoOp* concrete subclass is
// the default singleton used until real Pigeon codegen runs.
// Swap at app init:
//   PendingEventsApiShim.instance = MyRealImpl();
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// PendingCallEventShim — mirrors PendingCallEvent from Pigeon IDL
// ─────────────────────────────────────────────────────────────────────────────

class PendingCallEventShim {
  const PendingCallEventShim({
    required this.e164,
    required this.callType,
    required this.startedAtMs,
    required this.durationSec,
    this.statusCode,
    this.isUnknown = false,
  });

  /// E.164-normalised phone number, e.g. "+251911234567".
  final String e164;

  /// One of: INCOMING | OUTGOING | MISSED
  final String callType;

  /// Call start time in UTC epoch milliseconds.
  final int startedAtMs;

  /// Call duration in seconds.
  final int durationSec;

  /// Optional CRM status code to set on the lead after persisting.
  final String? statusCode;

  /// True if the caller was not found in the native lookup index.
  final bool isUnknown;
}

// ─────────────────────────────────────────────────────────────────────────────
// PendingEventsApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class PendingEventsApiShim {
  /// Drains and returns the in-memory pending-events queue.
  Future<List<PendingCallEventShim>> drainPendingEvents();

  /// Clears the native pending-events queue after successful DB commit.
  Future<void> clearPendingEvents();

  /// Swappable singleton — replace with the real Pigeon impl at app init.
  static PendingEventsApiShim instance = _NoOpPendingEventsApi();
}

class _NoOpPendingEventsApi implements PendingEventsApiShim {
  @override
  Future<List<PendingCallEventShim>> drainPendingEvents() async => [];

  @override
  Future<void> clearPendingEvents() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// CallLogEntryShim — mirrors CallLogEntry from Pigeon IDL
// ─────────────────────────────────────────────────────────────────────────────

class CallLogEntryShim {
  const CallLogEntryShim({
    required this.e164,
    required this.callType,
    required this.startedAtMs,
    required this.durationSec,
    this.displayName,
  });

  /// E.164-normalised phone number.
  final String e164;

  /// One of: INCOMING | OUTGOING | MISSED
  final String callType;

  /// Call start time in UTC epoch milliseconds.
  final int startedAtMs;

  /// Call duration in seconds.
  final int durationSec;

  /// Device contact display name, if available.
  final String? displayName;
}

// ─────────────────────────────────────────────────────────────────────────────
// CallLogApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class CallLogApiShim {
  /// Returns up to [limit] call log entries since [sinceMs] (epoch ms).
  Future<List<CallLogEntryShim>> getRecentCalls({
    required int sinceMs,
    required int limit,
  });

  /// Swappable singleton.
  static CallLogApiShim instance = _NoOpCallLogApi();
}

class _NoOpCallLogApi implements CallLogApiShim {
  @override
  Future<List<CallLogEntryShim>> getRecentCalls({
    required int sinceMs,
    required int limit,
  }) async =>
      [];
}

// ─────────────────────────────────────────────────────────────────────────────
// RecordingFileShim — mirrors RecordingFile from Pigeon IDL
// ─────────────────────────────────────────────────────────────────────────────

class RecordingFileShim {
  const RecordingFileShim({
    required this.uri,
    required this.displayName,
    required this.startedAtMs,
    required this.durationMs,
    this.sizeBytes = 0,
  });

  /// SAF content URI or file URI.
  final String uri;

  /// Human-readable filename.
  final String displayName;

  /// File creation/modification time in UTC epoch milliseconds.
  final int startedAtMs;

  /// Recording duration in milliseconds.
  final int durationMs;

  /// File size in bytes.
  final int sizeBytes;
}

// ─────────────────────────────────────────────────────────────────────────────
// RecordingFilesApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class RecordingFilesApiShim {
  /// Returns recording files created at or after [sinceMs] (epoch ms).
  Future<List<RecordingFileShim>> getRecordingsSince(int sinceMs);

  /// Swappable singleton.
  static RecordingFilesApiShim instance = _NoOpRecordingFilesApi();
}

class _NoOpRecordingFilesApi implements RecordingFilesApiShim {
  @override
  Future<List<RecordingFileShim>> getRecordingsSince(int sinceMs) async => [];
}

// ─────────────────────────────────────────────────────────────────────────────
// PermissionStatusShim — mirrors PermissionStatus from Pigeon IDL
// ─────────────────────────────────────────────────────────────────────────────

class PermissionStatusShim {
  const PermissionStatusShim({
    required this.permission,
    required this.isGranted,
  });

  final String permission;
  final bool isGranted;
}

// ─────────────────────────────────────────────────────────────────────────────
// PermissionsApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class PermissionsApiShim {
  /// Returns the current status of all monitored permissions.
  Future<List<PermissionStatusShim>> getAllPermissionStatuses();

  /// Requests the specified permission.
  /// Returns updated status after the request.
  Future<PermissionStatusShim> requestPermission(String permission);

  /// Opens the OS settings screen for the app.
  Future<void> openAppSettings();

  /// Swappable singleton.
  static PermissionsApiShim instance = _NoOpPermissionsApi();
}

class _NoOpPermissionsApi implements PermissionsApiShim {
  @override
  Future<List<PermissionStatusShim>> getAllPermissionStatuses() async => [];

  @override
  Future<PermissionStatusShim> requestPermission(String permission) async =>
      PermissionStatusShim(permission: permission, isGranted: false);

  @override
  Future<void> openAppSettings() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// SettingsSyncApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class SettingsSyncApiShim {
  /// Pushes the current overlay settings to the native layer.
  Future<void> syncOverlaySettings({
    required bool masterEnabled,
    required bool showHistory,
    required bool askUnknown,
  });

  /// Swappable singleton.
  static SettingsSyncApiShim instance = _NoOpSettingsSyncApi();
}

class _NoOpSettingsSyncApi implements SettingsSyncApiShim {
  @override
  Future<void> syncOverlaySettings({
    required bool masterEnabled,
    required bool showHistory,
    required bool askUnknown,
  }) async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// ScheduledAlarmShim — mirrors ScheduledAlarm from Pigeon IDL
// ─────────────────────────────────────────────────────────────────────────────

class ScheduledAlarmShim {
  const ScheduledAlarmShim({
    required this.alarmId,
    required this.triggerAtMs,
    required this.routeUri,
    required this.title,
    required this.body,
    this.isCallPlan = false,
  });

  /// Unique identifier for this alarm (UUID string).
  final String alarmId;

  /// Unix epoch milliseconds at which the alarm should fire.
  final int triggerAtMs;

  /// Deep-link route URI opened when the user taps the notification.
  /// Example: "/leads/abc123" or "/call-plan/xyz456".
  final String routeUri;

  /// Short notification title shown to the user.
  final String title;

  /// Notification body text.
  final String body;

  /// True for Call Plan alarms (routed to the call-plan notification channel).
  final bool isCallPlan;
}

// ─────────────────────────────────────────────────────────────────────────────
// AlarmsApiShim
// ─────────────────────────────────────────────────────────────────────────────

abstract class AlarmsApiShim {
  /// Schedule (or replace) the alarm described by [alarm].
  Future<void> scheduleAlarm(ScheduledAlarmShim alarm);

  /// Cancel the alarm identified by [alarmId], if it exists.
  Future<void> cancelAlarm(String alarmId);

  /// Cancel all alarms registered by Kiko.
  Future<void> cancelAllAlarms();

  /// Swappable singleton — replace with the real Pigeon impl at app init.
  static AlarmsApiShim instance = _NoOpAlarmsApi();
}

class _NoOpAlarmsApi implements AlarmsApiShim {
  @override
  Future<void> scheduleAlarm(ScheduledAlarmShim alarm) async {}

  @override
  Future<void> cancelAlarm(String alarmId) async {}

  @override
  Future<void> cancelAllAlarms() async {}
}
