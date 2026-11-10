import 'package:cloud_functions/cloud_functions.dart';

import '../../core/settings/app_settings.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a device registered in the cloud keystore.
class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.registeredAt,
  });

  final String deviceId;
  final String deviceName;
  final DateTime registeredAt;

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceId: map['deviceId'] as String,
      deviceName: map['deviceName'] as String,
      registeredAt: _parseDateTime(map['registeredAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.parse(value).toLocal();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    // Firestore Timestamp-like map: { _seconds, _nanoseconds } or { seconds, nanoseconds }
    if (value is Map) {
      final seconds = value['seconds'] ?? value['_seconds'];
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
      if (seconds is double) {
        return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).toInt());
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  String toString() =>
      'DeviceInfo(deviceId: $deviceId, deviceName: $deviceName, '
      'registeredAt: $registeredAt)';
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom exceptions
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when [CloudDeviceService.registerDevice] is called for a device that
/// has already been registered (Cloud Function code `already-exists`).
class DeviceAlreadyRegisteredException implements Exception {
  const DeviceAlreadyRegisteredException();

  @override
  String toString() =>
      'DeviceAlreadyRegisteredException: this device is already registered';
}

/// Thrown when [CloudDeviceService.registerDevice] is refused because the user
/// has reached the [CloudDeviceService.maxDevices] limit
/// (Cloud Function code `resource-exhausted`).
class MaxDevicesException implements Exception {
  const MaxDevicesException();

  @override
  String toString() =>
      'MaxDevicesException: maximum number of registered devices reached '
      '(limit: ${CloudDeviceService.maxDevices})';
}

/// Thrown when [CloudDeviceService.verifyOtp] is called with an incorrect or
/// expired OTP code.
class InvalidOtpException implements Exception {
  const InvalidOtpException();

  @override
  String toString() => 'InvalidOtpException: the OTP code is invalid or expired';
}

// ─────────────────────────────────────────────────────────────────────────────
// CloudDeviceService
// ─────────────────────────────────────────────────────────────────────────────

/// Manages device registration and OTP verification via Firebase Cloud
/// Functions.
///
/// Each user may register at most [maxDevices] devices. Device management
/// operations are delegated to Cloud Functions so that validation and
/// quota-enforcement happen server-side.
class CloudDeviceService {
  CloudDeviceService(this._settings);

  final AppSettings _settings;

  /// Maximum number of devices a single user may register.
  static const int maxDevices = 2;

  // ── Device registration ────────────────────────────────────────────────────

  /// Registers a device with the cloud backend.
  ///
  /// Calls the `registerDevice` Cloud Function with
  /// `{userId, deviceId, deviceName}`.
  ///
  /// Throws:
  /// * [DeviceAlreadyRegisteredException] — if the device is already registered
  ///   (`already-exists` from the function).
  /// * [MaxDevicesException] — if the user has reached [maxDevices]
  ///   (`resource-exhausted` from the function).
  Future<void> registerDevice({
    required String userId,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('registerDevice');
      await callable.call<void>({
        'userId': userId,
        'deviceId': deviceId,
        'deviceName': deviceName,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        throw const DeviceAlreadyRegisteredException();
      }
      if (e.code == 'resource-exhausted') {
        throw const MaxDevicesException();
      }
      rethrow;
    }
  }

  /// Returns all devices registered by [userId].
  ///
  /// Calls the `listDevices` Cloud Function and parses the result into a
  /// `List<DeviceInfo>`.
  Future<List<DeviceInfo>> listDevices(String userId) async {
    final callable = FirebaseFunctions.instance.httpsCallable('listDevices');
    final result = await callable.call<dynamic>({'userId': userId});

    final data = result.data;
    final List<dynamic> rawList = switch (data) {
      List() => data,
      Map() => (data['devices'] as List?) ?? const [],
      _ => const [],
    };

    return rawList.map((item) {
      final map = _asStringKeyedMap(item);
      return DeviceInfo.fromMap(map);
    }).toList();
  }

  /// Removes the device with [deviceId] from [userId]'s registration list.
  ///
  /// Calls the `removeDevice` Cloud Function.
  Future<void> removeDevice({
    required String userId,
    required String deviceId,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable('removeDevice');
    await callable.call<void>({
      'userId': userId,
      'deviceId': deviceId,
    });
  }

  // ── OTP ────────────────────────────────────────────────────────────────────

  /// Requests a one-time password to be sent to [email].
  ///
  /// Calls the `requestOtp` Cloud Function and returns the `otpToken` (a
  /// server-side session token) that must be passed to [verifyOtp].
  Future<String> requestOtp(String email) async {
    final callable = FirebaseFunctions.instance.httpsCallable('requestOtp');
    final result = await callable.call<dynamic>({'email': email});

    final data = _asStringKeyedMap(result.data);
    final token = data['otpToken'] as String?;
    if (token != null) return token;
    throw StateError(
      'requestOtp: unexpected response format — missing otpToken',
    );
  }

  /// Verifies a one-time password.
  ///
  /// * [otpToken] — the session token returned by [requestOtp].
  /// * [otpCode] — the numeric/alphanumeric code entered by the user.
  ///
  /// Throws [InvalidOtpException] if the code is wrong or expired.
  Future<void> verifyOtp({
    required String otpToken,
    required String otpCode,
  }) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyOtp');
      await callable.call<void>({
        'otpToken': otpToken,
        'otpCode': otpCode,
      });
    } on FirebaseFunctionsException {
      throw const InvalidOtpException();
    }
  }

  // ── Convenience helpers ────────────────────────────────────────────────────

  /// Returns `true` if the current device (identified by the device-id stored
  /// in [AppSettings]) is in the list of devices registered to [userId].
  Future<bool> isCurrentDeviceRegistered(String userId) async {
    final currentDeviceId = await _settings.getDeviceId();
    if (currentDeviceId == null) return false;

    final devices = await listDevices(userId);
    return devices.any((d) => d.deviceId == currentDeviceId);
  }

  static Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    throw StateError('Expected a map, got ${value.runtimeType}');
  }
}
