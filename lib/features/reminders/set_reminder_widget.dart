import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SetReminderWidget
// ─────────────────────────────────────────────────────────────────────────────
//
// Modal bottom sheet that lets the user set (or edit) a one-time reminder for
// a lead.
//
// Usage — show from a LeadDetailScreen action button:
//
//   showSetReminderSheet(
//     context: context,
//     ref: ref,
//     leadId: lead.id,
//     leadName: lead.name,
//     existing: currentReminder,   // null → new reminder
//   );
//
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showSetReminderSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String leadId,
  required String leadName,
  Reminder? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: _SetReminderSheet(
        leadId:   leadId,
        leadName: leadName,
        existing: existing,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _SetReminderSheet
// ─────────────────────────────────────────────────────────────────────────────

class _SetReminderSheet extends ConsumerStatefulWidget {
  const _SetReminderSheet({
    required this.leadId,
    required this.leadName,
    this.existing,
  });

  final String leadId;
  final String leadName;
  final Reminder? existing;

  @override
  ConsumerState<_SetReminderSheet> createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends ConsumerState<_SetReminderSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _notesCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.existing != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.existing!.dueAt)
        : DateTime.now().add(const Duration(hours: 1));

    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay.fromDateTime(initial);
    _notesCtrl =
        TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  bool get _isInFuture => _combinedDateTime.isAfter(DateTime.now());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_isInFuture || _saving) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(reminderServiceProvider);
      final dueAtMs = _combinedDateTime.millisecondsSinceEpoch;
      final notes   = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      if (widget.existing != null) {
        await service.reschedule(
          reminderId: widget.existing!.id,
          newDueAtMs: dueAtMs,
          leadName:   widget.leadName,
          notes:      notes,
        );
      } else {
        await service.createAndSchedule(
          leadId:   widget.leadId,
          leadName: widget.leadName,
          dueAtMs:  dueAtMs,
          notes:    notes,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (widget.existing == null || _saving) return;
    setState(() => _saving = true);

    try {
      await ref
          .read(reminderServiceProvider)
          .cancel(widget.existing!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cs     = theme.colorScheme;
    final media  = MediaQuery.of(context);

    final dateLabel = MaterialLocalizations.of(context)
        .formatMediumDate(_selectedDate);
    final timeLabel = _selectedTime.format(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: media.viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing != null ? 'Edit Reminder' : 'Set Reminder',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (widget.existing != null)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  tooltip: 'Remove reminder',
                  onPressed: _saving ? null : _delete,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.leadName,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),

          // ── Date + Time row ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: dateLabel,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerTile(
                  icon: Icons.access_time_outlined,
                  label: 'Time',
                  value: timeLabel,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Notes field ───────────────────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'What do you want to remember?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),

          // ── Validation hint ───────────────────────────────────────────────
          if (!_isInFuture)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Please choose a future date/time.',
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),

          // ── Save button ───────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.alarm_add_outlined),
              label: Text(widget.existing != null
                  ? 'Update Reminder'
                  : 'Set Reminder'),
              onPressed: (_isInFuture && !_saving) ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PickerTile
// ─────────────────────────────────────────────────────────────────────────────

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  Text(value,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
