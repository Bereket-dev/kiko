import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import '../../core/models/lead_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CallPlanScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Shown when a Call Plan alarm fires (route: /call-plan/:scheduleId).
//
// Lead priority order (spec §6):
//   1. Chosen leads  — explicitly picked for this schedule (CallPlanLeads rows)
//   2. Business-type filter — if schedule has filterBusinessType set
//   3. Due-today     — leads with a PENDING reminder due today
//
// Each lead row shows:
//   Call     → launches tel: intent, marks lead as CONTACTED
//   Snooze   → removes from this session (not from DB)
//   Done     → marks CallPlanLead.done = true (or just removes from list)
//   Open     → navigates to /leads/:id
//
// Empty state has a "Choose Leads" shortcut (routes to leads list).
// ─────────────────────────────────────────────────────────────────────────────

class CallPlanScreen extends ConsumerStatefulWidget {
  const CallPlanScreen({super.key, required this.scheduleId});

  final String scheduleId;

  @override
  ConsumerState<CallPlanScreen> createState() => _CallPlanScreenState();
}

class _CallPlanScreenState extends ConsumerState<CallPlanScreen> {
  /// Leads removed from the session via Snooze (not persisted).
  final Set<String> _snoozed = {};

  @override
  Widget build(BuildContext context) {
    final scheduleAsync =
        ref.watch(callPlanScheduleProvider(widget.scheduleId));

    return scheduleAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Call Plan')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (schedule) {
        if (schedule == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Call Plan')),
            body: const Center(child: Text('Schedule not found.')),
          );
        }
        return _CallPlanBody(
          schedule: schedule,
          snoozed: _snoozed,
          onSnooze: (id) => setState(() => _snoozed.add(id)),
          onDone: () {
            // Mark schedule done and pop.
            ref
                .read(callPlanRepositoryProvider)
                .markScheduleDone(widget.scheduleId);
            if (context.mounted) context.pop();
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CallPlanBody
// ─────────────────────────────────────────────────────────────────────────────

class _CallPlanBody extends ConsumerWidget {
  const _CallPlanBody({
    required this.schedule,
    required this.snoozed,
    required this.onSnooze,
    required this.onDone,
  });

  final CallPlanSchedule schedule;
  final Set<String> snoozed;
  final void Function(String leadId) onSnooze;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(callPlanLeadsProvider(schedule));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Plan'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Done'),
            onPressed: onDone,
          ),
        ],
      ),
      body: leadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading leads: $e')),
        data: (leads) {
          final visible = leads
              .where((l) => !snoozed.contains(l.id))
              .toList();

          if (visible.isEmpty) {
            return _EmptyState(schedule: schedule);
          }

          return Column(
            children: [
              if (schedule.filterBusinessType != null)
                _FilterBanner(type: schedule.filterBusinessType!),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _LeadCallTile(
                    lead: visible[i],
                    scheduleId: schedule.id,
                    onSnooze: () => onSnooze(visible[i].id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LeadCallTile
// ─────────────────────────────────────────────────────────────────────────────

class _LeadCallTile extends ConsumerWidget {
  const _LeadCallTile({
    required this.lead,
    required this.scheduleId,
    required this.onSnooze,
  });

  final Lead lead;
  final String scheduleId;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = LeadStatus.fromDb(lead.status);
    final theme  = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Name + status ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  lead.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: status.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: status.color,
                  ),
                ),
              ),
            ],
          ),
          if (lead.businessType != null) ...[
            const SizedBox(height: 2),
            Text(
              lead.businessType!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 10),

          // ── Action buttons ─────────────────────────────────────────────
          Row(
            children: [
              // Call
              _ActionButton(
                icon: Icons.call_outlined,
                label: 'Call',
                color: theme.colorScheme.primary,
                onTap: () => _call(context, ref),
              ),
              const SizedBox(width: 8),
              // Snooze
              _ActionButton(
                icon: Icons.snooze_outlined,
                label: 'Snooze',
                color: theme.colorScheme.secondary,
                onTap: onSnooze,
              ),
              const SizedBox(width: 8),
              // Done
              _ActionButton(
                icon: Icons.check_outlined,
                label: 'Done',
                color: Colors.green.shade700,
                onTap: () => _markDone(context, ref),
              ),
              const SizedBox(width: 8),
              // Open
              _ActionButton(
                icon: Icons.open_in_new_outlined,
                label: 'Open',
                color: theme.colorScheme.onSurfaceVariant,
                onTap: () => context.push('/leads/${lead.id}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    // Get primary phone.
    final phones = await ref
        .read(leadsRepositoryProvider)
        .getPhonesForLead(lead.id);

    final phone = phones.firstWhereOrNull((p) => p.isPrimary) ??
        phones.firstOrNull;

    if (phone == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number on file.')),
        );
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone.e164);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      // Mark as CONTACTED.
      await ref
          .read(leadsRepositoryProvider)
          .updateLead(lead.id, status: const Value('CONTACTED'));
    }
  }

  Future<void> _markDone(BuildContext context, WidgetRef ref) async {
    // Find the CallPlanLead row for this lead in this schedule.
    final rows = await ref
        .read(callPlanRepositoryProvider)
        .getLeadsForSchedule(scheduleId);

    final row = rows.firstWhereOrNull((r) => r.leadId == lead.id);
    if (row != null) {
      await ref
          .read(callPlanRepositoryProvider)
          .markLeadDone(row.id);
    }
    // Remove from visible list via snooze mechanism (parent will rebuild).
    onSnooze();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FilterBanner
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBanner extends StatelessWidget {
  const _FilterBanner({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cs.secondaryContainer,
      child: Row(
        children: [
          Icon(Icons.filter_list_outlined,
              size: 16, color: cs.onSecondaryContainer),
          const SizedBox(width: 8),
          Text(
            'Filtered by: $type',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.schedule});

  final CallPlanSchedule schedule;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_missed_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leads to call',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'All leads have been snoozed or marked done.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.people_outline),
              label: const Text('Choose Leads'),
              onPressed: () => context.push('/'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helpers
// ─────────────────────────────────────────────────────────────────────────────

extension _IterableExt<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }

  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
