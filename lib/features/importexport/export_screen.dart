import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../search/lead_filter.dart';
import 'import_export_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ExportScreen — Phase 7
// ─────────────────────────────────────────────────────────────────────────────

class ExportScreen extends ConsumerStatefulWidget {
  /// [activeFilter] is forwarded from SearchScreen when the user chooses
  /// "Export filtered". Pass null (or LeadFilter.empty) for the all-leads path.
  const ExportScreen({super.key, this.activeFilter});

  final LeadFilter? activeFilter;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _format = ExportFormat.csv;
  late ExportScope _scope;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _scope = (widget.activeFilter != null &&
            widget.activeFilter!.hasActiveFilters)
        ? ExportScope.filtered
        : ExportScope.all;
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final repo = ref.read(importExportRepositoryProvider);
      final bundle = await repo.export(
        format: _format,
        scope: _scope,
        filter: widget.activeFilter ?? LeadFilter.empty,
      );

      final paths = await repo.saveToTempFiles(bundle);
      final xFiles = paths.map((p) => XFile(p)).toList();

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: xFiles,
          subject: 'Kiko export',
          text: _scope == ExportScope.all
              ? 'All leads export'
              : 'Filtered leads export',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilter = widget.activeFilter != null &&
        widget.activeFilter!.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Scope ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Scope', theme: theme),
          const SizedBox(height: 8),

          RadioGroup<ExportScope>(
            groupValue: _scope,
            onChanged: (v) {
              if (v != null) setState(() => _scope = v);
            },
            child: Column(
              children: [
                RadioListTile<ExportScope>(
                  title: const Text('All leads'),
                  subtitle:
                      const Text('Export every lead in the database'),
                  value: ExportScope.all,
                ),
                RadioListTile<ExportScope>(
                  title: const Text('Current filter'),
                  subtitle: Text(
                    hasActiveFilter
                        ? 'Export only leads matching the active filter'
                        : 'No active filter — same as "All leads"',
                  ),
                  value: ExportScope.filtered,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Format ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Format', theme: theme),
          const SizedBox(height: 8),

          RadioGroup<ExportFormat>(
            groupValue: _format,
            onChanged: (v) {
              if (v != null) setState(() => _format = v);
            },
            child: Column(
              children: [
                RadioListTile<ExportFormat>(
                  title: const Text('CSV'),
                  subtitle: const Text(
                      'Three separate files: Leads, Calls, Reminders'),
                  value: ExportFormat.csv,
                ),
                RadioListTile<ExportFormat>(
                  title: const Text('Excel (XLSX)'),
                  subtitle: const Text(
                      'Single workbook with Leads, Calls and Reminders sheets'),
                  value: ExportFormat.xlsx,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Info card ────────────────────────────────────────────────────
          Card(
            color: theme.colorScheme.secondaryContainer
                .withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Images and call recordings are never included in exports.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Export button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share_outlined),
              label: Text(_exporting ? 'Exporting…' : 'Export & Share'),
              onPressed: _exporting ? null : _export,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}
