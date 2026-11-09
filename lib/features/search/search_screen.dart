import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import '../leads/status_chip.dart';
import 'lead_filter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Async result of queryLeads with the current filter.
final searchResultsProvider = FutureProvider<List<Lead>>((ref) async {
  final filter = ref.watch(searchFilterProvider);
  return ref.watch(leadsRepositoryProvider).queryLeads(filter);
});

// ─────────────────────────────────────────────────────────────────────────────
// SearchScreen
// ─────────────────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String value) {
    final current = ref.read(searchFilterProvider);
    ref.read(searchFilterProvider.notifier).state =
        current.copyWith(keyword: value);
  }

  void _clearFilters() {
    _controller.clear();
    ref.read(searchFilterProvider.notifier).state = LeadFilter.empty;
  }

  Future<void> _openFilterSheet() async {
    final current = ref.read(searchFilterProvider);
    final result = await showModalBottomSheet<LeadFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(initial: current),
    );
    if (result != null) {
      final withKeyword =
          result.copyWith(keyword: _controller.text);
      ref.read(searchFilterProvider.notifier).state = withKeyword;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(searchFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final theme = Theme.of(context);
    final hasFilters = filter.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search leads…',
            border: InputBorder.none,
          ),
          onChanged: _onKeywordChanged,
        ),
        actions: [
          if (hasFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear all filters',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Export results',
            onPressed: () => context.push('/export', extra: filter),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _hasStructuralFilters(filter),
              child: const Icon(Icons.tune_outlined),
            ),
            tooltip: 'Filters',
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active filter chips ──────────────────────────────────────────
          _FilterChipRow(
            filter: filter,
            onUpdate: (f) {
              ref.read(searchFilterProvider.notifier).state =
                  f.copyWith(keyword: _controller.text);
            },
          ),
          // ── Results ──────────────────────────────────────────────────────
          Expanded(
            child: resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (leads) {
                if (leads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 56,
                            color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          'No leads found',
                          style: theme.textTheme.titleMedium,
                        ),
                        if (hasFilters) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: leads.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) =>
                      _SearchResultTile(lead: leads[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasStructuralFilters(LeadFilter f) {
    return f.statuses.isNotEmpty ||
        f.sources.isNotEmpty ||
        f.createdRange.isNotEmpty ||
        f.lastContactRange.isNotEmpty ||
        f.hasReminder != null ||
        f.callDirection != null ||
        f.includeArchived;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchResultTile
// ─────────────────────────────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final status = LeadStatus.fromDb(lead.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: status.backgroundColor,
        child: Text(
          lead.name.isNotEmpty ? lead.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: status.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(lead.name,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: lead.businessType != null
          ? Text(lead.businessType!,
              maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: StatusChip(status: status),
      onTap: () => context.push('/leads/${lead.id}'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterChipRow — horizontal scrollable row of active filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.filter,
    required this.onUpdate,
  });

  final LeadFilter filter;
  final ValueChanged<LeadFilter> onUpdate;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    for (final s in filter.statuses) {
      chips.add(_chip(
        label: s.label,
        onDeleted: () => onUpdate(filter.copyWith(
          statuses: {...filter.statuses}..remove(s),
        )),
      ));
    }

    for (final s in filter.sources) {
      chips.add(_chip(
        label: 'Source: ${s.label}',
        onDeleted: () => onUpdate(filter.copyWith(
          sources: {...filter.sources}..remove(s),
        )),
      ));
    }

    if (filter.hasReminder == true) {
      chips.add(_chip(
        label: 'Has reminder',
        onDeleted: () =>
            onUpdate(filter.copyWith(clearHasReminder: true)),
      ));
    } else if (filter.hasReminder == false) {
      chips.add(_chip(
        label: 'No reminder',
        onDeleted: () =>
            onUpdate(filter.copyWith(clearHasReminder: true)),
      ));
    }

    if (filter.callDirection != null) {
      chips.add(_chip(
        label: filter.callDirection!.label,
        onDeleted: () =>
            onUpdate(filter.copyWith(clearCallDirection: true)),
      ));
    }

    if (filter.includeArchived) {
      chips.add(_chip(
        label: 'Archived',
        onDeleted: () =>
            onUpdate(filter.copyWith(includeArchived: false)),
      ));
    }

    if (filter.createdRange.isNotEmpty) {
      chips.add(_chip(
        label: 'Created: range',
        onDeleted: () => onUpdate(filter.copyWith(
          createdRange: const DateRangeMs(),
        )),
      ));
    }

    if (filter.lastContactRange.isNotEmpty) {
      chips.add(_chip(
        label: 'Contact: range',
        onDeleted: () => onUpdate(filter.copyWith(
          lastContactRange: const DateRangeMs(),
        )),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: chips),
    );
  }

  Widget _chip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterSheet — modal bottom sheet with all filter controls
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final LeadFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late LeadFilter _filter;
  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  Future<void> _pickDateRange(
    BuildContext context, {
    required DateRangeMs current,
    required ValueChanged<DateRangeMs> onPicked,
  }) async {
    final initial = DateTimeRange(
      start: current.startMs != null
          ? DateTime.fromMillisecondsSinceEpoch(current.startMs!)
          : DateTime.now().subtract(const Duration(days: 30)),
      end: current.endMs != null
          ? DateTime.fromMillisecondsSinceEpoch(current.endMs!)
          : DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initial,
    );

    if (picked != null) {
      onPicked(DateRangeMs(
        startMs: picked.start.millisecondsSinceEpoch,
        endMs: picked.end
            .copyWith(hour: 23, minute: 59, second: 59)
            .millisecondsSinceEpoch,
      ));
    }
  }

  String _formatRange(DateRangeMs r) {
    if (r.startMs != null && r.endMs != null) {
      return '${_dateFmt.format(DateTime.fromMillisecondsSinceEpoch(r.startMs!))} – '
          '${_dateFmt.format(DateTime.fromMillisecondsSinceEpoch(r.endMs!))}';
    }
    return 'Any';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('Filters',
                      style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _filter = LeadFilter.empty),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Status
                  _sectionLabel(theme, 'Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: LeadStatus.values.map((s) {
                      final selected =
                          _filter.statuses.contains(s);
                      return FilterChip(
                        label: Text(s.label),
                        selected: selected,
                        selectedColor: s.backgroundColor,
                        onSelected: (v) => setState(() {
                          final set = {..._filter.statuses};
                          v ? set.add(s) : set.remove(s);
                          _filter = _filter.copyWith(statuses: set);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Source
                  _sectionLabel(theme, 'Source'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: LeadSource.values.map((s) {
                      final selected =
                          _filter.sources.contains(s);
                      return FilterChip(
                        label: Text(s.label),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          final set = {..._filter.sources};
                          v ? set.add(s) : set.remove(s);
                          _filter = _filter.copyWith(sources: set);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Reminder
                  _sectionLabel(theme, 'Reminder'),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Has reminder'),
                        selected: _filter.hasReminder == true,
                        onSelected: (v) => setState(() {
                          _filter = v
                              ? _filter.copyWith(hasReminder: true)
                              : _filter.copyWith(
                                  clearHasReminder: true);
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('No reminder'),
                        selected: _filter.hasReminder == false,
                        onSelected: (v) => setState(() {
                          _filter = v
                              ? _filter.copyWith(hasReminder: false)
                              : _filter.copyWith(
                                  clearHasReminder: true);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Call direction
                  _sectionLabel(theme, 'Has call of type'),
                  Wrap(
                    spacing: 8,
                    children: CallDirectionFilter.values.map((d) {
                      return ChoiceChip(
                        label: Text(d.label),
                        selected: _filter.callDirection == d,
                        onSelected: (v) => setState(() {
                          _filter = v
                              ? _filter.copyWith(callDirection: d)
                              : _filter.copyWith(
                                  clearCallDirection: true);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Created range
                  _sectionLabel(theme, 'Created'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_formatRange(_filter.createdRange)),
                    trailing: _filter.createdRange.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _filter = _filter.copyWith(
                                  createdRange: const DateRangeMs());
                            }),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => _pickDateRange(
                      context,
                      current: _filter.createdRange,
                      onPicked: (r) =>
                          setState(() => _filter =
                              _filter.copyWith(createdRange: r)),
                    ),
                  ),

                  // Last contact range
                  _sectionLabel(theme, 'Last contact'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                        _formatRange(_filter.lastContactRange)),
                    trailing: _filter.lastContactRange.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _filter = _filter.copyWith(
                                  lastContactRange:
                                      const DateRangeMs());
                            }),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => _pickDateRange(
                      context,
                      current: _filter.lastContactRange,
                      onPicked: (r) => setState(() => _filter =
                          _filter.copyWith(lastContactRange: r)),
                    ),
                  ),

                  // Include archived
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include archived'),
                    value: _filter.includeArchived,
                    onChanged: (v) => setState(() {
                      _filter = _filter.copyWith(includeArchived: v);
                    }),
                  ),
                ],
              ),
            ),
            // Apply button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_filter),
                    child: const Text('Apply filters'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
