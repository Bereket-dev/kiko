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
          IconButton(
            icon: const Icon(Icons.content_paste_outlined),
            tooltip: 'Paste lead',
            onPressed: () => context.push('/leads/paste'),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Recent calls',
            onPressed: () => context.push('/recent-calls'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
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
