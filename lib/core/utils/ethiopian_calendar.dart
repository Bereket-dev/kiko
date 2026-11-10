// ─────────────────────────────────────────────────────────────────────────────
// EthiopianCalendar — Pure-Dart Ethiopian (Ge'ez / Ethio-Solar) calendar
// ─────────────────────────────────────────────────────────────────────────────
//
// The Ethiopian calendar has:
//   • 12 ordinary months of 30 days each.
//   • 1 intercalary month (Pagume) of 5 days (6 in a leap year).
//   • A solar year of 365.25 days, so leap years fall when (year % 4 == 3).
//
// Conversion algorithm:
//   The standard Meeus/JDN approach adapted for the Ge'ez epoch.
//   Ethiopian epoch JDN 1724221 = Meskerem 1, 1 AM
//                               = 29 Aug 8 CE (proleptic Julian).
//
// References:
//   • Dershowitz & Reingold, "Calendrical Calculations", Chapter 5.
//   • Multiple open-source Ethiopic calendar implementations (MIT-licensed).
//
// ─────────────────────────────────────────────────────────────────────────────

class EthiopianDate {
  const EthiopianDate(this.year, this.month, this.day);

  /// Ethiopian year (e.g. 2016, 2017 AM)
  final int year;

  /// Month number 1–13 (13 = Pagume)
  final int month;

  /// Day-of-month 1–30 (1–5 or 1–6 for month 13)
  final int day;

  /// Month name in Ge'ez/Amharic script.
  String get monthName => EthiopianCalendar.monthName(month);

  /// Month name in English transliteration.
  String get monthNameEn => EthiopianCalendar.monthNameEn(month);

  /// Human-readable string — e.g. "10 ሚያዝያ 2016" or "10 Miyazya 2016"
  String format({bool amharic = true}) {
    final m = amharic ? monthName : monthNameEn;
    return '$day $m $year';
  }

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is EthiopianDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

// ─────────────────────────────────────────────────────────────────────────────
// EthiopianCalendar
// ─────────────────────────────────────────────────────────────────────────────

class EthiopianCalendar {
  EthiopianCalendar._();

  // ── Ethiopian epoch ───────────────────────────────────────────────────────

  /// JDN of the Ethiopian epoch (Meskerem 1, 1 AM).
  static const int _etEpoch = 1724221;

  // ── Month names ───────────────────────────────────────────────────────────

  static const List<String> _monthNamesAm = [
    'መስከረም', //  1 Meskerem  — Sep/Oct
    'ጥቅምት',  //  2 Tikmt     — Oct/Nov
    'ህዳር',    //  3 Hidar     — Nov/Dec
    'ታህሳስ',  //  4 Tahsas    — Dec/Jan
    'ጥር',     //  5 Tir       — Jan/Feb
    'የካቲት',  //  6 Yekatit   — Feb/Mar
    'መጋቢት',  //  7 Megabit   — Mar/Apr
    'ሚያዝያ',  //  8 Miyazya   — Apr/May
    'ግንቦት',  //  9 Ginbot    — May/Jun
    'ሰኔ',     // 10 Sene      — Jun/Jul
    'ሐምሌ',   // 11 Hamle     — Jul/Aug
    'ነሐሴ',   // 12 Nehase    — Aug/Sep
    'ጳጉሜ',   // 13 Pagume    — Sep (5 or 6 days)
  ];

  static const List<String> _monthNamesEn = [
    'Meskerem',
    'Tikmt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miyazya',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  // ── Month name helpers ────────────────────────────────────────────────────

  /// Amharic month name for [month] (1-indexed, 1–13).
  static String monthName(int month) {
    assert(month >= 1 && month <= 13, 'Month must be 1–13, got $month');
    return _monthNamesAm[month - 1];
  }

  /// English month name for [month] (1-indexed, 1–13).
  static String monthNameEn(int month) {
    assert(month >= 1 && month <= 13, 'Month must be 1–13, got $month');
    return _monthNamesEn[month - 1];
  }

  // ── Leap year & month length ──────────────────────────────────────────────

  /// Returns true if [year] (Ethiopian) is a leap year.
  ///
  /// Ethiopian leap years occur when (year mod 4 == 3).
  /// Examples: 2015, 2019, 2023 AM are leap years.
  static bool isLeapYear(int year) => year % 4 == 3;

  /// Number of days in [month] for the given [year].
  ///
  /// Months 1–12: always 30 days.
  /// Month 13 (Pagume): 5 days in a regular year, 6 in a leap year.
  static int daysInMonth(int year, int month) {
    assert(month >= 1 && month <= 13);
    if (month < 13) return 30;
    return isLeapYear(year) ? 6 : 5;
  }

  // ── JDN ↔ Ethiopian ───────────────────────────────────────────────────────

  /// Ethiopian date → Julian Day Number.
  ///
  /// Uses `year ~/ 4` leap-day accumulation so that leap years (year % 4 == 3)
  /// place Pagume 6 immediately before the next Meskerem 1.
  static int ethiopianToJdn(int year, int month, int day) {
    return _etEpoch +
        365 * (year - 1) +
        year ~/ 4 +
        30 * (month - 1) +
        day -
        1;
  }

  /// Julian Day Number → [EthiopianDate].
  ///
  /// A 4-year cycle is 1461 days laid out as 365 + 365 + 366 + 365, because
  /// Ethiopian leap years fall when (year % 4 == 3) — i.e. year-in-cycle index 2.
  static EthiopianDate jdnToEthiopian(int jdn) {
    final offset = jdn - _etEpoch;
    final cycles = offset ~/ 1461;
    var rem = offset % 1461;
    if (rem < 0) rem += 1461;

    late final int yearInCycle;
    late final int dayInYear;
    if (rem < 365) {
      yearInCycle = 0;
      dayInYear = rem;
    } else if (rem < 730) {
      yearInCycle = 1;
      dayInYear = rem - 365;
    } else if (rem < 1096) {
      // Leap year (year % 4 == 3): 366 days
      yearInCycle = 2;
      dayInYear = rem - 730;
    } else {
      yearInCycle = 3;
      dayInYear = rem - 1096;
    }

    final year = 4 * cycles + yearInCycle + 1;
    final month = dayInYear ~/ 30 + 1;
    final day = dayInYear % 30 + 1;
    return EthiopianDate(year, month, day);
  }

  // ── JDN ↔ Gregorian (proleptic) ───────────────────────────────────────────

  /// Gregorian date → Julian Day Number (Algorithm by Henry F. Fliegel).
  static int gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Julian Day Number → Gregorian [DateTime] (UTC midnight).
  static DateTime jdnToGregorian(int jdn) {
    // Algorithm by Henry F. Fliegel (inverse of gregorianToJdn).
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime.utc(year, month, day);
  }

  // ── Gregorian ↔ Ethiopian ─────────────────────────────────────────────────

  /// Converts a Gregorian [DateTime] to an [EthiopianDate].
  /// Only the date portion is used; time is ignored.
  static EthiopianDate fromGregorian(DateTime gregorian) {
    final jdn = gregorianToJdn(gregorian.year, gregorian.month, gregorian.day);
    return jdnToEthiopian(jdn);
  }

  /// Converts an [EthiopianDate] to a Gregorian [DateTime] (UTC midnight).
  static DateTime toGregorian(EthiopianDate eth) {
    final jdn = ethiopianToJdn(eth.year, eth.month, eth.day);
    return jdnToGregorian(jdn);
  }

  /// Converts Ethiopian year/month/day to a Gregorian [DateTime] (UTC midnight).
  static DateTime ethiopianToGregorian(int year, int month, int day) =>
      toGregorian(EthiopianDate(year, month, day));

  // ── Convenience ───────────────────────────────────────────────────────────

  /// Returns today's date as an [EthiopianDate].
  static EthiopianDate today() => fromGregorian(DateTime.now());

  /// Format a Gregorian [DateTime] as an Ethiopian date string.
  ///
  /// [amharic] — use Amharic month names when true (default).
  /// Example: "10 ሚያዝያ 2016" or "10 Miyazya 2016"
  static String formatGregorian(DateTime gregorian, {bool amharic = true}) =>
      fromGregorian(gregorian).format(amharic: amharic);

  /// Format a Gregorian [DateTime] showing both calendars.
  ///
  /// Example: "10 ሚያዝያ 2016 (18 Apr 2024)"
  static String formatBoth(DateTime gregorian, {bool amharic = true}) {
    final eth = fromGregorian(gregorian);
    final grFmt = '${gregorian.day} ${_grMonthEn[gregorian.month - 1]} ${gregorian.year}';
    return '${eth.format(amharic: amharic)} ($grFmt)';
  }

  static const List<String> _grMonthEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
