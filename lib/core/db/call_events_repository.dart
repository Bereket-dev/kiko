import 'package:drift/drift.dart';

import '../db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CallEventsRepository
// ─────────────────────────────────────────────────────────────────────────────

class CallEventsRepository {
  CallEventsRepository(this._db);

  final AppDatabase _db;

  // ── Create ────────────────────────────────────────────────────────────────

  Future<CallEvent> createCallEvent({
    required String leadId,
    required String e164,
    required String callType, // INCOMING | OUTGOING | MISSED
    required int startedAtMs,
    int durationSec = 0,
    String? notes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowId = await _db.into(_db.callEvents).insert(
          CallEventsCompanion.insert(
            leadId: leadId,
            e164: e164,
            callType: callType,
            startedAt: startedAtMs,
            durationSec: Value(durationSec),
            notes: Value(notes),
            createdAt: now,
          ),
        );
    return (_db.select(_db.callEvents)
          ..where((t) => t.id.equals(rowId)))
        .getSingle();
  }

  // ── Batch insert (drain pending events) ──────────────────────────────────

  Future<List<CallEvent>> insertBatch(
      List<CallEventsCompanion> companions) async {
    final inserted = <CallEvent>[];
    await _db.transaction(() async {
      for (final c in companions) {
        final id = await _db.into(_db.callEvents).insert(c);
        final row = await (_db.select(_db.callEvents)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        inserted.add(row);
      }
    });
    return inserted;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Stream<List<CallEvent>> watchCallsForLead(String leadId) {
    return (_db.select(_db.callEvents)
          ..where((t) => t.leadId.equals(leadId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .watch();
  }

  Future<List<CallEvent>> getCallsForLead(String leadId) {
    return (_db.select(_db.callEvents)
          ..where((t) => t.leadId.equals(leadId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
        .get();
  }

  Future<CallEvent?> getLatestCallForLead(String leadId) {
    return (_db.select(_db.callEvents)
          ..where((t) => t.leadId.equals(leadId))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateNotes(int callEventId, String notes) async {
    await (_db.update(_db.callEvents)
          ..where((t) => t.id.equals(callEventId)))
        .write(CallEventsCompanion(notes: Value(notes)));
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteCallEvent(int callEventId) async {
    await (_db.delete(_db.callEvents)
          ..where((t) => t.id.equals(callEventId)))
        .go();
  }

  // ── Recordings ────────────────────────────────────────────────────────────

  Future<CallRecording> attachRecording({
    required int callEventId,
    required String uri,
    required String displayName,
    int durationMs = 0,
    int sizeBytes = 0,
    bool isManuallyAttached = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rowId = await _db.into(_db.callRecordings).insert(
          CallRecordingsCompanion.insert(
            callEventId: callEventId,
            uri: uri,
            displayName: displayName,
            durationMs: Value(durationMs),
            sizeBytes: Value(sizeBytes),
            isManuallyAttached: Value(isManuallyAttached),
            createdAt: now,
          ),
        );
    return (_db.select(_db.callRecordings)
          ..where((t) => t.id.equals(rowId)))
        .getSingle();
  }

  Future<List<CallRecording>> getRecordingsForCall(int callEventId) {
    return (_db.select(_db.callRecordings)
          ..where((t) => t.callEventId.equals(callEventId)))
        .get();
  }

  Future<void> removeRecording(int recordingId) async {
    await (_db.delete(_db.callRecordings)
          ..where((t) => t.id.equals(recordingId)))
        .go();
  }
}
