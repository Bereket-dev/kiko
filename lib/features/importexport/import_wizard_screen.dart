import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../app/providers.dart';
import 'import_export_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImportWizardScreen — Phase 7
// ─────────────────────────────────────────────────────────────────────────────
//
// Steps:
//   0 – Pick file
//   1 – Map columns
//   2 – Preview / validate rows
//   3 – Resolve conflicts
//   4 – Done (summary)
// ─────────────────────────────────────────────────────────────────────────────

class ImportWizardScreen extends ConsumerStatefulWidget {
  const ImportWizardScreen({super.key});

  @override
  ConsumerState<ImportWizardScreen> createState() =>
      _ImportWizardScreenState();
}

class _ImportWizardScreenState
    extends ConsumerState<ImportWizardScreen> {
  int _step = 0;

  // Step 0
  String? _filePath;
  String? _filePickError;
  bool _picking = false;

  // Step 1
  Map<String, int> _columnMap = {};
  int? _totalColumns;
  bool _detecting = false;

  // Step 2
  List<ImportRow> _rows = [];
  bool _parsing = false;
  String? _parseError;

  // Step 3 – conflict resolution
  final Map<int, ImportConflictAction> _actions = {};
  ImportApplyAllPolicy _applyAllPolicy =
      ImportApplyAllPolicy.keepExisting;
  bool _applyAllSet = false;

  // Step 4
  ImportResult? _result;
  bool _persisting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 5,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _StepPickFile(
            filePath: _filePath,
            error: _filePickError,
            picking: _picking,
            onPick: _pickFile,
            onNext: _goToColumnMap,
          ),
          _StepColumnMap(
            columnMap: _columnMap,
            totalColumns: _totalColumns ?? 0,
            detecting: _detecting,
            onColumnChanged: (key, idx) =>
                setState(() => _columnMap[key] = idx),
            onBack: () => setState(() => _step = 0),
            onNext: _parseRows,
          ),
          _StepPreview(
            rows: _rows,
            parsing: _parsing,
            parseError: _parseError,
            onBack: () => setState(() => _step = 1),
            onNext: _goToConflicts,
          ),
          _StepConflicts(
            rows: _rows,
            actions: _actions,
            applyAllPolicy: _applyAllPolicy,
            applyAllSet: _applyAllSet,
            onActionChanged: (rowIdx, action) =>
                setState(() => _actions[rowIdx] = action),
            onApplyAll: (policy) => setState(() {
              _applyAllPolicy = policy;
              _applyAllSet = true;
            }),
            onBack: () => setState(() => _step = 2),
            onImport: _persist,
            persisting: _persisting,
          ),
          _StepDone(
            result: _result,
            onClose: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ── Step 0: pick file ──────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _filePickError = null;
    });
    try {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'xlsx', 'xls'],
          allowMultiple: false,
        );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _filePath = result.files.first.path);
      }
    } catch (e) {
      setState(() => _filePickError = 'Failed to pick file: $e');
    } finally {
      setState(() => _picking = false);
    }
  }

  Future<void> _goToColumnMap() async {
    if (_filePath == null) return;
    setState(() => _detecting = true);
    try {
      final repo = ref.read(importExportRepositoryProvider);
      final map = await repo.detectColumnMap(_filePath!);
      setState(() {
        _columnMap = map;
        // Also count columns
        _totalColumns = _countFileColumns(_filePath!);
        _step = 1;
      });
    } catch (e) {
      setState(() => _filePickError = 'Could not read file: $e');
    } finally {
      setState(() => _detecting = false);
    }
  }

  int _countFileColumns(String path) {
    // Simple heuristic: use detected map max or default 10
    if (_columnMap.isEmpty) return 10;
    final maxIdx =
        _columnMap.values.reduce((a, b) => a > b ? a : b);
    return maxIdx + 2;
  }

  // ── Step 1→2: parse ────────────────────────────────────────────────────────

  Future<void> _parseRows() async {
    setState(() {
      _parsing = true;
      _parseError = null;
    });
    try {
      final repo = ref.read(importExportRepositoryProvider);
      final rows =
          await repo.parseFile(_filePath!, _columnMap);
      setState(() {
        _rows = rows;
        _step = 2;
      });
    } catch (e) {
      setState(() => _parseError = 'Parse failed: $e');
    } finally {
      setState(() => _parsing = false);
    }
  }

  // ── Step 2→3: go to conflicts if any ──────────────────────────────────────

  Future<void> _goToConflicts() async {
    // Pre-check which rows have conflicts
    final repo = ref.read(importExportRepositoryProvider);
    final conflictRows = <ImportRow>[];

    for (final row in _rows) {
      if (!row.isValid) continue;
      if (row.phonesE164.isEmpty) continue;
      final map = await repo.checkPhoneConflicts(row.phonesE164);
      if (map.isNotEmpty) conflictRows.add(row);
    }

    setState(() {
      _step = 3;
      // Pre-populate actions for all conflict rows with keepExisting
      for (final row in conflictRows) {
        _actions.putIfAbsent(
            row.rowIndex, () => ImportConflictAction.keepExisting);
      }
    });
  }

  // ── Step 3→4: persist ──────────────────────────────────────────────────────

  Future<void> _persist() async {
    setState(() => _persisting = true);
    try {
      final repo = ref.read(importExportRepositoryProvider);
      final result = await repo.persistRows(
        rows: _rows,
        actions: _actions,
        applyAllPolicy: _applyAllPolicy,
      );
      setState(() {
        _result = result;
        _step = 4;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _persisting = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── Step 0: Pick file ──────────────────────────────────────────────────────

class _StepPickFile extends StatelessWidget {
  const _StepPickFile({
    required this.filePath,
    required this.error,
    required this.picking,
    required this.onPick,
    required this.onNext,
  });

  final String? filePath;
  final String? error;
  final bool picking;
  final VoidCallback onPick;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1 of 4: Select file',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Choose a CSV or XLSX file to import leads from.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            icon: picking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.folder_open_outlined),
            label: const Text('Browse files'),
            onPressed: picking ? null : onPick,
          ),

          if (filePath != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  filePath!.split('/').last,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(filePath!),
              ),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!,
                style: TextStyle(
                    color: theme.colorScheme.error)),
          ],

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: filePath != null ? onNext : null,
              child: const Text('Next: Map columns'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Column map ────────────────────────────────────────────────────

class _StepColumnMap extends StatelessWidget {
  const _StepColumnMap({
    required this.columnMap,
    required this.totalColumns,
    required this.detecting,
    required this.onColumnChanged,
    required this.onBack,
    required this.onNext,
  });

  final Map<String, int> columnMap;
  final int totalColumns;
  final bool detecting;
  final void Function(String key, int idx) onColumnChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cols = List.generate(
        totalColumns, (i) => DropdownMenuItem(value: i, child: Text('Col ${i + 1}')));

    final canonicalKeys = ExportColumns.leadHeaders;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Step 2 of 4: Map columns',
                style: theme.textTheme.titleMedium),
          ),
          if (detecting)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView.separated(
              itemCount: canonicalKeys.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1),
              itemBuilder: (context, i) {
                final key = canonicalKeys[i];
                final selected = columnMap[key];
                return ListTile(
                  title: Text(_keyLabel(key)),
                  subtitle: Text(key,
                      style: const TextStyle(fontSize: 11)),
                  trailing: SizedBox(
                    width: 120,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('—'),
                      value: selected,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('—'),
                        ),
                        ...cols,
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          onColumnChanged(key, v);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              TextButton(
                  onPressed: onBack, child: const Text('Back')),
              const Spacer(),
              FilledButton(
                onPressed: columnMap.containsKey(ExportColumns.name)
                    ? onNext
                    : null,
                child: const Text('Next: Preview'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _keyLabel(String key) {
    switch (key) {
      case ExportColumns.name:
        return 'Name *';
      case ExportColumns.businessType:
        return 'Business type';
      case ExportColumns.status:
        return 'Status';
      case ExportColumns.source:
        return 'Source';
      case ExportColumns.phones:
        return 'Phones';
      case ExportColumns.notes:
        return 'Notes';
      case ExportColumns.createdAt:
        return 'Created at';
      case ExportColumns.lastContactAt:
        return 'Last contact at';
      case ExportColumns.archived:
        return 'Archived';
      default:
        return key;
    }
  }
}

// ── Step 2: Preview / validate ─────────────────────────────────────────────

class _StepPreview extends StatelessWidget {
  const _StepPreview({
    required this.rows,
    required this.parsing,
    required this.parseError,
    required this.onBack,
    required this.onNext,
  });

  final List<ImportRow> rows;
  final bool parsing;
  final String? parseError;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = rows.where((r) => r.isValid).length;
    final invalid = rows.length - valid;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3 of 4: Preview',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          if (parsing) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ] else if (parseError != null) ...[
            const SizedBox(height: 8),
            Text(parseError!,
                style:
                    TextStyle(color: theme.colorScheme.error)),
          ] else ...[
            Text(
              '$valid valid  •  $invalid with errors',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (ctx, i) {
                  final row = rows[i];
                  return ListTile(
                    leading: Icon(
                      row.isValid
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: row.isValid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      size: 20,
                    ),
                    title: Text(
                        row.name.isEmpty ? '(empty)' : row.name),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (row.phonesE164.isNotEmpty)
                          Text(row.phonesE164.join(', '),
                              style: const TextStyle(
                                  fontSize: 11)),
                        ...row.errors.map((e) => Text(
                              e,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      theme.colorScheme.error),
                            )),
                      ],
                    ),
                    isThreeLine: row.errors.isNotEmpty,
                    dense: true,
                  );
                },
              ),
            ),
          ],
          Row(
            children: [
              TextButton(
                  onPressed: onBack, child: const Text('Back')),
              const Spacer(),
              FilledButton(
                onPressed: rows.isEmpty || parsing ? null : onNext,
                child: const Text('Next: Conflicts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Resolve conflicts ──────────────────────────────────────────────

class _StepConflicts extends StatefulWidget {
  const _StepConflicts({
    required this.rows,
    required this.actions,
    required this.applyAllPolicy,
    required this.applyAllSet,
    required this.onActionChanged,
    required this.onApplyAll,
    required this.onBack,
    required this.onImport,
    required this.persisting,
  });

  final List<ImportRow> rows;
  final Map<int, ImportConflictAction> actions;
  final ImportApplyAllPolicy applyAllPolicy;
  final bool applyAllSet;
  final void Function(int rowIdx, ImportConflictAction action)
      onActionChanged;
  final void Function(ImportApplyAllPolicy policy) onApplyAll;
  final VoidCallback onBack;
  final VoidCallback onImport;
  final bool persisting;

  @override
  State<_StepConflicts> createState() => _StepConflictsState();
}

class _StepConflictsState extends State<_StepConflicts> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflictRows = widget.rows
        .where((r) => widget.actions.containsKey(r.rowIndex))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4 of 4: Resolve conflicts',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            conflictRows.isEmpty
                ? 'No conflicts detected.'
                : '${conflictRows.length} rows have phone number conflicts.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),

          if (conflictRows.isNotEmpty) ...[
            // Apply-all policy
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text('Apply to all remaining:',
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          ImportApplyAllPolicy.values
                              .map(
                                (p) => ChoiceChip(
                                  label:
                                      Text(_policyLabel(p)),
                                  selected:
                                      widget.applyAllPolicy ==
                                              p &&
                                          widget.applyAllSet,
                                  onSelected: (v) {
                                    if (v) {
                                      widget.onApplyAll(p);
                                    }
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: conflictRows.length,
                itemBuilder: (ctx, i) {
                  final row = conflictRows[i];
                  final action = widget.actions[row.rowIndex] ??
                      ImportConflictAction.keepExisting;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(row.name,
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w500)),
                          if (row.phonesE164.isNotEmpty)
                            Text(
                              row.phonesE164.join(', '),
                              style: const TextStyle(
                                  fontSize: 12),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: [
                              ImportConflictAction.keepExisting,
                              ImportConflictAction.mergeAll,
                              ImportConflictAction.skip,
                              ImportConflictAction.saveAsSeparate,
                            ]
                                .map((a) => ChoiceChip(
                                      label: Text(
                                          _actionLabel(a),
                                          style:
                                              const TextStyle(
                                                  fontSize: 12)),
                                      selected: action == a,
                                      onSelected: (v) {
                                        if (v) {
                                          widget.onActionChanged(
                                              row.rowIndex, a);
                                        }
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                      visualDensity:
                                          VisualDensity.compact,
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Spacer(),
          ],

          Row(
            children: [
              TextButton(
                  onPressed: widget.persisting
                      ? null
                      : widget.onBack,
                  child: const Text('Back')),
              const Spacer(),
              FilledButton(
                onPressed:
                    widget.persisting ? null : widget.onImport,
                child: widget.persisting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _actionLabel(ImportConflictAction a) {
    switch (a) {
      case ImportConflictAction.keepExisting:
        return 'Keep existing';
      case ImportConflictAction.mergeAll:
        return 'Merge';
      case ImportConflictAction.skip:
        return 'Skip';
      case ImportConflictAction.saveAsSeparate:
        return 'Save separate';
      case ImportConflictAction.reviewAndMerge:
        return 'Review';
    }
  }

  String _policyLabel(ImportApplyAllPolicy p) {
    switch (p) {
      case ImportApplyAllPolicy.keepExisting:
        return 'Keep existing';
      case ImportApplyAllPolicy.mergeAll:
        return 'Merge all';
      case ImportApplyAllPolicy.skip:
        return 'Skip all';
    }
  }
}

// ── Step 4: Done ────────────────────────────────────────────────────────────

class _StepDone extends StatelessWidget {
  const _StepDone({required this.result, required this.onClose});

  final ImportResult? result;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text('Import complete',
              style: theme.textTheme.headlineSmall),
          if (r != null) ...[
            const SizedBox(height: 24),
            _statRow(theme, Icons.add_circle_outline,
                '${r.created} created'),
            _statRow(theme, Icons.merge_outlined,
                '${r.merged} merged'),
            _statRow(theme, Icons.skip_next_outlined,
                '${r.skipped} skipped'),
            if (r.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('${r.errors.length} errors',
                  style: TextStyle(
                      color: theme.colorScheme.error)),
              const SizedBox(height: 4),
              Expanded(
                child: ListView.builder(
                  itemCount: r.errors.length,
                  itemBuilder: (ctx, i) => Text(
                    r.errors[i],
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(ThemeData theme, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
