import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';
import 'status_chip.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeadsListScreen
// ─────────────────────────────────────────────────────────────────────────────

class LeadsListScreen extends ConsumerWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(watchLeadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiko'),
        actions: [
          // Phase 7 — Search
          IconButton(
            icon: const Icon(Icons.search_outlined),
            tooltip: 'Search leads',
            onPressed: () => context.push('/search'),
          ),
          // Overflow menu for secondary actions
          PopupMenuButton<_AppBarAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _AppBarAction.paste:
                  context.push('/leads/paste');
                case _AppBarAction.recentCalls:
                  context.push('/recent-calls');
                case _AppBarAction.import_:
                  context.push('/import');
                case _AppBarAction.export:
                  context.push('/export');
                case _AppBarAction.settings:
                  context.push('/settings');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _AppBarAction.paste,
                child: ListTile(
                  leading: Icon(Icons.content_paste_outlined),
                  title: Text('Paste lead'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppBarAction.recentCalls,
                child: ListTile(
                  leading: Icon(Icons.call_outlined),
                  title: Text('Recent calls'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AppBarAction.import_,
                child: ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('Import'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppBarAction.export,
                child: ListTile(
                  leading: Icon(Icons.download_outlined),
                  title: Text('Export'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AppBarAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: leadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (leads) {
          if (leads.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push('/leads/add'),
              onPaste: () => context.push('/leads/paste'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(watchLeadsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: leads.length,
              separatorBuilder: (ctx, i) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, i) =>
                  _LeadTile(lead: leads[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_add_lead',
        onPressed: () => context.push('/leads/add'),
        tooltip: 'Add lead',
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _AppBarAction { paste, recentCalls, import_, export, settings }

// ─────────────────────────────────────────────────────────────────────────────
// _LeadTile
// ─────────────────────────────────────────────────────────────────────────────

class _LeadTile extends StatelessWidget {
  const _LeadTile({required this.lead});

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
          ? Text(
              lead.businessType!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: StatusChip(status: status),
      onTap: () => context.push('/leads/${lead.id}'),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onPaste});

  final VoidCallback onAdd;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 72,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leads yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first lead manually or paste contact info.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lead'),
                  onPressed: onAdd,
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.content_paste_outlined),
                  label: const Text('Paste'),
                  onPressed: onPaste,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
