import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pigeon/api_shims.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OEM battery guidance
// ─────────────────────────────────────────────────────────────────────────────

/// Manufacturer-specific battery optimisation instructions.
/// Detected via [MethodChannel] `device_info` — falls back to generic.
class OemBatteryGuide {
  const OemBatteryGuide._({
    required this.manufacturer,
    required this.autostartLabel,
    required this.autostartPath,
    required this.batteryPath,
    required this.instructions,
  });

  final String manufacturer;
  final String? autostartLabel;
  final String? autostartPath;
  final String batteryPath;
  final String instructions;

  static const _channel = MethodChannel('kiko/device_info');

  /// Detects the device manufacturer and returns the matching guide.
  /// Falls back to a generic guide if the manufacturer is unknown or the
  /// platform channel is unavailable (test/desktop environments).
  static Future<OemBatteryGuide> detect() async {
    String? manufacturer;
    try {
      manufacturer =
          await _channel.invokeMethod<String>('getManufacturer');
    } catch (_) {
      // Platform channel not available (test or desktop) — use generic.
    }
    return _guideFor(manufacturer);
  }

  static OemBatteryGuide _guideFor(String? manufacturer) {
    final m = (manufacturer ?? '').toLowerCase();

    // Samsung
    if (m.contains('samsung')) {
      return const OemBatteryGuide._(
        manufacturer: 'Samsung',
        autostartLabel: null,
        autostartPath: null,
        batteryPath: 'Settings → Apps → Kiko → Battery → Unrestricted',
        instructions: '1. Open Settings → Apps\n'
            '2. Find and tap Kiko\n'
            '3. Tap Battery\n'
            '4. Select "Unrestricted"',
      );
    }

    // Xiaomi / Redmi / Poco
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
      return const OemBatteryGuide._(
        manufacturer: 'Xiaomi',
        autostartLabel: 'Autostart',
        autostartPath:
            'Settings → Apps → Permissions → Autostart → Enable Kiko',
        batteryPath: 'Settings → Apps → Kiko → Battery saver → No restrictions',
        instructions: '1. Open Settings → Apps → Permissions → Autostart\n'
            '2. Find Kiko and enable the toggle\n'
            '3. Go back to Settings → Apps → Kiko\n'
            '4. Tap "Battery saver"\n'
            '5. Select "No restrictions"',
      );
    }

    // Tecno (Transsion)
    if (m.contains('tecno') || m.contains('transsion')) {
      return const OemBatteryGuide._(
        manufacturer: 'Tecno',
        autostartLabel: 'Autostart Manager',
        autostartPath: 'Phone Manager → Autostart Manager → Enable Kiko',
        batteryPath: 'Settings → Battery → Kiko → Don\'t optimise',
        instructions: '1. Open Phone Manager (or HiOS Security)\n'
            '2. Tap Autostart Manager\n'
            '3. Find Kiko and enable it\n'
            '4. Open Settings → Battery\n'
            '5. Find Kiko and select "Don\'t optimise" (or "Unrestricted")',
      );
    }

    // Infinix (also Transsion)
    if (m.contains('infinix') || m.contains('infinix mobility')) {
      return const OemBatteryGuide._(
        manufacturer: 'Infinix',
        autostartLabel: 'Autostart Management',
        autostartPath: 'XOS Security → Autostart Management → Enable Kiko',
        batteryPath: 'Settings → Battery → Kiko → Don\'t optimise',
        instructions: '1. Open XOS Security\n'
            '2. Tap Autostart Management\n'
            '3. Find Kiko and enable it\n'
            '4. Open Settings → Battery\n'
            '5. Find Kiko and select "Don\'t optimise" (or "Unrestricted")',
      );
    }

    // Generic fallback
    return const OemBatteryGuide._(
      manufacturer: 'Unknown',
      autostartLabel: 'Autostart',
      autostartPath: 'Settings → Apps → Permissions → Autostart → Enable Kiko',
      batteryPath: 'Settings → Apps → Kiko → Battery → Unrestricted',
      instructions: '1. Open Settings → Apps → Kiko\n'
          '2. Tap Battery\n'
          '3. Select "Unrestricted" or "Don\'t optimise"\n'
          '4. If your device has an Autostart manager, enable Kiko there too',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission step descriptor
// ─────────────────────────────────────────────────────────────────────────────

enum _PermissionId {
  callScreening,
  overlay,
  callLog,
  phoneState,
  notifications,
  batteryExemption,
}

class _PermissionStep {
  const _PermissionStep({
    required this.id,
    required this.icon,
    required this.title,
    required this.rationale,
    required this.buttonLabel,
  });

  final _PermissionId id;
  final IconData icon;
  final String title;
  final String rationale;
  final String buttonLabel;
}

const _steps = <_PermissionStep>[
  _PermissionStep(
    id: _PermissionId.callScreening,
    icon: Icons.call_outlined,
    title: 'Call Screening',
    rationale:
        'Allows Kiko to identify callers during incoming calls and show '
        'lead info on screen — even when the app is closed.',
    buttonLabel: 'Grant role',
  ),
  _PermissionStep(
    id: _PermissionId.overlay,
    icon: Icons.layers_outlined,
    title: 'Display Over Other Apps',
    rationale:
        'Required to show the caller overlay window during an incoming call '
        'when the screen is locked or another app is open.',
    buttonLabel: 'Open settings',
  ),
  _PermissionStep(
    id: _PermissionId.callLog,
    icon: Icons.history_outlined,
    title: 'Call Log Access',
    rationale:
        'Used to read your call history so Kiko can link calls to leads and '
        'show the Recent Calls screen.',
    buttonLabel: 'Allow',
  ),
  _PermissionStep(
    id: _PermissionId.phoneState,
    icon: Icons.phone_android_outlined,
    title: 'Phone State',
    rationale:
        'Lets Kiko detect when a call starts or ends so it can trigger the '
        'post-call status update dialog.',
    buttonLabel: 'Allow',
  ),
  _PermissionStep(
    id: _PermissionId.notifications,
    icon: Icons.notifications_outlined,
    title: 'Notifications',
    rationale:
        'Needed to show reminders and call-plan alerts as Android '
        'notifications (Android 13 and above).',
    buttonLabel: 'Allow',
  ),
  _PermissionStep(
    id: _PermissionId.batteryExemption,
    icon: Icons.battery_charging_full_outlined,
    title: 'Battery Optimisation',
    rationale:
        'Some devices aggressively kill background services. Exempting Kiko '
        'from battery optimisation keeps the call overlay reliable.',
    buttonLabel: 'Exempt Kiko',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// PermissionsWizardScreen
// ─────────────────────────────────────────────────────────────────────────────

class PermissionsWizardScreen extends ConsumerStatefulWidget {
  const PermissionsWizardScreen({super.key});

  @override
  ConsumerState<PermissionsWizardScreen> createState() =>
      _PermissionsWizardScreenState();
}

class _PermissionsWizardScreenState
    extends ConsumerState<PermissionsWizardScreen> {
  int _currentStep = 0;
  bool _requesting = false;

  // OEM battery guide loaded when the battery step is reached.
  OemBatteryGuide? _batteryGuide;
  bool _batteryGuideLoading = false;
  bool _showOemInstructions = false;

  _PermissionStep get _step => _steps[_currentStep];
  bool get _isLast => _currentStep == _steps.length - 1;

  void _advance() {
    if (_isLast) {
      // Wizard complete — go back (or to home).
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } else {
      setState(() => _currentStep++);
    }
  }

  Future<void> _onGrant() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      await _requestPermission(_step.id);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
    // Move to next step regardless of outcome — user can skip.
    _advance();
  }

  Future<void> _requestPermission(_PermissionId id) async {
    final api = PermissionsApiShim.instance;
    final permissionKey = _permissionKey(id);

    if (id == _PermissionId.batteryExemption) {
      // Battery exemption opens settings; no boolean return.
      await api.openAppSettings();
      return;
    }

    await api.requestPermission(permissionKey);
  }

  String _permissionKey(_PermissionId id) {
    switch (id) {
      case _PermissionId.callScreening:
        return 'call_screening';
      case _PermissionId.overlay:
        return 'overlay';
      case _PermissionId.callLog:
        return 'call_log';
      case _PermissionId.phoneState:
        return 'phone_state';
      case _PermissionId.notifications:
        return 'notifications';
      case _PermissionId.batteryExemption:
        return 'battery_exemption';
    }
  }

  /// Loads the OEM-specific battery guide when the battery step is shown.
  Future<void> _maybeLoadBatteryGuide() async {
    if (_step.id != _PermissionId.batteryExemption) return;
    if (_batteryGuide != null || _batteryGuideLoading) return;

    setState(() => _batteryGuideLoading = true);
    try {
      final guide = await OemBatteryGuide.detect();
      if (mounted) setState(() => _batteryGuide = guide);
    } finally {
      if (mounted) setState(() => _batteryGuideLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Load battery guide when entering that step.
    if (_step.id == _PermissionId.batteryExemption &&
        _batteryGuide == null &&
        !_batteryGuideLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeLoadBatteryGuide();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Step progress indicator ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: List.generate(_steps.length, (i) {
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isDone
                          ? cs.primary
                          : isActive
                              ? cs.primary.withValues(alpha: 0.6)
                              : cs.outlineVariant,
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of ${_steps.length}',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),

          const SizedBox(height: 8),

          // ── Step content ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _step.icon,
                    size: 72,
                    color: cs.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _step.title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _step.rationale,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),

                  // ── OEM battery instructions ──────────────────────────────
                  if (_step.id == _PermissionId.batteryExemption) ...[
                    const SizedBox(height: 16),
                    if (_batteryGuideLoading)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_batteryGuide != null) ...[
                      if (_batteryGuide!.manufacturer != 'Unknown') ...[
                        Text(
                          'Device detected: ${_batteryGuide!.manufacturer}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _showOemInstructions = !_showOemInstructions),
                        icon: Icon(_showOemInstructions
                            ? Icons.expand_less
                            : Icons.expand_more),
                        label: Text(_showOemInstructions
                            ? 'Hide device-specific instructions'
                            : 'Show device-specific instructions'),
                      ),
                      if (_showOemInstructions) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: cs.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_batteryGuide!.autostartLabel != null) ...[
                                Text(
                                  '${_batteryGuide!.autostartLabel}:',
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _batteryGuide!.autostartPath!,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                'Battery:',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _batteryGuide!.batteryPath,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Steps:',
                                style: theme.textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _batteryGuide!.instructions,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _requesting ? null : _onGrant,
                    child: _requesting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step.buttonLabel),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _advance,
                    child: Text(_isLast ? 'Done' : 'Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
