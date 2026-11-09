import '../../core/db/call_plan_repository.dart';
import '../../core/db/database.dart';
import 'alarm_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CallPlanService
// ─────────────────────────────────────────────────────────────────────────────
//
// Coordinates between CallPlanRepository (DB) and AlarmService (native
// AlarmManager).  All call-plan schedule mutations go through here so the DB
// row and the native alarm always stay in sync.
//
// ── Public surface ─────────────────────────────────────────────────────────
//
//  createAndSchedule(...)   → insert DB row + schedule native alarm
//  cancel(scheduleId)       → cancel native alarm + delete DB row
//  rescheduleAll()          → re-arm every PENDING schedule (boot drain)
//
// One-per-device rule: each schedule is independent; multiple schedules can
// coexist (each has its own alarmId UUID).
// ─────────────────────────────────────────────────────────────────────────────

class CallPlanService {
  CallPlanService({
    required CallPlanRepository callPlanRepo,
    required AlarmService alarmService,
  })  : _repo = callPlanRepo,
        _alarm = alarmService;

  final CallPlanRepository _repo;
  final AlarmService _alarm;

  // ── Create ────────────────────────────────────────────────────────────────

  /// Create a DB schedule row, optionally pin chosen leads, and schedule the
  /// native alarm.
  ///
  /// [triggerAtMs]         UTC epoch ms when the alarm should fire.
  /// [leadIds]             Optional list of specific lead UUIDs to include;
  ///                       if empty the schedule falls back to
  ///                       [filterBusinessType] or due-today logic.
  /// [filterBusinessType]  Optional business-type string to filter leads.
  /// [notes]               Optional notes shown in the notification body.
  ///
  /// Returns the newly created [CallPlanSchedule].
  Future<CallPlanSchedule> createAndSchedule({
    required int triggerAtMs,
    List<String> leadIds = const [],
    String? filterBusinessType,
    String? notes,
  }) async {
    final schedule = await _repo.createSchedule(
      triggerAtMs: triggerAtMs,
      filterBusinessType: filterBusinessType,
      notes: notes,
    );

    if (leadIds.isNotEmpty) {
      await _repo.setScheduleLeads(schedule.id, leadIds);
    }

    await _alarm.scheduleCallPlan(
      alarmId: schedule.alarmId,
      scheduleId: schedule.id,
      triggerAtMs: triggerAtMs,
      notes: notes,
    );

    return schedule;
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Cancel the native alarm and delete the DB row for [scheduleId].
  Future<void> cancel(String scheduleId) async {
    final schedule = await _repo.getScheduleById(scheduleId);
    if (schedule == null) return;
    await _alarm.cancelCallPlan(schedule.alarmId);
    await _repo.deleteSchedule(scheduleId);
  }

  // ── Reschedule ────────────────────────────────────────────────────────────

  /// Re-arm every PENDING call-plan schedule in the DB.
  ///
  /// Called once after cold-start (boot drain) to cover the case where
  /// AlarmManager lost its alarms while the app process was dead.
  /// Skips schedules whose triggerAt is already in the past (marks them DONE).
  Future<void> rescheduleAll() async {
    final pending = await _repo.getPendingSchedules();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final schedule in pending) {
      if (schedule.triggerAt <= now) {
        // Already past — mark done so it doesn't pollute future reschedules.
        await _repo.markScheduleDone(schedule.id);
        continue;
      }

      await _alarm.scheduleCallPlan(
        alarmId: schedule.alarmId,
        scheduleId: schedule.id,
        triggerAtMs: schedule.triggerAt,
        notes: schedule.notes,
      );
    }
  }
}
