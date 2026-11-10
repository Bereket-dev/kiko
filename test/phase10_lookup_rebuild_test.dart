// ignore_for_file: lines_longer_than_80_chars
// Integration test: lookup index rebuild after import
//
// Verifies that ImportExportRepository.persistRows() calls
// LookupIndexService.rebuildIndex() with the full set of imported leads
// and their phones after a successful import batch.

import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/core/db/call_events_repository.dart';
import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/db/leads_repository.dart';
import 'package:kiko/core/db/reminders_repository.dart';
import 'package:kiko/core/models/lead_status.dart';
import 'package:kiko/core/utils/lookup_index_service.dart';
import 'package:kiko/features/importexport/import_export_models.dart';
import 'package:kiko/features/importexport/import_export_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake LookupIndexService — records rebuild calls for assertions
// ─────────────────────────────────────────────────────────────────────────────

class _FakeLookupIndexService extends LookupIndexService {
  const _FakeLookupIndexService();

  static int rebuildCount = 0;
  static List<Lead>? lastRebuildLeads;
  static Map<String, List<LeadPhone>>? lastRebuildPhones;

  static void reset() {
    rebuildCount = 0;
    lastRebuildLeads = null;
    lastRebuildPhones = null;
  }

  @override
  Future<void> upsertLead({
    required Lead lead,
    required List<LeadPhone> phones,
  }) async {}

  @override
  Future<void> removeLead(List<String> e164Numbers) async {}

  @override
  Future<void> rebuildIndex({
    required List<Lead> leads,
    required Map<String, List<LeadPhone>> phonesByLeadId,
  }) async {
    rebuildCount++;
    lastRebuildLeads = leads;
    lastRebuildPhones = phonesByLeadId;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

AppDatabase _openTestDb() => AppDatabase(openInMemoryDatabase());

void main() {
  late AppDatabase db;
  late LeadsRepository leadsRepo;
  late CallEventsRepository callsRepo;
  late RemindersRepository remindersRepo;
  late ImportExportRepository ie;
  late _FakeLookupIndexService fakeLookup;

  setUp(() {
    db = _openTestDb();
    leadsRepo = LeadsRepository(db);
    callsRepo = CallEventsRepository(db);
    remindersRepo = RemindersRepository(db);
    fakeLookup = const _FakeLookupIndexService();
    _FakeLookupIndexService.reset();

    ie = ImportExportRepository(
      leadsRepo: leadsRepo,
      callEventsRepo: callsRepo,
      remindersRepo: remindersRepo,
      lookupIndex: fakeLookup,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ── rebuild is called after a successful import ───────────────────────────

  test('rebuildIndex called once after persistRows with new leads', () async {
    final rows = [
      ImportRow(
        rowIndex: 1,
        name: 'Abebe Kebede',
        phonesE164: ['+251911000001'],
        rawPhones: ['+251911000001'],
        status: LeadStatus.newLead,
        errors: [],
      ),
      ImportRow(
        rowIndex: 2,
        name: 'Meron Tadesse',
        phonesE164: ['+251911000002'],
        rawPhones: ['+251911000002'],
        status: LeadStatus.newLead,
        errors: [],
      ),
    ];

    await ie.persistRows(rows: rows, actions: {});

    expect(_FakeLookupIndexService.rebuildCount, 1,
        reason: 'rebuildIndex should be called exactly once after import');
  });

  test('rebuildIndex receives all imported leads', () async {
    final rows = [
      ImportRow(
        rowIndex: 1,
        name: 'Alemu Girma',
        phonesE164: ['+251911000010'],
        rawPhones: ['+251911000010'],
        status: LeadStatus.newLead,
        errors: [],
      ),
      ImportRow(
        rowIndex: 2,
        name: 'Tigist Haile',
        phonesE164: ['+251911000011'],
        rawPhones: ['+251911000011'],
        status: LeadStatus.won,
        errors: [],
      ),
    ];

    await ie.persistRows(rows: rows, actions: {});

    final names =
        _FakeLookupIndexService.lastRebuildLeads?.map((l) => l.name).toSet();
    expect(names, containsAll(['Alemu Girma', 'Tigist Haile']));
  });

  test('rebuildIndex receives phones keyed by leadId', () async {
    final rows = [
      ImportRow(
        rowIndex: 1,
        name: 'Yonas Bekele',
        phonesE164: ['+251911000020', '+251922000021'],
        rawPhones: ['+251911000020', '+251922000021'],
        status: LeadStatus.newLead,
        errors: [],
      ),
    ];

    await ie.persistRows(rows: rows, actions: {});

    final phones = _FakeLookupIndexService.lastRebuildPhones;
    expect(phones, isNotNull);
    expect(phones!.length, 1);

    // The single entry should have both phones.
    final leadPhones = phones.values.first;
    final e164s = leadPhones.map((p) => p.e164).toSet();
    expect(e164s, containsAll(['+251911000020', '+251922000021']));
  });

  test('rebuildIndex still called even when all rows are skipped (zero created)',
      () async {
    // Pre-seed a lead so the import row causes a conflict.
    await leadsRepo.createLead(
      name: 'Existing',
      phones: [(e164: '+251911000030', label: null, isPrimary: true)],
    );
    _FakeLookupIndexService.reset();

    final rows = [
      ImportRow(
        rowIndex: 1,
        name: 'Conflict',
        phonesE164: ['+251911000030'],
        rawPhones: ['+251911000030'],
        status: LeadStatus.newLead,
        errors: [],
      ),
    ];

    final result = await ie.persistRows(
      rows: rows,
      actions: {1: ImportConflictAction.keepExisting},
    );

    expect(result.skipped, 1);
    // rebuildIndex should still run to keep the index consistent.
    expect(_FakeLookupIndexService.rebuildCount, 1);
  });

  test('rebuildIndex leads list includes pre-existing leads', () async {
    // Seed an existing lead.
    await leadsRepo.createLead(
      name: 'Old Lead',
      phones: [(e164: '+251911000040', label: null, isPrimary: true)],
    );
    _FakeLookupIndexService.reset();

    // Import a new lead.
    final rows = [
      ImportRow(
        rowIndex: 1,
        name: 'New Lead',
        phonesE164: ['+251911000041'],
        rawPhones: ['+251911000041'],
        status: LeadStatus.newLead,
        errors: [],
      ),
    ];

    await ie.persistRows(rows: rows, actions: {});

    final names =
        _FakeLookupIndexService.lastRebuildLeads?.map((l) => l.name).toSet();
    expect(names, containsAll(['Old Lead', 'New Lead']));
  });
}
