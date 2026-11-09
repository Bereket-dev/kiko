import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/crypto/db_key_manager.dart';
import '../core/db/call_events_repository.dart';
import '../core/db/call_plan_repository.dart';
import '../core/db/database.dart';
import '../core/db/leads_repository.dart';
import '../core/db/reminders_repository.dart';
import '../core/settings/app_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Core providers — initialised in bootstrap() before ProviderScope mounts
// ─────────────────────────────────────────────────────────────────────────────

/// Override this with the real [AppDatabase] instance after bootstrap.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
      'appDatabaseProvider must be overridden in ProviderScope overrides.');
});

/// Override this with the real [AppSettings] instance after bootstrap.
final appSettingsProvider = Provider<AppSettings>((ref) {
  throw UnimplementedError(
      'appSettingsProvider must be overridden in ProviderScope overrides.');
});

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

// ─────────────────────────────────────────────────────────────────────────────
// Bootstrap result
// ─────────────────────────────────────────────────────────────────────────────

class BootstrapResult {
  const BootstrapResult({
    required this.db,
    required this.settings,
  });

  final AppDatabase db;
  final AppSettings settings;
}

/// Called from [main()] before [runApp()].
/// Opens the encrypted DB, verifies FTS5, creates settings.
Future<BootstrapResult> bootstrap() async {
  // 1. Load SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final settings = AppSettings(prefs: prefs);

  // 2. Get or create DB encryption key
  final keyManager = DbKeyManager();
  final hexKey = await keyManager.getOrCreateKey();

  // 3. Open the encrypted database
  final executor = openEncryptedDatabase(hexKey);
  final db = AppDatabase(executor);

  // 4. FTS5 gate — abort if FTS5 is unavailable (spec requirement)
  await db.verifyFts5Available();

  // 5. Seed device ID (no-op if already set)
  await settings.getOrCreateDeviceId();

  return BootstrapResult(db: db, settings: settings);
}
