import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/pigeon/api_shims.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RecentCallsScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Loads the system call log (via CallLogApiShim), cross-references known leads,
// and lets the user navigate to a lead detail or add an unknown caller as a
// new lead.
// ─────────────────────────────────────────────────────────────────────────────

class RecentCallsScreen extends ConsumerStatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  ConsumerState<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends ConsumerState<RecentCallsScreen> {
  static const _limit = 100;
  static const _sinceMs = 0; // all time

  List<_EnrichedEntry>? _entries;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final callApi = CallLogApiShim.instance;
      final leadsRepo = ref.read(leadsRepositoryProvider);

      final raw = await callApi.getRecentCalls(
          sinceMs: _sinceMs, limit: _limit);

      // Cross-reference with known leads.
      final enriched = <_EnrichedEntry>[];
      for (final entry in raw) {
        final dupes = await leadsRepo.findDuplicatesByPhones([entry.e164]);
        enriched.add(_EnrichedEntry(
          raw: entry,
          leadId: dupes.isNotEmpty ? dupes.first.id : null,
          leadName: dupes.isNotEmpty ? dupes.first.name : null,
        ));
      }

      if (mounted) {
        setState(() {
          _entries = enriched;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _entries == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }
    if (_entries == null || _entries!.isEmpty) {
      return const Center(child: Text('No recent calls found.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _entries!.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 72),
        itemBuilder: (context, i) => _CallTile(
          entry: _entries![i],
          onTap: () => _onTap(context, _entries![i]),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, _EnrichedEntry entry) {
    if (entry.leadId != null) {
      context.push('/leads/${entry.leadId}');
    } else {
      context.push('/leads/add?phone=${Uri.encodeComponent(entry.raw.e164)}');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EnrichedEntry
// ─────────────────────────────────────────────────────────────────────────────

class _EnrichedEntry {
  const _EnrichedEntry({
    required this.raw,
    this.leadId,
    this.leadName,
  });

  final CallLogEntryShim raw;
  final String? leadId;
  final String? leadName;

  bool get isKnown => leadId != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// _CallTile
// ─────────────────────────────────────────────────────────────────────────────

class _CallTile extends StatelessWidget {
  const _CallTile({required this.entry, required this.onTap});

  final _EnrichedEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final raw = entry.raw;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _directionColor(raw.callType, cs).withValues(alpha: 0.15),
        child: Icon(
          _directionIcon(raw.callType),
          color: _directionColor(raw.callType, cs),
          size: 22,
        ),
      ),
      title: Text(
        entry.leadName ?? entry.raw.displayName ?? raw.e164,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        [
          if (entry.leadName != null || entry.raw.displayName != null) raw.e164,
          _formatTimestamp(raw.startedAtMs),
          if (raw.durationSec > 0) _formatDuration(raw.durationSec),
        ].join(' · '),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
      trailing: entry.isKnown
          ? null
          : IconButton(
              icon: Icon(Icons.person_add_outlined, color: cs.primary),
              tooltip: 'Add as lead',
              onPressed: onTap,
            ),
      onTap: onTap,
    );
  }

  IconData _directionIcon(String callType) {
    switch (callType) {
      case 'INCOMING':
        return Icons.call_received_outlined;
      case 'OUTGOING':
        return Icons.call_made_outlined;
      case 'MISSED':
        return Icons.call_missed_outlined;
      default:
        return Icons.call_outlined;
    }
  }

  Color _directionColor(String callType, ColorScheme cs) {
    switch (callType) {
      case 'INCOMING':
        return cs.primary;
      case 'OUTGOING':
        return cs.tertiary;
      case 'MISSED':
        return cs.error;
      default:
        return cs.outline;
    }
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  String _formatDuration(int sec) {
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }
}
