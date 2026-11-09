import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import '../leads/status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CreateCallPlanScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Lets the user schedule a Call Plan session.
//
// Fields:
//   • Date + time picker  — when the alarm should fire
//   • Lead picker         — optionally choose specific leads (multi-select)
//   • Business-type filter — optionally filter to a business type
//   • Notes               — optional note shown in the notification
//
// Priority logic (per spec) is applied when the session fires in
// CallPlanScreen:
//   1. Chosen leads (if any were pinned here)
//   2. Business-type filter (if set)
//   3. Due-today leads (leads with a PENDING reminder due today)
//
// Usage:
//   context.push('/call-plan/new');
// ─────────────────────────────────────────────────────────────────────────────

class CreateCallPlanScreen extends ConsumerStatefulWidget {
  const CreateCallPlanScreen({super.key});

  @override
  ConsumerState<CreateCallPlanScreen> createState() =>
      _CreateCallPlanScreenState();
}

class _CreateCallPlanScreenState extends ConsumerState<CreateCallPlanScreen> {
  // ── State ─────────────────────────────────────────────────────────────────

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  /// Selected lead UUIDs to pin to this call plan.
  final Set<String> _selectedLeadIds = {};

  /// Currently set business-type filter (null = no filter).
  String? _filterBusinessType;

  final TextEditingController _notesCtrl = TextEditingController();
  bool _saving = false;

  // ── Init / dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: 0);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  bool get _isInFuture => _combinedDateTime.isAfter(DateTime.now());

  bool get _canSave => _isInFuture && !_saving;

  // ── Date / time pickers ───────────────────────────────────────────────────

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

  // ── Lead picker ───────────────────────────────────────────────────────────

  Future<void> _openLeadPicker() async {
    final leadsAsync = ref.read(watchLeadsProvider);
    final leads = leadsAsync.valueOrNull ?? [];

    if (leads.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leads found.')),
      );
      return;
    }

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _LeadPickerDialog(
        leads: leads,
        initialSelected: _selectedLeadIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLeadIds
          ..clear()
          ..addAll(result);
        // Choosing specific leads removes the business-type filter since they
        // have different priority. User can still add a filter afterward.
      });
    }
  }

  // ── Business-type picker ──────────────────────────────────────────────────

  Future<void> _openBusinessTypePicker() async {
    final typesAsync = await ref.read(businessTypesProvider.future);

    if (typesAsync.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No business types found.')),
      );
      return;
    }

    if (!mounted) return;
    final result = await showDialog<String?>(
      context: context,
      builder: (_) => _BusinessTypePickerDialog(
        types: typesAsync,
        initial: _filterBusinessType,
      ),
    );

    if (result != null) {
      // result == '' means "clear filter"
      setState(() {
        _filterBusinessType = result.isEmpty ? null : result;
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);

    try {
      final service = ref.read(callPlanServiceProvider);
      final triggerAtMs = _combinedDateTime.millisecondsSinceEpoch;
      final notes =
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

      await service.createAndSchedule(
        triggerAtMs: triggerAtMs,
        leadIds: _selectedLeadIds.toList(),
        filterBusinessType: _filterBusinessType,
        notes: notes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call plan scheduled.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(_selectedDate);
    final timeLabel = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Call Plan'),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Schedule'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── Date + Time ─────────────────────────────────────────────────
          _SectionHeader(title: 'When'),
          const SizedBox(height: 8),
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
          if (!_isInFuture) ...[
            const SizedBox(height: 4),
            Text(
              'Please choose a future date/time.',
              style: TextStyle(color: cs.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),

          // ── Lead selection ──────────────────────────────────────────────
          _SectionHeader(title: 'Leads (optional)'),
          const SizedBox(height: 4),
          Text(
            'Pin specific leads for this session. '
            'If none are chosen, leads are selected by filter or due-today logic.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.people_outline),
            label: Text(_selectedLeadIds.isEmpty
                ? 'Choose Leads'
                : '${_selectedLeadIds.length} lead${_selectedLeadIds.length == 1 ? '' : 's'} selected'),
            onPressed: _openLeadPicker,
          ),
          if (_selectedLeadIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            _SelectedLeadChips(
              selectedIds: _selectedLeadIds,
              onRemove: (id) => setState(() => _selectedLeadIds.remove(id)),
            ),
          ],
          const SizedBox(height: 20),

          // ── Business-type filter ────────────────────────────────────────
          _SectionHeader(title: 'Business-type filter (optional)'),
          const SizedBox(height: 4),
          Text(
            'Filter leads by business type. Applied only when no specific leads '
            'are chosen (or after them in priority).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list_outlined),
                  label: Text(_filterBusinessType ?? 'No filter'),
                  onPressed: _openBusinessTypePicker,
                ),
              ),
              if (_filterBusinessType != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.clear, color: cs.error),
                  tooltip: 'Remove filter',
                  onPressed: () =>
                      setState(() => _filterBusinessType = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ── Notes ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Notes (optional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              hintText: 'E.g. "Follow up on Q4 deals"',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes_outlined),
            ),
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // ── Save button ─────────────────────────────────────────────────
          FilledButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.alarm_add_outlined),
            label: const Text('Schedule Call Plan'),
            onPressed: _canSave ? _save : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SelectedLeadChips — compact chip row for chosen leads
// ─────────────────────────────────────────────────────────────────────────────

class _SelectedLeadChips extends ConsumerWidget {
  const _SelectedLeadChips({
    required this.selectedIds,
    required this.onRemove,
  });

  final Set<String> selectedIds;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(watchLeadsProvider);
    final allLeads = leadsAsync.valueOrNull ?? [];
    final selected =
        allLeads.where((l) => selectedIds.contains(l.id)).toList();

    if (selected.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: selected.map((lead) {
        return Chip(
          label: Text(lead.name, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => onRemove(lead.id),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LeadPickerDialog — multi-select checklist of all active leads
// ─────────────────────────────────────────────────────────────────────────────

class _LeadPickerDialog extends StatefulWidget {
  const _LeadPickerDialog({
    required this.leads,
    required this.initialSelected,
  });

  final List<Lead> leads;
  final Set<String> initialSelected;

  @override
  State<_LeadPickerDialog> createState() => _LeadPickerDialogState();
}

class _LeadPickerDialogState extends State<_LeadPickerDialog> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Leads'),
      contentPadding: const EdgeInsets.only(top: 8),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: ListView.builder(
          itemCount: widget.leads.length,
          itemBuilder: (_, i) {
            final lead = widget.leads[i];
            final checked = _selected.contains(lead.id);
            final status = LeadStatus.fromDb(lead.status);
            return CheckboxListTile(
              value: checked,
              secondary: StatusChip(status: status),
              title: Text(lead.name),
              subtitle: lead.businessType != null
                  ? Text(lead.businessType!,
                      style: Theme.of(context).textTheme.bodySmall)
                  : null,
              onChanged: (_) => setState(() {
                if (checked) {
                  _selected.remove(lead.id);
                } else {
                  _selected.add(lead.id);
                }
              }),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(_selected.isEmpty ? 'No leads' : 'Confirm'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BusinessTypePickerDialog — single-select list of existing business types
// ─────────────────────────────────────────────────────────────────────────────

class _BusinessTypePickerDialog extends StatelessWidget {
  const _BusinessTypePickerDialog({
    required this.types,
    required this.initial,
  });

  final List<String> types;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by business type'),
      contentPadding: const EdgeInsets.only(top: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "No filter" option
              ListTile(
                leading: Radio<String>(
                  value: '',
                  groupValue: initial ?? '',
                  onChanged: (_) => Navigator.pop(context, ''),
                ),
                title: const Text('No filter'),
                onTap: () => Navigator.pop(context, ''),
              ),
              const Divider(height: 1),
              ...types.map((t) {
                return ListTile(
                  leading: Radio<String>(
                    value: t,
                    groupValue: initial ?? '',
                    onChanged: (_) => Navigator.pop(context, t),
                  ),
                  title: Text(t),
                  onTap: () => Navigator.pop(context, t),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

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
