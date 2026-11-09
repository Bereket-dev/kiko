// Pigeon IDL — Recording files via Storage Access Framework
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/recording_files_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/RecordingFilesApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// Metadata for a single audio recording file.
class RecordingFile {
  /// Content URI (e.g. "content://…") or file URI of the recording.
  late String uri;

  /// Human-readable file name (without directory path).
  late String displayName;

  /// Duration of the audio in milliseconds.
  late int durationMs;

  /// File size in bytes.
  late int sizeBytes;

  /// Unix epoch milliseconds of the file's last-modified timestamp.
  late int lastModifiedMs;
}

@HostApi()
abstract class RecordingFilesApi {
  /// Persist the SAF folder [uri] returned by the system folder picker.
  ///
  /// Kotlin takes a persistable URI permission and stores the URI so it
  /// survives process death.
  void setRecordingsFolderUri(String uri);

  /// List all audio files in the persisted recordings folder that were
  /// last modified after [sinceTimestampMs] (Unix epoch ms).
  ///
  /// Returns an empty list when no folder has been configured or no new
  /// files are found.
  @async
  List<RecordingFile> getRecordingsSince(int sinceTimestampMs);
}
