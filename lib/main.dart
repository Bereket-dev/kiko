import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'features/security/app_lock_wrapper.dart';
import 'features/security/pin_setup_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final boot = await bootstrap();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(boot.db),
        appSettingsProvider.overrideWithValue(boot.settings),
      ],
      child: const KikoApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _scheduleReschedule
// ─────────────────────────────────────────────────────────────────────────────
//
// Re-arms all PENDING reminders and call-plan schedules whose native
// AlarmManager entries may have been cleared while the process was dead
// (e.g. after device reboot, force-stop, or OEM battery kill).
//
// Called both:
//   • On cold start (addPostFrameCallback in _KikoAppState.initState)
//   • On lifecycle resume (didChangeAppLifecycleState)
//
// Order: drain pending call events first so any status updates land in DB
// before rescheduleAll reads reminder/schedule rows.
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _rescheduleAll(WidgetRef ref) async {
  // 1. Drain pending native call events first.
  await ref.read(pendingDrainServiceProvider).drain();

  // 2. Build leadId → name map for reminder notification titles.
  final leads = await ref.read(leadsRepositoryProvider).watchAllLeads().first;
  final leadNames = {for (final l in leads) l.id: l.name};

  // 3. Re-arm reminders.
  await ref.read(reminderServiceProvider).rescheduleAll(leadNames: leadNames);

  // 4. Re-arm call-plan schedules.
  await ref.read(callPlanServiceProvider).rescheduleAll();
}

// ─────────────────────────────────────────────────────────────────────────────
// _AppLifecycleObserver
// ─────────────────────────────────────────────────────────────────────────────
//
// Triggers the full reschedule + drain whenever the app returns to the
// foreground. Registered on the WidgetsBinding by KikoApp.
// Note: auto-lock lifecycle is handled inside AppLockWrapper.
// ─────────────────────────────────────────────────────────────────────────────

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget; errors are handled inside each service.
      _rescheduleAll(_ref);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KikoApp
// ─────────────────────────────────────────────────────────────────────────────

class KikoApp extends ConsumerStatefulWidget {
  const KikoApp({super.key});

  @override
  ConsumerState<KikoApp> createState() => _KikoAppState();
}

class _KikoAppState extends ConsumerState<KikoApp> {
  late final _AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    // Run once on cold start after the first frame so the provider container
    // is fully initialised before we read from it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleAll(ref);
      _maybeOfferPinSetup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  // ── First-launch PIN setup ────────────────────────────────────────────────
  //
  // On the very first launch (pinSetupOffered == false), show the skippable
  // PIN setup screen via an overlay modal route.  Marks the flag after the
  // screen is dismissed (whether the user set a PIN or skipped).

  Future<void> _maybeOfferPinSetup() async {
    final settings = ref.read(appSettingsProvider);
    if (settings.pinSetupOffered) return;

    // If a PIN is already set (e.g. restored from backup), skip the offer.
    final hasPinSet = await settings.hasPinSet();
    if (hasPinSet) {
      await settings.setPinSetupOffered(true);
      return;
    }

    final nav = appNavigatorKey.currentState;
    if (nav == null || !mounted) return;

    await nav.push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PinSetupScreen(
          allowSkip: true,
          onComplete: () {
            // Mark as offered so this screen never shows again.
            settings.setPinSetupOffered(true);
            nav.pop();
          },
        ),
      ),
    );

    // Fallback: also mark as offered if the user dismissed via system back.
    await settings.setPinSetupOffered(true);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the locale preference so the app rebuilds when language changes.
    final localeCode = ref.watch(localePrefProvider);
    final locale = Locale(localeCode);

    return MaterialApp.router(
      title: 'Kiko',
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Wrap the entire navigator tree with AppLockWrapper.
        return AppLockWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
