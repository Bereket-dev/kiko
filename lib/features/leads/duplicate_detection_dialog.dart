import 'package:flutter/material.dart';

import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import 'lead_draft.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DuplicateAction — what the user chose
// ─────────────────────────────────────────────────────────────────────────────

enum DuplicateAction {
  /// Open MergeLeadScreen and let the user reconcile fields.
  reviewAndMerge,

  /// Keep the existing lead untouched; discard the draft.
  keepExisting,

  /// Save the draft as a brand-new lead (only valid when the conflicting
  /// phones have been removed from the draft first — callers must verify).
  saveAsSeparate,

  /// Do nothing; return to the editor.
  cancel,
}

// ─────────────────────────────────────────────────────────────────────────────
// DuplicateDetectionResult
// ─────────────────────────────────────────────────────────────────────────────

class DuplicateDetectionResult {
  const DuplicateDetectionResult({
    required this.action,
    this.chosenTargetLeadId,
  });

  final DuplicateAction action;

  /// Set when [action] == [DuplicateAction.reviewAndMerge] and the user
  /// selected a specific target lead to merge into.
  final String? chosenTargetLeadId;
}

// ─────────────────────────────────────────────────────────────────────────────
// DuplicateDetectionDialog
// ─────────────────────────────────────────────────────────────────────────────
//
// Shown when at least one phone in the draft matches an existing lead.
// Presents a list of conflicting leads so the user can choose how to proceed.
//
// Usage:
//   final result = await DuplicateDetectionDialog.show(
//     context,
//     draft: draft,
//     duplicates: duplicateLeads,
//   );
// ─────────────────────────────────────────────────────────────────────────────

class DuplicateDetectionDialog extends StatefulWidget {
  const DuplicateDetectionDialog({
    super.key,
    required this.draft,
    required this.duplicates,
    required this.canSaveAsSeparate,
  });

  /// The draft being saved.
  final LeadDraft draft;

  /// Existing leads that share at least one phone with the draft.
  final List<Lead> duplicates;

  /// True when all conflicting phones have been removed from the draft,
  /// so "Save as separate" is a valid option.
  final bool canSaveAsSeparate;

  /// Shows the dialog and returns the user's choice (never null — Cancel is
  /// returned if the dialog is dismissed by tapping outside).
  static Future<DuplicateDetectionResult> show(
    BuildContext context, {
    required LeadDraft draft,
    required List<Lead> duplicates,
    required bool canSaveAsSeparate,
  }) async {
    final result = await showDialog<DuplicateDetectionResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DuplicateDetectionDialog(
        draft: draft,
        duplicates: duplicates,
        canSaveAsSeparate: canSaveAsSeparate,
      ),
    );
    return result ??
        const DuplicateDetectionResult(action: DuplicateAction.cancel);
  }

  @override
  State<DuplicateDetectionDialog> createState() =>
      _DuplicateDetectionDialogState();
}

class _DuplicateDetectionDialogState extends State<DuplicateDetectionDialog> {
  /// When there are multiple duplicates the user picks one to merge into.
  int _selectedIndex = 0;

  Lead get _selectedLead => widget.duplicates[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(Icons.merge_type_rounded, color: colorScheme.secondary),
      title: const Text('Duplicate phone detected'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.duplicates.length == 1
                    ? 'A lead with the same phone number already exists.'
                    : '${widget.duplicates.length} leads share the same phone number.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Conflicting-lead list (radio when >1)
              if (widget.duplicates.length == 1)
                _LeadCard(lead: widget.duplicates.first._asSummary, theme: theme)
              else ...[
                Text('Select which lead to merge into:',
                    style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                ...widget.duplicates.asMap().entries.map((e) {
                  final i = e.key;
                  final lead = e.value;
                  return RadioListTile<int>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: i,
                    groupValue: _selectedIndex,
                    onChanged: (v) => setState(() => _selectedIndex = v!),
                    title: Text(lead.name,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: lead.businessType != null
                        ? Text(lead.businessType!,
                            style: theme.textTheme.bodySmall)
                        : null,
                    secondary: _StatusBadge(
                        status: LeadStatus.fromDb(lead.status)),
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Draft summary
              Text('Your draft:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              _LeadCard(
                lead: _DraftSummaryLead(widget.draft),
                theme: theme,
                isDraft: true,
              ),
            ],
          ),
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        // Cancel — go back to editor
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const DuplicateDetectionResult(action: DuplicateAction.cancel),
          ),
          child: const Text('Cancel'),
        ),

        // Keep existing — discard draft
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const DuplicateDetectionResult(
                action: DuplicateAction.keepExisting),
          ),
          child: const Text('Keep existing'),
        ),

        // Save as separate — only if phones no longer conflict
        if (widget.canSaveAsSeparate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const DuplicateDetectionResult(
                  action: DuplicateAction.saveAsSeparate),
            ),
            child: const Text('Save as separate'),
          ),

        // Review & merge — primary action
        FilledButton.icon(
          icon: const Icon(Icons.merge_type_rounded, size: 18),
          label: const Text('Review & merge'),
          onPressed: () => Navigator.of(context).pop(
            DuplicateDetectionResult(
              action: DuplicateAction.reviewAndMerge,
              chosenTargetLeadId: _selectedLead.id,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LeadCard — compact summary of a lead or draft
// ─────────────────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.theme,
    this.isDraft = false,
  });

  final _LeadSummary lead;
  final ThemeData theme;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDraft
            ? cs.secondaryContainer.withValues(alpha: 0.4)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDraft ? cs.secondary.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (lead.businessType != null) ...[
                  const SizedBox(height: 2),
                  Text(lead.businessType!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (!isDraft) _StatusBadge(status: lead.status!),
          if (isDraft)
            Chip(
              label: const Text('Draft'),
              padding: EdgeInsets.zero,
              labelStyle: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.secondary),
              side: BorderSide(color: cs.secondary.withValues(alpha: 0.5)),
              backgroundColor: cs.secondaryContainer.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusBadge
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          color: status.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers: abstract summary + draft adapter
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal summary interface consumed by [_LeadCard].
abstract class _LeadSummary {
  String get name;
  String? get businessType;
  LeadStatus? get status;
}

/// Wraps a [Lead] (DB row) as a [_LeadSummary].
extension on Lead {
  _LeadSummary get _asSummary => _DbLeadSummary(this);
}

class _DbLeadSummary implements _LeadSummary {
  const _DbLeadSummary(this._lead);
  final Lead _lead;
  @override
  String get name => _lead.name;
  @override
  String? get businessType => _lead.businessType;
  @override
  LeadStatus? get status => LeadStatus.fromDb(_lead.status);
}

/// Wraps a [LeadDraft] as a [_LeadSummary].
class _DraftSummaryLead implements _LeadSummary {
  const _DraftSummaryLead(this._draft);
  final LeadDraft _draft;
  @override
  String get name => _draft.name.isEmpty ? '(no name)' : _draft.name;
  @override
  String? get businessType =>
      (_draft.businessType?.isEmpty ?? true) ? null : _draft.businessType;
  @override
  LeadStatus? get status => null; // draft has no committed status badge
}
