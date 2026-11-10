import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kiko/core/settings/app_settings.dart';
import 'package:kiko/features/cloud/e2e_key_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppSettings settings;
  late E2EKeyService service;
  final secureStore = <String, String>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    secureStore.clear();

    // Mock flutter_secure_storage platform channel.
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
    settings = AppSettings(prefs: prefs);
    service = E2EKeyService(settings);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  test('recovery code has expected format', () async {
    final code = await service.generateRecoveryCode();
    final parts = code.split('-');
    expect(parts.length, 8);
    for (final part in parts) {
      expect(part.length, 4);
      expect(part, matches(RegExp(r'^[0-9A-F]{4}$')));
    }
  });

  test('wrap then unwrap recovers the data key', () async {
    final dataKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
    final recoveryCode = await service.generateRecoveryCode();

    final wrapped =
        await service.wrapKeyWithRecoveryCode(dataKey, recoveryCode);
    expect(wrapped.length, 60);

    final unwrapped =
        await service.unwrapKeyWithRecoveryCode(wrapped, recoveryCode);
    expect(unwrapped, dataKey);
  });

  test('wrong recovery code throws InvalidRecoveryCodeException', () async {
    final dataKey = Uint8List.fromList(List<int>.generate(32, (i) => i));
    final wrapped = await service.wrapKeyWithRecoveryCode(
      dataKey,
      'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111',
    );

    expect(
      () => service.unwrapKeyWithRecoveryCode(
        wrapped,
        'ZZZZ-YYYY-XXXX-WWWW-VVVV-UUUU-TTTT-SSSS',
      ),
      throwsA(isA<InvalidRecoveryCodeException>()),
    );
  });

  test('local recovery code hash verifies', () async {
    const code = 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF-0000-1111';
    await service.saveRecoveryCodeHashLocally(code);
    expect(await service.verifyRecoveryCodeLocally(code), isTrue);
    expect(await service.verifyRecoveryCodeLocally('wrong'), isFalse);
  });
}
