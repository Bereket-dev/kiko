import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show InsertMode, OrderingTerm, Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/db/database.dart';
import '../../core/settings/app_settings.dart';
import 'e2e_key_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BackupResult  (sealed result type)
// ─────────────────────────────────────────────────────────────────────────────

sealed class BackupResult {
  const BackupResult._();

  factory BackupResult.success({required int sizeBytes}) = BackupSuccess;
  factory BackupResult.skipped() = BackupSkipped;
  factory BackupResult.failed(String reason) = BackupFailed;
}

class BackupSuccess extends BackupResult {
  const BackupSuccess({required this.sizeBytes}) : super._();
  final int sizeBytes;
}

class BackupSkipped extends BackupResult {
  const BackupSkipped() : super._();
}

class BackupFailed extends BackupResult {
  const BackupFailed(this.reason) : super._();
  final String reason;
}

// ─────────────────────────────────────────────────────────────────────────────
// BackupEntry  (metadata for a single stored backup file)
// ─────────────────────────────────────────────────────────────────────────────

class BackupEntry {
  const BackupEntry({
    required this.path,
    required this.timestamp,
    required this.sizeBytes,
  });

  final String path;
  final DateTime timestamp;
  final int sizeBytes;
}

// ─────────────────────────────────────────────────────────────────────────────
// CloudBackupService
// ─────────────────────────────────────────────────────────────────────────────

class CloudBackupService {
  CloudBackupService({
    required AppDatabase db,
    required AppSettings settings,
    required E2EKeyService keyService,
  })  : _db = db,
        _settings = settings,
        _keyService = keyService;

  final AppDatabase _db;
  final AppSettings _settings;
  final E2EKeyService _keyService;

  /// WorkManager unique name / task name for the daily backup job.
  static const String backupTaskUniqueName = 'kiko_backup';
  static const String backupTaskName = 'kikoBackupTask';

  // Maximum backups to retain per user.
  static const int _maxBackups = 3;

  // AES-256-GCM: 12-byte nonce, 16-byte tag.
  static const int _nonceLength = 12;

  // ── runBackup ─────────────────────────────────────────────────────────────

  /// Performs a full encrypted backup to Firebase Storage via a short-lived
  /// signed upload URL from the `getUploadUrl` Cloud Function.
  Future<BackupResult> runBackup({bool force = false}) async {
    try {
      if (!_settings.backupEnabled && !force) {
        return BackupResult.skipped();
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return BackupResult.failed('No authenticated user.');
      }

      // ── 1. Load data ──────────────────────────────────────────────────────

      final leads = await (_db.select(_db.leads)
            ..where((t) => t.archived.equals(false))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

      final leadIds = leads.map((l) => l.id).toList();

      final allPhones = leadIds.isEmpty
          ? <LeadPhone>[]
          : await (_db.select(_db.leadPhones)
                ..where((t) => t.leadId.isIn(leadIds)))
              .get();

      final allSections = leadIds.isEmpty
          ? <LeadSection>[]
          : await (_db.select(_db.leadSections)
                ..where((t) => t.leadId.isIn(leadIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

      final callEventsList = <CallEvent>[];
      for (final leadId in leadIds) {
        final events = await (_db.select(_db.callEvents)
              ..where((t) => t.leadId.equals(leadId))
              ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
              ..limit(30))
            .get();
        callEventsList.addAll(events);
      }

      final pendingReminders = await (_db.select(_db.reminders)
            ..where((t) => t.state.equals('PENDING'))
            ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]))
          .get();

      // ── 2. Serialise ──────────────────────────────────────────────────────

      final phonesBy = <String, List<LeadPhone>>{};
      for (final p in allPhones) {
        (phonesBy[p.leadId] ??= []).add(p);
      }

      final sectionsBy = <String, List<LeadSection>>{};
      for (final s in allSections) {
        (sectionsBy[s.leadId] ??= []).add(s);
      }

      final now = DateTime.now();
      final exportedAt = now.toUtc().toIso8601String();

      final leadsJson = leads.map((lead) {
        final phones = (phonesBy[lead.id] ?? [])
            .map((p) => {
                  'e164': p.e164,
                  'label': p.label,
                  'isPrimary': p.isPrimary,
                })
            .toList();

        final sections = (sectionsBy[lead.id] ?? [])
            .map((s) => {
                  'title': s.title,
                  'body': s.body,
                  'position': s.position,
                })
            .toList();

        return {
          'id': lead.id,
          'name': lead.name,
          'businessType': lead.businessType,
          'status': lead.status,
          'notes': lead.notes,
          'source': lead.source,
          'createdAt':
              DateTime.fromMillisecondsSinceEpoch(lead.createdAt, isUtc: true)
                  .toIso8601String(),
          'updatedAt':
              DateTime.fromMillisecondsSinceEpoch(lead.updatedAt, isUtc: true)
                  .toIso8601String(),
          'phones': phones,
          'sections': sections,
        };
      }).toList();

      final callEventsJson = callEventsList
          .map((ce) => {
                'id': ce.id,
                'leadId': ce.leadId,
                'e164': ce.e164,
                'callType': ce.callType,
                'startedAt': DateTime.fromMillisecondsSinceEpoch(
                        ce.startedAt,
                        isUtc: true)
                    .toIso8601String(),
                'durationSec': ce.durationSec,
                'notes': ce.notes,
              })
          .toList();

      final remindersJson = pendingReminders
          .map((r) => {
                'id': r.id,
                'leadId': r.leadId,
                'alarmId': r.alarmId,
                'dueAt': DateTime.fromMillisecondsSinceEpoch(r.dueAt,
                        isUtc: true)
                    .toIso8601String(),
                'state': r.state,
                'notes': r.notes,
              })
          .toList();

      final backupMap = {
        'version': 1,
        'exportedAt': exportedAt,
        'leads': leadsJson,
        'callEvents': callEventsJson,
        'reminders': remindersJson,
      };

      final jsonString = jsonEncode(backupMap);
      final jsonBytes = Uint8List.fromList(utf8.encode(jsonString));

      // ── 3. Hash check (skip if unchanged) ────────────────────────────────

      final sha256 = Sha256();
      final hashSink = sha256.newHashSink();
      hashSink.add(jsonBytes);
      hashSink.close();
      final hashBytes = await hashSink.hash();
      final newHash =
          hashBytes.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      if (!force && _settings.lastBackupHash == newHash) {
        return BackupResult.skipped();
      }

      // ── 4. GZip compress ──────────────────────────────────────────────────

      final compressed =
          Uint8List.fromList(GZipEncoder().encode(jsonBytes) ?? jsonBytes);

      // ── 5. AES-256-GCM encrypt ────────────────────────────────────────────

      final dataKey = await _keyService.getOrCreateDataKey();
      final nonce = _generateRandomBytes(_nonceLength);

      final aesGcm = AesGcm.with256bits();
      final secretKey = SecretKey(dataKey);
      final secretBox = await aesGcm.encrypt(
        compressed,
        secretKey: secretKey,
        nonce: nonce,
      );

      final ciphertext = Uint8List.fromList(secretBox.cipherText);
      final tag = Uint8List.fromList(secretBox.mac.bytes);
      final blob = Uint8List(nonce.length + ciphertext.length + tag.length)
        ..setRange(0, nonce.length, nonce)
        ..setRange(nonce.length, nonce.length + ciphertext.length, ciphertext)
        ..setRange(nonce.length + ciphertext.length,
            nonce.length + ciphertext.length + tag.length, tag);

      // ── 6. Upload via signed URL ──────────────────────────────────────────

      final timestampMs = now.millisecondsSinceEpoch;
      final filename = '$timestampMs.enc';
      final upload = await _getUploadUrl(user.uid, filename);
      await _httpPut(upload.uploadUrl, blob);
      final storagePath = upload.storagePath;

      // ── 7. Trim old backups ───────────────────────────────────────────────

      await _trimOldBackups(user.uid);

      // ── 8. Persist metadata ───────────────────────────────────────────────

      await _settings.setLastBackupMs(timestampMs);
      await _settings.setLastBackupHash(newHash);

      // Ignore unused local — storagePath kept for clarity/debugging.
      assert(storagePath.isNotEmpty);

      return BackupResult.success(sizeBytes: blob.length);
    } catch (e, stack) {
      // ignore: avoid_print
      print('[CloudBackupService] runBackup failed: $e\n$stack');
      return BackupResult.failed(e.toString());
    }
  }

  // ── listBackups ───────────────────────────────────────────────────────────

  /// Lists all encrypted backup files stored for [userId], sorted newest first.
  Future<List<BackupEntry>> listBackups(String userId) async {
    final ref = FirebaseStorage.instance.ref().child('users/$userId/backups');
    final ListResult result = await ref.listAll();

    final entries = <BackupEntry>[];

    for (final item in result.items) {
      try {
        final meta = await item.getMetadata();
        final fileName = item.name;
        final tsStr = fileName.replaceAll('.enc', '');
        final tsMs = int.tryParse(tsStr);
        final timestamp = tsMs != null
            ? DateTime.fromMillisecondsSinceEpoch(tsMs, isUtc: true)
            : (meta.updated ?? meta.timeCreated ?? DateTime.now().toUtc());

        entries.add(BackupEntry(
          path: item.fullPath,
          timestamp: timestamp,
          sizeBytes: meta.size ?? 0,
        ));
      } catch (_) {
        // Skip items whose metadata cannot be retrieved.
      }
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  // ── restoreBackup ─────────────────────────────────────────────────────────

  /// Downloads the backup at [storagePath] via a signed URL, decrypts it using
  /// [dataKey], decompresses it, and restores leads + phones + sections in a
  /// single Drift transaction (all existing leads are wiped first).
  Future<void> restoreBackup({
    required String userId,
    required String storagePath,
    required Uint8List dataKey,
  }) async {
    // ── Download via signed URL ───────────────────────────────────────────

    final downloadUrl = await _getDownloadUrl(userId, storagePath);
    final blob = await _httpGet(downloadUrl);
    if (blob.isEmpty) {
      throw StateError('Downloaded backup is empty: $storagePath');
    }

    // ── Decrypt ───────────────────────────────────────────────────────────

    if (blob.length <= _nonceLength + 16) {
      throw StateError(
          'Backup file too small to be valid (${blob.length} bytes).');
    }

    final nonce = blob.sublist(0, _nonceLength);
    final tagStart = blob.length - 16;
    final cipherText = blob.sublist(_nonceLength, tagStart);
    final tag = blob.sublist(tagStart);

    final aesGcm = AesGcm.with256bits();
    final secretKey = SecretKey(dataKey);
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(tag),
    );

    final compressed = Uint8List.fromList(
      await aesGcm.decrypt(secretBox, secretKey: secretKey),
    );

    // ── Decompress ────────────────────────────────────────────────────────

    final jsonBytes =
        Uint8List.fromList(GZipDecoder().decodeBytes(compressed));
    final jsonString = utf8.decode(jsonBytes);
    final Map<String, dynamic> backupMap =
        jsonDecode(jsonString) as Map<String, dynamic>;

    // ── Parse ─────────────────────────────────────────────────────────────

    final leadsRaw =
        (backupMap['leads'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    // ── Restore in a single transaction ──────────────────────────────────

    await _db.transaction(() async {
      await _db.delete(_db.leads).go();

      for (final leadMap in leadsRaw) {
        final leadId = leadMap['id'] as String;
        final createdAt = _parseEpochMs(leadMap['createdAt']);
        final updatedAt = _parseEpochMs(leadMap['updatedAt']);

        await _db.into(_db.leads).insert(
              LeadsCompanion.insert(
                id: leadId,
                name: leadMap['name'] as String,
                businessType: Value(leadMap['businessType'] as String?),
                status: Value((leadMap['status'] as String?) ?? 'NEW'),
                source: Value((leadMap['source'] as String?) ?? 'MANUAL'),
                notes: Value(leadMap['notes'] as String?),
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
            );

        final phones = (leadMap['phones'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final phone in phones) {
          await _db.into(_db.leadPhones).insert(
                LeadPhonesCompanion.insert(
                  leadId: leadId,
                  e164: phone['e164'] as String,
                  label: Value(phone['label'] as String?),
                  isPrimary: Value((phone['isPrimary'] as bool?) ?? false),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }

        final sections = (leadMap['sections'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final (i, section) in sections.indexed) {
          await _db.into(_db.leadSections).insert(
                LeadSectionsCompanion.insert(
                  leadId: leadId,
                  title: section['title'] as String,
                  body: section['body'] as String,
                  position: Value((section['position'] as int?) ?? i),
                ),
              );
        }

        await _db.rebuildFtsRow(
          leadId: leadId,
          name: leadMap['name'] as String,
          businessType: leadMap['businessType'] as String?,
          notes: leadMap['notes'] as String?,
          phones: phones.map((p) => p['e164'] as String).toList(),
          sections: sections
              .expand((s) => [
                    s['title'] as String,
                    s['body'] as String,
                  ])
              .toList(),
        );
      }
    });
  }

  // ── schedulePeriodicBackup ────────────────────────────────────────────────

  /// Registers a WorkManager periodic task that fires every 24 hours on a
  /// connected network (Wi-Fi only when [wifiOnly] is true).
  static Future<void> schedulePeriodicBackup({bool wifiOnly = true}) async {
    await Workmanager().registerPeriodicTask(
      backupTaskUniqueName,
      backupTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType:
            wifiOnly ? NetworkType.unmetered : NetworkType.connected,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      tag: backupTaskUniqueName,
    );
  }

  /// Cancels the scheduled periodic backup task.
  static Future<void> cancelPeriodicBackup() async {
    await Workmanager().cancelByUniqueName(backupTaskUniqueName);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<({String uploadUrl, String storagePath})> _getUploadUrl(
    String userId,
    String filename,
  ) async {
    final callable = FirebaseFunctions.instance.httpsCallable('getUploadUrl');
    final result = await callable.call<dynamic>({
      'userId': userId,
      'filename': filename,
    });
    final data = _asMap(result.data);
    final uploadUrl = data['uploadUrl'] as String?;
    final storagePath = data['storagePath'] as String?;
    if (uploadUrl == null || storagePath == null) {
      throw StateError('getUploadUrl: missing uploadUrl/storagePath');
    }
    return (uploadUrl: uploadUrl, storagePath: storagePath);
  }

  Future<String> _getDownloadUrl(String userId, String storagePath) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('getDownloadUrl');
    final result = await callable.call<dynamic>({
      'userId': userId,
      'storagePath': storagePath,
    });
    final data = _asMap(result.data);
    final downloadUrl = data['downloadUrl'] as String?;
    if (downloadUrl == null) {
      throw StateError('getDownloadUrl: missing downloadUrl');
    }
    return downloadUrl;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  static Future<void> _httpPut(String url, Uint8List body) async {
    final client = HttpClient();
    try {
      final request = await client.putUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
      request.headers.contentLength = body.length;
      request.add(body);
      final response = await request.close();
      await response.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Upload failed with HTTP ${response.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }

  static Future<Uint8List> _httpGet(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Download failed with HTTP ${response.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close(force: true);
    }
  }

  static Uint8List _generateRandomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  static int _parseEpochMs(dynamic value) {
    if (value == null) return DateTime.now().millisecondsSinceEpoch;
    if (value is int) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _trimOldBackups(String userId) async {
    try {
      final entries = await listBackups(userId);
      if (entries.length <= _maxBackups) return;

      final toDelete = entries.sublist(_maxBackups);
      await Future.wait(
        toDelete.map(
          (e) => FirebaseStorage.instance.ref().child(e.path).delete(),
        ),
      );
    } catch (_) {
      // Trim failures are non-fatal; backup has already been stored.
    }
  }
}
