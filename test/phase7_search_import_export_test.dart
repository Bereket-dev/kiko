// ignore_for_file: lines_longer_than_80_chars
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/core/db/call_events_repository.dart';
import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/db/leads_repository.dart';
import 'package:kiko/core/db/reminders_repository.dart';
import 'package:kiko/core/models/lead_status.dart';
import 'package:kiko/features/importexport/import_export_models.dart';
import 'package:kiko/features/importexport/import_export_repository.dart';
import 'package:kiko/features/search/lead_filter.dart';
import 'package:path/path.dart' as p;

AppDatabase openTestDb() => AppDatabase(openInMemoryDatabase());

void main() {
  late AppDatabase db;
  late LeadsRepository leads;
  late CallEventsRepository calls;
  late RemindersRepository reminders;
  late ImportExportRepository ie;

  setUp(() async {
    db = openTestDb();
    leads = LeadsRepository(db);
    calls = CallEventsRepository(db);
    reminders = RemindersRepository(db);
    ie = ImportExportRepository(
      leadsRepo: leads,
      callEventsRepo: calls,
      remindersRepo: reminders,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Lead> seedLead({
    String name = 'Abebe Kebede',
    String status = 'NEW',
    String source = 'MANUAL',
    List<String> e164s = const ['+251911000001'],
    bool archived = false,
    String? notes,
    String? businessType = 'Retailer',
  }) async {
    final lead = await leads.createLead(
      name: name,
      businessType: businessType,
      status: status,
      source: source,
      notes: notes,
      phones: e164s
          .asMap()
          .entries
          .map(
            (e) => (
              e164: e.value,
              label: null as String?,
              isPrimary: e.key == 0,
            ),
          )
          .toList(),
    );
    if (archived) {
      await leads.updateLead(lead.id, archived: const Value(true));
      return (await leads.getLeadById(lead.id))!;
    }
    return lead;
  }

  // ── LeadFilter model ───────────────────────────────────────────────────────

  group('LeadFilter', () {
    test('empty has no active filters', () {
      expect(LeadFilter.empty.hasActiveFilters, isFalse);
    });

    test('keyword alone counts as active', () {
      expect(const LeadFilter(keyword: 'abebe').hasActiveFilters, isTrue);
    });

    test('copyWith clearHasReminder clears the field', () {
      final f = const LeadFilter(hasReminder: true)
          .copyWith(clearHasReminder: true);
      expect(f.hasReminder, isNull);
    });

    test('equality ignores set order', () {
      final a = LeadFilter(
        statuses: {LeadStatus.newLead, LeadStatus.won},
      );
      final b = LeadFilter(
        statuses: {LeadStatus.won, LeadStatus.newLead},
      );
      expect(a, equals(b));
    });
  });

  // ── queryLeads / FTS search ────────────────────────────────────────────────

  group('queryLeads', () {
    test('returns non-archived leads by default', () async {
      await seedLead(name: 'Active', e164s: ['+251911000010']);
      await seedLead(
        name: 'Archived',
        e164s: ['+251911000011'],
        archived: true,
      );

      final results = await leads.queryLeads(LeadFilter.empty);
      expect(results.map((l) => l.name), ['Active']);
    });

    test('includeArchived returns archived leads too', () async {
      await seedLead(name: 'Active', e164s: ['+251911000012']);
      await seedLead(
        name: 'Archived',
        e164s: ['+251911000013'],
        archived: true,
      );

      final results = await leads.queryLeads(
        const LeadFilter(includeArchived: true),
      );
      expect(results.map((l) => l.name).toSet(), {'Active', 'Archived'});
    });

    test('filters by status', () async {
      await seedLead(
        name: 'New one',
        status: 'NEW',
        e164s: ['+251911000014'],
      );
      await seedLead(
        name: 'Won one',
        status: 'WON',
        e164s: ['+251911000015'],
      );

      final results = await leads.queryLeads(
        LeadFilter(statuses: {LeadStatus.won}),
      );
      expect(results.map((l) => l.name), ['Won one']);
    });

    test('filters by source', () async {
      await seedLead(
        name: 'Manual',
        source: 'MANUAL',
        e164s: ['+251911000016'],
      );
      await seedLead(
        name: 'Imported',
        source: 'IMPORT',
        e164s: ['+251911000017'],
      );

      final results = await leads.queryLeads(
        LeadFilter(sources: {LeadSource.import_}),
      );
      expect(results.map((l) => l.name), ['Imported']);
    });

    test('filters by hasReminder', () async {
      final withRem = await seedLead(
        name: 'Has rem',
        e164s: ['+251911000018'],
      );
      await seedLead(name: 'No rem', e164s: ['+251911000019']);
      await reminders.createReminder(
        leadId: withRem.id,
        dueAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
      );

      final has = await leads.queryLeads(
        const LeadFilter(hasReminder: true),
      );
      final none = await leads.queryLeads(
        const LeadFilter(hasReminder: false),
      );

      expect(has.map((l) => l.name), ['Has rem']);
      expect(none.map((l) => l.name), ['No rem']);
    });

    test('filters by call direction', () async {
      final incoming = await seedLead(
        name: 'Incoming lead',
        e164s: ['+251911000020'],
      );
      await seedLead(name: 'Quiet lead', e164s: ['+251911000021']);
      await calls.createCallEvent(
        leadId: incoming.id,
        e164: '+251911000020',
        callType: 'INCOMING',
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
      );

      final results = await leads.queryLeads(
        const LeadFilter(callDirection: CallDirectionFilter.incoming),
      );
      expect(results.map((l) => l.name), ['Incoming lead']);
    });

    test('FTS keyword search matches name', () async {
      await seedLead(name: 'Selamawit Hailu', e164s: ['+251911000022']);
      await seedLead(name: 'Dawit Bekele', e164s: ['+251911000023']);

      final results = await leads.searchLeads('Selamawit');
      expect(results.map((l) => l.name), ['Selamawit Hailu']);
    });

    test('FTS + status filter combine', () async {
      await seedLead(
        name: 'Selam New',
        status: 'NEW',
        e164s: ['+251911000024'],
      );
      await seedLead(
        name: 'Selam Won',
        status: 'WON',
        e164s: ['+251911000025'],
      );

      final results = await leads.queryLeads(
        LeadFilter(keyword: 'Selam', statuses: {LeadStatus.won}),
      );
      expect(results.map((l) => l.name), ['Selam Won']);
    });
  });

  // ── Export ─────────────────────────────────────────────────────────────────

  group('export', () {
    test('CSV export includes lead row with phones joined', () async {
      await seedLead(
        name: 'Export Me',
        e164s: ['+251911000030', '+251922000031'],
        notes: 'hello',
      );

      final bundle = await ie.export(
        format: ExportFormat.csv,
        scope: ExportScope.all,
      );

      expect(bundle.xlsxBytes, isNull);
      expect(bundle.leadsCsv, contains('name'));
      expect(bundle.leadsCsv, contains('Export Me'));
      expect(bundle.leadsCsv, contains('+251911000030;+251922000031'));
      expect(bundle.leadsCsv, contains('hello'));
      expect(bundle.callsCsv, contains('lead_name'));
      expect(bundle.remindersCsv, contains('due_at'));
    });

    test('filtered export respects status filter', () async {
      await seedLead(
        name: 'Keep',
        status: 'WON',
        e164s: ['+251911000032'],
      );
      await seedLead(
        name: 'Drop',
        status: 'NEW',
        e164s: ['+251911000033'],
      );

      final bundle = await ie.export(
        format: ExportFormat.csv,
        scope: ExportScope.filtered,
        filter: LeadFilter(statuses: {LeadStatus.won}),
      );

      expect(bundle.leadsCsv, contains('Keep'));
      expect(bundle.leadsCsv, isNot(contains('Drop')));
    });

    test('XLSX export produces bytes', () async {
      await seedLead(name: 'Xlsx Lead', e164s: ['+251911000034']);

      final bundle = await ie.export(
        format: ExportFormat.xlsx,
        scope: ExportScope.all,
      );

      expect(bundle.xlsxBytes, isNotNull);
      expect(bundle.xlsxBytes!, isNotEmpty);
    });

    test('export includes call and reminder rows', () async {
      final lead = await seedLead(
        name: 'With History',
        e164s: ['+251911000035'],
      );
      await calls.createCallEvent(
        leadId: lead.id,
        e164: '+251911000035',
        callType: 'OUTGOING',
        startedAtMs: DateTime.now().millisecondsSinceEpoch,
        durationSec: 42,
      );
      await reminders.createReminder(
        leadId: lead.id,
        dueAtMs: DateTime.now().millisecondsSinceEpoch + 86000000,
        notes: 'Call back',
      );

      final bundle = await ie.export(
        format: ExportFormat.csv,
        scope: ExportScope.all,
      );

      expect(bundle.callsCsv, contains('With History'));
      expect(bundle.callsCsv, contains('OUTGOING'));
      expect(bundle.remindersCsv, contains('With History'));
      expect(bundle.remindersCsv, contains('Call back'));
    });
  });

  // ── Import ─────────────────────────────────────────────────────────────────

  group('import', () {
    Future<String> writeTempCsv(String contents) async {
      final dir = await Directory.systemTemp.createTemp('kiko_import_');
      final file = File(p.join(dir.path, 'leads.csv'));
      await file.writeAsString(contents);
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      return file.path;
    }

    test('detectColumnMap maps common aliases', () async {
      final path = await writeTempCsv(
        'Name,Phone,Status,Notes\nAbebe,+251911000040,NEW,hi\n',
      );
      final map = await ie.detectColumnMap(path);
      expect(map[ExportColumns.name], 0);
      expect(map[ExportColumns.phones], 1);
      expect(map[ExportColumns.status], 2);
      expect(map[ExportColumns.notes], 3);
    });

    test('parseFile validates required name and normalizes phones', () async {
      final path = await writeTempCsv(
        'name,phones,status\n'
        'Valid Person,0911234567,NEW\n'
        ',0911987654,NEW\n'
        'Bad Phone,not-a-phone,NEW\n'
        'Bad Status,0911111111,NOT_A_STATUS\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);

      expect(rows.length, 4);
      expect(rows[0].isValid, isTrue);
      expect(rows[0].phonesE164, ['+251911234567']);
      expect(rows[1].isValid, isFalse);
      expect(rows[1].errors, contains('Name is required'));
      expect(rows[2].isValid, isFalse);
      expect(rows[2].errors.any((e) => e.contains('normalize')), isTrue);
      expect(rows[3].isValid, isFalse);
      expect(rows[3].errors.any((e) => e.contains('Unknown status')), isTrue);
    });

    test('persistRows creates new leads', () async {
      final path = await writeTempCsv(
        'name,phones,status,business_type\n'
        'Import A,0911000001,NEW,Cafe\n'
        'Import B,0911000002,WON,Shop\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);
      final result = await ie.persistRows(rows: rows, actions: {});

      expect(result.created, 2);
      expect(result.merged, 0);
      expect(result.skipped, 0);
      expect(result.errors, isEmpty);

      final all = await leads.queryLeads(LeadFilter.empty);
      expect(all.map((l) => l.name).toSet(), {'Import A', 'Import B'});
      expect(all.every((l) => l.source == 'IMPORT'), isTrue);
    });

    test('persistRows keepExisting skips conflicts', () async {
      await seedLead(name: 'Existing', e164s: ['+251911000050']);
      final path = await writeTempCsv(
        'name,phones\nClash,+251911000050\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);
      final result = await ie.persistRows(
        rows: rows,
        actions: {
          for (final r in rows) r.rowIndex: ImportConflictAction.keepExisting,
        },
      );

      expect(result.skipped, 1);
      expect(result.created, 0);
      final all = await leads.queryLeads(LeadFilter.empty);
      expect(all.length, 1);
      expect(all.first.name, 'Existing');
    });

    test('persistRows mergeAll unions phones', () async {
      await seedLead(
        name: 'Existing',
        e164s: ['+251911000060'],
        notes: 'old',
      );
      final path = await writeTempCsv(
        'name,phones,notes\nMerged,+251911000060;0911000061,new note\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);
      final result = await ie.persistRows(
        rows: rows,
        actions: {
          for (final r in rows) r.rowIndex: ImportConflictAction.mergeAll,
        },
      );

      expect(result.merged, 1);
      final all = await leads.queryLeads(LeadFilter.empty);
      expect(all.length, 1);
      expect(all.first.name, 'Merged');
      expect(all.first.notes, 'new note');

      final phones = await leads.getPhonesForLead(all.first.id);
      expect(
        phones.map((p) => p.e164).toSet(),
        {'+251911000060', '+251911000061'},
      );
    });

    test('persistRows apply-all policy covers unresolved conflicts', () async {
      await seedLead(name: 'Existing', e164s: ['+251911000070']);
      final path = await writeTempCsv(
        'name,phones\nSkip Me,+251911000070\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);
      final result = await ie.persistRows(
        rows: rows,
        actions: const {},
        applyAllPolicy: ImportApplyAllPolicy.skip,
      );

      expect(result.skipped, 1);
      expect(result.created, 0);
    });

    test('persistRows saveAsSeparate drops conflicting phones', () async {
      await seedLead(name: 'Existing', e164s: ['+251911000080']);
      final path = await writeTempCsv(
        'name,phones\nSeparate,+251911000080;0911000081\n',
      );
      final map = await ie.detectColumnMap(path);
      final rows = await ie.parseFile(path, map);
      final result = await ie.persistRows(
        rows: rows,
        actions: {
          for (final r in rows)
            r.rowIndex: ImportConflictAction.saveAsSeparate,
        },
      );

      expect(result.created, 1);
      final all = await leads.queryLeads(LeadFilter.empty);
      expect(all.length, 2);
      final created = all.firstWhere((l) => l.name == 'Separate');
      final phones = await leads.getPhonesForLead(created.id);
      expect(phones.map((p) => p.e164), ['+251911000081']);
    });
  });
}
