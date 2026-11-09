// Pigeon IDL — Permissions and Android roles
// Dart host API: Dart calls → Kotlin

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/core/pigeon/permissions_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/com/bereket/kiko/pigeon/PermissionsApi.kt',
  kotlinOptions: KotlinOptions(package: 'com.bereket.kiko.pigeon'),
))

/// Snapshot of every permission/role Kiko needs at runtime.
class PermissionStatus {
  /// Whether Kiko holds the ROLE_CALL_SCREENING system role.
  late bool hasCallScreening;

  /// Whether the SYSTEM_ALERT_WINDOW (overlay) permission is granted.
  late bool hasOverlay;

  /// Whether READ_CALL_LOG is granted.
  late bool hasCallLog;

  /// Whether READ_PHONE_STATE is granted.
  late bool hasPhoneState;

  /// Whether POST_NOTIFICATIONS is granted (Android 13+).
  late bool hasNotifications;

  /// Whether the battery-optimisation exemption is active.
  late bool hasBatteryOptimizationExempt;
}

@HostApi()
abstract class PermissionsApi {
  /// Return the current state of all required permissions/roles.
  @async
  PermissionStatus checkPermissions();

  /// Launch the system dialog to request ROLE_CALL_SCREENING.
  ///
  /// Returns true if the role was granted after the request.
  @async
  bool requestCallScreeningRole();

  /// Launch the Settings overlay-permission screen.
  ///
  /// Returns true if SYSTEM_ALERT_WINDOW was granted.
  @async
  bool requestOverlayPermission();

  /// Request the READ_CALL_LOG runtime permission.
  ///
  /// Returns true if the permission was granted.
  @async
  bool requestCallLogPermission();

  /// Open battery-optimisation settings so the user can exempt Kiko.
  void requestBatteryOptimizationExemption();
}
