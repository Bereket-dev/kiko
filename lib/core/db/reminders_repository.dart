import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RemindersRepository
// ─────────────────────────────────────────────────────────────────────────────

class RemindersRepository {
  RemindersRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Create ────────────────────────────────────────────────────────────────

  Future<Reminder> createReminder({
    required String leadId,
    required int dueAtMs,
    String? notes,
  }) async {
    final alarmId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowId = await _db.into(_db.reminders).insert(
          RemindersCompanion.insert(
            leadId: leadId,
            alarmId: alarmId,
            dueAt: dueAtMs,
            notes: Value(notes),
            createdAt: now,
          ),
        );
    return (_db.select(_db.reminders)
          ..where((t) => t.id.equals(rowId)))
        .getSingle();
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Reminder?> getPendingReminderForLead(String leadId) {
    return (_db.select(_db.reminders)
          ..where((t) =>
              t.leadId.equals(leadId) & t.state.equals('PENDING'))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<Reminder?> getReminderById(int id) {
    return (_db.select(_db.reminders)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<Reminder>> getPendingReminders() {
    return (_db.select(_db.reminders)
          ..where((t) => t.state.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .get();
  }

  Stream<List<Reminder>> watchPendingReminders() {
    return (_db.select(_db.reminders)
          ..where((t) => t.state.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
        .watch();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> markFired(int reminderId) async {
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .write(const RemindersCompanion(state: Value('FIRED')));
  }

  Future<void> markDismissed(int reminderId) async {
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .write(const RemindersCompanion(state: Value('DISMISSED')));
  }

  Future<Reminder> rescheduleReminder(int reminderId, int newDueAtMs) async {
    final alarmId = _uuid.v4();
    await (_db.update(_db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .write(RemindersCompanion(
          alarmId: Value(alarmId),
          dueAt: Value(newDueAtMs),
          state: const Value('PENDING'),
        ));
    return (_db.select(_db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .getSingle();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteReminder(int reminderId) async {
    await (_db.delete(_db.reminders)
          ..where((t) => t.id.equals(reminderId)))
        .go();
  }
}
