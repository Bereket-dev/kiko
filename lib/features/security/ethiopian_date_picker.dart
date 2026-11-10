import 'package:flutter/material.dart';

import '../../core/utils/ethiopian_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EthiopianDatePicker
// ─────────────────────────────────────────────────────────────────────────────
//
// A modal date-picker dialog that lets the user navigate and select a date
// using the Ethiopian calendar.
//
// Usage:
//   final date = await showEthiopianDatePickerDialog(
//     context: context,
//     initialDate: EthiopianCalendar.today(),
//   );
//   if (date != null) { /* use date */ }
//
// Returns the selected [EthiopianDate], or null if the dialog was dismissed.
// ─────────────────────────────────────────────────────────────────────────────

Future<EthiopianDate?> showEthiopianDatePickerDialog({
  required BuildContext context,
  EthiopianDate? initialDate,
  EthiopianDate? firstDate,
  EthiopianDate? lastDate,
  bool showGregorianEquivalent = true,
}) {
  return showDialog<EthiopianDate>(
    context: context,
    builder: (_) => EthiopianDatePickerDialog(
      initialDate: initialDate ?? EthiopianCalendar.today(),
      firstDate: firstDate,
      lastDate: lastDate,
      showGregorianEquivalent: showGregorianEquivalent,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EthiopianDatePickerDialog
// ─────────────────────────────────────────────────────────────────────────────

class EthiopianDatePickerDialog extends StatefulWidget {
  const EthiopianDatePickerDialog({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
    this.showGregorianEquivalent = true,
  });

  final EthiopianDate initialDate;
  final EthiopianDate? firstDate;
  final EthiopianDate? lastDate;
  final bool showGregorianEquivalent;

  @override
  State<EthiopianDatePickerDialog> createState() =>
      _EthiopianDatePickerDialogState();
}

class _EthiopianDatePickerDialogState
    extends State<EthiopianDatePickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
  }

  EthiopianDate get _selected => EthiopianDate(_year, _month, _day);

  int get _daysInCurrentMonth =>
      EthiopianCalendar.daysInMonth(_year, _month);

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _month = 13;
        _year--;
      } else {
        _month--;
      }
      _clampDay();
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 13) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
      _clampDay();
    });
  }

  void _clampDay() {
    final maxDay = EthiopianCalendar.daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
  }

  bool _isDisabled(EthiopianDate date) {
    if (widget.firstDate != null) {
      final first = widget.firstDate!;
      if (date.year < first.year) { return true; }
      if (date.year == first.year && date.month < first.month) { return true; }
      if (date.year == first.year &&
          date.month == first.month &&
          date.day < first.day) { return true; }
    }
    if (widget.lastDate != null) {
      final last = widget.lastDate!;
      if (date.year > last.year) { return true; }
      if (date.year == last.year && date.month > last.month) { return true; }
      if (date.year == last.year &&
          date.month == last.month &&
          date.day > last.day) { return true; }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final today = EthiopianCalendar.today();
    final grEquiv = EthiopianCalendar.toGregorian(_selected);
    final grText =
        '${grEquiv.day} ${_grMonthEn[grEquiv.month - 1]} ${grEquiv.year}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select date',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: cs.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  _selected.format(amharic: true),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showGregorianEquivalent) ...[
                  const SizedBox(height: 2),
                  Text(
                    grText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Month/Year navigation ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: _prevMonth,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: _pickYearMonth,
                      child: Text(
                        '${EthiopianCalendar.monthName(_month)} $_year',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),

          // ── Day grid ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _DayGrid(
              daysInMonth: _daysInCurrentMonth,
              selectedDay: _day,
              todayDay: (today.year == _year && today.month == _month)
                  ? today.day
                  : null,
              isDisabled: (d) =>
                  _isDisabled(EthiopianDate(_year, _month, d)),
              onDaySelected: (d) => setState(() => _day = d),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Actions ───────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickYearMonth() async {
    // Allow picking year via a simple spinner dialog.
    final pickedYear = await showDialog<int>(
      context: context,
      builder: (_) => _YearPickerDialog(initialYear: _year),
    );
    if (pickedYear != null && mounted) {
      setState(() {
        _year = pickedYear;
        _clampDay();
      });
    }
  }

  static const List<String> _grMonthEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// _DayGrid — renders a grid of numbered day buttons
// ─────────────────────────────────────────────────────────────────────────────

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.daysInMonth,
    required this.selectedDay,
    required this.todayDay,
    required this.isDisabled,
    required this.onDaySelected,
  });

  final int daysInMonth;
  final int selectedDay;
  final int? todayDay;
  final bool Function(int day) isDisabled;
  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth,
      itemBuilder: (_, i) {
        final day = i + 1;
        final isSelected = day == selectedDay;
        final isToday = day == todayDay;
        final disabled = isDisabled(day);

        Color? bg;
        Color fg;
        Border? border;

        if (isSelected) {
          bg = cs.primary;
          fg = cs.onPrimary;
        } else if (isToday) {
          bg = cs.primaryContainer;
          fg = cs.onPrimaryContainer;
          border = Border.all(color: cs.primary, width: 1.5);
        } else {
          bg = null;
          fg = disabled ? cs.onSurface.withValues(alpha: 0.38) : cs.onSurface;
        }

        return GestureDetector(
          onTap: disabled ? null : () => onDaySelected(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _YearPickerDialog — a simple year picker
// ─────────────────────────────────────────────────────────────────────────────

class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog({required this.initialYear});
  final int initialYear;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _year;
  late final ScrollController _scrollController;

  static const int _startYear = 1990;
  static const int _endYear = 2100;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    // Scroll to initial year
    final offset = (_year - _startYear) * 48.0;
    _scrollController = ScrollController(
      initialScrollOffset: (offset - 96).clamp(0.0, double.infinity),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      title: const Text('Select year'),
      content: SizedBox(
        width: 200,
        height: 300,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _endYear - _startYear + 1,
          itemExtent: 48,
          itemBuilder: (_, i) {
            final y = _startYear + i;
            final selected = y == _year;
            return InkWell(
              onTap: () => setState(() => _year = y),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? cs.primaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$y',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: selected ? cs.onPrimaryContainer : null,
                    fontWeight:
                        selected ? FontWeight.bold : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_year),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
