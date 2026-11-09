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
// AppLifecycleObserver
// ─────────────────────────────────────────────────────────────────────────────
//
// Drains the native pending-events queue whenever the app returns to the
// foreground.  Registered on the WidgetsBinding by KikoApp.
// ─────────────────────────────────────────────────────────────────────────────

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver(this._ref);

  final WidgetRef _ref;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget; errors are handled inside drain().
      _ref.read(pendingDrainServiceProvider).drain();
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
    // Drain once on startup (cold start) as well.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingDrainServiceProvider).drain();
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
