import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CallPlanRepository
// ─────────────────────────────────────────────────────────────────────────────

class CallPlanRepository {
  CallPlanRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Schedules ─────────────────────────────────────────────────────────────

  Future<CallPlanSchedule> createSchedule({
    required int triggerAtMs,
    String? filterBusinessType,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final alarmId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.callPlanSchedules).insert(
          CallPlanSchedulesCompanion.insert(
            id: id,
            alarmId: alarmId,
            triggerAt: triggerAtMs,
            filterBusinessType: Value(filterBusinessType),
            notes: Value(notes),
            createdAt: now,
          ),
        );

    return (_db.select(_db.callPlanSchedules)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<CallPlanSchedule?> getScheduleById(String id) {
    return (_db.select(_db.callPlanSchedules)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<CallPlanSchedule>> getPendingSchedules() {
    return (_db.select(_db.callPlanSchedules)
          ..where((t) => t.state.equals('PENDING'))
          ..orderBy([(t) => OrderingTerm.asc(t.triggerAt)]))
        .get();
  }

  Future<void> markScheduleActive(String id) async {
    await (_db.update(_db.callPlanSchedules)
          ..where((t) => t.id.equals(id)))
        .write(const CallPlanSchedulesCompanion(state: Value('ACTIVE')));
  }

  Future<void> markScheduleDone(String id) async {
    await (_db.update(_db.callPlanSchedules)
          ..where((t) => t.id.equals(id)))
        .write(const CallPlanSchedulesCompanion(state: Value('DONE')));
  }

  Future<void> deleteSchedule(String id) async {
    await (_db.delete(_db.callPlanSchedules)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  // ── Chosen leads ──────────────────────────────────────────────────────────

  Future<void> setScheduleLeads(
      String scheduleId, List<String> leadIds) async {
    await _db.transaction(() async {
      await (_db.delete(_db.callPlanLeads)
            ..where((t) => t.scheduleId.equals(scheduleId)))
          .go();

      for (final (i, leadId) in leadIds.indexed) {
        await _db.into(_db.callPlanLeads).insert(
              CallPlanLeadsCompanion.insert(
                scheduleId: scheduleId,
                leadId: leadId,
                position: Value(i),
              ),
            );
      }
    });
  }

  Future<List<CallPlanLead>> getLeadsForSchedule(String scheduleId) {
    return (_db.select(_db.callPlanLeads)
          ..where((t) => t.scheduleId.equals(scheduleId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  Future<void> markLeadDone(int callPlanLeadId) async {
    await (_db.update(_db.callPlanLeads)
          ..where((t) => t.id.equals(callPlanLeadId)))
        .write(const CallPlanLeadsCompanion(done: Value(true)));
  }

  // ── Dismissed numbers ─────────────────────────────────────────────────────

  Future<void> dismissNumber(String e164) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.into(_db.dismissedNumbers).insertOnConflictUpdate(
          DismissedNumbersCompanion.insert(e164: e164, dismissedAt: now),
        );
  }

  Future<bool> isNumberDismissed(String e164) async {
    final row = await (_db.select(_db.dismissedNumbers)
          ..where((t) => t.e164.equals(e164)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> clearDismissedNumbers() async {
    await _db.delete(_db.dismissedNumbers).go();
  }

  Future<List<DismissedNumber>> getAllDismissedNumbers() {
    return _db.select(_db.dismissedNumbers).get();
  }
}
