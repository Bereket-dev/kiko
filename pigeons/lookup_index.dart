// Pigeon IDL — Encrypted lookup index (E.164 → lead info)
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/lookup_index.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/LookupIndex.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// A single entry in the native encrypted lookup index.
class LookupEntry {
  /// E.164-normalised phone number (e.g. "+251911234567").
  late String e164;

  /// Display name of the lead.
  late String name;

  /// Status code string (e.g. "NEW", "CONTACTED", "WON", …).
  late String statusCode;

  /// Most recent note snippet; null when no notes exist.
  String? lastNote;

  /// Unix epoch milliseconds of the last call; null when never called.
  int? lastCallAt;
}

@HostApi()
abstract class LookupIndexApi {
  /// Insert or update a single entry in the lookup index.
  void upsertEntry(LookupEntry entry);

  /// Remove the entry for [e164] from the lookup index.
  void removeEntry(String e164);

  /// Atomically replace the entire lookup index with [entries].
  ///
  /// Used after import/restore to keep the native store in sync.
  void rebuildIndex(List<LookupEntry> entries);

  /// Return the entry for [e164], or null if not found.
  @async
  LookupEntry? lookupByE164(String e164);
}
