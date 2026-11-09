// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/features/parser/phone_normalizer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PhoneNormalizer tests — spec section 6.2
//
// All Ethiopian (ET, +251) number formats that the app must handle:
//   - Mobile:    09x xxxxxxxx  (Ethio Telecom / Safaricom ET)
//   - Mobile:    07x xxxxxxxx  (Safaricom ET)
//   - Landline:  011 xxxxxxx   (Addis Ababa)
//   - Landline:  0[2-5]x xxxxxxxx (regional)
//   - Subscriber only: 9xxxxxxxx / 7xxxxxxxx (9 digits, no leading 0)
//   - Country code variants: +251, 00251, 251 (bare)
//   - With formatting: spaces, dashes, dots, parentheses
//   - International non-ET numbers (pass-through)
//   - Invalid / too-short inputs → null / exception
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const n = PhoneNormalizer(); // default region ET

  group('Ethiopian mobile numbers (09x prefix)', () {
    test('plain 10-digit local format', () {
      expect(n.normalize('0911234567'), '+251911234567');
    });

    test('with spaces', () {
      expect(n.normalize('091 123 4567'), '+251911234567');
    });

    test('with dashes', () {
      expect(n.normalize('091-123-4567'), '+251911234567');
    });

    test('with dots', () {
      expect(n.normalize('091.123.4567'), '+251911234567');
    });

    test('mixed formatting', () {
      expect(n.normalize('0911 23-45 67'), '+251911234567');
    });

    test('07x mobile prefix', () {
      expect(n.normalize('0712345678'), '+251712345678');
    });

    test('07x with dashes', () {
      expect(n.normalize('071-234-5678'), '+251712345678');
    });
  });

  group('Ethiopian mobile — international representations', () {
    test('+251 E.164 — already normalised', () {
      expect(n.normalize('+251911234567'), '+251911234567');
    });

    test('+251 with spaces', () {
      expect(n.normalize('+251 91 123 4567'), '+251911234567');
    });

    test('+251 with dashes', () {
      expect(n.normalize('+251-91-123-4567'), '+251911234567');
    });

    test('00251 IDD prefix', () {
      expect(n.normalize('00251911234567'), '+251911234567');
    });

    test('00251 with spaces', () {
      expect(n.normalize('00251 91 123 4567'), '+251911234567');
    });

    test('251 bare country code (9-digit subscriber)', () {
      expect(n.normalize('251911234567'), '+251911234567');
    });
  });

  group('Ethiopian mobile — subscriber-only (no leading 0)', () {
    test('9-digit mobile starting with 9', () {
      expect(n.normalize('911234567'), '+251911234567');
    });

    test('9-digit mobile starting with 7', () {
      expect(n.normalize('712345678'), '+251712345678');
    });
  });

  group('Ethiopian landline numbers', () {
    test('Addis Ababa 011 prefix (10 digits)', () {
      // 0111234567 → strip leading 0 → 111234567 → +251111234567 (12 digits)
      expect(n.normalize('0111234567'), '+251111234567');
    });

    test('regional 022 prefix', () {
      expect(n.normalize('0221234567'), '+251221234567');
    });

    test('regional 033 prefix', () {
      expect(n.normalize('0331234567'), '+251331234567');
    });

    test('regional 046 prefix', () {
      expect(n.normalize('0461234567'), '+251461234567');
    });
  });

  group('Formatting edge cases', () {
    test('leading/trailing whitespace', () {
      expect(n.normalize('  0911234567  '), '+251911234567');
    });

    test('number in parentheses format: (0911) 234567', () {
      expect(n.normalize('(0911) 234567'), '+251911234567');
    });

    test('number with multiple spaces between groups', () {
      expect(n.normalize('0911  234  567'), '+251911234567');
    });

    test('already-formatted E.164 is returned unchanged', () {
      expect(n.normalize('+251911234567'), '+251911234567');
    });

    test('number with a leading plus and spaces', () {
      expect(n.normalize('+251 9 11 23 45 67'), '+251911234567');
    });
  });

  group('Non-ET international numbers (pass-through)', () {
    test('US number +1', () {
      expect(n.normalize('+12125551234'), '+12125551234');
    });

    test('Kenya +254', () {
      expect(n.normalize('+254712345678'), '+254712345678');
    });

    test('UK +44', () {
      expect(n.normalize('+447911123456'), '+447911123456');
    });

    test('00 IDD non-ET passes through', () {
      expect(n.normalize('0012025551234'), '+12025551234');
    });
  });

  group('tryNormalize — graceful null on invalid input', () {
    test('empty string → null', () {
      expect(n.tryNormalize(''), isNull);
    });

    test('too short (3 digits) → null', () {
      expect(n.tryNormalize('123'), isNull);
    });

    test('letters only → null', () {
      expect(n.tryNormalize('abcdef'), isNull);
    });

    test('special chars only → null', () {
      expect(n.tryNormalize('---...'), isNull);
    });
  });

  group('normalize — throws on invalid input', () {
    test('empty string throws', () {
      expect(() => n.normalize(''), throwsA(isA<PhoneNormalizationException>()));
    });

    test('too short throws', () {
      expect(
        () => n.normalize('123'),
        throwsA(isA<PhoneNormalizationException>()),
      );
    });

    test('too long (>15 digits after +) throws', () {
      expect(
        () => n.normalize('+12345678901234567'),
        throwsA(isA<PhoneNormalizationException>()),
      );
    });
  });

  group('Different default region', () {
    test('KE region — 07x treated as Kenyan', () {
      const ke = PhoneNormalizer(defaultRegion: 'KE');
      expect(ke.normalize('0712345678'), '+254712345678');
    });

    test('US region — 10-digit number', () {
      const us = PhoneNormalizer(defaultRegion: 'US');
      expect(us.normalize('2125551234'), '+12125551234');
    });
  });
}
