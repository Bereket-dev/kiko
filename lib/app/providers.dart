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
