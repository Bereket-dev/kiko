import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/utils/date_display.dart';
import 'cloud_device_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DevicesScreen
// ─────────────────────────────────────────────────────────────────────────────

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  late final CloudDeviceService _deviceService;

  List<DeviceInfo>? _devices;
  String? _currentDeviceId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _deviceService = CloudDeviceService(ref.read(appSettingsProvider));
    _load();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Not signed in.';
          _loading = false;
        });
        return;
      }

      final settings = ref.read(appSettingsProvider);
      final results = await Future.wait([
        _deviceService.listDevices(user.uid),
        settings.getDeviceId(),
      ]);

      if (!mounted) return;
      setState(() {
        _devices = results[0] as List<DeviceInfo>;
        _currentDeviceId = results[1] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Device removal ────────────────────────────────────────────────────────

  Future<void> _removeDevice(DeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove device?'),
        content: Text(
          'Remove "${device.deviceName}" from your registered devices? '
          'This device will no longer be able to restore backups.',
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _deviceService.removeDevice(
        userId: user.uid,
        deviceId: device.deviceId,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove device: $e')),
      );
    }
  }

  // ── Add this device ───────────────────────────────────────────────────────

  Future<void> _addThisDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final settings = ref.read(appSettingsProvider);
    final deviceId = await settings.getOrCreateDeviceId();
    final email = settings.cloudUserEmail ?? user.email ?? '';

    if (!mounted) return;

    final registered = await showDialog<bool>(
      context: context,
      builder: (_) => _OtpDialog(
        deviceService: _deviceService,
        userId: user.uid,
        deviceId: deviceId,
        initialEmail: email,
      ),
    );

    if (registered == true) {
      await _load();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  bool get _isCurrentDeviceRegistered {
    final id = _currentDeviceId;
    if (id == null || _devices == null) return false;
    return _devices!.any((d) => d.deviceId == id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final calMode = settings.calendarDisplayMode;

    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (_devices == null || _devices!.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices_outlined,
                  size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No devices registered',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Register this device to enable encrypted backup and restore.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _devices!.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, index) {
          final device = _devices![index];
          final isCurrent = device.deviceId == _currentDeviceId;
          final registeredMs =
              device.registeredAt.millisecondsSinceEpoch;

          return ListTile(
            leading: Icon(
              isCurrent ? Icons.phone_android : Icons.devices_outlined,
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    device.deviceName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('This device'),
                    labelStyle: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              'Registered ${DateDisplay.formatMs(registeredMs, mode: calMode)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove device',
              color: isCurrent ? null : theme.colorScheme.error,
              onPressed: isCurrent ? null : () => _removeDevice(device),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
        ],
      ),
      body: body,
      floatingActionButton:
          (!_loading && _error == null && !_isCurrentDeviceRegistered)
              ? FloatingActionButton.extended(
                  onPressed: _addThisDevice,
                  icon: const Icon(Icons.add),
                  label: const Text('Add This Device'),
                )
              : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OtpDialog
// ─────────────────────────────────────────────────────────────────────────────

/// A two-step dialog:
///  Step 1 — Email field (pre-filled) + "Send Code" button.
///  Step 2 — 6-digit OTP field + countdown timer + "Verify" button.
/// Returns `true` if device was successfully registered.
class _OtpDialog extends StatefulWidget {
  const _OtpDialog({
    required this.deviceService,
    required this.userId,
    required this.deviceId,
    required this.initialEmail,
  });

  final CloudDeviceService deviceService;
  final String userId;
  final String deviceId;
  final String initialEmail;

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  // Step 1
  late final TextEditingController _emailCtrl;
  // Step 2
  final TextEditingController _codeCtrl = TextEditingController();

  int _step = 1; // 1 = email, 2 = code
  String? _otpToken;

  bool _loading = false;
  String? _error;

  // Countdown
  static const _countdownSeconds = 10 * 60; // 10 min
  int _secondsLeft = _countdownSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Countdown ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    _secondsLeft = _countdownSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String get _countdownLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Step 1: Request OTP ───────────────────────────────────────────────────

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await widget.deviceService.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _otpToken = token;
        _step = 2;
        _loading = false;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to send code: $e';
        _loading = false;
      });
    }
  }

  // ── Step 2: Verify OTP + Register ────────────────────────────────────────

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }
    if (_secondsLeft <= 0) {
      setState(() => _error = 'Code expired. Please request a new one.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.deviceService.verifyOtp(
        otpToken: _otpToken!,
        otpCode: code,
      );

      final deviceName = _deviceName();
      await widget.deviceService.registerDevice(
        userId: widget.userId,
        deviceId: widget.deviceId,
        deviceName: deviceName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on InvalidOtpException {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid or expired code. Please try again.';
        _loading = false;
      });
    } on DeviceAlreadyRegisteredException {
      if (!mounted) return;
      // Already registered — treat as success.
      Navigator.of(context).pop(true);
    } on MaxDevicesException {
      if (!mounted) return;
      setState(() {
        _error =
            'Maximum number of devices (${CloudDeviceService.maxDevices}) reached. '
            'Remove an existing device first.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed: $e';
        _loading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _deviceName() {
    if (Platform.isAndroid) return 'Android Device';
    if (Platform.isIOS) return 'iPhone';
    return 'Mobile Device';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add This Device'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : _step == 1
              ? _buildStep1()
              : _buildStep2(),
      actions: _loading ? [] : _buildActions(),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your email to receive a one-time verification code.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendCode(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A 6-digit code was sent to ${_emailCtrl.text.trim()}.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeCtrl,
          decoration: const InputDecoration(
            labelText: '6-digit code',
            prefixIcon: Icon(Icons.lock_outline),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              _secondsLeft > 0 ? Icons.timer_outlined : Icons.timer_off_outlined,
              size: 16,
              color: _secondsLeft > 0
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              _secondsLeft > 0
                  ? 'Code expires in $_countdownLabel'
                  : 'Code expired',
              style: TextStyle(
                fontSize: 13,
                color: _secondsLeft > 0
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: TextStyle(
                color: Theme.of(context).colorScheme.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      if (_step == 1)
        FilledButton(
          onPressed: _sendCode,
          child: const Text('Send Code'),
        )
      else ...[
        TextButton(
          onPressed: () {
            _countdownTimer?.cancel();
            setState(() {
              _step = 1;
              _error = null;
              _codeCtrl.clear();
            });
          },
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: _secondsLeft > 0 ? _verify : null,
          child: const Text('Verify'),
        ),
      ],
    ];
  }
}
