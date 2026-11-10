import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/settings/app_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LockoutState
// ─────────────────────────────────────────────────────────────────────────────

class LockoutState {
  const LockoutState({
    required this.failureCount,
    required this.lockedUntil,
  });

  final int failureCount;

  /// Non-null when actively locked out; the [DateTime] when lockout ends.
  final DateTime? lockedUntil;

  /// True when the user must wait before trying again.
  bool get isLockedOut =>
      lockedUntil != null && DateTime.now().isBefore(lockedUntil!);

  /// Remaining lockout duration, or [Duration.zero] when not locked.
  Duration get remainingLockout {
    if (lockedUntil == null) return Duration.zero;
    final remaining = lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  LockoutState copyWith({int? failureCount, DateTime? lockedUntil}) {
    return LockoutState(
      failureCount: failureCount ?? this.failureCount,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  static const LockoutState none = LockoutState(failureCount: 0, lockedUntil: null);
}

// ─────────────────────────────────────────────────────────────────────────────
// PinVerifyResult
// ─────────────────────────────────────────────────────────────────────────────

enum PinVerifyResult {
  /// Correct PIN — user is authenticated.
  success,

  /// Wrong PIN; [attemptsRemaining] tells how many tries are left before lockout.
  wrongPin,

  /// Locked out — must wait [lockoutState.remainingLockout].
  lockedOut,

  /// No PIN has been set up yet.
  noPinSet,
}

class PinVerifyResponse {
  const PinVerifyResponse({
    required this.result,
    required this.lockoutState,
    this.attemptsRemaining,
  });

  final PinVerifyResult result;
  final LockoutState lockoutState;

  /// Non-null when [result] is [PinVerifyResult.wrongPin].
  final int? attemptsRemaining;
}

// ─────────────────────────────────────────────────────────────────────────────
// PinService
// ─────────────────────────────────────────────────────────────────────────────
//
// Spec (Phase 8):
//   • 4-digit PIN stored as PBKDF2-HMAC-SHA256(pin, salt, 100000 iterations).
//   • Salt: 16 bytes random, hex-encoded alongside the hash.
//   • Lockout schedule: 5 failures → 30s, 6 → 1m, 7+ → 5m.
//   • DB key is NOT tied to PIN.  PIN changes never re-encrypt the database.
//
// ─────────────────────────────────────────────────────────────────────────────

class PinService {
  PinService(this._settings);

  final AppSettings _settings;

  // ── In-memory lockout state ───────────────────────────────────────────────
  // Persisted in memory only; resets on app restart (acceptable per spec,
  // which only requires the lockout during one session).

  LockoutState _lockout = LockoutState.none;

  // ── PBKDF2 ───────────────────────────────────────────────────────────────

  static const int _pbkdf2Iterations = 100000;
  static const int _saltLengthBytes = 16;
  static const int _hashLengthBytes = 32; // SHA-256 → 256 bits

  static final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: _hashLengthBytes * 8,
  );

  // ── Setup / change ────────────────────────────────────────────────────────

  /// Returns true if a PIN has been stored.
  Future<bool> hasPinSet() => _settings.hasPinSet();

  /// Sets up (or replaces) the PIN.
  /// Callers should confirm the PIN before calling this.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = await _deriveHash(pin, salt);
    await _settings.storePinHash(
      base64.encode(hash),
      base64.encode(salt),
    );
    // Reset lockout on PIN change.
    _lockout = LockoutState.none;
  }

  /// Clears the PIN, disabling the lock screen.
  Future<void> clearPin() async {
    await _settings.clearPin();
    _lockout = LockoutState.none;
  }

  // ── Verification ──────────────────────────────────────────────────────────

  /// Current in-memory lockout state.
  LockoutState get lockoutState => _lockout;

  /// Attempts to verify [pin] against the stored hash.
  ///
  /// Returns a [PinVerifyResponse] with the result and updated lockout state.
  Future<PinVerifyResponse> verifyPin(String pin) async {
    // 1. Check if PIN is set.
    if (!await hasPinSet()) {
      return PinVerifyResponse(
        result: PinVerifyResult.noPinSet,
        lockoutState: _lockout,
      );
    }

    // 2. Check lockout.
    if (_lockout.isLockedOut) {
      return PinVerifyResponse(
        result: PinVerifyResult.lockedOut,
        lockoutState: _lockout,
      );
    }

    // 3. Load stored hash and salt.
    final storedHashB64 = await _settings.getPinHash();
    final storedSaltB64 = await _settings.getPinSalt();
    if (storedHashB64 == null || storedSaltB64 == null) {
      return PinVerifyResponse(
        result: PinVerifyResult.noPinSet,
        lockoutState: _lockout,
      );
    }

    final storedSalt = base64.decode(storedSaltB64);
    final storedHash = base64.decode(storedHashB64);

    // 4. Derive hash for entered PIN.
    final derivedHash = await _deriveHash(pin, storedSalt);

    // 5. Constant-time comparison.
    if (_secureEquals(derivedHash, storedHash)) {
      _lockout = LockoutState.none; // Reset on success.
      return PinVerifyResponse(
        result: PinVerifyResult.success,
        lockoutState: _lockout,
      );
    }

    // 6. Wrong PIN — increment failure counter and apply lockout.
    _lockout = _applyFailure(_lockout);
    final attemptsLeft = _attemptsBeforeLockout(_lockout.failureCount);
    return PinVerifyResponse(
      result: PinVerifyResult.wrongPin,
      lockoutState: _lockout,
      attemptsRemaining: attemptsLeft,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  static Uint8List _generateSalt() {
    final rng = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(_saltLengthBytes, (_) => rng.nextInt(256)));
  }

  static Future<Uint8List> _deriveHash(String pin, List<int> salt) async {
    final secretKey = SecretKey(utf8.encode(pin));
    final derived = await _pbkdf2.deriveKey(
      secretKey: secretKey,
      nonce: salt,
    );
    return Uint8List.fromList(await derived.extractBytes());
  }

  /// Constant-time byte-slice comparison to resist timing attacks.
  static bool _secureEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Updates [current] by incrementing failures and computing lockout duration.
  ///
  /// Lockout schedule (cumulative failures):
  ///   5 failures  → 30 seconds
  ///   6 failures  → 1 minute
  ///   7+ failures → 5 minutes
  static LockoutState _applyFailure(LockoutState current) {
    final failures = current.failureCount + 1;
    DateTime? newLockedUntil;

    if (failures >= 7) {
      newLockedUntil = DateTime.now().add(const Duration(minutes: 5));
    } else if (failures == 6) {
      newLockedUntil = DateTime.now().add(const Duration(minutes: 1));
    } else if (failures == 5) {
      newLockedUntil = DateTime.now().add(const Duration(seconds: 30));
    }

    return LockoutState(
      failureCount: failures,
      lockedUntil: newLockedUntil,
    );
  }

  /// How many attempts remain before the NEXT lockout trigger.
  /// Returns 0 when already locked or at max.
  static int _attemptsBeforeLockout(int failures) {
    if (failures >= 5) return 0;
    return 5 - failures;
  }

  /// Resets in-memory lockout state (e.g. after biometric success).
  void resetLockout() {
    _lockout = LockoutState.none;
  }
}
