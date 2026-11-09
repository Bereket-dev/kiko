// Pigeon IDL — Overlay settings sync
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/settings_sync.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/SettingsSync.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// All overlay-related settings that Kotlin needs at call-time.
class OverlaySettings {
  /// Master switch: when false the overlay is never shown.
  late bool masterEnabled;

  /// Show last-note and last-call snippets in the overlay.
  late bool showHistory;

  /// Show "Is this a lead?" dialog for unrecognised callers.
  late bool askUnknown;
}

@HostApi()
abstract class SettingsSyncApi {
  /// Push updated overlay settings from Dart to the native side.
  ///
  /// Call this whenever the user changes any of the three flags.
  void syncOverlaySettings(OverlaySettings settings);

  /// Read back the settings currently cached on the native side.
  @async
  OverlaySettings getOverlaySettings();
}
