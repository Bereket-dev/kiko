// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/core/utils/ethiopian_calendar.dart';
import 'package:kiko/features/security/pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EthiopianCalendar unit tests
// ─────────────────────────────────────────────────────────────────────────────
//
// Reference dates verified against the JDN algorithm implemented in
// EthiopianCalendar (epoch JDN 1724221 = Meskerem 1, 1 AM).
//
// Correct conversions (algorithm-verified):
//   GR 2024-04-18 == ET 10 Miyazya 2016  (non-leap year)
//   GR 2024-09-11 == ET 01 Meskerem 2017 (ET New Year 2017)
//   GR 2024-02-10 == ET 02 Yekatit 2016
//   GR 2016-09-11 == ET 01 Meskerem 2009 (ET New Year 2009)
//   GR 2000-01-01 == ET 22 Tahsas 1992
//   GR 1998-09-11 == ET 01 Meskerem 1991
//   ET 2016-08-10 == GR 2024-04-18
//   ET 2016-08-11 == GR 2024-04-19
//   ET 1992-04-23 == GR 2000-01-02
//   ET 2016-13-01 == GR 2024-09-06  (1st Pagume 2016)
//   ET 2016-13-05 == GR 2024-09-10  (last day of Pagume 2016)
//   ET 2015-13-06 == GR 2023-09-11  (Pagume 6, leap year 2015)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('EthiopianCalendar — fromGregorian', () {
    test('18 Apr 2024 (GR) → 10 Miyazya 2016 (ET)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(2024, 4, 18));
      expect(eth.year, 2016);
      expect(eth.month, 8); // Miyazya
      expect(eth.day, 10);
      expect(eth.monthNameEn, 'Miyazya');
    });

    test('11 Sep 2024 (GR) → 01 Meskerem 2017 (ET New Year)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(2024, 9, 11));
      expect(eth.year, 2017);
      expect(eth.month, 1);
      expect(eth.day, 1);
      expect(eth.monthNameEn, 'Meskerem');
    });

    test('10 Feb 2024 (GR) → 02 Yekatit 2016 (ET)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(2024, 2, 10));
      expect(eth.year, 2016);
      expect(eth.month, 6); // Yekatit
      expect(eth.day, 2);
    });

    test('11 Sep 2016 (GR) → 01 Meskerem 2009 (ET)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(2016, 9, 11));
      expect(eth.year, 2009);
      expect(eth.month, 1);
      expect(eth.day, 1);
    });

    test('01 Jan 2000 (GR) → 22 Tahsas 1992 (ET)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(2000, 1, 1));
      expect(eth.year, 1992);
      expect(eth.month, 4); // Tahsas
      expect(eth.day, 22);
    });

    test('11 Sep 1998 (GR) → 01 Meskerem 1991 (ET)', () {
      final eth = EthiopianCalendar.fromGregorian(DateTime(1998, 9, 11));
      expect(eth.year, 1991);
      expect(eth.month, 1);
      expect(eth.day, 1);
    });
  });

  group('EthiopianCalendar — toGregorian', () {
    test('10 Miyazya 2016 (ET) → 18 Apr 2024 (GR)', () {
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2016, 8, 10));
      expect(gr.year, 2024);
      expect(gr.month, 4);
      expect(gr.day, 18);
    });

    test('11 Miyazya 2016 (ET) → 19 Apr 2024 (GR)', () {
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2016, 8, 11));
      expect(gr.year, 2024);
      expect(gr.month, 4);
      expect(gr.day, 19);
    });

    test('01 Meskerem 2017 (ET) → 11 Sep 2024 (GR)', () {
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2017, 1, 1));
      expect(gr.year, 2024);
      expect(gr.month, 9);
      expect(gr.day, 11);
    });

    test('01 Meskerem 2009 (ET) → 11 Sep 2016 (GR)', () {
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2009, 1, 1));
      expect(gr.year, 2016);
      expect(gr.month, 9);
      expect(gr.day, 11);
    });

    test('23 Tahsas 1992 (ET) → 02 Jan 2000 (GR)', () {
      // ET 1992-04-23 → GR 2000-01-02 (algorithm-verified)
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(1992, 4, 23));
      expect(gr.year, 2000);
      expect(gr.month, 1);
      expect(gr.day, 2);
    });
  });

  group('EthiopianCalendar — round-trip', () {
    test('fromGregorian → toGregorian round-trips correctly', () {
      final testDates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 4, 18),
        DateTime(2024, 9, 11),
        DateTime(2023, 3, 15),
        DateTime(2000, 6, 20),
        DateTime(1990, 12, 31),
      ];
      for (final gr in testDates) {
        final eth = EthiopianCalendar.fromGregorian(gr);
        final backToGr = EthiopianCalendar.toGregorian(eth);
        expect(
          backToGr,
          DateTime.utc(gr.year, gr.month, gr.day),
          reason: 'Round-trip failed for ${gr.year}-${gr.month}-${gr.day}',
        );
      }
    });

    test('100 sequential days round-trip correctly', () {
      var base = DateTime(2024, 1, 1);
      for (var i = 0; i < 100; i++) {
        final date = base.add(Duration(days: i));
        final eth = EthiopianCalendar.fromGregorian(date);
        final back = EthiopianCalendar.toGregorian(eth);
        expect(
          back,
          DateTime.utc(date.year, date.month, date.day),
          reason: 'Day $i round-trip failed',
        );
      }
    });
  });

  group('EthiopianCalendar — leap years', () {
    // ET leap years: year % 4 == 3
    // 2015 % 4 == 3 → leap
    // 2019 % 4 == 3 → leap
    // 2016 % 4 == 0 → not leap

    test('2015 AM is a leap year', () {
      expect(EthiopianCalendar.isLeapYear(2015), isTrue);
    });

    test('2019 AM is a leap year', () {
      expect(EthiopianCalendar.isLeapYear(2019), isTrue);
    });

    test('2016 AM is not a leap year', () {
      expect(EthiopianCalendar.isLeapYear(2016), isFalse);
    });

    test('2017 AM is not a leap year', () {
      expect(EthiopianCalendar.isLeapYear(2017), isFalse);
    });

    test('Pagume has 6 days in leap year 2015', () {
      expect(EthiopianCalendar.daysInMonth(2015, 13), 6);
    });

    test('Pagume has 5 days in non-leap year 2016', () {
      expect(EthiopianCalendar.daysInMonth(2016, 13), 5);
    });

    test('Regular months always have 30 days', () {
      for (var m = 1; m <= 12; m++) {
        expect(EthiopianCalendar.daysInMonth(2016, m), 30,
            reason: 'Month $m should have 30 days');
      }
    });

    test('Leap year: 06 Pagume 2015 (ET) → valid Gregorian date', () {
      // 2015 ET is leap; Pagume 6 should exist
      // ET 2015-13-6 -> GR 2023-9-11
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2015, 13, 6));
      expect(gr.year, 2023);
      expect(gr.month, 9);
      expect(gr.day, 11);
      // And round-trip back
      final eth = EthiopianCalendar.fromGregorian(gr);
      expect(eth.year, 2015);
      expect(eth.month, 13);
      expect(eth.day, 6);
    });
  });

  group('EthiopianCalendar — Pagume edge cases', () {
    test('Last day of Pagume (non-leap) 2016 ET → day before ET New Year', () {
      // ET 2016-13-5 → GR 2024-09-10 (algorithm-verified)
      // The next Gregorian day (Sep 11) is ET New Year 2017.
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2016, 13, 5));
      expect(gr.year, 2024);
      expect(gr.month, 9);
      expect(gr.day, 10);
      // Next day should be 01 Meskerem 2017
      final nextDay = EthiopianCalendar.fromGregorian(
          gr.add(const Duration(days: 1)));
      expect(nextDay.year, 2017);
      expect(nextDay.month, 1);
      expect(nextDay.day, 1);
    });

    test('01 Pagume 2016 ET → 06 Sep 2024 GR', () {
      // ET 2016-13-1 → GR 2024-09-06 (algorithm-verified)
      final gr = EthiopianCalendar.toGregorian(EthiopianDate(2016, 13, 1));
      expect(gr.year, 2024);
      expect(gr.month, 9);
      expect(gr.day, 6);
    });
  });

  group('EthiopianCalendar — month names', () {
    test('Month 1 is Meskerem (Amharic)', () {
      expect(EthiopianCalendar.monthName(1), 'መስከረም');
    });

    test('Month 8 is Miyazya (English)', () {
      expect(EthiopianCalendar.monthNameEn(8), 'Miyazya');
    });

    test('Month 13 is Pagume (English)', () {
      expect(EthiopianCalendar.monthNameEn(13), 'Pagume');
    });

    test('All 13 month names are non-empty', () {
      for (var m = 1; m <= 13; m++) {
        expect(EthiopianCalendar.monthName(m), isNotEmpty);
        expect(EthiopianCalendar.monthNameEn(m), isNotEmpty);
      }
    });
  });

  group('EthiopianDate — toString and format', () {
    test('toString formats as yyyy-mm-dd with padding', () {
      expect(EthiopianDate(2016, 8, 10).toString(), '2016-08-10');
      expect(EthiopianDate(2016, 1, 1).toString(), '2016-01-01');
    });

    test('format with amharic=true uses Amharic month names', () {
      final eth = EthiopianDate(2016, 8, 10);
      expect(eth.format(amharic: true), '10 ሚያዝያ 2016');
    });

    test('format with amharic=false uses English month names', () {
      final eth = EthiopianDate(2016, 8, 10);
      expect(eth.format(amharic: false), '10 Miyazya 2016');
    });
  });

  group('EthiopianCalendar — formatGregorian', () {
    test('formatGregorian with amharic=false', () {
      // GR 18 Apr 2024 = ET 10 Miyazya 2016 (algorithm-verified)
      final result = EthiopianCalendar.formatGregorian(
        DateTime(2024, 4, 18),
        amharic: false,
      );
      expect(result, '10 Miyazya 2016');
    });

    test('formatBoth includes both calendars', () {
      final result = EthiopianCalendar.formatBoth(
        DateTime(2024, 4, 18),
        amharic: false,
      );
      expect(result, contains('Miyazya'));
      expect(result, contains('Apr'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // PIN lockout unit tests (pure logic, no Flutter / secure storage)
  // ─────────────────────────────────────────────────────────────────────────

  group('LockoutState', () {
    test('Initial state has no lockout', () {
      const state = LockoutState.none;
      expect(state.failureCount, 0);
      expect(state.lockedUntil, isNull);
      expect(state.isLockedOut, isFalse);
      expect(state.remainingLockout, Duration.zero);
    });

    test('No lockout after 4 failures', () {
      var state = LockoutState.none;
      for (var i = 0; i < 4; i++) {
        state = _applyFailure(state);
      }
      expect(state.failureCount, 4);
      expect(state.isLockedOut, isFalse);
    });

    test('30s lockout after 5 failures', () {
      var state = LockoutState.none;
      for (var i = 0; i < 5; i++) {
        state = _applyFailure(state);
      }
      expect(state.failureCount, 5);
      expect(state.isLockedOut, isTrue);
      expect(
        state.remainingLockout.inSeconds,
        greaterThanOrEqualTo(28), // allow minor timing delta
      );
      expect(state.remainingLockout.inSeconds, lessThanOrEqualTo(30));
    });

    test('1m lockout after 6 failures', () {
      var state = LockoutState.none;
      for (var i = 0; i < 6; i++) {
        state = _applyFailure(state);
      }
      expect(state.failureCount, 6);
      expect(state.isLockedOut, isTrue);
      expect(state.remainingLockout.inSeconds, greaterThanOrEqualTo(58));
      expect(state.remainingLockout.inSeconds, lessThanOrEqualTo(60));
    });

    test('5m lockout after 7+ failures', () {
      var state = LockoutState.none;
      for (var i = 0; i < 7; i++) {
        state = _applyFailure(state);
      }
      expect(state.failureCount, 7);
      expect(state.isLockedOut, isTrue);
      expect(state.remainingLockout.inSeconds, greaterThanOrEqualTo(298));
      expect(state.remainingLockout.inSeconds, lessThanOrEqualTo(300));
    });

    test('8+ failures still use 5m lockout', () {
      var state = LockoutState.none;
      for (var i = 0; i < 10; i++) {
        state = _applyFailure(state);
      }
      expect(state.failureCount, 10);
      expect(state.isLockedOut, isTrue);
      expect(state.remainingLockout.inSeconds, greaterThanOrEqualTo(295));
    });

    test('remainingLockout is zero when not locked', () {
      const state = LockoutState(failureCount: 3, lockedUntil: null);
      expect(state.remainingLockout, Duration.zero);
    });

    test('isLockedOut is false when lockedUntil is in the past', () {
      final state = LockoutState(
        failureCount: 5,
        lockedUntil: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(state.isLockedOut, isFalse);
      expect(state.remainingLockout, Duration.zero);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mirror of PinService._applyFailure for white-box testing
// (keeps test file self-contained without exposing internals)
// ─────────────────────────────────────────────────────────────────────────────

LockoutState _applyFailure(LockoutState current) {
  final failures = current.failureCount + 1;
  DateTime? newLockedUntil;

  if (failures >= 7) {
    newLockedUntil = DateTime.now().add(const Duration(minutes: 5));
  } else if (failures == 6) {
    newLockedUntil = DateTime.now().add(const Duration(minutes: 1));
  } else if (failures == 5) {
    newLockedUntil = DateTime.now().add(const Duration(seconds: 30));
  }

  return LockoutState(failureCount: failures, lockedUntil: newLockedUntil);
}
