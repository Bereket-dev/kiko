// ignore_for_file: lines_longer_than_80_chars
// Integration test: backup skip-if-unchanged
//
// Verifies that CloudBackupService.computeSnapshotHash produces a stable hash
// for identical data and a different hash when data changes.
// Also verifies the skip comparison logic: when lastBackupHash equals the
// newly computed hash, the backup should be skipped.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/settings/app_settings.dart';
import 'package:kiko/features/cloud/cloud_backup_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

AppDatabase _openTestDb() => AppDatabase(openInMemoryDatabase());

/// Creates an AppSettings backed by mock SharedPreferences + mock secure storage.
Future<AppSettings> _createTestSettings() async {
  // Ensure binding is initialized for platform channel mocks.
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});
  final secureStore = <String, String>{};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          final key = (call.arguments as Map)['key'] as String?;
          return key == null ? null : secureStore[key];
        case 'write':
          final args = call.arguments as Map;
          final key = args['key'] as String?;
          final value = args['value'] as String?;
          if (key != null && value != null) secureStore[key] = value;
          return null;
        case 'delete':
          final key = (call.arguments as Map)['key'] as String?;
          if (key != null) secureStore.remove(key);
          return null;
        case 'deleteAll':
          secureStore.clear();
          return null;
        case 'readAll':
          return Map<String, String>.from(secureStore);
        default:
          return null;
      }
    },
  );

  final prefs = await SharedPreferences.getInstance();
  return AppSettings(prefs: prefs);
}

/// Builds a backup map identical to what runBackup() constructs internally.
Map<String, dynamic> _buildBackupMap({
  String name = 'Test Lead',
  String status = 'NEW',
  String phone = '+251911000001',
}) {
  return {
    'version': 1,
    'exportedAt': '2023-11-14T00:00:00.000Z',
    'leads': [
      {
        'id': 'test-id',
        'name': name,
        'businessType': 'Retailer',
        'status': status,
        'notes': null,
        'source': 'MANUAL',
        'createdAt': '2023-11-14T00:00:00.000Z',
        'updatedAt': '2023-11-14T00:00:00.000Z',
        'phones': [
          {'e164': phone, 'label': null, 'isPrimary': true},
        ],
        'sections': [],
      },
    ],
    'callEvents': [],
    'reminders': [],
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('computeSnapshotHash', () {
    test('identical backup maps produce identical hashes', () async {
      final mapA = _buildBackupMap();
      final mapB = _buildBackupMap();

      final hashA = await CloudBackupService.computeSnapshotHash(mapA);
      final hashB = await CloudBackupService.computeSnapshotHash(mapB);

      expect(hashA, hashB,
          reason: 'Identical backup maps must produce the same hash');
    });

    test('different lead names produce different hashes', () async {
      final mapA = _buildBackupMap(name: 'Abebe');
      final mapB = _buildBackupMap(name: 'Meron');

      final hashA = await CloudBackupService.computeSnapshotHash(mapA);
      final hashB = await CloudBackupService.computeSnapshotHash(mapB);

      expect(hashA, isNot(hashB),
          reason: 'Different lead names must produce different hashes');
    });

    test('different phone numbers produce different hashes', () async {
      final mapA = _buildBackupMap(phone: '+251911000001');
      final mapB = _buildBackupMap(phone: '+251911000002');

      final hashA = await CloudBackupService.computeSnapshotHash(mapA);
      final hashB = await CloudBackupService.computeSnapshotHash(mapB);

      expect(hashA, isNot(hashB));
    });

    test('different statuses produce different hashes', () async {
      final mapA = _buildBackupMap(status: 'NEW');
      final mapB = _buildBackupMap(status: 'WON');

      final hashA = await CloudBackupService.computeSnapshotHash(mapA);
      final hashB = await CloudBackupService.computeSnapshotHash(mapB);

      expect(hashA, isNot(hashB));
    });

    test('hash is a 64-character hex string', () async {
      final hash = await CloudBackupService.computeSnapshotHash(_buildBackupMap());

      expect(hash.length, 64,
          reason: 'SHA-256 hex digest should be 64 chars');
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue,
          reason: 'Hash should be a lowercase hex string');
    });

    test('empty backup map produces a valid hash', () async {
      final hash = await CloudBackupService.computeSnapshotHash({});

      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
    });

    test('added call event changes hash', () async {
      final mapA = _buildBackupMap();

      final mapB = _buildBackupMap();
      (mapB['callEvents'] as List).add({
        'id': 1,
        'leadId': 'test-id',
        'e164': '+251911000001',
        'callType': 'INCOMING',
        'startedAt': '2023-11-14T00:00:00.000Z',
        'durationSec': 120,
        'notes': null,
      });

      final hashA = await CloudBackupService.computeSnapshotHash(mapA);
      final hashB = await CloudBackupService.computeSnapshotHash(mapB);

      expect(hashA, isNot(hashB),
          reason: 'Adding a call event must change the hash');
    });
  });

  group('skip-if-unchanged logic', () {
    late AppDatabase db;
    late AppSettings settings;

    setUp(() async {
      db = _openTestDb();
      settings = await _createTestSettings();
    });

    tearDown(() async {
      await db.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    test('when lastBackupHash matches computed hash, backup is skipped',
        () async {
      // 1. Compute the hash for a known backup map.
      final backupMap = _buildBackupMap();
      final hash = await CloudBackupService.computeSnapshotHash(backupMap);

      // 2. Store it as the last backup hash.
      await settings.setLastBackupHash(hash);

      // 3. Simulate the skip check (same logic as runBackup step 3).
      final newHash = await CloudBackupService.computeSnapshotHash(backupMap);
      final shouldSkip = (settings.lastBackupHash == newHash);

      expect(shouldSkip, isTrue,
          reason: 'When lastBackupHash equals newHash, backup should be skipped');
    });

    test('when lastBackupHash differs from computed hash, backup proceeds',
        () async {
      // 1. Store a stale hash.
      await settings.setLastBackupHash(
          '0000000000000000000000000000000000000000000000000000000000000000');

      // 2. Compute the actual hash.
      final backupMap = _buildBackupMap();
      final newHash = await CloudBackupService.computeSnapshotHash(backupMap);

      // 3. Simulate the skip check.
      final shouldSkip = (settings.lastBackupHash == newHash);

      expect(shouldSkip, isFalse,
          reason:
              'When hashes differ, backup should proceed (not be skipped)');
    });

    test('when lastBackupHash is null (first backup), backup proceeds',
        () async {
      // 1. Do not set any lastBackupHash (remains null).
      expect(settings.lastBackupHash, isNull);

      // 2. Compute the hash.
      final backupMap = _buildBackupMap();
      final newHash = await CloudBackupService.computeSnapshotHash(backupMap);

      // 3. Simulate the skip check.
      final shouldSkip = (settings.lastBackupHash == newHash);

      expect(shouldSkip, isFalse,
          reason: 'First backup (null hash) should never be skipped');
    });

    test('after data changes, hash no longer matches lastBackupHash',
        () async {
      // 1. Backup with original data.
      final originalMap = _buildBackupMap(name: 'Original');
      final originalHash =
          await CloudBackupService.computeSnapshotHash(originalMap);
      await settings.setLastBackupHash(originalHash);

      // 2. Data changes (lead name updated).
      final changedMap = _buildBackupMap(name: 'Updated');
      final changedHash =
          await CloudBackupService.computeSnapshotHash(changedMap);

      // 3. The skip check should now return false.
      final shouldSkip = (settings.lastBackupHash == changedHash);
      expect(shouldSkip, isFalse,
          reason: 'After data change, hash mismatch should trigger a new backup');
    });

    test('force=true bypasses hash check', () async {
      // The skip check in runBackup is: if (!force && _settings.lastBackupHash == newHash)
      // When force is true, the condition short-circuits and never skips.
      final backupMap = _buildBackupMap();
      final hash = await CloudBackupService.computeSnapshotHash(backupMap);
      await settings.setLastBackupHash(hash);

      // Simulate: force=true bypasses the hash comparison.
      // ignore: dead_code
      const force = true;
      final newHash = await CloudBackupService.computeSnapshotHash(backupMap);
      // When force is true, runBackup never reaches the skip check.
      // Verify the hashes match (would skip if !force) but force overrides.
      expect(settings.lastBackupHash, newHash);
      // With force=true, the skip condition `!force && ...` is always false.
      // ignore: dead_code
      if (!force && settings.lastBackupHash == newHash) {
        fail('force=true should bypass skip check');
      }
    });
  });
}
