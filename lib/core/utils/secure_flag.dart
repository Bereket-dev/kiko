import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SecureFlag — Android FLAG_SECURE helper (optional screenshot protection)
// ─────────────────────────────────────────────────────────────────────────────

class SecureFlag {
  SecureFlag._();

  static const _channel = MethodChannel('com.bereket.kiko/secure_flag');

  /// Enable or disable FLAG_SECURE on the current activity window.
  static Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecureFlag', {'enabled': enabled});
    } on PlatformException {
      // No-op on unsupported platforms / missing plugin wiring.
    } on MissingPluginException {
      // Expected on non-Android or before native channel is registered.
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SecureFlagScope
// ─────────────────────────────────────────────────────────────────────────────
//
// Wraps a subtree and sets FLAG_SECURE while it is mounted (when [enabled]).
// Use this around sensitive screens (lead detail, add/edit) to prevent
// screenshots when the user has enabled the setting.
//
// Usage:
//   return SecureFlagScope(
//     enabled: settings.flagSecureEnabled,
//     child: Scaffold(...),
//   );
// ─────────────────────────────────────────────────────────────────────────────

class SecureFlagScope extends StatefulWidget {
  const SecureFlagScope({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<SecureFlagScope> createState() => _SecureFlagScopeState();
}

class _SecureFlagScopeState extends State<SecureFlagScope> {
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      SecureFlag.setEnabled(true);
    }
  }

  @override
  void didUpdateWidget(SecureFlagScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      SecureFlag.setEnabled(widget.enabled);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      // Restore normal mode when leaving the sensitive screen.
      SecureFlag.setEnabled(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
