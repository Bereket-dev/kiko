import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/crypto/db_key_manager.dart';
import '../../core/db/database.dart';
import '../../core/settings/app_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DeleteAccountException
// ─────────────────────────────────────────────────────────────────────────────

class DeleteAccountException implements Exception {
  const DeleteAccountException(this.message);
  final String message;

  @override
  String toString() => 'DeleteAccountException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
// DeleteAccountService
// ─────────────────────────────────────────────────────────────────────────────
//
// Performs the full account-deletion wipe sequence:
//   1. Call the `deleteAccount` Cloud Function to remove server-side data.
//   2. Sign out of Firebase Auth.
//   3. Delete the local DB encryption key (DbKeyManager).
//   4. Clear all app settings (SharedPreferences + SecureStorage).
//   5. Close the Drift database (the missing key prevents it reopening).
//
// The caller is responsible for navigating to /onboarding afterwards.
// ─────────────────────────────────────────────────────────────────────────────

class DeleteAccountService {
  const DeleteAccountService({
    required AppSettings settings,
    required AppDatabase db,
  })  : _settings = settings,
        _db = db;

  final AppSettings _settings;
  final AppDatabase _db;

  Future<void> deleteAccount() async {
    try {
      // 1. Get current user UID — must be signed in.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw const DeleteAccountException('No signed-in user found.');
      }
      final uid = user.uid;

      // 2. Call the deleteAccount Cloud Function.
      await FirebaseFunctions.instance
          .httpsCallable('deleteAccount')
          .call<void>({'userId': uid});

      // 3. Sign out of Firebase Auth.
      await FirebaseAuth.instance.signOut();

      // 4. Delete the local DB encryption key.
      await DbKeyManager().deleteKey();

      // 5. Clear all app settings (SharedPreferences + SecureStorage).
      await _settings.clearAll();

      // 6. Close the Drift database.
      //    The DB key is gone so it cannot be reopened; the app will
      //    need to restart / navigate to onboarding which triggers a fresh
      //    bootstrap on next cold start.
      await _db.close();
    } on DeleteAccountException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw DeleteAccountException(
        'Cloud Function failed (${e.code}): ${e.message}',
      );
    } catch (e) {
      throw DeleteAccountException(e.toString());
    }
  }
}
