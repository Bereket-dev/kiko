import 'package:drift/drift.dart';

import '../db/database.dart';
import '../pigeon/api_shims.dart';

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

  /// Get a single call event by its integer primary key.
  Future<CallEvent?> getCallEventById(int id) {
    return (_db.select(_db.callEvents)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns call events since [sinceMs] that have no attached recording.
  Future<List<CallEvent>> getCallEventsWithNoRecordingSince(
      int sinceMs) async {
    final rows = await _db.customSelect(
      'SELECT ce.* FROM call_events ce '
      'LEFT JOIN call_recordings cr ON cr.call_event_id = ce.id '
      'WHERE ce.started_at >= ? AND cr.id IS NULL '
      'ORDER BY ce.started_at DESC',
      variables: [Variable.withInt(sinceMs)],
    ).get();

    return rows.map((r) => CallEvent(
          id: r.read<int>('id'),
          leadId: r.read<String>('lead_id'),
          e164: r.read<String>('e164'),
          callType: r.read<String>('call_type'),
          startedAt: r.read<int>('started_at'),
          durationSec: r.read<int>('duration_sec'),
          notes: r.readNullable<String>('notes'),
          createdAt: r.read<int>('created_at'),
        )).toList();
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

  // ── Drain pending events from native layer ────────────────────────────────

  /// Drains the native pending-events queue into the Drift DB in one
  /// transaction.
  ///
  /// 1. Calls [PendingEventsApiShim.drainPendingEvents()] — uses a no-op
  ///    in-memory list until Pigeon codegen runs.
  /// 2. For each event: look up leadId by e164; if found, inserts a
  ///    [CallEvent] row, updates [Lead.lastContactAt], and optionally updates
  ///    [Lead.status] when [PendingCallEventShim.statusCode] is set.
  /// 3. Calls [PendingEventsApiShim.clearPendingEvents()] only after
  ///    the transaction commits successfully.
  /// 4. Returns the count of events actually persisted.
  ///
  /// Idempotent: duplicates are silently skipped via the unique constraint on
  /// (leadId, startedAt) — any [SqlException] for a duplicate row is caught and
  /// the loop continues.
  Future<int> drainAndPersistPending() async {
    final events =
        await PendingEventsApiShim.instance.drainPendingEvents();
    if (events.isEmpty) return 0;

    int persisted = 0;

    await _db.transaction(() async {
      for (final event in events) {
        // 1. Look up the lead that owns this phone number.
        final phoneRows = await _db.customSelect(
          'SELECT lead_id FROM lead_phones WHERE e164 = ? LIMIT 1',
          variables: [Variable.withString(event.e164)],
        ).get();

        if (phoneRows.isEmpty) {
          // Unknown caller — no matching lead; skip.
          continue;
        }

        final leadId = phoneRows.first.read<String>('lead_id');
        final now = DateTime.now().millisecondsSinceEpoch;

        // 2. Insert the call event; skip on unique-constraint violation.
        try {
          await _db.into(_db.callEvents).insert(
                CallEventsCompanion.insert(
                  leadId: leadId,
                  e164: event.e164,
                  callType: event.callType,
                  startedAt: event.startedAtMs,
                  durationSec: Value(event.durationSec),
                  createdAt: now,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        } catch (_) {
          // Unique constraint violation or other insert error — skip this row.
          continue;
        }

        persisted++;

        // 3. Update lastContactAt on the lead.
        await (_db.update(_db.leads)
              ..where((t) => t.id.equals(leadId)))
            .write(
          LeadsCompanion(
            lastContactAt: Value(event.startedAtMs),
            updatedAt: Value(now),
          ),
        );

        // 4. If the event carries a status code, update the lead status too.
        if (event.statusCode != null && event.statusCode!.isNotEmpty) {
          await (_db.update(_db.leads)
                ..where((t) => t.id.equals(leadId)))
              .write(
            LeadsCompanion(
              status: Value(event.statusCode!),
              updatedAt: Value(now),
            ),
          );
        }
      }
    });

    // 5. Clear the native queue only after a successful commit.
    if (persisted > 0) {
      await PendingEventsApiShim.instance.clearPendingEvents();
    }

    return persisted;
  }
}
