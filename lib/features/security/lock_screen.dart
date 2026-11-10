import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/providers.dart';
import 'pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LockScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Shown whenever the app auto-locks (see AppLockWrapper).
//
// Provides:
//   • 4-digit PIN entry via custom numeric keypad.
//   • Biometric (fingerprint / face) authentication via local_auth.
//   • Lockout UX with countdown timer.
//   • "Forgot PIN" action (stubbed; Phase 9 wires email OTP).
//
// [onAuthenticated] is called when the user is successfully verified.
// ─────────────────────────────────────────────────────────────────────────────

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({
    super.key,
    required this.onAuthenticated,
    this.showForgotPin = true,
  });

  final VoidCallback onAuthenticated;
  final bool showForgotPin;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final List<String> _enteredDigits = [];

  String? _errorMessage;
  bool _isBusy = false;

  // Lockout countdown
  LockoutState _lockout = LockoutState.none;
  String? _lockoutMessage;

  @override
  void initState() {
    super.initState();
    _updateLockout();
    // Try biometric automatically on first display.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  void _updateLockout() {
    final pinService = ref.read(pinServiceProvider);
    setState(() {
      _lockout = pinService.lockoutState;
      _lockoutMessage = _buildLockoutMessage(_lockout);
    });
  }

  String? _buildLockoutMessage(LockoutState state) {
    if (!state.isLockedOut) return null;
    final remaining = state.remainingLockout;
    final secs = remaining.inSeconds;
    if (secs >= 60) {
      return 'Too many attempts. Try again in ${remaining.inMinutes}m ${secs % 60}s';
    }
    return 'Too many attempts. Try again in ${secs}s';
  }

  // ── Biometric ─────────────────────────────────────────────────────────────

  Future<void> _tryBiometric() async {
    if (_isBusy) return;
    final canUseBio = await _canAuthWithBiometric();
    if (!canUseBio || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Kiko',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN fallback inside system dialog
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        ref.read(pinServiceProvider).resetLockout();
        widget.onAuthenticated();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool> _canAuthWithBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  // ── PIN entry ─────────────────────────────────────────────────────────────

  void _onDigitPressed(String digit) {
    if (_isBusy || _lockout.isLockedOut) return;
    if (_enteredDigits.length >= 4) return;
    setState(() {
      _enteredDigits.add(digit);
      _errorMessage = null;
    });
    if (_enteredDigits.length == 4) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_isBusy || _enteredDigits.isEmpty) return;
    setState(() {
      _enteredDigits.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _submitPin() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final pin = _enteredDigits.join();
    final pinService = ref.read(pinServiceProvider);
    final response = await pinService.verifyPin(pin);

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      _enteredDigits.clear();
      _lockout = response.lockoutState;
    });

    switch (response.result) {
      case PinVerifyResult.success:
        widget.onAuthenticated();

      case PinVerifyResult.wrongPin:
        final left = response.attemptsRemaining ?? 0;
        setState(() {
          _errorMessage = left > 0
              ? 'Incorrect PIN. $left attempt${left == 1 ? '' : 's'} remaining.'
              : 'Incorrect PIN.';
          _lockoutMessage = _buildLockoutMessage(_lockout);
        });
        HapticFeedback.vibrate();
        // Start countdown refresh if now locked out
        if (_lockout.isLockedOut) _startLockoutRefresh();

      case PinVerifyResult.lockedOut:
        setState(() => _lockoutMessage = _buildLockoutMessage(_lockout));
        _startLockoutRefresh();

      case PinVerifyResult.noPinSet:
        // Should not happen on lock screen — treat as bypass.
        widget.onAuthenticated();
    }
  }

  // ── Lockout countdown refresh ─────────────────────────────────────────────

  void _startLockoutRefresh() {
    Future<void> refresh() async {
      while (mounted && _lockout.isLockedOut) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() => _lockoutMessage = _buildLockoutMessage(_lockout));
      }
      if (mounted) setState(() => _lockoutMessage = null);
    }

    refresh();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // App icon / lock icon
            Icon(Icons.lock_outline_rounded, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Kiko is locked',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to continue',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),

            const SizedBox(height: 32),

            // PIN dots
            _PinDots(length: _enteredDigits.length),

            const SizedBox(height: 16),

            // Error / lockout message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _lockout.isLockedOut
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _lockoutMessage ?? '',
                        key: ValueKey(_lockoutMessage),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.error),
                      ),
                    )
                  : (_errorMessage != null
                      ? Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            key: ValueKey(_errorMessage),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.error),
                          ),
                        )
                      : const SizedBox(height: 20, key: ValueKey('empty'))),
            ),

            const Spacer(flex: 1),

            // Numeric keypad
            _NumericKeypad(
              onDigit: _lockout.isLockedOut ? null : _onDigitPressed,
              onBackspace: _lockout.isLockedOut ? null : _onBackspace,
              onBiometric: _tryBiometric,
              isBusy: _isBusy,
            ),

            const Spacer(flex: 1),

            // Forgot PIN
            if (widget.showForgotPin)
              TextButton(
                onPressed: _isBusy ? null : _onForgotPin,
                child: const Text('Forgot PIN'),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onForgotPin() {
    // Phase 9 will wire email OTP here. For now show info dialog.
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Forgot PIN?'),
        content: const Text(
          'PIN reset via email OTP will be available after account setup '
          '(Phase 9). For now, please uninstall and reinstall the app to '
          'reset all data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PinDots
// ─────────────────────────────────────────────────────────────────────────────

class _PinDots extends StatelessWidget {
  const _PinDots({required this.length});
  final int length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? cs.primary : Colors.transparent,
            border: Border.all(
              color: filled ? cs.primary : cs.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NumericKeypad
// ─────────────────────────────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
    required this.isBusy,
  });

  final ValueChanged<String>? onDigit;
  final VoidCallback? onBackspace;
  final VoidCallback? onBiometric;
  final bool isBusy;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._rows.map(
          (row) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map((d) => _KeypadButton(
                      label: d,
                      onPressed: onDigit != null
                          ? () => onDigit!(d)
                          : null,
                    ))
                .toList(),
          ),
        ),
        // Bottom row: biometric | 0 | backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _KeypadButton(
              icon: Icons.fingerprint_rounded,
              onPressed: isBusy ? null : onBiometric,
            ),
            _KeypadButton(
              label: '0',
              onPressed: onDigit != null ? () => onDigit!('0') : null,
            ),
            _KeypadButton(
              icon: Icons.backspace_outlined,
              onPressed: onBackspace,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.onPressed,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 88,
      height: 72,
      child: TextButton(
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: theme.colorScheme.onSurface,
        ),
        onPressed: onPressed,
        child: label != null
            ? Text(
                label!,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              )
            : Icon(icon, size: 28),
      ),
    );
  }
}
