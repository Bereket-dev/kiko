import 'package:intl/intl.dart';

import 'ethiopian_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DateDisplay — formats dates according to the calendar display setting
// ─────────────────────────────────────────────────────────────────────────────
//
// Modes (AppSettings.calendarDisplayMode):
//   "ET"   — Ethiopian only (default)
//   "GR"   — Gregorian only
//   "BOTH" — Ethiopian with Gregorian in parentheses
//
// ─────────────────────────────────────────────────────────────────────────────

class DateDisplay {
  DateDisplay._();

  static final _grMedium = DateFormat('d MMM yyyy');
  static final _grShort = DateFormat('d/M/yyyy');

  /// Format a [DateTime] using [mode] ("ET" | "GR" | "BOTH").
  ///
  /// [amharic] controls Ethiopian month-name script (true = Amharic).
  static String format(
    DateTime date, {
    required String mode,
    bool amharic = true,
  }) {
    switch (mode) {
      case 'GR':
        return _grMedium.format(date);
      case 'BOTH':
        return EthiopianCalendar.formatBoth(date, amharic: amharic);
      case 'ET':
      default:
        return EthiopianCalendar.formatGregorian(date, amharic: amharic);
    }
  }

  /// Format an epoch-ms timestamp.
  static String formatMs(
    int ms, {
    required String mode,
    bool amharic = true,
  }) =>
      format(
        DateTime.fromMillisecondsSinceEpoch(ms),
        mode: mode,
        amharic: amharic,
      );

  /// Compact Gregorian fallback (e.g. list rows).
  static String formatShortGregorian(DateTime date) => _grShort.format(date);
}
