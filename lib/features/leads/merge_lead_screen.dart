import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import 'lead_draft.dart';
import 'status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MergeLeadScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Shown after the user picks "Review & merge" in DuplicateDetectionDialog.
//
// Route: /leads/merge?targetId=<uuid>  (extra args passed via GoRouter extra)
//
// Layout
//   ┌──────────────────────────────────────────┐
//   │  AppBar: Merge Lead  [Merge] action button│
//   ├──────────────────────────────────────────┤
//   │  Section: Name                           │
//   │    [Existing]  ←radio→  [Draft]          │
//   ├──────────────────────────────────────────┤
//   │  Section: Business Type                  │
//   │    [Existing]  ←radio→  [Draft]          │
//   ├──────────────────────────────────────────┤
//   │  Section: Status                         │
//   │    [Existing]  ←radio→  [Draft]          │
//   ├──────────────────────────────────────────┤
//   │  Section: Notes                          │
//   │    [Existing]  ←radio→  [Draft]          │
//   ├──────────────────────────────────────────┤
//   │  Section: Phones (union checkboxes)      │
//   │    [✓ +251...] existing                  │
//   │    [✓ +251...] draft (new)               │
//   ├──────────────────────────────────────────┤
//   │  Section: Sections (reorderable list)    │
//   │    kept = ✓; draggable handle            │
//   └──────────────────────────────────────────┘
//
// Quick-action bottom bar:
//   [Keep all existing]  [Take all from draft]  [Merge all]
// ─────────────────────────────────────────────────────────────────────────────

class MergeLeadScreen extends ConsumerStatefulWidget {
  const MergeLeadScreen({
    super.key,
    required this.targetLead,
    required this.existingPhones,
    required this.existingSections,
    required this.draft,
    required this.draftPhones,   // normalized e164 phones from the draft
    required this.draftSections,
  });

  final Lead targetLead;
  final List<LeadPhone> existingPhones;
  final List<LeadSection> existingSections;
  final LeadDraft draft;
  final List<({String e164, String? label, bool isPrimary})> draftPhones;
  final List<({String title, String body})> draftSections;

  @override
  ConsumerState<MergeLeadScreen> createState() => _MergeLeadScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _MergeLeadScreenState extends ConsumerState<MergeLeadScreen> {
  // ── Field pickers (true = use draft; false = keep existing) ──────────────
  bool _useDraftName = false;
  bool _useDraftBusinessType = false;
  bool _useDraftStatus = false;
  bool _useDraftNotes = false;

  // ── Phone union: Set of e164s the user wants to keep ─────────────────────
  late Set<String> _keepPhones;

  // ── Merged sections list (reorderable, each entry has a keep flag) ────────
  late List<_MergedSection> _mergedSections;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initPhones();
    _initSections();
  }

  void _initPhones() {
    // Start with all phones checked (union).
    final all = <String>{};
    for (final p in widget.existingPhones) {
      all.add(p.e164);
    }
    for (final p in widget.draftPhones) {
      all.add(p.e164);
    }
    _keepPhones = all;
  }

  void _initSections() {
    // Existing sections first, then draft-only sections appended.
    final sections = <_MergedSection>[];

    for (final s in widget.existingSections) {
      sections.add(_MergedSection(
        title: s.title,
        body: s.body,
        source: _SectionSource.existing,
        keep: true,
      ));
    }

    // Find draft sections that don't exactly match any existing one.
    for (final ds in widget.draftSections) {
      final isDuplicate = widget.existingSections.any(
        (es) =>
            es.title.trim().toLowerCase() == ds.title.trim().toLowerCase() &&
            es.body.trim() == ds.body.trim(),
      );
      if (!isDuplicate) {
        sections.add(_MergedSection(
          title: ds.title,
          body: ds.body,
          source: _SectionSource.draft,
          keep: true,
        ));
      }
    }

    _mergedSections = sections;
  }

  // ── Quick actions ─────────────────────────────────────────────────────────

  void _keepAllExisting() {
    setState(() {
      _useDraftName = false;
      _useDraftBusinessType = false;
      _useDraftStatus = false;
      _useDraftNotes = false;
      _keepPhones = widget.existingPhones.map((p) => p.e164).toSet();
      for (final s in _mergedSections) {
        s.keep = s.source == _SectionSource.existing;
      }
    });
  }

  void _takeAllFromDraft() {
    setState(() {
      _useDraftName = true;
      _useDraftBusinessType = true;
      _useDraftStatus = true;
      _useDraftNotes = true;
      _keepPhones = widget.draftPhones.map((p) => p.e164).toSet();
      for (final s in _mergedSections) {
        s.keep = s.source == _SectionSource.draft;
      }
    });
  }

  void _mergeAll() {
    setState(() {
      _useDraftName =
          widget.draft.name.trim().isNotEmpty;
      _useDraftBusinessType =
          (widget.draft.businessType?.trim().isNotEmpty ?? false);
      _useDraftStatus = true;
      _useDraftNotes =
          (widget.draft.notes?.trim().isNotEmpty ?? false);
      // Union all phones.
      final all = <String>{};
      for (final p in widget.existingPhones) {
        all.add(p.e164);
      }
      for (final p in widget.draftPhones) {
        all.add(p.e164);
      }
      _keepPhones = all;
      // Keep all sections.
      for (final s in _mergedSections) {
        s.keep = true;
      }
    });
  }

  // ── Build final merged data ───────────────────────────────────────────────

  List<({String e164, String? label, bool isPrimary})> _buildMergedPhones() {
    final result = <({String e164, String? label, bool isPrimary})>[];

    // Existing phones first (preserves order).
    for (final p in widget.existingPhones) {
      if (_keepPhones.contains(p.e164)) {
        result.add((
          e164: p.e164,
          label: p.label,
          isPrimary: p.isPrimary,
        ));
      }
    }

    // Draft-only phones appended.
    final existingE164s = widget.existingPhones.map((p) => p.e164).toSet();
    for (final p in widget.draftPhones) {
      if (!existingE164s.contains(p.e164) && _keepPhones.contains(p.e164)) {
        result.add(p);
      }
    }

    // Ensure exactly one primary.
    if (result.isNotEmpty && !result.any((p) => p.isPrimary)) {
      final first = result.first;
      result[0] = (e164: first.e164, label: first.label, isPrimary: true);
    }

    return result;
  }

  List<({String title, String body})> _buildMergedSections() {
    return _mergedSections
        .where((s) => s.keep)
        .map((s) => (title: s.title, body: s.body))
        .toList();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(leadsRepositoryProvider);
      final lookupService = ref.read(lookupIndexServiceProvider);
      final targetId = widget.targetLead.id;

      final name = _useDraftName
          ? widget.draft.name.trim()
          : null;
      final businessType = _useDraftBusinessType
          ? (widget.draft.businessType?.trim() ?? '')
          : null;
      final status = _useDraftStatus
          ? widget.draft.status.dbValue
          : null;
      final notes = _useDraftNotes
          ? (widget.draft.notes?.trim() ?? '')
          : null;

      final snapshot = await repo.mergeLead(
        targetLeadId: targetId,
        name: name,
        businessType: businessType,
        status: status,
        notes: notes,
        mergedPhones: _buildMergedPhones(),
        mergedSections: _buildMergedSections(),
      );

      // Upsert lookup index.
      final updatedLead = await repo.getLeadById(targetId);
      final updatedPhones = await repo.getPhonesForLead(targetId);
      if (updatedLead != null) {
        await lookupService.upsertLead(
            lead: updatedLead, phones: updatedPhones);
      }

      if (!mounted) return;

      // Pop back to list and show undo snackbar.
      context.go('/');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Leads merged'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await repo.undoMerge(snapshot);
              // Re-sync lookup.
              final restoredLead = await repo.getLeadById(targetId);
              final restoredPhones = await repo.getPhonesForLead(targetId);
              if (restoredLead != null) {
                await lookupService.upsertLead(
                    lead: restoredLead, phones: restoredPhones);
              }
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Merge failed: $e')),
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
    final existing = widget.targetLead;
    final draft = widget.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge Lead'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            FilledButton.icon(
              icon: const Icon(Icons.merge_type_rounded, size: 18),
              label: const Text('Merge'),
              onPressed: _save,
              style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Quick actions ────────────────────────────────────────────────
          _QuickActionsBar(
            onKeepExisting: _keepAllExisting,
            onTakeDraft: _takeAllFromDraft,
            onMergeAll: _mergeAll,
          ),
          const SizedBox(height: 16),

          // ── Column headers ───────────────────────────────────────────────
          _ColumnHeaders(theme: theme),
          const Divider(),

          // ── Name ─────────────────────────────────────────────────────────
          _FieldPickerRow(
            label: 'Name',
            existingValue: existing.name,
            draftValue: draft.name.trim().isEmpty ? null : draft.name.trim(),
            useDraft: _useDraftName,
            onChanged: (v) => setState(() => _useDraftName = v),
          ),

          // ── Business Type ─────────────────────────────────────────────────
          _FieldPickerRow(
            label: 'Business Type',
            existingValue:
                existing.businessType?.isEmpty ?? true
                    ? '—'
                    : existing.businessType!,
            draftValue:
                draft.businessType?.isEmpty ?? true
                    ? null
                    : draft.businessType,
            useDraft: _useDraftBusinessType,
            onChanged: (v) => setState(() => _useDraftBusinessType = v),
          ),

          // ── Status ────────────────────────────────────────────────────────
          _StatusPickerRow(
            existingStatus: LeadStatus.fromDb(existing.status),
            draftStatus: draft.status,
            useDraft: _useDraftStatus,
            onChanged: (v) => setState(() => _useDraftStatus = v),
          ),

          // ── Notes ─────────────────────────────────────────────────────────
          _FieldPickerRow(
            label: 'Notes',
            existingValue: existing.notes?.isEmpty ?? true ? '—' : existing.notes!,
            draftValue:
                draft.notes?.isEmpty ?? true ? null : draft.notes,
            useDraft: _useDraftNotes,
            maxLines: 3,
            onChanged: (v) => setState(() => _useDraftNotes = v),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // ── Phones ────────────────────────────────────────────────────────
          _PhoneUnionSection(
            existingPhones: widget.existingPhones,
            draftPhones: widget.draftPhones,
            keepPhones: _keepPhones,
            onToggle: (e164, keep) {
              setState(() {
                if (keep) {
                  _keepPhones.add(e164);
                } else {
                  _keepPhones.remove(e164);
                }
              });
            },
          ),

          const SizedBox(height: 16),
          const Divider(),

          // ── Sections ──────────────────────────────────────────────────────
          _SectionsMergePanel(
            sections: _mergedSections,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                final item = _mergedSections.removeAt(oldIndex);
                _mergedSections.insert(newIndex, item);
              });
            },
            onToggleKeep: (index, keep) {
              setState(() => _mergedSections[index].keep = keep);
            },
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickActionsBar
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsBar extends StatelessWidget {
  const _QuickActionsBar({
    required this.onKeepExisting,
    required this.onTakeDraft,
    required this.onMergeAll,
  });

  final VoidCallback onKeepExisting;
  final VoidCallback onTakeDraft;
  final VoidCallback onMergeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.history_outlined, size: 16),
          label: const Text('Keep existing'),
          onPressed: onKeepExisting,
          visualDensity: VisualDensity.compact,
        ),
        ActionChip(
          avatar: const Icon(Icons.edit_note_outlined, size: 16),
          label: const Text('Take from draft'),
          onPressed: onTakeDraft,
          visualDensity: VisualDensity.compact,
        ),
        ActionChip(
          avatar: Icon(Icons.merge_type_rounded,
              size: 16, color: theme.colorScheme.secondary),
          label: Text('Merge all',
              style: TextStyle(color: theme.colorScheme.secondary)),
          onPressed: onMergeAll,
          visualDensity: VisualDensity.compact,
          backgroundColor:
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ColumnHeaders
// ─────────────────────────────────────────────────────────────────────────────

class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 80),
          Expanded(
            child: Center(
              child: Text('Existing',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Center(
              child: Text('Draft',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FieldPickerRow — radio-toggle between existing and draft value
// ─────────────────────────────────────────────────────────────────────────────

class _FieldPickerRow extends StatelessWidget {
  const _FieldPickerRow({
    required this.label,
    required this.existingValue,
    required this.draftValue,
    required this.useDraft,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String? existingValue;
  final String? draftValue;
  final bool useDraft;
  final ValueChanged<bool> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label column
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),

          // Existing value
          Expanded(
            child: _ValueCell(
              value: existingValue ?? '—',
              isSelected: !useDraft,
              onTap: () => onChanged(false),
              selectedColor: cs.primaryContainer,
              selectedBorderColor: cs.primary,
              maxLines: maxLines,
            ),
          ),

          // Radio toggle
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => onChanged(!useDraft),
                  child: Icon(
                    useDraft
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),

          // Draft value
          Expanded(
            child: _ValueCell(
              value: draftValue ?? '—',
              isSelected: useDraft,
              isDisabled: draftValue == null,
              onTap: draftValue != null ? () => onChanged(true) : null,
              selectedColor: cs.secondaryContainer,
              selectedBorderColor: cs.secondary,
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusPickerRow — same layout but renders StatusChip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPickerRow extends StatelessWidget {
  const _StatusPickerRow({
    required this.existingStatus,
    required this.draftStatus,
    required this.useDraft,
    required this.onChanged,
  });

  final LeadStatus existingStatus;
  final LeadStatus draftStatus;
  final bool useDraft;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget wrap(LeadStatus s, bool selected, bool isDraft) {
      return GestureDetector(
        onTap: () => onChanged(isDraft),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? (isDraft ? cs.secondaryContainer : cs.primaryContainer)
                    .withValues(alpha: 0.6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? (isDraft ? cs.secondary : cs.primary)
                  : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [StatusChip(status: s)],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Status',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ),
          Expanded(child: wrap(existingStatus, !useDraft, false)),
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => onChanged(!useDraft),
                  child: Icon(
                    useDraft
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: wrap(draftStatus, useDraft, true)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ValueCell
// ─────────────────────────────────────────────────────────────────────────────

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.value,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBorderColor,
    this.isDisabled = false,
    this.onTap,
    this.maxLines = 1,
  });

  final String value;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color selectedBorderColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDisabled
              ? cs.surfaceContainerLowest
              : isSelected
                  ? selectedColor.withValues(alpha: 0.6)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled
                ? cs.outlineVariant.withValues(alpha: 0.3)
                : isSelected
                    ? selectedBorderColor
                    : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDisabled
                ? cs.onSurface.withValues(alpha: 0.35)
                : cs.onSurface,
            fontStyle: isDisabled ? FontStyle.italic : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhoneUnionSection
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneUnionSection extends StatelessWidget {
  const _PhoneUnionSection({
    required this.existingPhones,
    required this.draftPhones,
    required this.keepPhones,
    required this.onToggle,
  });

  final List<LeadPhone> existingPhones;
  final List<({String e164, String? label, bool isPrimary})> draftPhones;
  final Set<String> keepPhones;
  final void Function(String e164, bool keep) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingE164s = existingPhones.map((p) => p.e164).toSet();

    final allPhones = <({String e164, String? label, bool isExisting})>[];
    for (final p in existingPhones) {
      allPhones.add((e164: p.e164, label: p.label, isExisting: true));
    }
    for (final p in draftPhones) {
      if (!existingE164s.contains(p.e164)) {
        allPhones.add((e164: p.e164, label: p.label, isExisting: false));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phones',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Check phones to include in the merged lead.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...allPhones.map((p) {
          final isKept = keepPhones.contains(p.e164);
          return CheckboxListTile(
            dense: true,
            value: isKept,
            onChanged: (v) => onToggle(p.e164, v ?? false),
            title: Row(
              children: [
                Expanded(
                  child: Text(p.e164,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          decoration:
                              isKept ? null : TextDecoration.lineThrough)),
                ),
                if (p.label != null) ...[
                  const SizedBox(width: 4),
                  Chip(
                    label: Text(p.label!),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              p.isExisting ? 'Existing' : 'From draft',
              style: theme.textTheme.labelSmall?.copyWith(
                color: p.isExisting
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
            ),
            secondary: Icon(
              p.isExisting
                  ? Icons.history_outlined
                  : Icons.edit_note_outlined,
              size: 18,
              color: p.isExisting
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
          );
        }),
        if (allPhones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No phones.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionsMergePanel — reorderable list with keep toggles
// ─────────────────────────────────────────────────────────────────────────────

class _SectionsMergePanel extends StatelessWidget {
  const _SectionsMergePanel({
    required this.sections,
    required this.onReorder,
    required this.onToggleKeep,
  });

  final List<_MergedSection> sections;
  final ReorderCallback onReorder;
  final void Function(int index, bool keep) onToggleKeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sections',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Toggle to include/exclude. Drag to reorder.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        if (sections.isEmpty)
          Text('No sections.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline))
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sections.length,
            onReorderItem: (oldIndex, newIndex) => onReorder(oldIndex, newIndex),
            proxyDecorator: (child, index, animation) => Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
            itemBuilder: (context, index) {
              final s = sections[index];
              return _SectionMergeTile(
                key: ValueKey(s.stableKey),
                section: s,
                onToggle: (v) => onToggleKeep(index, v),
              );
            },
          ),
      ],
    );
  }
}

class _SectionMergeTile extends StatelessWidget {
  const _SectionMergeTile({
    super.key,
    required this.section,
    required this.onToggle,
  });

  final _MergedSection section;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final sourceColor = section.source == _SectionSource.existing
        ? cs.primary
        : cs.secondary;
    final sourceLabel = section.source == _SectionSource.existing
        ? 'Existing'
        : 'From draft';

    return Opacity(
      opacity: section.keep ? 1.0 : 0.45,
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          leading: const Icon(Icons.drag_handle),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title.isEmpty ? '(untitled)' : section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  decoration: section.keep ? null : TextDecoration.lineThrough,
                ),
              ),
              if (section.body.isNotEmpty)
                Text(
                  section.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    decoration:
                        section.keep ? null : TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sourceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sourceLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: sourceColor,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Checkbox(
                value: section.keep,
                onChanged: (v) => onToggle(v ?? true),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting data classes
// ─────────────────────────────────────────────────────────────────────────────

enum _SectionSource { existing, draft }

class _MergedSection {
  _MergedSection({
    required this.title,
    required this.body,
    required this.source,
    required this.keep,
  }) : stableKey = UniqueKey().toString();

  final String stableKey;
  final String title;
  final String body;
  final _SectionSource source;
  bool keep;
}
