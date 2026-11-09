import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/pigeon/api_shims.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SettingsScreen
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;

  Future<void> _syncOverlay() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final settings = ref.read(appSettingsProvider);
      await SettingsSyncApiShim.instance.syncOverlaySettings(
        masterEnabled: settings.overlayMasterEnabled,
        showHistory: settings.overlayShowHistory,
        askUnknown: settings.askUnknown,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sync overlay settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _resetDismissedNumbers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset dismissed numbers?'),
        content: const Text(
          'Kiko will start asking again whether unknown callers '
          'you previously dismissed are leads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(callPlanRepositoryProvider);
      await repo.clearDismissedNumbers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dismissed numbers cleared.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // ── Overlay ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Overlay', theme: theme),

          SwitchListTile(
            title: const Text('Show caller overlay'),
            subtitle: const Text(
                'Display lead info during incoming calls'),
            value: settings.overlayMasterEnabled,
            onChanged: (v) async {
              await settings.setOverlayMasterEnabled(v);
              setState(() {});
              await _syncOverlay();
            },
          ),

          SwitchListTile(
            title: const Text('Show call history'),
            subtitle: const Text(
                'Include last note and last call date in overlay'),
            value: settings.overlayShowHistory,
            onChanged: settings.overlayMasterEnabled
                ? (v) async {
                    await settings.setOverlayShowHistory(v);
                    setState(() {});
                    await _syncOverlay();
                  }
                : null,
          ),

          SwitchListTile(
            title: const Text('Ask about unknown callers'),
            subtitle: const Text(
                'Show "Is this a lead?" dialog for unrecognised numbers'),
            value: settings.askUnknown,
            onChanged: settings.overlayMasterEnabled
                ? (v) async {
                    await settings.setAskUnknown(v);
                    setState(() {});
                    await _syncOverlay();
                  }
                : null,
          ),

          if (_syncing)
            const LinearProgressIndicator(minHeight: 2),

          const Divider(),

          // ── Calls ──────────────────────────────────────────────────────────
          _SectionHeader(title: 'Calls', theme: theme),

          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Recent calls'),
            subtitle: const Text('View call log and add leads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/recent-calls'),
          ),

          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permissions'),
            subtitle: const Text('Grant or review required permissions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/permissions-wizard'),
          ),

          const Divider(),

          // ── Data ───────────────────────────────────────────────────────────
          _SectionHeader(title: 'Data', theme: theme),

          ListTile(
            leading: Icon(Icons.block_outlined,
                color: theme.colorScheme.error),
            title: const Text('Reset dismissed numbers'),
            subtitle: const Text(
                'Start asking again about previously dismissed callers'),
            onTap: _resetDismissedNumbers,
          ),

          const Divider(),

          // ── About ──────────────────────────────────────────────────────────
          _SectionHeader(title: 'About', theme: theme),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(
              '1.0.0',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 24),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
