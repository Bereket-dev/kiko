// ignore_for_file: lines_longer_than_80_chars
// Integration test: pending drain
//
// Verifies that PendingDrainService.drain() completes without error when
// the native queue is empty (count=0) and when events are present.
//
// PendingDrainService calls:
//   1. CallEventsRepository.drainAndPersistPending() → returns int count
//   2. If count > 0, refreshes the lookup index for recently updated leads.
//
// drainAndPersistPending() uses PendingEventsApiShim which is a no-op stub
// (returns []) in tests. To test the drain flow with real events, we swap
// the shim instance with a fake that returns test events.

import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/core/db/call_events_repository.dart';
import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/db/leads_repository.dart';
import 'package:kiko/core/db/pending_drain_service.dart';
import 'package:kiko/core/pigeon/api_shims.dart';
import 'package:kiko/core/utils/lookup_index_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake PendingEventsApiShim — injects test events
// ─────────────────────────────────────────────────────────────────────────────

class _FakePendingEventsApi implements PendingEventsApiShim {
  _FakePendingEventsApi(this._events);

  final List<PendingCallEventShim> _events;
  bool clearCalled = false;

  @override
  Future<List<PendingCallEventShim>> drainPendingEvents() async => _events;

  @override
  Future<void> clearPendingEvents() async {
    clearCalled = true;
  }
}

// Empty no-op replacement for tearDown (can't access private _NoOpPendingEventsApi).
class _EmptyPendingEventsApi implements PendingEventsApiShim {
  @override
  Future<List<PendingCallEventShim>> drainPendingEvents() async => [];

  @override
  Future<void> clearPendingEvents() async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake LookupIndexService — tracks upsert calls
// ─────────────────────────────────────────────────────────────────────────────

class _FakeLookupIndexService extends LookupIndexService {
  const _FakeLookupIndexService();

  static int upsertCount = 0;
  static List<String> upsertedLeadIds = [];

  static void reset() {
    upsertCount = 0;
    upsertedLeadIds.clear();
  }

  @override
  Future<void> upsertLead({
    required Lead lead,
    required List<LeadPhone> phones,
  }) async {
    upsertCount++;
    upsertedLeadIds.add(lead.id);
  }

  @override
  Future<void> removeLead(List<String> e164Numbers) async {}

  @override
  Future<void> rebuildIndex({
    required List<Lead> leads,
    required Map<String, List<LeadPhone>> phonesByLeadId,
  }) async {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

AppDatabase _openTestDb() => AppDatabase(openInMemoryDatabase());

void main() {
  late AppDatabase db;
  late LeadsRepository leadsRepo;
  late CallEventsRepository callsRepo;
  late PendingDrainService drainService;

  setUp(() async {
    db = _openTestDb();
    leadsRepo = LeadsRepository(db);
    callsRepo = CallEventsRepository(db);
    _FakeLookupIndexService.reset();
    drainService = PendingDrainService(
      callEventsRepository: callsRepo,
      leadsRepository: leadsRepo,
      lookupIndexService: const _FakeLookupIndexService(),
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
    // Restore no-op shim so subsequent tests start clean.
    PendingEventsApiShim.instance = _EmptyPendingEventsApi();
  });

  test('drain completes without error when queue is empty (count=0)', () async {
    // Ensure the no-op shim returns empty.
    PendingEventsApiShim.instance = _EmptyPendingEventsApi();

    await drainService.drain();

    // No events → no upserts.
    expect(_FakeLookupIndexService.upsertCount, 0);
  });

  test('drain persists a pending event and updates lookup index', () async {
    // Seed a lead with a phone so the pending event can match.
    final lead = await leadsRepo.createLead(
      name: 'Selam Tesfaye',
      phones: [(e164: '+251911000001', label: null, isPrimary: true)],
    );

    // Use a recent timestamp (within the last hour) so the lookup refresh
    // query (lastContactAt >= now - 1hr) finds this lead.
    final recentMs = DateTime.now().millisecondsSinceEpoch;

    // Inject a fake pending event for this lead's phone number.
    PendingEventsApiShim.instance = _FakePendingEventsApi([
      PendingCallEventShim(
        e164: '+251911000001',
        callType: 'INCOMING',
        startedAtMs: recentMs,
        durationSec: 120,
      ),
    ]);

    await drainService.drain();

    // Verify the call event was persisted to the DB.
    final callEvents = await callsRepo.getCallsForLead(lead.id);
    expect(callEvents.length, 1);
    expect(callEvents.first.e164, '+251911000001');
    expect(callEvents.first.callType, 'INCOMING');
    expect(callEvents.first.durationSec, 120);

    // Verify lastContactAt was updated.
    final updated = await leadsRepo.getLeadById(lead.id);
    expect(updated!.lastContactAt, recentMs);

    // Verify the native pending events were cleared.
    final fake = PendingEventsApiShim.instance as _FakePendingEventsApi;
    expect(fake.clearCalled, isTrue);

    // Verify lookup index was refreshed for the affected lead.
    expect(_FakeLookupIndexService.upsertCount, 1);
    expect(_FakeLookupIndexService.upsertedLeadIds, contains(lead.id));
  });

  test('drain skips events for unknown callers (no matching lead)', () async {
    final recentMs = DateTime.now().millisecondsSinceEpoch;
    PendingEventsApiShim.instance = _FakePendingEventsApi([
      PendingCallEventShim(
        e164: '+251999999999',
        callType: 'INCOMING',
        startedAtMs: recentMs,
        durationSec: 60,
      ),
    ]);

    await drainService.drain();

    // No events should have been persisted (no matching lead).
    // The service should complete without error.
    expect(_FakeLookupIndexService.upsertCount, 0);
  });

  test('drain applies status code from pending event to lead', () async {
    final lead = await leadsRepo.createLead(
      name: 'Dawit Alemu',
      status: 'NEW',
      phones: [(e164: '+251911000002', label: null, isPrimary: true)],
    );

    final recentMs = DateTime.now().millisecondsSinceEpoch;

    PendingEventsApiShim.instance = _FakePendingEventsApi([
      PendingCallEventShim(
        e164: '+251911000002',
        callType: 'OUTGOING',
        startedAtMs: recentMs,
        durationSec: 300,
        statusCode: 'CONTACTED',
      ),
    ]);

    await drainService.drain();

    final updated = await leadsRepo.getLeadById(lead.id);
    expect(updated!.status, 'CONTACTED');
  });

  test('drain handles multiple events for same lead (no unique constraint yet)',
      () async {
    final lead = await leadsRepo.createLead(
      name: 'Hanna Girma',
      phones: [(e164: '+251911000003', label: null, isPrimary: true)],
    );

    final recentMs = DateTime.now().millisecondsSinceEpoch;

    PendingEventsApiShim.instance = _FakePendingEventsApi([
      PendingCallEventShim(
        e164: '+251911000003',
        callType: 'INCOMING',
        startedAtMs: recentMs,
        durationSec: 30,
      ),
      PendingCallEventShim(
        e164: '+251911000003',
        callType: 'INCOMING',
        startedAtMs: recentMs + 1000, // 1 second later — distinct event
        durationSec: 30,
      ),
    ]);

    await drainService.drain();

    final callEvents = await callsRepo.getCallsForLead(lead.id);
    expect(callEvents.length, 2,
        reason: 'Two events with different timestamps should both persist');
  });
}
