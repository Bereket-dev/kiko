import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PinSetupScreen
// ─────────────────────────────────────────────────────────────────────────────
//
// Two-step PIN setup:
//   Step 1 — user enters a new 4-digit PIN.
//   Step 2 — user confirms by re-entering the same PIN.
//
// [onComplete] is called after successful setup (or skip).
// [allowSkip]  when true, shows a "Skip" action (first-launch flow).
// [isChanging] when true, the title says "Change PIN" instead of "Set up PIN".
// ─────────────────────────────────────────────────────────────────────────────

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({
    super.key,
    required this.onComplete,
    this.allowSkip = false,
    this.isChanging = false,
  });

  final VoidCallback onComplete;
  final bool allowSkip;
  final bool isChanging;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final List<String> _entered = [];
  String? _firstPin;
  bool _isConfirmStep = false;
  String? _errorMessage;
  bool _isSaving = false;

  String get _title {
    if (widget.isChanging) return _isConfirmStep ? 'Confirm new PIN' : 'Enter new PIN';
    return _isConfirmStep ? 'Confirm PIN' : 'Set up PIN';
  }

  String get _subtitle {
    if (_isConfirmStep) return 'Re-enter your PIN to confirm';
    return 'Choose a 4-digit PIN to protect your data';
  }

  void _onDigitPressed(String digit) {
    if (_isSaving) return;
    if (_entered.length >= 4) return;
    setState(() {
      _entered.add(digit);
      _errorMessage = null;
    });
    if (_entered.length == 4) {
      _onComplete();
    }
  }

  void _onBackspace() {
    if (_isSaving || _entered.isEmpty) return;
    setState(() {
      _entered.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _onComplete() async {
    final pin = _entered.join();

    if (!_isConfirmStep) {
      // Step 1 → move to confirmation
      setState(() {
        _firstPin = pin;
        _entered.clear();
        _isConfirmStep = true;
      });
      return;
    }

    // Step 2 — confirmation step
    if (pin != _firstPin) {
      HapticFeedback.vibrate();
      setState(() {
        _entered.clear();
        _isConfirmStep = false;
        _firstPin = null;
        _errorMessage = "PINs didn't match. Please try again.";
      });
      return;
    }

    // Save PIN
    setState(() => _isSaving = true);
    try {
      await ref.read(pinServiceProvider).setPin(pin);
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _entered.clear();
          _isConfirmStep = false;
          _firstPin = null;
          _errorMessage = 'Failed to save PIN. Please try again.';
        });
      }
    }
  }

  void _onSkip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (widget.allowSkip)
            TextButton(
              onPressed: _isSaving ? null : _onSkip,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            Icon(
              _isConfirmStep
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_outlined,
              size: 56,
              color: cs.primary,
            ),
            const SizedBox(height: 16),

            Text(
              _title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 32),

            // PIN dots
            _PinDots(length: _entered.length),

            const SizedBox(height: 16),

            // Error message
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _errorMessage != null
                  ? Padding(
                      key: ValueKey(_errorMessage),
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.error),
                      ),
                    )
                  : const SizedBox(height: 20, key: ValueKey('empty')),
            ),

            if (_isSaving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),

            const Spacer(flex: 1),

            // Numeric keypad
            _NumericKeypad(
              onDigit: _isSaving ? null : _onDigitPressed,
              onBackspace: _isSaving ? null : _onBackspace,
            ),

            const Spacer(flex: 1),

            // Step indicator
            _StepIndicator(step: _isConfirmStep ? 2 : 1),
            const SizedBox(height: 24),
          ],
        ),
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
// _NumericKeypad (setup version — no biometric button)
// ─────────────────────────────────────────────────────────────────────────────

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String>? onDigit;
  final VoidCallback? onBackspace;

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
        // Bottom row: empty | 0 | backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88, height: 72), // placeholder
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

// ─────────────────────────────────────────────────────────────────────────────
// _StepIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i + 1 == step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active ? cs.primary : cs.outlineVariant,
          ),
        );
      }),
    );
  }
}
