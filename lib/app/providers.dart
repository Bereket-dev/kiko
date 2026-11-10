import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/crypto/db_key_manager.dart';
import '../core/db/call_events_repository.dart';
import '../core/db/call_plan_repository.dart';
import '../core/db/database.dart';
import '../core/db/leads_repository.dart';
import '../core/db/pending_drain_service.dart';
import '../core/db/reminders_repository.dart';
import '../core/settings/app_settings.dart';
import '../core/utils/image_service.dart';
import '../core/utils/lookup_index_service.dart';
import '../features/calls/recording_scan_service.dart';
import '../features/cloud/cloud_auth_service.dart';
import '../features/cloud/cloud_backup_service.dart';
import '../features/cloud/cloud_device_service.dart';
import '../features/cloud/delete_account_service.dart';
import '../features/cloud/e2e_key_service.dart';
import '../features/importexport/import_export_repository.dart';
import '../features/reminders/alarm_service.dart';
import '../features/reminders/call_plan_service.dart';
import '../features/reminders/reminder_service.dart';
import '../features/search/lead_filter.dart';
import '../features/security/pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core providers — initialised in bootstrap() before ProviderScope mounts
// ─────────────────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden.');
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError('appSettingsProvider must be overridden.');
});

// ─────────────────────────────────────────────────────────────────────────────
// Service providers
// ─────────────────────────────────────────────────────────────────────────────

final imageServiceProvider = Provider<ImageService>((_) => const ImageService());

final lookupIndexServiceProvider =
    Provider<LookupIndexService>((_) => const LookupIndexService());

// ─────────────────────────────────────────────────────────────────────────────
// Repository providers
// ─────────────────────────────────────────────────────────────────────────────

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(ref.watch(appDatabaseProvider));
});

final callEventsRepositoryProvider = Provider<CallEventsRepository>((ref) {
  return CallEventsRepository(ref.watch(appDatabaseProvider));
});

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.watch(appDatabaseProvider));
});

final callPlanRepositoryProvider = Provider<CallPlanRepository>((ref) {
  return CallPlanRepository(ref.watch(appDatabaseProvider));
});

final pendingDrainServiceProvider = Provider<PendingDrainService>((ref) {
  return PendingDrainService(
    callEventsRepository: ref.watch(callEventsRepositoryProvider),
    leadsRepository: ref.watch(leadsRepositoryProvider),
    lookupIndexService: ref.watch(lookupIndexServiceProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

final recordingScanServiceProvider = Provider<RecordingScanService>((ref) {
  return RecordingScanService(
    callEventsRepo: ref.watch(callEventsRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Leads UI providers
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of all non-archived leads, newest first.
final watchLeadsProvider = StreamProvider<List<Lead>>((ref) {
  return ref.watch(leadsRepositoryProvider).watchAllLeads();
});

/// Single lead by id.
final leadDetailProvider =
    FutureProvider.family<Lead?, String>((ref, id) async {
  return ref.watch(leadsRepositoryProvider).getLeadById(id);
});

/// Phones for a lead.
final leadPhonesProvider =
    FutureProvider.family<List<LeadPhone>, String>((ref, leadId) async {
  return ref.watch(leadsRepositoryProvider).getPhonesForLead(leadId);
});

/// Sections for a lead.
final leadSectionsProvider =
    FutureProvider.family<List<LeadSection>, String>((ref, leadId) async {
  return ref.watch(leadsRepositoryProvider).getSectionsForLead(leadId);
});

/// Images for a lead.
final leadImagesProvider =
    FutureProvider.family<List<LeadImage>, String>((ref, leadId) async {
  return ref.watch(leadsRepositoryProvider).getImagesForLead(leadId);
});

/// Distinct non-null business types (trimmed, case-insensitive deduped).
final businessTypesProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(leadsRepositoryProvider).getDistinctBusinessTypes();
});

// ─────────────────────────────────────────────────────────────────────────────
// Phase 4 — Merge providers
// ─────────────────────────────────────────────────────────────────────────────

/// Find duplicate leads whose e164 phones conflict with [e164s].
/// Pass [excludeLeadId] when editing an existing lead to skip its own phones.
///
/// Example:
///   ref.read(duplicatesByPhonesProvider(
///     (e164s: ['+251911...'], excludeLeadId: null)
///   ).future)
final duplicatesByPhonesProvider = FutureProvider.family<List<Lead>,
    ({List<String> e164s, String? excludeLeadId})>(
  (ref, args) async {
    return ref.watch(leadsRepositoryProvider).findDuplicatesByPhones(
          args.e164s,
          excludeLeadId: args.excludeLeadId,
        );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Phase 6 — Reminders and Call Plan providers
// ─────────────────────────────────────────────────────────────────────────────

final alarmServiceProvider = Provider<AlarmService>((_) => AlarmService());

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    remindersRepo: ref.watch(remindersRepositoryProvider),
    alarmService:  ref.watch(alarmServiceProvider),
  );
});

/// Pending reminder for a single lead (null when none).
final leadReminderProvider =
    FutureProvider.family<Reminder?, String>((ref, leadId) async {
  return ref
      .watch(remindersRepositoryProvider)
      .getPendingReminderForLead(leadId);
});

/// Stream of all PENDING reminders — used by boot-drain + reminder badge.
final pendingRemindersProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(remindersRepositoryProvider).watchPendingReminders();
});

final callPlanServiceProvider = Provider<CallPlanService>((ref) {
  return CallPlanService(
    callPlanRepo: ref.watch(callPlanRepositoryProvider),
    alarmService: ref.watch(alarmServiceProvider),
  );
});

/// All PENDING call-plan schedules — used by boot-drain reschedule.
final pendingCallPlanSchedulesProvider =
    FutureProvider<List<CallPlanSchedule>>((ref) async {
  return ref.watch(callPlanRepositoryProvider).getPendingSchedules();
});

/// A single CallPlanSchedule by id.
final callPlanScheduleProvider =
    FutureProvider.family<CallPlanSchedule?, String>((ref, id) async {
  return ref.watch(callPlanRepositoryProvider).getScheduleById(id);
});

/// Prioritised lead list for a given CallPlanSchedule.
///
/// Priority order:
///   1. Chosen leads  (CallPlanLeads rows for this schedule, undone)
///   2. Business-type filter  (if schedule.filterBusinessType != null)
///   3. Due-today  (leads with a PENDING reminder due today)
///
/// Deduplication is applied so a lead appears at most once.
final callPlanLeadsProvider =
    FutureProvider.family<List<Lead>, CallPlanSchedule>((ref, schedule) async {
  final leadsRepo    = ref.watch(leadsRepositoryProvider);
  final callPlanRepo = ref.watch(callPlanRepositoryProvider);
  final remRepo      = ref.watch(remindersRepositoryProvider);

  final seen = <String>{};
  final result = <Lead>[];

  // 1. Chosen leads.
  final chosenRows = await callPlanRepo.getLeadsForSchedule(schedule.id);
  for (final row in chosenRows) {
    if (row.done) continue;
    final lead = await leadsRepo.getLeadById(row.leadId);
    if (lead != null && !lead.archived && seen.add(lead.id)) {
      result.add(lead);
    }
  }

  // 2. Business-type filter.
  if (schedule.filterBusinessType != null) {
    final all = await leadsRepo.watchAllLeads().first;
    for (final lead in all) {
      if (lead.businessType == schedule.filterBusinessType &&
          seen.add(lead.id)) {
        result.add(lead);
      }
    }
  }

  // 3. Due-today leads (have a PENDING reminder due today).
  final pending = await remRepo.getPendingReminders();
  final todayStart = DateTime.now()
      .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
      .millisecondsSinceEpoch;
  final todayEnd = DateTime.now()
      .copyWith(hour: 23, minute: 59, second: 59, millisecond: 999)
      .millisecondsSinceEpoch;

  for (final reminder in pending) {
    if (reminder.dueAt < todayStart || reminder.dueAt > todayEnd) continue;
    final lead = await leadsRepo.getLeadById(reminder.leadId);
    if (lead != null && !lead.archived && seen.add(lead.id)) {
      result.add(lead);
    }
  }

  return result;
});

// ─────────────────────────────────────────────────────────────────────────────
// Phase 7 — Search + Import/Export providers
// ─────────────────────────────────────────────────────────────────────────────

/// Import/Export repository (CSV, XLSX export + import with conflict resolution).
final importExportRepositoryProvider =
    Provider<ImportExportRepository>((ref) {
  return ImportExportRepository(
    leadsRepo: ref.watch(leadsRepositoryProvider),
    callEventsRepo: ref.watch(callEventsRepositoryProvider),
    remindersRepo: ref.watch(remindersRepositoryProvider),
    lookupIndex: ref.watch(lookupIndexServiceProvider),
  );
});

/// Active filter used by SearchScreen. Reset to empty when leaving search.
final searchFilterProvider =
    StateProvider<LeadFilter>((ref) => LeadFilter.empty);

// ─────────────────────────────────────────────────────────────────────────────
// Phase 8 — Security & Localisation providers
// ─────────────────────────────────────────────────────────────────────────────

/// PIN service singleton — holds in-memory lockout state.
final pinServiceProvider = Provider<PinService>((ref) {
  return PinService(ref.watch(appSettingsProvider));
});

/// Currently active locale code ("en" or "am").
/// Watching this triggers a rebuild of [KikoApp], switching the locale.
final localePrefProvider = StateProvider<String>((ref) {
  return ref.watch(appSettingsProvider).language;
});

// ─────────────────────────────────────────────────────────────────────────────
// Phase 9 — Cloud providers
// ─────────────────────────────────────────────────────────────────────────────

final cloudAuthServiceProvider = Provider<CloudAuthService>((ref) {
  return CloudAuthService();
});

final e2eKeyServiceProvider = Provider<E2EKeyService>((ref) {
  return E2EKeyService(ref.watch(appSettingsProvider));
});

final cloudDeviceServiceProvider = Provider<CloudDeviceService>((ref) {
  return CloudDeviceService(ref.watch(appSettingsProvider));
});

final cloudBackupServiceProvider = Provider<CloudBackupService>((ref) {
  return CloudBackupService(
    db: ref.watch(appDatabaseProvider),
    settings: ref.watch(appSettingsProvider),
    keyService: ref.watch(e2eKeyServiceProvider),
  );
});

final deleteAccountServiceProvider = Provider<DeleteAccountService>((ref) {
  return DeleteAccountService(
    settings: ref.watch(appSettingsProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// Stream of Firebase Auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(cloudAuthServiceProvider).authStateChanges;
});

/// True once onboarding is complete.
final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).onboardingComplete;
});

// ─────────────────────────────────────────────────────────────────────────────
// Bootstrap result
// ─────────────────────────────────────────────────────────────────────────────

class BootstrapResult {
  const BootstrapResult({required this.db, required this.settings});
  final AppDatabase db;
  final AppSettings settings;
}

Future<BootstrapResult> bootstrap() async {
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings(prefs: prefs);
  final keyManager = DbKeyManager();
  final hexKey = await keyManager.getOrCreateKey();
  final executor = openEncryptedDatabase(hexKey);
  final db = AppDatabase(executor);
  await db.verifyFts5Available();
  await settings.getOrCreateDeviceId();
  return BootstrapResult(db: db, settings: settings);
}
