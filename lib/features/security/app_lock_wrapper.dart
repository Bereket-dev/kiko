import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'lock_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppLockWrapper
// ─────────────────────────────────────────────────────────────────────────────
//
// Wraps the entire app widget tree and shows a [LockScreen] overlay whenever:
//   • The app returns from background and auto-lock timeout has expired.
//   • The app was just launched and a PIN is set.
//
// Auto-lock logic:
//   • When the app goes to background, record the timestamp.
//   • On resume, compare elapsed time to [AppSettings.autoLockTimeoutMs].
//   • A timeout of 0 ms means "lock immediately on background" (default).
//   • If no PIN is set, the wrapper is transparent (passes through).
//
// The [LockScreen] is shown as a full-screen overlay using [Stack] so the
// Navigator state (and all provider state) is preserved beneath it.
// ─────────────────────────────────────────────────────────────────────────────

class AppLockWrapper extends ConsumerStatefulWidget {
  const AppLockWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _locked = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Listen for programmatic "Lock now" requests (e.g. from settings screen).
    appLockNotifier.addListener(_onExternalLockRequest);
    // Check if we should lock on startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLock();
    });
  }

  @override
  void dispose() {
    appLockNotifier.removeListener(_onExternalLockRequest);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onExternalLockRequest() {
    if (appLockNotifier.value && mounted) {
      setState(() => _locked = true);
      // Reset the notifier so it can fire again next time.
      appLockNotifier.value = false;
    }
  }

  Future<void> _checkInitialLock() async {
    final settings = ref.read(appSettingsProvider);
    final hasPinSet = await settings.hasPinSet();
    if (hasPinSet && mounted) {
      setState(() => _locked = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Record the time the app went to background.
        _backgroundedAt = DateTime.now();

      case AppLifecycleState.resumed:
        _checkAutoLock();

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkAutoLock() async {
    // If already locked, nothing to do.
    if (_locked) return;

    final settings = ref.read(appSettingsProvider);
    final hasPinSet = await settings.hasPinSet();
    if (!hasPinSet) return;

    final timeoutMs = settings.autoLockTimeoutMs;

    if (_backgroundedAt == null) {
      // No recorded background time — lock for safety.
      if (mounted) setState(() => _locked = true);
      return;
    }

    final elapsed = DateTime.now().difference(_backgroundedAt!).inMilliseconds;
    if (elapsed >= timeoutMs) {
      if (mounted) setState(() => _locked = true);
    }
    _backgroundedAt = null;
  }

  void _onAuthenticated() {
    if (mounted) {
      setState(() {
        _locked = false;
        _backgroundedAt = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          LockScreen(
            key: const ValueKey('lock_screen'),
            onAuthenticated: _onAuthenticated,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// lockNow — programmatically lock the app (e.g. from settings)
// ─────────────────────────────────────────────────────────────────────────────

/// A [ValueNotifier] that the settings screen can flip to programmatically
/// trigger a lock. [AppLockWrapper] listens and sets [_locked] accordingly.
///
/// Usage:
///   appLockNotifier.value = true;
final appLockNotifier = ValueNotifier<bool>(false);
