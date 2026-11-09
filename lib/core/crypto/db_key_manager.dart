import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DB Key Manager
// ─────────────────────────────────────────────────────────────────────────────
//
// Generates a random 256-bit key on first launch and wraps it with Android
// Keystore via flutter_secure_storage (EncryptedSharedPreferences on Android,
// Keychain on iOS).
//
// The DB key is INDEPENDENT of the user PIN (spec section 4 / Phase 1).
// PIN changes never re-encrypt the database.
// ─────────────────────────────────────────────────────────────────────────────

const _kDbKeyAlias = 'kiko_db_key_hex';

class DbKeyManager {
  DbKeyManager({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                keyCipherAlgorithm:
                    KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
                storageCipherAlgorithm:
                    StorageCipherAlgorithm.AES_GCM_NoPadding,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Returns the 64-char hex DB key, generating and persisting one if absent.
  Future<String> getOrCreateKey() async {
    final existing = await _storage.read(key: _kDbKeyAlias);
    if (existing != null && existing.length == 64) return existing;

    final key = _generateRandomHexKey();
    await _storage.write(key: _kDbKeyAlias, value: key);
    return key;
  }

  /// Delete the key (used during account deletion / data wipe).
  Future<void> deleteKey() async {
    await _storage.delete(key: _kDbKeyAlias);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static String _generateRandomHexKey() {
    final random = Random.secure();
    final bytes = Uint8List(32);
    for (var i = 0; i < 32; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
