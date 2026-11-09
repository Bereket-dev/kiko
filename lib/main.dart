import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';

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
// Root widget
// ─────────────────────────────────────────────────────────────────────────────

class KikoApp extends ConsumerWidget {
  const KikoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kiko',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiko')),
      body: const Center(child: Text('Phase 1 foundation ready.')),
    );
  }
}
