// ignore_for_file: type_annotate_public_apis
import 'package:drift/drift.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Leads
// ─────────────────────────────────────────────────────────────────────────────

/// Main leads table. UUID PK, timestamps in UTC epoch ms.
class Leads extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get businessType => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('NEW'))();
  TextColumn get source => text().withDefault(const Constant('MANUAL'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()(); // UTC epoch ms
  IntColumn get updatedAt => integer()(); // UTC epoch ms
  IntColumn get lastContactAt => integer().nullable()(); // UTC epoch ms

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK(status IN (\'NEW\',\'CONTACTED\',\'INTERESTED\',\'NEGOTIATING\',\'WON\',\'LOST\',\'FOLLOW_UP\'))',
        'CHECK(source IN (\'PASTE\',\'IMPORT\',\'CALL\',\'MANUAL\'))',
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Lead Phones
// ─────────────────────────────────────────────────────────────────────────────

class LeadPhones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  TextColumn get e164 => text()(); // normalised E.164 number
  TextColumn get label => text().nullable()(); // e.g. "Mobile", "Work"
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  List<String> get customConstraints => ['UNIQUE (e164)'];
}

// ─────────────────────────────────────────────────────────────────────────────
// Lead Sections  (freeform text blocks)
// ─────────────────────────────────────────────────────────────────────────────

class LeadSections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Lead Images
// ─────────────────────────────────────────────────────────────────────────────

class LeadImages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()(); // app-private storage, encrypted
  IntColumn get position => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()(); // UTC epoch ms
}

// ─────────────────────────────────────────────────────────────────────────────
// Call Events
// ─────────────────────────────────────────────────────────────────────────────

class CallEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  TextColumn get e164 => text()();
  TextColumn get callType => text()(); // INCOMING | OUTGOING | MISSED
  IntColumn get startedAt => integer()(); // UTC epoch ms
  IntColumn get durationSec => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()(); // UTC epoch ms

  @override
  List<String> get customConstraints => [
        'CHECK(call_type IN (\'INCOMING\',\'OUTGOING\',\'MISSED\'))',
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminders
// ─────────────────────────────────────────────────────────────────────────────

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  TextColumn get alarmId => text()(); // UUID for AlarmManager
  IntColumn get dueAt => integer()(); // UTC epoch ms
  TextColumn get state =>
      text().withDefault(const Constant('PENDING'))(); // PENDING | FIRED | DISMISSED
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()(); // UTC epoch ms

  @override
  List<String> get customConstraints => [
        'CHECK(state IN (\'PENDING\',\'FIRED\',\'DISMISSED\'))',
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Call Plan Schedules
// ─────────────────────────────────────────────────────────────────────────────

class CallPlanSchedules extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get alarmId => text()(); // UUID for AlarmManager
  IntColumn get triggerAt => integer()(); // UTC epoch ms
  TextColumn get state =>
      text().withDefault(const Constant('PENDING'))(); // PENDING | ACTIVE | DONE
  TextColumn get filterBusinessType =>
      text().nullable()(); // null = all; else filter to type
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()(); // UTC epoch ms

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// Call Plan Leads  (chosen-lead overrides for a schedule)
// ─────────────────────────────────────────────────────────────────────────────

class CallPlanLeads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scheduleId =>
      text().references(CallPlanSchedules, #id, onDelete: KeyAction.cascade)();
  TextColumn get leadId =>
      text().references(Leads, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Dismissed Numbers  (unknown callers user said "not a lead")
// ─────────────────────────────────────────────────────────────────────────────

class DismissedNumbers extends Table {
  TextColumn get e164 => text()();
  IntColumn get dismissedAt => integer()(); // UTC epoch ms

  @override
  Set<Column> get primaryKey => {e164};
}

// ─────────────────────────────────────────────────────────────────────────────
// Call Recordings
// ─────────────────────────────────────────────────────────────────────────────

class CallRecordings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get callEventId =>
      integer().references(CallEvents, #id, onDelete: KeyAction.cascade)();
  TextColumn get uri => text()(); // SAF content URI or file URI
  TextColumn get displayName => text()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  BoolColumn get isManuallyAttached =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()(); // UTC epoch ms

  @override
  List<String> get customConstraints => ['UNIQUE (call_event_id, uri)'];
}

// ─────────────────────────────────────────────────────────────────────────────
// FTS5 virtual table  — lead_search
// ─────────────────────────────────────────────────────────────────────────────
// Drift doesn't generate FTS5 tables natively; the virtual table and its
// triggers are created in a migration / onCreate callback using raw SQL.
// See AppDatabase.onCreate() in database.dart.
