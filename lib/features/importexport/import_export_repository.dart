import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/db/call_events_repository.dart';
import '../../core/db/database.dart';
import '../../core/db/leads_repository.dart';
import '../../core/db/reminders_repository.dart';
import '../../core/models/lead_status.dart';
import '../../core/utils/lookup_index_service.dart';
import '../../features/parser/phone_normalizer.dart';
import '../../features/search/lead_filter.dart';
import 'import_export_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImportExportRepository — Phase 7
// ─────────────────────────────────────────────────────────────────────────────

class ImportExportRepository {
  ImportExportRepository({
    required LeadsRepository leadsRepo,
    required CallEventsRepository callEventsRepo,
    required RemindersRepository remindersRepo,
    LookupIndexService lookupIndex = const LookupIndexService(),
  })  : _leads = leadsRepo,
        _calls = callEventsRepo,
        _reminders = remindersRepo,
        _lookup = lookupIndex;

  final LeadsRepository _leads;
  final CallEventsRepository _calls;
  final RemindersRepository _reminders;
  final LookupIndexService _lookup;

  static final _isoFmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
  static final _csvCodec = Csv();
  static const _normalizer = PhoneNormalizer();

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Exports to [format] with scope [all] or [filtered] using [filter].
  /// Returns an [ExportBundle] with CSV strings and/or XLSX bytes.
  Future<ExportBundle> export({
    required ExportFormat format,
    required ExportScope scope,
    LeadFilter filter = LeadFilter.empty,
  }) async {
    final List<Lead> leads;
    if (scope == ExportScope.filtered) {
      leads = await _leads.queryLeads(filter);
    } else {
      leads = await _leads.queryLeads(
        const LeadFilter(includeArchived: true),
      );
    }

    // Build rows
    final leadRows = <List<dynamic>>[];
    final callRows = <List<dynamic>>[];
    final reminderRows = <List<dynamic>>[];

    // Headers
    leadRows.add(ExportColumns.leadHeaders);
    callRows.add(ExportColumns.callHeaders);
    reminderRows.add(ExportColumns.reminderHeaders);

    for (final lead in leads) {
      final phones = await _leads.getPhonesForLead(lead.id);
      final phonesStr =
          phones.map((p) => p.e164).join(';');

      leadRows.add([
        lead.name,
        lead.businessType ?? '',
        lead.status,
        lead.source,
        phonesStr,
        lead.notes ?? '',
        _ms2iso(lead.createdAt),
        lead.lastContactAt != null ? _ms2iso(lead.lastContactAt!) : '',
        lead.archived ? '1' : '0',
      ]);

      // Call events for this lead
      final calls = await _calls.getCallsForLead(lead.id);
      for (final c in calls) {
        callRows.add([
          lead.name,
          lead.id,
          c.e164,
          c.callType,
          _ms2iso(c.startedAt),
          c.durationSec,
          c.notes ?? '',
        ]);
      }

      // Reminders
      final reminder =
          await _reminders.getPendingReminderForLead(lead.id);
      if (reminder != null) {
        reminderRows.add([
          lead.name,
          lead.id,
          _ms2iso(reminder.dueAt),
          reminder.state,
          reminder.notes ?? '',
        ]);
      }
    }

    // CSV strings
    final leadsCsv = _csvCodec.encode(leadRows);
    final callsCsv = _csvCodec.encode(callRows);
    final remindersCsv = _csvCodec.encode(reminderRows);

    if (format == ExportFormat.csv) {
      return ExportBundle(
        leadsCsv: leadsCsv,
        callsCsv: callsCsv,
        remindersCsv: remindersCsv,
      );
    }

    // XLSX
    final xlsxBytes = _buildXlsx(leadRows, callRows, reminderRows);
    return ExportBundle(
      leadsCsv: leadsCsv,
      callsCsv: callsCsv,
      remindersCsv: remindersCsv,
      xlsxBytes: xlsxBytes,
    );
  }

  List<int> _buildXlsx(
    List<List<dynamic>> leadsRows,
    List<List<dynamic>> callsRows,
    List<List<dynamic>> remindersRows,
  ) {
    final excel = Excel.createExcel();

    // Remove default sheet if present
    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null) {
      excel.delete(defaultSheet);
    }

    _fillSheet(excel, 'Leads', leadsRows);
    _fillSheet(excel, 'Calls', callsRows);
    _fillSheet(excel, 'Reminders', remindersRows);

    final encoded = excel.encode();
    return encoded ?? [];
  }

  void _fillSheet(
      Excel excel, String name, List<List<dynamic>> rows) {
    final sheet = excel[name];
    for (final (ri, row) in rows.indexed) {
      for (final (ci, cell) in row.indexed) {
        final cellRef = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: ci, rowIndex: ri),
        );
        cellRef.value = TextCellValue(cell.toString());

        if (ri == 0) {
          // Bold header
          cellRef.cellStyle = CellStyle(bold: true);
        }
      }
    }
  }

  /// Save export to a temp file and return the path.
  Future<List<String>> saveToTempFiles(ExportBundle bundle) async {
    final tmp = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final paths = <String>[];

    if (bundle.xlsxBytes != null) {
      final f = File(p.join(tmp.path, 'kiko_export_$ts.xlsx'));
      await f.writeAsBytes(bundle.xlsxBytes!);
      paths.add(f.path);
    } else {
      final leads = File(p.join(tmp.path, 'kiko_leads_$ts.csv'));
      await leads.writeAsString(bundle.leadsCsv);
      paths.add(leads.path);

      final calls = File(p.join(tmp.path, 'kiko_calls_$ts.csv'));
      await calls.writeAsString(bundle.callsCsv);
      paths.add(calls.path);

      final reminders =
          File(p.join(tmp.path, 'kiko_reminders_$ts.csv'));
      await reminders.writeAsString(bundle.remindersCsv);
      paths.add(reminders.path);
    }

    return paths;
  }

  // ── Import: parse ──────────────────────────────────────────────────────────

  /// Parses a CSV or XLSX file and returns validated [ImportRow] list.
  /// [columnMap] maps canonical column keys → file column indices.
  Future<List<ImportRow>> parseFile(
    String filePath,
    Map<String, int> columnMap,
  ) async {
    final ext = p.extension(filePath).toLowerCase();
    List<List<dynamic>> rawRows;

    if (ext == '.xlsx' || ext == '.xls') {
      rawRows = _parseXlsx(filePath);
    } else {
      rawRows = await _parseCsv(filePath);
    }

    if (rawRows.isEmpty) return [];

    // Drop the header row if it looks like text
    final firstRow = rawRows.first;
    final hasHeader = columnMap.values.any((idx) {
      if (idx >= firstRow.length) return false;
      final val = firstRow[idx]?.toString() ?? '';
      return ExportColumns.leadHeaders.contains(val.toLowerCase()) ||
          ExportColumns.headerAliases.containsKey(val.toLowerCase());
    });

    final dataRows = hasHeader ? rawRows.skip(1).toList() : rawRows;

    return [
      for (final (i, row) in dataRows.indexed)
        _parseRow(i + (hasHeader ? 2 : 1), row, columnMap),
    ];
  }

  ImportRow _parseRow(
    int rowIndex,
    List<dynamic> row,
    Map<String, int> columnMap,
  ) {
    String cell(String key) {
      final idx = columnMap[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx]?.toString().trim() ?? '';
    }

    final name = cell(ExportColumns.name);
    final errors = <String>[];

    if (name.isEmpty) errors.add('Name is required');

    // Parse phones
    final rawPhonesStr = cell(ExportColumns.phones);
    final rawPhones = rawPhonesStr
        .split(RegExp(r'[;,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final e164List = <String>[];
    for (final raw in rawPhones) {
      final e164 = _normalizer.tryNormalize(raw);
      if (e164 != null) {
        e164List.add(e164);
      } else {
        errors.add('Could not normalize phone: $raw');
      }
    }

    // Parse status
    LeadStatus status = LeadStatus.newLead;
    final statusStr = cell(ExportColumns.status).toUpperCase();
    if (statusStr.isNotEmpty) {
      final match = LeadStatus.values
          .where((s) => s.dbValue == statusStr)
          .toList();
      if (match.isEmpty) {
        errors.add('Unknown status: $statusStr');
      } else {
        status = match.first;
      }
    }

    return ImportRow(
      rowIndex: rowIndex,
      name: name,
      businessType: cell(ExportColumns.businessType).isEmpty
          ? null
          : cell(ExportColumns.businessType),
      status: status,
      notes: cell(ExportColumns.notes).isEmpty
          ? null
          : cell(ExportColumns.notes),
      phonesE164: e164List,
      rawPhones: rawPhones,
      errors: errors,
    );
  }

  // ── Import: persist ────────────────────────────────────────────────────────

  /// Persists [rows] according to conflict [actions].
  ///
  /// [actions] maps rowIndex → [ImportConflictAction].
  /// [applyAllPolicy] is applied to any row whose rowIndex is NOT in [actions].
  Future<ImportResult> persistRows({
    required List<ImportRow> rows,
    required Map<int, ImportConflictAction> actions,
    ImportApplyAllPolicy applyAllPolicy =
        ImportApplyAllPolicy.keepExisting,
  }) async {
    int created = 0;
    int merged = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final row in rows) {
      if (!row.isValid) {
        skipped++;
        errors.addAll(row.errors.map((e) => 'Row ${row.rowIndex}: $e'));
        continue;
      }

      // Detect conflict: does any e164 exist?
      final conflictMap =
          await _leads.mapPhonesToLeadIds(row.phonesE164);
      final conflictLeadId = conflictMap.values.firstOrNull;

      if (conflictLeadId == null) {
        // No conflict — create
        try {
          await _leads.createLead(
            name: row.name,
            businessType: row.businessType,
            status: row.status.dbValue,
            source: LeadSource.import_.dbValue,
            notes: row.notes,
            phones: [
              for (final (i, e) in row.phonesE164.indexed)
                (e164: e, label: null, isPrimary: i == 0),
            ],
          );
          created++;
        } catch (e) {
          errors.add('Row ${row.rowIndex}: $e');
        }
        continue;
      }

      // Conflict — determine action
      final action = actions[row.rowIndex] ??
          _policyToAction(applyAllPolicy);

      switch (action) {
        case ImportConflictAction.skip:
        case ImportConflictAction.keepExisting:
          skipped++;

        case ImportConflictAction.mergeAll:
          try {
            final existingPhones =
                await _leads.getPhonesForLead(conflictLeadId);
            final existingE164s =
                existingPhones.map((p) => p.e164).toSet();

            final allPhones = [
              ...existingPhones.map((p) => (
                    e164: p.e164,
                    label: p.label,
                    isPrimary: p.isPrimary,
                  )),
              for (final (_, e) in row.phonesE164.indexed)
                if (!existingE164s.contains(e))
                  (e164: e, label: null, isPrimary: false),
            ];

            final existingSections =
                await _leads.getSectionsForLead(conflictLeadId);

            await _leads.mergeLead(
              targetLeadId: conflictLeadId,
              name: row.name,
              businessType: row.businessType,
              status: row.status.dbValue,
              notes: row.notes,
              mergedPhones: allPhones,
              mergedSections: existingSections
                  .map((s) => (title: s.title, body: s.body))
                  .toList(),
            );
            merged++;
          } catch (e) {
            errors.add('Row ${row.rowIndex}: $e');
          }

        case ImportConflictAction.saveAsSeparate:
          // Remove conflicting phones and create new lead
          final safePhones = row.phonesE164
              .where((e) => !conflictMap.containsKey(e))
              .toList();
          try {
            await _leads.createLead(
              name: row.name,
              businessType: row.businessType,
              status: row.status.dbValue,
              source: LeadSource.import_.dbValue,
              notes: row.notes,
              phones: [
                for (final (i, e) in safePhones.indexed)
                  (e164: e, label: null, isPrimary: i == 0),
              ],
            );
            created++;
          } catch (e) {
            errors.add('Row ${row.rowIndex}: $e');
          }

        case ImportConflictAction.reviewAndMerge:
          // Should have been resolved before calling persistRows.
          skipped++;
      }
    }

    // Spec: rebuild native lookup index after an import batch.
    await _rebuildLookupIndex();

    return ImportResult(
      created: created,
      merged: merged,
      skipped: skipped,
      errors: errors,
    );
  }

  Future<void> _rebuildLookupIndex() async {
    final leads = await _leads.queryLeads(
      const LeadFilter(includeArchived: true),
    );
    final phonesByLeadId = <String, List<LeadPhone>>{};
    for (final lead in leads) {
      phonesByLeadId[lead.id] = await _leads.getPhonesForLead(lead.id);
    }
    await _lookup.rebuildIndex(
      leads: leads,
      phonesByLeadId: phonesByLeadId,
    );
  }

  // ── Conflict detection (public for wizard) ────────────────────────────────

  /// Checks whether any of the given [e164s] already belong to a lead.
  /// Returns a map e164 → leadId for conflicts found.
  Future<Map<String, String>> checkPhoneConflicts(
          List<String> e164s) =>
      _leads.mapPhonesToLeadIds(e164s);

  // ── Auto column-map detection ──────────────────────────────────────────────

  /// Reads only the first row of a file and attempts to auto-map headers.
  /// Returns a map canonical-column-key → column-index.
  Future<Map<String, int>> detectColumnMap(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    List<dynamic> headerRow;

    if (ext == '.xlsx' || ext == '.xls') {
      final rows = _parseXlsx(filePath);
      if (rows.isEmpty) return {};
      headerRow = rows.first;
    } else {
      final rows = await _parseCsv(filePath);
      if (rows.isEmpty) return {};
      headerRow = rows.first;
    }

    final result = <String, int>{};
    for (final (i, cell) in headerRow.indexed) {
      final lower = cell.toString().trim().toLowerCase();
      final canonical = ExportColumns.headerAliases[lower];
      if (canonical != null) {
        result.putIfAbsent(canonical, () => i);
      }
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<List<dynamic>>> _parseCsv(String filePath) async {
    final content = await File(filePath).readAsString();
    return _csvCodec.decode(content);
  }

  List<List<dynamic>> _parseXlsx(String filePath) {
    final bytes = File(filePath).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    // Use first sheet
    final sheetName = excel.tables.keys.firstOrNull;
    if (sheetName == null) return [];

    final sheet = excel.tables[sheetName];
    if (sheet == null) return [];

    return sheet.rows.map((row) {
      return row.map((cell) => cell?.value?.toString() ?? '').toList();
    }).toList();
  }

  static String _ms2iso(int ms) {
    return _isoFmt
        .format(DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true));
  }

  ImportConflictAction _policyToAction(ImportApplyAllPolicy policy) {
    switch (policy) {
      case ImportApplyAllPolicy.keepExisting:
        return ImportConflictAction.keepExisting;
      case ImportApplyAllPolicy.mergeAll:
        return ImportConflictAction.mergeAll;
      case ImportApplyAllPolicy.skip:
        return ImportConflictAction.skip;
    }
  }
}
