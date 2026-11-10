import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:io' show Platform;

import '../../app/providers.dart';
import '../security/pin_setup_screen.dart';
import '../settings/permissions_wizard_screen.dart';
import 'cloud_auth_service.dart';
import 'cloud_backup_service.dart';
import 'cloud_device_service.dart';
import 'e2e_key_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step indices
// ─────────────────────────────────────────────────────────────────────────────

const _kStepLanguage = 0;
const _kStepDone = 5;
const _kTotalSteps = 6;

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = _kStepLanguage;

  // Lazily-created service instances (wired to providers in task 10).
  late final CloudAuthService _authService = CloudAuthService();
  late final E2EKeyService _keyService =
      E2EKeyService(ref.read(appSettingsProvider));

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _advance() {
    final next = _currentStep + 1;
    if (next >= _kTotalSteps) return;
    setState(() => _currentStep = next);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable Android back gesture on early steps (Language, Account, Recovery).
      canPop: _currentStep >= 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _LanguageStep(onAdvance: _advance),
                    _AccountStep(
                      authService: _authService,
                      onAdvance: _advance,
                    ),
                    _RecoveryStep(
                      authService: _authService,
                      keyService: _keyService,
                      onAdvance: _advance,
                    ),
                    _PinStep(onAdvance: _advance),
                    _PermissionsStep(onAdvance: _advance),
                    _DoneStep(onComplete: widget.onComplete),
                  ],
                ),
              ),
              if (_currentStep < _kStepDone)
                _StepDots(
                  total: _kTotalSteps - 1, // hide Done from dot count
                  current: _currentStep,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Language
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({required this.onAdvance});

  final VoidCallback onAdvance;

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final settings = ref.read(appSettingsProvider);
    await settings.setLanguage(code);
    ref.read(localePrefProvider.notifier).state = code;
    onAdvance();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Choose Language',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ቋንቋ ይምረጡ',
            style: theme.textTheme.titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _LangButton(
            label: 'English',
            onPressed: () => _select(context, ref, 'en'),
          ),
          const SizedBox(height: 16),
          _LangButton(
            label: 'አማርኛ (Amharic)',
            onPressed: () => _select(context, ref, 'am'),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          textStyle: Theme.of(context).textTheme.titleMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Account (Create / Sign In)
// ─────────────────────────────────────────────────────────────────────────────

class _AccountStep extends ConsumerStatefulWidget {
  const _AccountStep({
    required this.authService,
    required this.onAdvance,
  });

  final CloudAuthService authService;
  final VoidCallback onAdvance;

  @override
  ConsumerState<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<_AccountStep>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  // Shown after successful sign-up, waiting for email verification.
  bool _awaitingVerification = false;

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  // ── Create Account ─────────────────────────────────────────────────────────

  Future<void> _onCreateAccount() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authService.signUp(email, password);
      await ref.read(appSettingsProvider).setCloudUserEmail(email);
      if (mounted) setState(() => _awaitingVerification = true);
    } on CloudAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  Future<void> _onSignIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authService.signIn(email, password);
      await ref.read(appSettingsProvider).setCloudUserEmail(email);
      // signIn() throws if email not verified, so reaching here means verified.
      if (mounted) widget.onAdvance();
    } on CloudAuthException catch (e) {
      if (mounted) {
        if (e.code == 'email-not-verified') {
          setState(() {
            _awaitingVerification = true;
            _error = null;
          });
        } else {
          setState(() => _error = e.message);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Resend verification ────────────────────────────────────────────────────

  Future<void> _onResend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.sendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent.')),
        );
      }
    } on CloudAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Check if verified now ──────────────────────────────────────────────────

  Future<void> _onCheckVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Reload the Firebase user to get fresh emailVerified status.
      await widget.authService.currentUser?.reload();
      if (widget.authService.isEmailVerified) {
        final email = widget.authService.currentUser?.email;
        if (email != null) {
          await ref.read(appSettingsProvider).setCloudUserEmail(email);
        }
        if (mounted) widget.onAdvance();
      } else {
        if (mounted) {
          setState(() =>
              _error = 'Email not verified yet. Please check your inbox.');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to check verification.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_awaitingVerification) {
      return _VerificationWaiting(
        email: _emailCtrl.text.trim(),
        loading: _loading,
        error: _error,
        onResend: _onResend,
        onCheckVerification: _onCheckVerification,
        onBack: () => setState(() {
          _awaitingVerification = false;
          _error = null;
        }),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.cloud_outlined, size: 56, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Your Account',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in or create an account to enable cloud backup.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── Tabs ───────────────────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            onTap: (_) => _clearError(),
            tabs: const [
              Tab(text: 'Create Account'),
              Tab(text: 'Sign In'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Email field ────────────────────────────────────────────────────
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            onChanged: (_) => _clearError(),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Password field ─────────────────────────────────────────────────
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearError(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          // ── Confirm Password (Create only) ─────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: ListenableBuilder(
              listenable: _tabController,
              builder: (context, _) {
                if (_tabController.index != 0) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _clearError(),
                      onSubmitted: (_) => _onCreateAccount(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Error ──────────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 24),

          // ── Action button ──────────────────────────────────────────────────
          ListenableBuilder(
            listenable: _tabController,
            builder: (context, _) {
              final isCreate = _tabController.index == 0;
              return FilledButton(
                onPressed: _loading
                    ? null
                    : isCreate
                        ? _onCreateAccount
                        : _onSignIn,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isCreate ? 'Create Account' : 'Sign In'),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Awaiting-verification sub-widget
// ─────────────────────────────────────────────────────────────────────────────

class _VerificationWaiting extends StatelessWidget {
  const _VerificationWaiting({
    required this.email,
    required this.loading,
    required this.error,
    required this.onResend,
    required this.onCheckVerification,
    required this.onBack,
  });

  final String email;
  final bool loading;
  final String? error;
  final VoidCallback onResend;
  final VoidCallback onCheckVerification;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_unread_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Check Your Email',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'A verification link has been sent to\n$email\n\nOpen it, then come back and tap Continue.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: loading ? null : onCheckVerification,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: loading ? null : onResend,
            child: const Text('Resend Email'),
          ),
          TextButton(
            onPressed: onBack,
            child: const Text('← Back'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Consent & Recovery Code
// ─────────────────────────────────────────────────────────────────────────────

class _RecoveryStep extends ConsumerStatefulWidget {
  const _RecoveryStep({
    required this.authService,
    required this.keyService,
    required this.onAdvance,
  });

  final CloudAuthService authService;
  final E2EKeyService keyService;
  final VoidCallback onAdvance;

  @override
  ConsumerState<_RecoveryStep> createState() => _RecoveryStepState();
}

class _RecoveryStepState extends ConsumerState<_RecoveryStep> {
  /// `true` when Firestore already has a wrapped key (second-device path).
  bool _isRestore = false;
  String? _recoveryCode;
  final _restoreCodeCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _loading = false;
  bool _initializing = true;
  String? _error;
  bool _savedChecked = false;

  /// OTP stage for second device when another device is already registered.
  bool _needsOtp = false;
  String? _otpToken;
  bool _otpSent = false;

  late final CloudDeviceService _deviceService =
      CloudDeviceService(ref.read(appSettingsProvider));

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _restoreCodeCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final userId = widget.authService.currentUser?.uid;
      if (userId == null) throw Exception('Not signed in.');

      final existing =
          await widget.keyService.fetchWrappedKeyFromFirestore(userId);
      if (existing != null) {
        // Second device — unlock with existing recovery code.
        final devices = await _deviceService.listDevices(userId);
        if (!mounted) return;
        setState(() {
          _isRestore = true;
          _needsOtp = devices.isNotEmpty;
          _initializing = false;
        });
        return;
      }

      // First device — generate a fresh recovery code.
      final code = await widget.keyService.generateRecoveryCode();
      if (!mounted) return;
      setState(() {
        _isRestore = false;
        _recoveryCode = code;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to prepare encryption setup.\n$e';
        _initializing = false;
      });
    }
  }

  Future<void> _onCopy() async {
    if (_recoveryCode == null) return;
    await Clipboard.setData(ClipboardData(text: _recoveryCode!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery code copied to clipboard.')),
      );
    }
  }

  Future<void> _registerThisDevice(String userId) async {
    final settings = ref.read(appSettingsProvider);
    final deviceId = await settings.getOrCreateDeviceId();
    final deviceName = Platform.isAndroid
        ? 'Android device'
        : (Platform.isIOS ? 'iOS device' : 'Device');
    try {
      await _deviceService.registerDevice(
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
      );
    } on DeviceAlreadyRegisteredException {
      // Already registered — fine.
    }
    final devices = await _deviceService.listDevices(userId);
    await settings.setDevicesRegistered(devices.length);
  }

  Future<void> _sendOtp() async {
    final email = widget.authService.currentUser?.email;
    if (email == null) {
      setState(() => _error = 'No email on the signed-in account.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _deviceService.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _otpToken = token;
        _otpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to $email')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to send OTP.\n$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onContinueFirstDevice() async {
    if (_recoveryCode == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final settings = ref.read(appSettingsProvider);
      final userId = widget.authService.currentUser?.uid;
      if (userId == null) throw Exception('Not signed in.');

      final dataKey = await widget.keyService.getOrCreateDataKey();
      final wrapped = await widget.keyService
          .wrapKeyWithRecoveryCode(dataKey, _recoveryCode!);
      await widget.keyService.storeWrappedKeyInFirestore(userId, wrapped);
      await widget.keyService.saveRecoveryCodeHashLocally(_recoveryCode!);
      await settings.setBackupEnabled(true);
      await _registerThisDevice(userId);
      await CloudBackupService.schedulePeriodicBackup(
        wifiOnly: settings.backupWifiOnly,
      );

      if (mounted) widget.onAdvance();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _error = 'Failed to protect your data. Please try again.\n$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onContinueRestore() async {
    final code = _restoreCodeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your recovery code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final settings = ref.read(appSettingsProvider);
      final userId = widget.authService.currentUser?.uid;
      if (userId == null) throw Exception('Not signed in.');

      if (_needsOtp) {
        if (!_otpSent || _otpToken == null) {
          setState(() => _error = 'Send and enter the email OTP first.');
          return;
        }
        final otpCode = _otpCtrl.text.trim();
        if (otpCode.isEmpty) {
          setState(() => _error = 'Enter the OTP from your email.');
          return;
        }
        await _deviceService.verifyOtp(
          otpToken: _otpToken!,
          otpCode: otpCode,
        );
      }

      final wrapped =
          await widget.keyService.fetchWrappedKeyFromFirestore(userId);
      if (wrapped == null) {
        throw Exception('No wrapped key found for this account.');
      }

      final dataKey =
          await widget.keyService.unwrapKeyWithRecoveryCode(wrapped, code);
      await widget.keyService.storeDataKey(dataKey);
      await widget.keyService.saveRecoveryCodeHashLocally(code);
      await settings.setBackupEnabled(true);
      await _registerThisDevice(userId);
      await CloudBackupService.schedulePeriodicBackup(
        wifiOnly: settings.backupWifiOnly,
      );

      if (mounted) widget.onAdvance();
    } on InvalidRecoveryCodeException {
      if (mounted) setState(() => _error = 'Incorrect recovery code.');
    } on InvalidOtpException {
      if (mounted) setState(() => _error = 'Invalid or expired OTP.');
    } on MaxDevicesException {
      if (mounted) {
        setState(() => _error =
            'Maximum of ${CloudDeviceService.maxDevices} devices reached. '
            'Remove a device from another copy of Kiko, then try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to unlock this account.\n$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isRestore) {
      return _buildRestore(theme, cs);
    }
    return _buildFirstDevice(theme, cs);
  }

  Widget _buildFirstDevice(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.shield_outlined, size: 56, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Protect Your Data',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Kiko uses end-to-end encryption. Your data is encrypted on this '
            'device before it is uploaded, so only you can read it.\n\n'
            'Save the recovery code below in a safe place. If you lose access '
            'to this device, you will need it to restore your data.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_error != null && _recoveryCode == null)
            Column(
              children: [
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _bootstrap,
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (_recoveryCode != null)
            _RecoveryCodeBox(
              code: _recoveryCode!,
              onCopy: _onCopy,
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _savedChecked,
                onChanged: _recoveryCode == null
                    ? null
                    : (v) => setState(() => _savedChecked = v ?? false),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _recoveryCode == null
                      ? null
                      : () => setState(() => _savedChecked = !_savedChecked),
                  child: Text(
                    'I have saved my recovery code safely',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null && _recoveryCode != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_savedChecked && !_loading && _recoveryCode != null)
                ? _onContinueFirstDevice
                : null,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRestore(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(Icons.lock_open_outlined, size: 56, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Unlock Your Data',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This account already has an encrypted backup key. Enter the '
            'recovery code you saved when you first set up Kiko.'
            '${_needsOtp ? '\n\nBecause another device is registered, we will '
                'also email you a one-time code.' : ''}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _restoreCodeCtrl,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Recovery code',
              hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.vpn_key_outlined),
            ),
          ),
          if (_needsOtp) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Email OTP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: Text(_otpSent ? 'Resend' : 'Send OTP'),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _onContinueRestore,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unlock & Continue'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recovery code display widget
// ─────────────────────────────────────────────────────────────────────────────

class _RecoveryCodeBox extends StatelessWidget {
  const _RecoveryCodeBox({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          SelectableText(
            code,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — PIN Setup (skippable)
// ─────────────────────────────────────────────────────────────────────────────

class _PinStep extends StatefulWidget {
  const _PinStep({required this.onAdvance});

  final VoidCallback onAdvance;

  @override
  State<_PinStep> createState() => _PinStepState();
}

class _PinStepState extends State<_PinStep> {
  bool _inPinSetup = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_inPinSetup) {
      return PinSetupScreen(
        isChanging: false,
        allowSkip: true,
        onComplete: () {
          setState(() => _inPinSetup = false);
          widget.onAdvance();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Add a Lock',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Set a 4-digit PIN to prevent unauthorised access to your leads '
            'and call data.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _inPinSetup = true),
              child: const Text('Set Up PIN'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onAdvance,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Permissions (skippable)
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsStep extends StatefulWidget {
  const _PermissionsStep({required this.onAdvance});

  final VoidCallback onAdvance;

  @override
  State<_PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends State<_PermissionsStep> {
  bool _inWizard = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_inWizard) {
      // Wrap in a Navigator-like override so PermissionsWizardScreen's
      // context.pop() falls back to our callback.
      return _WizardWrapper(
        child: PermissionsWizardScreen(
          key: const ValueKey('permissions-wizard'),
        ),
        onDone: () {
          setState(() => _inWizard = false);
          widget.onAdvance();
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.security_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Allow Permissions',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Kiko needs a few permissions to identify callers, show the '
            'overlay, and remind you to follow up with leads.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _PermissionBullet(
            icon: Icons.call_outlined,
            label: 'Call screening — identify callers',
          ),
          _PermissionBullet(
            icon: Icons.layers_outlined,
            label: 'Overlay — show info during calls',
          ),
          _PermissionBullet(
            icon: Icons.history_outlined,
            label: 'Call log — link calls to leads',
          ),
          _PermissionBullet(
            icon: Icons.notifications_outlined,
            label: 'Notifications — reminders & alerts',
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => setState(() => _inWizard = true),
              child: const Text('Grant Permissions'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onAdvance,
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }
}

class _PermissionBullet extends StatelessWidget {
  const _PermissionBullet({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps [PermissionsWizardScreen] in a local [Navigator] so that
/// [context.pop()] inside the wizard pops back to us rather than the app
/// root, and calls [onDone] when the wizard finishes.
class _WizardWrapper extends StatefulWidget {
  const _WizardWrapper({required this.child, required this.onDone});

  final Widget child;
  final VoidCallback onDone;

  @override
  State<_WizardWrapper> createState() => _WizardWrapperState();
}

class _WizardWrapperState extends State<_WizardWrapper> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          final nav = _navigatorKey.currentState;
          if (nav != null && nav.canPop()) {
            nav.pop();
          } else {
            widget.onDone();
          }
        }
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Done
// ─────────────────────────────────────────────────────────────────────────────

class _DoneStep extends ConsumerWidget {
  const _DoneStep({required this.onComplete});

  final VoidCallback onComplete;

  Future<void> _finish(WidgetRef ref) async {
    final settings = ref.read(appSettingsProvider);
    await settings.setOnboardingComplete(true);
    if (settings.backupEnabled) {
      await CloudBackupService.schedulePeriodicBackup(
        wifiOnly: settings.backupWifiOnly,
      );
    }
    onComplete();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 56,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "You're all set!",
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your data is encrypted and backed up. '
            'Kiko is ready to help you manage your leads.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _finish(ref),
              child: const Text('Start Using Kiko'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step dots indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
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
