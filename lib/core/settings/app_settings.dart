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

// Secure keys
const _kPinHash = 'secure_pin_hash';
const _kPinSalt = 'secure_pin_salt';
const _kDeviceId = 'secure_device_id';

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

  // ── Full wipe (account deletion) ─────────────────────────────────────────

  Future<void> clearAll() async {
    await _prefs.clear();
    await _secure.deleteAll();
  }
}
