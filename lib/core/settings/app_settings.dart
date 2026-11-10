import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Key constants
// ─────────────────────────────────────────────────────────────────────────────

const _kLanguage = 'setting_language';
const _kOverlayMasterEnabled = 'setting_overlay_master';
const _kOverlayShowHistory = 'setting_overlay_history';
const _kAskUnknown = 'setting_ask_unknown';
const _kBackupEnabled = 'setting_backup_enabled';
const _kLastBackupMs = 'setting_last_backup_ms';
const _kAutoLockTimeoutMs = 'setting_auto_lock_timeout_ms';
const _kCalendarDisplayMode = 'setting_calendar_mode';
const _kRecordingsFolderUri = 'setting_recordings_folder_uri';
const _kPinSetupOffered = 'setting_pin_setup_offered';
const _kFlagSecureEnabled = 'setting_flag_secure';

// Cloud / onboarding keys
const _kOnboardingComplete = 'setting_onboarding_complete';
const _kCloudUserEmail = 'setting_cloud_user_email';
const _kLastBackupHash = 'setting_last_backup_hash';
const _kBackupWifiOnly = 'setting_backup_wifi_only';
const _kDevicesRegistered = 'setting_devices_registered';

// Secure keys
const _kPinHash = 'secure_pin_hash';
const _kPinSalt = 'secure_pin_salt';
const _kDeviceId = 'secure_device_id';

// Secure cloud keys
const _kDataKeyB64 = 'secure_data_key_b64';
const _kWrappedKeyB64 = 'secure_wrapped_key_b64';
const _kRecoveryCodeHash = 'secure_recovery_code_hash';

// ─────────────────────────────────────────────────────────────────────────────
// AppSettings
// ─────────────────────────────────────────────────────────────────────────────
//
// Non-sensitive settings: SharedPreferences.
// Sensitive settings (PIN hash/salt, device id): flutter_secure_storage.
// ─────────────────────────────────────────────────────────────────────────────

class AppSettings {
  AppSettings({
    required SharedPreferences prefs,
    FlutterSecureStorage? secureStorage,
  })  : _prefs = prefs,
        _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                keyCipherAlgorithm:
                    KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
                storageCipherAlgorithm:
                    StorageCipherAlgorithm.AES_GCM_NoPadding,
              ),
            );

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  final _uuid = const Uuid();

  // ── Language ──────────────────────────────────────────────────────────────

  /// e.g. "en", "am"
  String get language => _prefs.getString(_kLanguage) ?? 'en';
  Future<void> setLanguage(String code) =>
      _prefs.setString(_kLanguage, code);

  // ── Overlay settings ──────────────────────────────────────────────────────

  bool get overlayMasterEnabled =>
      _prefs.getBool(_kOverlayMasterEnabled) ?? true;
  Future<void> setOverlayMasterEnabled(bool v) =>
      _prefs.setBool(_kOverlayMasterEnabled, v);

  bool get overlayShowHistory =>
      _prefs.getBool(_kOverlayShowHistory) ?? true;
  Future<void> setOverlayShowHistory(bool v) =>
      _prefs.setBool(_kOverlayShowHistory, v);

  bool get askUnknown => _prefs.getBool(_kAskUnknown) ?? true;
  Future<void> setAskUnknown(bool v) => _prefs.setBool(_kAskUnknown, v);

  // ── Backup ────────────────────────────────────────────────────────────────

  bool get backupEnabled => _prefs.getBool(_kBackupEnabled) ?? true;
  Future<void> setBackupEnabled(bool v) =>
      _prefs.setBool(_kBackupEnabled, v);

  int? get lastBackupMs => _prefs.getInt(_kLastBackupMs);
  Future<void> setLastBackupMs(int ms) =>
      _prefs.setInt(_kLastBackupMs, ms);

  // ── Auto-lock ─────────────────────────────────────────────────────────────

  /// 0 = lock immediately on background.
  int get autoLockTimeoutMs =>
      _prefs.getInt(_kAutoLockTimeoutMs) ?? 0;
  Future<void> setAutoLockTimeoutMs(int ms) =>
      _prefs.setInt(_kAutoLockTimeoutMs, ms);

  // ── Calendar display ──────────────────────────────────────────────────────

  /// "ET" = Ethiopian, "GR" = Gregorian, "BOTH" = Ethiopian + Gregorian
  String get calendarDisplayMode =>
      _prefs.getString(_kCalendarDisplayMode) ?? 'ET';
  Future<void> setCalendarDisplayMode(String mode) =>
      _prefs.setString(_kCalendarDisplayMode, mode);

  // ── First-launch PIN setup ────────────────────────────────────────────────

  /// True once the skippable first-launch PIN screen has been shown.
  bool get pinSetupOffered => _prefs.getBool(_kPinSetupOffered) ?? false;
  Future<void> setPinSetupOffered(bool v) =>
      _prefs.setBool(_kPinSetupOffered, v);

  // ── FLAG_SECURE (screenshot protection) ───────────────────────────────────

  /// When true, lead screens set Android FLAG_SECURE.
  bool get flagSecureEnabled => _prefs.getBool(_kFlagSecureEnabled) ?? false;
  Future<void> setFlagSecureEnabled(bool v) =>
      _prefs.setBool(_kFlagSecureEnabled, v);

  // ── Recordings folder ─────────────────────────────────────────────────────

  String? get recordingsFolderUri =>
      _prefs.getString(_kRecordingsFolderUri);
  Future<void> setRecordingsFolderUri(String uri) =>
      _prefs.setString(_kRecordingsFolderUri, uri);

  // ── PIN (secure storage) ──────────────────────────────────────────────────

  Future<String?> getPinHash() => _secure.read(key: _kPinHash);
  Future<String?> getPinSalt() => _secure.read(key: _kPinSalt);
  Future<bool> hasPinSet() async => (await getPinHash()) != null;

  Future<void> storePinHash(String hash, String salt) async {
    await _secure.write(key: _kPinHash, value: hash);
    await _secure.write(key: _kPinSalt, value: salt);
  }

  Future<void> clearPin() async {
    await _secure.delete(key: _kPinHash);
    await _secure.delete(key: _kPinSalt);
  }

  // ── Device ID (secure storage) ────────────────────────────────────────────

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secure.read(key: _kDeviceId);
    if (existing != null) return existing;
    final id = _uuid.v4();
    await _secure.write(key: _kDeviceId, value: id);
    return id;
  }

  Future<String?> getDeviceId() => _secure.read(key: _kDeviceId);

  Future<void> clearDeviceId() => _secure.delete(key: _kDeviceId);

  // ── Onboarding ────────────────────────────────────────────────────────────

  bool get onboardingComplete =>
      _prefs.getBool(_kOnboardingComplete) ?? false;
  Future<void> setOnboardingComplete(bool v) =>
      _prefs.setBool(_kOnboardingComplete, v);

  // ── Cloud user ────────────────────────────────────────────────────────────

  String? get cloudUserEmail => _prefs.getString(_kCloudUserEmail);
  Future<void> setCloudUserEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_kCloudUserEmail);
    } else {
      await _prefs.setString(_kCloudUserEmail, email);
    }
  }

  // ── Backup hash (change-detection) ───────────────────────────────────────

  /// SHA-256 hex of the last successfully uploaded snapshot.
  /// Null if no backup has been completed yet.
  String? get lastBackupHash => _prefs.getString(_kLastBackupHash);
  Future<void> setLastBackupHash(String? hash) async {
    if (hash == null) {
      await _prefs.remove(_kLastBackupHash);
    } else {
      await _prefs.setString(_kLastBackupHash, hash);
    }
  }

  // ── Backup Wi-Fi only ─────────────────────────────────────────────────────

  bool get backupWifiOnly => _prefs.getBool(_kBackupWifiOnly) ?? true;
  Future<void> setBackupWifiOnly(bool v) =>
      _prefs.setBool(_kBackupWifiOnly, v);

  // ── Devices registered ────────────────────────────────────────────────────

  int get devicesRegistered => _prefs.getInt(_kDevicesRegistered) ?? 0;
  Future<void> setDevicesRegistered(int count) =>
      _prefs.setInt(_kDevicesRegistered, count);

  // ── Data key (secure storage) ─────────────────────────────────────────────

  /// Base64-encoded 32-byte device data key.
  Future<String?> getDataKeyB64() => _secure.read(key: _kDataKeyB64);
  Future<void> setDataKeyB64(String b64) =>
      _secure.write(key: _kDataKeyB64, value: b64);
  Future<void> clearDataKey() => _secure.delete(key: _kDataKeyB64);

  // ── Wrapped key (secure storage) ──────────────────────────────────────────

  /// Base64-encoded recovery-code-wrapped copy of the data key.
  Future<String?> getWrappedKeyB64() => _secure.read(key: _kWrappedKeyB64);
  Future<void> setWrappedKeyB64(String b64) =>
      _secure.write(key: _kWrappedKeyB64, value: b64);
  Future<void> clearWrappedKey() => _secure.delete(key: _kWrappedKeyB64);

  // ── Recovery code hash (secure storage) ───────────────────────────────────

  /// Bcrypt/SHA-256 hash of the recovery code for local verification.
  Future<String?> getRecoveryCodeHash() =>
      _secure.read(key: _kRecoveryCodeHash);
  Future<void> setRecoveryCodeHash(String hash) =>
      _secure.write(key: _kRecoveryCodeHash, value: hash);
  Future<void> clearRecoveryCodeHash() =>
      _secure.delete(key: _kRecoveryCodeHash);

  // ── Clear cloud state (keeps PIN, language, overlay) ─────────────────────

  /// Removes only cloud-related prefs and secure keys.
  /// Does NOT touch PIN, language, overlay/ask settings, or device ID.
  Future<void> clearCloudState() async {
    await Future.wait([
      _prefs.remove(_kCloudUserEmail),
      _prefs.remove(_kLastBackupHash),
      _prefs.remove(_kBackupWifiOnly),
      _prefs.remove(_kDevicesRegistered),
      _prefs.remove(_kOnboardingComplete),
      _secure.delete(key: _kDataKeyB64),
      _secure.delete(key: _kWrappedKeyB64),
      _secure.delete(key: _kRecoveryCodeHash),
    ]);
  }

  // ── Full wipe (account deletion) ─────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.clear();
    await _secure.deleteAll();
  }
}
