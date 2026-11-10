import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/scrypt.dart';

import '../../core/settings/app_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown by [E2EKeyService.unwrapKeyWithRecoveryCode] when AEAD authentication
/// fails, indicating an incorrect recovery code was supplied.
class InvalidRecoveryCodeException implements Exception {
  const InvalidRecoveryCodeException();

  @override
  String toString() =>
      'InvalidRecoveryCodeException: the recovery code is incorrect';
}

// ─────────────────────────────────────────────────────────────────────────────
// E2EKeyService
// ─────────────────────────────────────────────────────────────────────────────

/// Manages end-to-end encryption keys:
///
/// * Device data key — stored in [FlutterSecureStorage].
/// * Recovery code — user-readable code that can unlock the data key even if
///   secure storage is lost.
/// * Key wrapping — scrypt (N=16384, r=8, p=1) → AES-256-GCM.
/// * Cloud keystore — the wrapped key is persisted in Firestore under
///   `users/{userId}/keystore/wrapped`.
class E2EKeyService {
  E2EKeyService(this._settings);

  final AppSettings _settings;

  // ── Constants ──────────────────────────────────────────────────────────────

  static const _kSalt = 'kiko-recovery-v1';
  static const _kScryptN = 16384;
  static const _kScryptR = 8;
  static const _kScryptP = 1;
  static const _kNonceLength = 12; // AES-GCM standard nonce
  static const _kKeyLength = 32; // 256 bits

  // ── Lazy algorithm instances ───────────────────────────────────────────────

  static final _aesGcm = AesGcm.with256bits(nonceLength: _kNonceLength);

  static final _sha256 = Sha256();

  // ── Data key management ────────────────────────────────────────────────────

  /// Returns the device data key, creating and persisting a fresh one if none
  /// exists yet.
  ///
  /// The key is stored as a base-64 string in [FlutterSecureStorage] under
  /// `secure_data_key_b64`.
  Future<Uint8List> getOrCreateDataKey() async {
    final existing = await _settings.getDataKeyB64();
    if (existing != null) {
      return base64.decode(existing);
    }

    // Generate 32 cryptographically random bytes.
    final secretKey = await _aesGcm.newSecretKey();
    final keyBytes = Uint8List.fromList(await secretKey.extractBytes());

    await _settings.setDataKeyB64(base64.encode(keyBytes));
    return keyBytes;
  }

  /// Persists an already-unwrapped [dataKey] into secure storage (second-device
  /// restore path).
  Future<void> storeDataKey(Uint8List dataKey) async {
    await _settings.setDataKeyB64(base64.encode(dataKey));
  }

  // ── Recovery code ──────────────────────────────────────────────────────────

  /// Generates a fresh recovery code from 16 random bytes encoded as hex,
  /// then formatted into 4-character groups separated by hyphens.
  ///
  /// Hex avoids alphabet collisions with the hyphen separator (unlike
  /// base64url, which includes `-`). Format:
  /// `XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX`
  Future<String> generateRecoveryCode() async {
    final rng = Random.secure();
    final rawBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => rng.nextInt(256)),
    );

    // 16 bytes → 32 hex characters.
    final hex = rawBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    assert(hex.length == 32, 'Expected 32 chars, got ${hex.length}');

    // Group into 4-char chunks: XXXX-XXXX-...
    final buffer = StringBuffer();
    for (int i = 0; i < hex.length; i += 4) {
      if (i > 0) buffer.write('-');
      buffer.write(hex.substring(i, i + 4));
    }
    return buffer.toString(); // 32 chars + 7 hyphens = 39-char string
  }

  // ── Key wrapping ───────────────────────────────────────────────────────────

  /// Wraps [dataKey] using a key derived from [recoveryCode] via scrypt
  /// (N=16384, r=8, p=1, fixed salt `kiko-recovery-v1`), then encrypts with
  /// AES-256-GCM.
  ///
  /// Returns a 60-byte blob: `[12-byte nonce | 32-byte ciphertext | 16-byte tag]`.
  Future<Uint8List> wrapKeyWithRecoveryCode(
    Uint8List dataKey,
    String recoveryCode,
  ) async {
    final wrappingKey = _deriveWrappingKey(recoveryCode);

    final nonce = _aesGcm.newNonce();
    assert(nonce.length == _kNonceLength);

    final secretBox = await _aesGcm.encrypt(
      dataKey,
      secretKey: wrappingKey,
      nonce: nonce,
    );

    final blob = Uint8List(
      _kNonceLength + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    blob.setRange(0, _kNonceLength, nonce);
    blob.setRange(
      _kNonceLength,
      _kNonceLength + secretBox.cipherText.length,
      secretBox.cipherText,
    );
    blob.setRange(
      _kNonceLength + secretBox.cipherText.length,
      blob.length,
      secretBox.mac.bytes,
    );
    return blob;
  }

  /// Reverses [wrapKeyWithRecoveryCode], recovering the original data key.
  ///
  /// Throws [InvalidRecoveryCodeException] if the AEAD tag does not match
  /// (i.e. the recovery code is wrong or the blob is corrupt).
  Future<Uint8List> unwrapKeyWithRecoveryCode(
    Uint8List wrappedBlob,
    String recoveryCode,
  ) async {
    if (wrappedBlob.length < _kNonceLength + _kKeyLength + 16) {
      throw const InvalidRecoveryCodeException();
    }

    final nonce = wrappedBlob.sublist(0, _kNonceLength);
    final cipherText =
        wrappedBlob.sublist(_kNonceLength, _kNonceLength + _kKeyLength);
    final macBytes = wrappedBlob.sublist(_kNonceLength + _kKeyLength);

    final wrappingKey = _deriveWrappingKey(recoveryCode);

    try {
      final plainText = await _aesGcm.decrypt(
        SecretBox(
          cipherText,
          nonce: nonce,
          mac: Mac(macBytes),
        ),
        secretKey: wrappingKey,
      );
      return Uint8List.fromList(plainText);
    } on SecretBoxAuthenticationError {
      throw const InvalidRecoveryCodeException();
    } catch (_) {
      throw const InvalidRecoveryCodeException();
    }
  }

  // ── Firestore keystore ─────────────────────────────────────────────────────

  /// Writes the [wrappedKey] to Firestore at
  /// `users/{userId}/keystore/wrapped`.
  Future<void> storeWrappedKeyInFirestore(
    String userId,
    Uint8List wrappedKey,
  ) async {
    final b64 = base64.encode(wrappedKey);
    await _settings.setWrappedKeyB64(b64);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('keystore')
        .doc('wrapped')
        .set({
      'wrappedKeyB64': b64,
      'kdf': 'scrypt',
      'kdfParams': {
        'N': _kScryptN,
        'r': _kScryptR,
        'p': _kScryptP,
        'salt': _kSalt,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reads `users/{userId}/keystore/wrapped` and returns the wrapped key, or
  /// `null` if the document does not exist.
  Future<Uint8List?> fetchWrappedKeyFromFirestore(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('keystore')
        .doc('wrapped')
        .get();

    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final b64 = data['wrappedKeyB64'] as String?;
    if (b64 == null) return null;

    await _settings.setWrappedKeyB64(b64);
    return base64.decode(b64);
  }

  // ── Local recovery code hash ───────────────────────────────────────────────

  /// SHA-256 hashes [recoveryCode] and stores the hex digest in
  /// [FlutterSecureStorage] under `secure_recovery_code_hash`.
  Future<void> saveRecoveryCodeHashLocally(String recoveryCode) async {
    final hash = await _sha256Hash(recoveryCode);
    await _settings.setRecoveryCodeHash(hash);
  }

  /// Returns `true` if the SHA-256 hash of [recoveryCode] matches the
  /// previously stored hash.
  Future<bool> verifyRecoveryCodeLocally(String recoveryCode) async {
    final stored = await _settings.getRecoveryCodeHash();
    if (stored == null) return false;
    final hash = await _sha256Hash(recoveryCode);
    return hash == stored;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Derives a 32-byte [SecretKey] from [recoveryCode] using scrypt with the
  /// fixed salt `kiko-recovery-v1`.
  SecretKey _deriveWrappingKey(String recoveryCode) {
    final password = Uint8List.fromList(utf8.encode(recoveryCode));
    final salt = Uint8List.fromList(utf8.encode(_kSalt));
    final out = Uint8List(_kKeyLength);

    final scrypt = Scrypt()
      ..init(
        ScryptParameters(_kScryptN, _kScryptR, _kScryptP, _kKeyLength, salt),
      );
    scrypt.deriveKey(password, 0, out, 0);
    return SecretKey(out);
  }

  /// Returns the hex-encoded SHA-256 digest of [input].
  Future<String> _sha256Hash(String input) async {
    final hash = await _sha256.hash(utf8.encode(input));
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
