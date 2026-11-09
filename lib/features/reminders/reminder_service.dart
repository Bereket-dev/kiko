import '../../core/db/database.dart';
import '../../core/db/reminders_repository.dart';
import 'alarm_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReminderService
// ─────────────────────────────────────────────────────────────────────────────
//
// Coordinates between RemindersRepository (DB) and AlarmService (native
// AlarmManager).  All reminder mutations go through here so the DB row and
// the native alarm always stay in sync.
//
// ── Public surface ─────────────────────────────────────────────────────────
//
//  createAndSchedule(...)   → insert DB row + schedule native alarm
//  cancel(reminderId)       → cancel native alarm + mark DISMISSED in DB
//  reschedule(reminderId, newDueAtMs)
//                           → cancel old alarm + schedule new one + update DB
//  rescheduleAll()          → called on boot-drain; re-arms every PENDING alarm
//
// ─────────────────────────────────────────────────────────────────────────────

class ReminderService {
  ReminderService({
    required RemindersRepository remindersRepo,
    required AlarmService alarmService,
  })  : _repo = remindersRepo,
        _alarm = alarmService;

  final RemindersRepository _repo;
  final AlarmService _alarm;

  // ── Create ────────────────────────────────────────────────────────────────

  /// Create a DB reminder row and schedule the native alarm.
  ///
  /// Replaces any existing PENDING reminder for [leadId] (one-per-lead rule):
  /// the old native alarm is cancelled first.
  ///
  /// Returns the newly created [Reminder].
  Future<Reminder> createAndSchedule({
    required String leadId,
    required String leadName,
    required int dueAtMs,
    String? notes,
  }) async {
    // Cancel existing reminder for this lead, if any.
    final existing = await _repo.getPendingReminderForLead(leadId);
    if (existing != null) {
      await _alarm.cancelReminder(existing.alarmId);
      await _repo.deleteReminder(existing.id);
    }

    // Create new DB row.
    final reminder = await _repo.createReminder(
      leadId:  leadId,
      dueAtMs: dueAtMs,
      notes:   notes,
    );

    // Schedule native alarm.
    await _alarm.scheduleReminder(
      alarmId:  reminder.alarmId,
      leadId:   leadId,
      dueAtMs:  dueAtMs,
      leadName: leadName,
      notes:    notes,
    );

    return reminder;
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  /// Cancel the native alarm and mark the DB row DISMISSED.
  Future<void> cancel(int reminderId) async {
    final reminder = await _getById(reminderId);
    if (reminder == null) return;
    await _alarm.cancelReminder(reminder.alarmId);
    await _repo.markDismissed(reminderId);
  }

  // ── Reschedule ────────────────────────────────────────────────────────────

  /// Move reminder to [newDueAtMs]: cancels old alarm, updates DB, schedules new alarm.
  ///
  /// [leadName] is required to rebuild the notification title.
  Future<Reminder> reschedule({
    required int reminderId,
    required int newDueAtMs,
    required String leadName,
    String? notes,
  }) async {
    final old = await _getById(reminderId);
    if (old != null) {
      await _alarm.cancelReminder(old.alarmId);
    }

    final updated = await _repo.rescheduleReminder(reminderId, newDueAtMs);

    await _alarm.scheduleReminder(
      alarmId:  updated.alarmId,
      leadId:   updated.leadId,
      dueAtMs:  newDueAtMs,
      leadName: leadName,
      notes:    notes ?? updated.notes,
    );

    return updated;
  }

  // ── Boot drain ────────────────────────────────────────────────────────────

  /// Re-arm every PENDING reminder in the DB.
  ///
  /// Called once after app cold-start (boot drain) to cover the case where
  /// AlarmManager lost its alarms while the app process was dead.
  /// Skips reminders whose dueAt is already in the past.
  ///
  /// [leadNames] is a map of leadId → name used to build notification titles.
  /// Pass an empty map to use a generic title.
  Future<void> rescheduleAll({Map<String, String> leadNames = const {}}) async {
    final pending = await _repo.getPendingReminders();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final reminder in pending) {
      if (reminder.dueAt <= now) {
        // Already past — mark fired so it doesn't pollute future reschedules.
        await _repo.markFired(reminder.id);
        continue;
      }

      final name = leadNames[reminder.leadId] ?? 'Lead';
      await _alarm.scheduleReminder(
        alarmId:  reminder.alarmId,
        leadId:   reminder.leadId,
        dueAtMs:  reminder.dueAt,
        leadName: name,
        notes:    reminder.notes,
      );
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<Reminder?> _getById(int id) =>
      _repo.getReminderById(id);
}
