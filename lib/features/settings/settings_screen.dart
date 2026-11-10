import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/pigeon/api_shims.dart';
import '../security/app_lock_wrapper.dart';
import '../security/pin_setup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auto-lock timeout options
// ─────────────────────────────────────────────────────────────────────────────

const _autoLockOptions = <({String label, int ms})>[
  (label: 'Immediately', ms: 0),
  (label: 'After 30 seconds', ms: 30 * 1000),
  (label: 'After 1 minute', ms: 60 * 1000),
  (label: 'After 5 minutes', ms: 5 * 60 * 1000),
  (label: 'After 15 minutes', ms: 15 * 60 * 1000),
];

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
  bool? _hasPinSet;

  @override
  void initState() {
    super.initState();
    _loadPinState();
  }

  Future<void> _loadPinState() async {
    final settings = ref.read(appSettingsProvider);
    final has = await settings.hasPinSet();
    if (mounted) setState(() => _hasPinSet = has);
  }

  // ── Overlay sync ──────────────────────────────────────────────────────────

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

  // ── Dismissed numbers ─────────────────────────────────────────────────────

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

  // ── Security / PIN ────────────────────────────────────────────────────────

  Future<void> _onSetupPin() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          allowSkip: false,
          onComplete: () {
            Navigator.of(context).pop();
            _loadPinState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN lock enabled')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onChangePin() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PinSetupScreen(
          isChanging: true,
          allowSkip: false,
          onComplete: () {
            Navigator.of(context).pop();
            _loadPinState();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN updated')),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onDisablePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable PIN lock?'),
        content: const Text(
          'Your app data will not be PIN-protected. '
          'The database encryption key remains unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(pinServiceProvider).clearPin();
    _loadPinState();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN lock disabled')),
      );
    }
  }

  Future<void> _onAutoLockChange() async {
    final settings = ref.read(appSettingsProvider);
    final current = settings.autoLockTimeoutMs;
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => _AutoLockPickerDialog(currentMs: current),
    );
    if (picked != null && mounted) {
      await settings.setAutoLockTimeoutMs(picked);
      setState(() {});
    }
  }

  // ── Language ──────────────────────────────────────────────────────────────

  Future<void> _onLanguageChange() async {
    final settings = ref.read(appSettingsProvider);
    final current = settings.language;
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _LanguagePickerDialog(currentCode: current),
    );
    if (picked != null && mounted) {
      await settings.setLanguage(picked);
      // Update the locale provider so KikoApp rebuilds.
      ref.read(localePrefProvider.notifier).state = picked;
      setState(() {});
    }
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Future<void> _onCalendarModeChange() async {
    final settings = ref.read(appSettingsProvider);
    final current = settings.calendarDisplayMode;
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _CalendarModePickerDialog(currentMode: current),
    );
    if (picked != null && mounted) {
      await settings.setCalendarDisplayMode(picked);
      setState(() {});
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Overlay ────────────────────────────────────────────────────────
          _SectionHeader(title: 'Overlay', theme: theme),

          SwitchListTile(
            title: const Text('Show caller overlay'),
            subtitle: const Text('Display lead info during incoming calls'),
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

          if (_syncing) const LinearProgressIndicator(minHeight: 2),

          const Divider(),

          // ── Security ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Security', theme: theme),

          if (_hasPinSet == null)
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Loading…'),
            )
          else if (!_hasPinSet!)
            ListTile(
              leading: const Icon(Icons.lock_open_outlined),
              title: const Text('Set up PIN'),
              subtitle: const Text('Protect the app with a 4-digit PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _onSetupPin,
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change PIN'),
              subtitle: const Text('Update your 4-digit PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _onChangePin,
            ),
            ListTile(
              leading: Icon(Icons.no_encryption_outlined,
                  color: theme.colorScheme.error),
              title: const Text('Disable PIN'),
              subtitle: const Text('Remove PIN lock'),
              onTap: _onDisablePin,
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Auto-lock'),
              subtitle: Text(_autoLockLabel(settings.autoLockTimeoutMs)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _onAutoLockChange,
            ),
            ListTile(
              leading: const Icon(Icons.lock_clock_outlined),
              title: const Text('Lock now'),
              subtitle: const Text('Immediately lock the app'),
              onTap: () {
                appLockNotifier.value = true;
                context.pop();
              },
            ),
          ],

          const Divider(),

          // ── Language ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Language', theme: theme),

          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: Text(_languageLabel(settings.language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _onLanguageChange,
          ),

          const Divider(),

          // ── Calendar ───────────────────────────────────────────────────────
          _SectionHeader(title: 'Calendar', theme: theme),

          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Calendar display'),
            subtitle: Text(_calendarModeLabel(settings.calendarDisplayMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _onCalendarModeChange,
          ),

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
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Import leads'),
            subtitle: const Text('Import from CSV or Excel file'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/import'),
          ),

          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export leads'),
            subtitle: const Text('Export to CSV or Excel'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/export'),
          ),

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

  static String _autoLockLabel(int ms) {
    for (final opt in _autoLockOptions) {
      if (opt.ms == ms) return opt.label;
    }
    return 'After ${ms ~/ 1000}s';
  }

  static String _languageLabel(String code) {
    switch (code) {
      case 'am':
        return 'አማርኛ (Amharic)';
      default:
        return 'English';
    }
  }

  static String _calendarModeLabel(String mode) {
    switch (mode) {
      case 'ET':
        return 'Ethiopian (ዓ.ም)';
      case 'GR':
        return 'Gregorian';
      case 'BOTH':
        return 'Both';
      default:
        return 'Ethiopian (ዓ.ም)';
    }
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

// ─────────────────────────────────────────────────────────────────────────────
// _AutoLockPickerDialog
// ─────────────────────────────────────────────────────────────────────────────

class _AutoLockPickerDialog extends StatelessWidget {
  const _AutoLockPickerDialog({required this.currentMs});
  final int currentMs;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Auto-lock'),
      children: _autoLockOptions.map((opt) {
        return SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(opt.ms),
          child: Row(
            children: [
              Expanded(child: Text(opt.label)),
              if (opt.ms == currentMs)
                const Icon(Icons.check, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LanguagePickerDialog
// ─────────────────────────────────────────────────────────────────────────────

class _LanguagePickerDialog extends StatelessWidget {
  const _LanguagePickerDialog({required this.currentCode});
  final String currentCode;

  @override
  Widget build(BuildContext context) {
    const options = <({String code, String label})>[
      (code: 'en', label: 'English'),
      (code: 'am', label: 'አማርኛ (Amharic)'),
    ];
    return SimpleDialog(
      title: const Text('Language'),
      children: options.map((opt) {
        return SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(opt.code),
          child: Row(
            children: [
              Expanded(child: Text(opt.label)),
              if (opt.code == currentCode) const Icon(Icons.check, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CalendarModePickerDialog
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarModePickerDialog extends StatelessWidget {
  const _CalendarModePickerDialog({required this.currentMode});
  final String currentMode;

  @override
  Widget build(BuildContext context) {
    const options = <({String mode, String label})>[
      (mode: 'ET', label: 'Ethiopian (ዓ.ም)'),
      (mode: 'GR', label: 'Gregorian'),
      (mode: 'BOTH', label: 'Both'),
    ];
    return SimpleDialog(
      title: const Text('Calendar display'),
      children: options.map((opt) {
        return SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(opt.mode),
          child: Row(
            children: [
              Expanded(child: Text(opt.label)),
              if (opt.mode == currentMode) const Icon(Icons.check, size: 18),
            ],
          ),
        );
      }).toList(),
    );
  }
}
