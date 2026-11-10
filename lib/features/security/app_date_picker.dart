import 'package:flutter/material.dart';

import '../../core/utils/ethiopian_calendar.dart';
import 'ethiopian_date_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// showAppDatePicker
// ─────────────────────────────────────────────────────────────────────────────
//
// Picks a Gregorian [DateTime] (date portion only) using either the Ethiopian
// calendar dialog or the Material Gregorian picker, based on [calendarMode].
//
// Modes:
//   "ET" / "BOTH" → Ethiopian picker (returns converted Gregorian DateTime)
//   "GR"          → Material showDatePicker
//
// ─────────────────────────────────────────────────────────────────────────────

Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String calendarMode = 'ET',
}) async {
  if (calendarMode == 'GR') {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  final ethInitial = EthiopianCalendar.fromGregorian(initialDate);
  final ethFirst = EthiopianCalendar.fromGregorian(firstDate);
  final ethLast = EthiopianCalendar.fromGregorian(lastDate);

  final picked = await showEthiopianDatePickerDialog(
    context: context,
    initialDate: ethInitial,
    firstDate: ethFirst,
    lastDate: ethLast,
    showGregorianEquivalent: calendarMode == 'BOTH' || calendarMode == 'ET',
  );

  if (picked == null) return null;
  final gr = EthiopianCalendar.toGregorian(picked);
  // Preserve local calendar date (not UTC) for reminder scheduling.
  return DateTime(gr.year, gr.month, gr.day);
}
