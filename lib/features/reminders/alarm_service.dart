import '../../core/pigeon/api_shims.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlarmService
// ─────────────────────────────────────────────────────────────────────────────
//
// Thin layer between the reminder / call-plan business logic and the native
// AlarmManager via AlarmsApiShim.
//
// Callers never import AlarmsApiShim directly — they use AlarmService so the
// shim swap point remains internal.
// ─────────────────────────────────────────────────────────────────────────────

class AlarmService {
  AlarmService({AlarmsApiShim? shim})
      : _shim = shim ?? AlarmsApiShim.instance;

  final AlarmsApiShim _shim;

  // ── Reminder alarms ───────────────────────────────────────────────────────

  /// Schedule a native alarm for a lead reminder.
  ///
  /// [alarmId]    UUID stored in the Reminders table.
  /// [leadId]     Lead UUID — used to build the deep-link route.
  /// [dueAtMs]    UTC epoch ms when the alarm should fire.
  /// [leadName]   Shown in the notification title.
  /// [notes]      Optional notes shown in the notification body.
  Future<void> scheduleReminder({
    required String alarmId,
    required String leadId,
    required int dueAtMs,
    required String leadName,
    String? notes,
  }) {
    return _shim.scheduleAlarm(
      ScheduledAlarmShim(
        alarmId:    alarmId,
        triggerAtMs: dueAtMs,
        routeUri:   '/leads/$leadId',
        title:      'Reminder: $leadName',
        body:       notes?.isNotEmpty == true ? notes! : 'Tap to open lead.',
        isCallPlan: false,
      ),
    );
  }

  /// Cancel the native alarm for a reminder.
  Future<void> cancelReminder(String alarmId) => _shim.cancelAlarm(alarmId);

  // ── Call-plan alarms ──────────────────────────────────────────────────────

  /// Schedule a native alarm for a call-plan session.
  ///
  /// [alarmId]      UUID stored in CallPlanSchedules.alarmId.
  /// [scheduleId]   CallPlanSchedule UUID — used to build the deep-link route.
  /// [triggerAtMs]  UTC epoch ms when the alarm should fire.
  /// [notes]        Optional notes shown in the notification body.
  Future<void> scheduleCallPlan({
    required String alarmId,
    required String scheduleId,
    required int triggerAtMs,
    String? notes,
  }) {
    return _shim.scheduleAlarm(
      ScheduledAlarmShim(
        alarmId:    alarmId,
        triggerAtMs: triggerAtMs,
        routeUri:   '/call-plan/$scheduleId',
        title:      'Call Plan',
        body:       notes?.isNotEmpty == true ? notes! : 'Time to make your calls.',
        isCallPlan: true,
      ),
    );
  }

  /// Cancel the native alarm for a call-plan schedule.
  Future<void> cancelCallPlan(String alarmId) => _shim.cancelAlarm(alarmId);

  // ── Bulk ops ──────────────────────────────────────────────────────────────

  /// Cancel every Kiko alarm (used only in factory-reset / data-wipe flows).
  Future<void> cancelAll() => _shim.cancelAllAlarms();
}
