import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
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
// The Kotlin BootReceiver handles re-scheduling on BOOT_COMPLETED using
// AlarmStore (SharedPreferences), which covers the case where Flutter never
// starts.  This Dart path is the safety net for any gap between native
// reschedule and Dart state.
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
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kiko',
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
