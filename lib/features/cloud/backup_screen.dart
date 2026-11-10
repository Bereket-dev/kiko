import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import 'cloud_backup_service.dart';
import 'e2e_key_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BackupScreen
// ─────────────────────────────────────────────────────────────────────────────

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  late final CloudBackupService _backupService;

  List<BackupEntry> _history = [];
  bool _historyLoading = false;
  bool _backingUp = false;

  static final _dtFormat = DateFormat('d MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _backupService = CloudBackupService(
      db: ref.read(appDatabaseProvider),
      settings: settings,
      keyService: E2EKeyService(settings),
    );
    _loadHistory();
  }

  // ── History loading ───────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _historyLoading = true);

    try {
      final entries = await _backupService.listBackups(user.uid);
      if (!mounted) return;
      setState(() {
        _history = entries.take(3).toList();
        _historyLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _historyLoading = false);
    }
  }

  // ── Backup now ────────────────────────────────────────────────────────────

  Future<void> _backupNow() async {
    if (_backingUp) return;
    setState(() => _backingUp = true);

    try {
      final result = await _backupService.runBackup(force: true);

      if (!mounted) return;

      final message = switch (result) {
        BackupSuccess(:final sizeBytes) =>
          'Backup complete (${_formatSize(sizeBytes)})',
        BackupSkipped() => 'Up to date — nothing to back up',
        BackupFailed(:final reason) => 'Backup failed: $reason',
      };

      final isError = result is BackupFailed;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.errorContainer
              : null,
        ),
      );

      if (!isError) await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  // ── Restore flow ──────────────────────────────────────────────────────────

  Future<void> _restoreEntry(BackupEntry entry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Step 1: Confirmation dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace ALL current data with the backup from '
          '${_dtFormat.format(entry.timestamp.toLocal())}.\n\n'
          'This action cannot be undone.',
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Step 2: Recovery code dialog.
    final recoveryCode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RecoveryCodeDialog(),
    );
    if (recoveryCode == null || !mounted) return;

    // Step 3: Unwrap the data key using the recovery code.
    Uint8List dataKey;
    try {
      final settings = ref.read(appSettingsProvider);
      final keyService = E2EKeyService(settings);

      // Prefer Firestore keystore (authoritative); fall back to local copy.
      Uint8List? wrappedBlob =
          await keyService.fetchWrappedKeyFromFirestore(user.uid);
      if (wrappedBlob == null) {
        final wrappedKeyB64 = await settings.getWrappedKeyB64();
        if (wrappedKeyB64 != null) {
          wrappedBlob = Uint8List.fromList(base64Decode(wrappedKeyB64));
        }
      }
      if (wrappedBlob == null) {
        throw StateError('No wrapped key found. '
            'Please set up your recovery code before restoring.');
      }

      dataKey = await keyService.unwrapKeyWithRecoveryCode(
        wrappedBlob,
        recoveryCode,
      );
      await keyService.storeDataKey(dataKey);
    } on InvalidRecoveryCodeException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid recovery code')),
      );
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unwrap key: $e')),
      );
      return;
    }

    // Step 4: Restore.
    try {
      await _backupService.restoreBackup(
        userId: user.uid,
        storagePath: entry.path,
        dataKey: dataKey,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore complete')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    final lastBackupMs = settings.lastBackupMs;
    final lastBackupLabel = lastBackupMs != null
        ? _dtFormat.format(
            DateTime.fromMillisecondsSinceEpoch(lastBackupMs).toLocal())
        : 'Never';
    final nextBackupLabel =
        settings.backupEnabled ? 'Automatic (daily)' : 'Manual only';

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status card ────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup status',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    icon: Icons.history_outlined,
                    label: 'Last backup',
                    value: lastBackupLabel,
                  ),
                  const SizedBox(height: 6),
                  _StatusRow(
                    icon: Icons.schedule_outlined,
                    label: 'Next backup',
                    value: nextBackupLabel,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _backingUp ? null : _backupNow,
                      icon: _backingUp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.backup_outlined),
                      label: Text(_backingUp ? 'Backing up…' : 'Back Up Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Settings section ───────────────────────────────────────────────
          _SectionHeader(title: 'Settings', theme: theme),

          SwitchListTile(
            title: const Text('Automatic backup'),
            subtitle: const Text('Back up daily in the background'),
            secondary: const Icon(Icons.cloud_sync_outlined),
            value: settings.backupEnabled,
            onChanged: (v) async {
              await settings.setBackupEnabled(v);
              if (v) {
                await CloudBackupService.schedulePeriodicBackup(
                  wifiOnly: settings.backupWifiOnly,
                );
              } else {
                await CloudBackupService.cancelPeriodicBackup();
              }
              setState(() {});
            },
          ),

          SwitchListTile(
            title: const Text('Wi-Fi only'),
            subtitle: const Text('Only run automatic backup on Wi-Fi'),
            secondary: const Icon(Icons.wifi_outlined),
            value: settings.backupWifiOnly,
            onChanged: settings.backupEnabled
                ? (v) async {
                    await settings.setBackupWifiOnly(v);
                    await CloudBackupService.schedulePeriodicBackup(
                      wifiOnly: v,
                    );
                    setState(() {});
                  }
                : null,
          ),

          const SizedBox(height: 8),

          // ── Backup history ─────────────────────────────────────────────────
          if (_historyLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ))
          else if (_history.isNotEmpty) ...[
            _SectionHeader(title: 'Backup History', theme: theme),
            ..._history.map((entry) => _BackupHistoryTile(
                  entry: entry,
                  onRestore: () => _restoreEntry(entry),
                )),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusRow
// ─────────────────────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BackupHistoryTile
// ─────────────────────────────────────────────────────────────────────────────

class _BackupHistoryTile extends StatelessWidget {
  const _BackupHistoryTile({
    required this.entry,
    required this.onRestore,
  });

  final BackupEntry entry;
  final VoidCallback onRestore;

  static final _dtFormat = DateFormat('d MMM yyyy, HH:mm');

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localTime = entry.timestamp.toLocal();

    return ListTile(
      leading: const Icon(Icons.cloud_done_outlined),
      title: Text(_dtFormat.format(localTime)),
      subtitle: Text(
        _formatSize(entry.sizeBytes),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: TextButton(
        onPressed: onRestore,
        child: const Text('Restore'),
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
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
// _RecoveryCodeDialog
// ─────────────────────────────────────────────────────────────────────────────

/// Prompts the user for their recovery code.
/// Returns the entered code string on "Restore", null on cancel.
/// The caller is responsible for key-unwrapping and showing errors.
class _RecoveryCodeDialog extends StatefulWidget {
  const _RecoveryCodeDialog();

  @override
  State<_RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<_RecoveryCodeDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your recovery code.');
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recovery Code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your recovery code to decrypt the backup.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              labelText: 'Recovery code',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Restore'),
        ),
      ],
    );
  }
}
