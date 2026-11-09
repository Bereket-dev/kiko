import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables.dart';

part 'database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Database
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    Leads,
    LeadPhones,
    LeadSections,
    LeadImages,
    CallEvents,
    Reminders,
    CallPlanSchedules,
    CallPlanLeads,
    DismissedNumbers,
    CallRecordings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts5Table();
          await _createPerformanceIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        },
      );

  // ── FTS5 virtual table ───────────────────────────────────────────────────

  Future<void> _createFts5Table() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS lead_search
      USING fts5(
        lead_id UNINDEXED,
        name,
        business_type,
        notes,
        phones,
        sections,
        content=''
      )
    ''');
  }

  // ── Additional performance indexes ──────────────────────────────────────

  Future<void> _createPerformanceIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leads_updated_at ON leads(updated_at DESC)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leads_business_type ON leads(business_type COLLATE NOCASE)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leads_archived ON leads(archived)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_call_events_lead ON call_events(lead_id, started_at DESC)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(due_at, state)');
  }

  // ── FTS row rebuild (called from repositories in-transaction) ────────────

  Future<void> rebuildFtsRow({
    required String leadId,
    required String name,
    String? businessType,
    String? notes,
    required List<String> phones,
    required List<String> sections,
  }) async {
    await customStatement(
        'DELETE FROM lead_search WHERE lead_id = ?', [leadId]);
    final phonesText = phones.join(' ');
    final sectionsText = sections.join(' ');
    await customStatement(
      'INSERT INTO lead_search(lead_id, name, business_type, notes, phones, sections) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [leadId, name, businessType ?? '', notes ?? '', phonesText, sectionsText],
    );
  }

  Future<void> removeFtsRow(String leadId) async {
    await customStatement(
        'DELETE FROM lead_search WHERE lead_id = ?', [leadId]);
  }

  // ── FTS5 gate ────────────────────────────────────────────────────────────

  /// Throws [StateError] if FTS5 is not available.
  Future<void> verifyFts5Available() async {
    try {
      await customStatement(
          'CREATE VIRTUAL TABLE IF NOT EXISTS _fts5_probe USING fts5(x)');
      await customStatement('DROP TABLE IF EXISTS _fts5_probe');
    } catch (e) {
      throw StateError(
        'FTS5 is not available in this SQLite build. '
        'Cannot proceed. Error: $e',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Connection factory
// ─────────────────────────────────────────────────────────────────────────────

/// Opens an encrypted SQLCipher database.
/// [hexKey] is a 64-char hex string (32-byte key).
QueryExecutor openEncryptedDatabase(String hexKey) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kiko.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    }

    final cipherDb = sqlite3.open(file.path);
    cipherDb.execute("PRAGMA key = \"x'$hexKey'\"");
    cipherDb.execute('PRAGMA cipher_compatibility = 4');

    return NativeDatabase.opened(cipherDb);
  });
}

/// Opens an in-memory unencrypted database (for tests only).
QueryExecutor openInMemoryDatabase() {
  return NativeDatabase.memory();
}
