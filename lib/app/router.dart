import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/calls/recent_calls_screen.dart';
import '../features/importexport/export_screen.dart';
import '../features/importexport/import_wizard_screen.dart';
import '../features/leads/leads_list_screen.dart';
import '../features/leads/lead_detail_screen.dart';
import '../features/leads/add_edit_lead_screen.dart';
import '../features/leads/merge_lead_screen.dart';
import '../features/leads/paste_preview_screen.dart';
import '../features/reminders/call_plan_screen.dart';
import '../features/reminders/create_call_plan_screen.dart';
import '../features/search/lead_filter.dart';
import '../features/search/search_screen.dart';
import '../features/security/pin_setup_screen.dart';
import '../features/settings/permissions_wizard_screen.dart';
import '../features/settings/settings_screen.dart';

/// A [GlobalKey] for the app's root Navigator.
///
/// Used by [KikoApp] to push the first-launch PIN setup screen imperatively.
final appNavigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// MergeRouteArgs — typed extras for /leads/merge
// ─────────────────────────────────────────────────────────────────────────────

class MergeRouteArgs {
  const MergeRouteArgs({
    required this.screen,
  });

  /// Pre-built MergeLeadScreen instance passed via GoRouter extra.
  final MergeLeadScreen screen;
}

// ─────────────────────────────────────────────────────────────────────────────
// App Router
// ─────────────────────────────────────────────────────────────────────────────
//
// Routes (deep-linkable per spec):
//   /                        → Leads list
//   /leads/:id               → Lead detail
//   /leads/add               → Add lead (optional ?phone= from native intent)
//   /leads/:id/edit          → Edit lead
//   /leads/paste             → Paste-to-preview screen
//   /leads/add?phone=<e164>  → Add lead pre-filled with phone (from overlay)
//   /leads/merge             → Merge lead screen (extra: MergeRouteArgs)
//   /recent-calls            → Recent calls list (Phase 5)
//   /permissions-wizard      → Step-by-step permissions wizard (Phase 5)
//   /settings                → App settings (Phase 5)
//   /call-plan/new           → Create a new call-plan schedule (Phase 6)
//   /call-plan/:scheduleId   → Call plan session screen (Phase 6)
//   /search                  → FTS5 search + filters (Phase 7)
//   /export                  → Export screen (Phase 7) — extra: LeadFilter?
//   /import                  → Import wizard (Phase 7)
//   /pin-setup               → PIN setup/change screen (Phase 8)
// ─────────────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  navigatorKey: appNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LeadsListScreen(),
      routes: [
        GoRoute(
          path: 'leads/add',
          builder: (_, state) {
            final phone = state.uri.queryParameters['phone'];
            return AddEditLeadScreen(prefillPhone: phone);
          },
        ),
        GoRoute(
          path: 'leads/paste',
          builder: (context, state) => const PastePreviewScreen(),
        ),
        GoRoute(
          path: 'leads/merge',
          builder: (_, state) {
            final args = state.extra as MergeRouteArgs?;
            if (args == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Merge Lead')),
                body: const Center(child: Text('Missing merge data.')),
              );
            }
            return args.screen;
          },
        ),
        GoRoute(
          path: 'leads/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return LeadDetailScreen(leadId: id);
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) {
                final id = state.pathParameters['id']!;
                return AddEditLeadScreen(editLeadId: id);
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/recent-calls',
      builder: (_, _) => const RecentCallsScreen(),
    ),
    GoRoute(
      path: '/permissions-wizard',
      builder: (_, _) => const PermissionsWizardScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/call-plan/new',
      builder: (_, _) => const CreateCallPlanScreen(),
    ),
    GoRoute(
      path: '/call-plan/:scheduleId',
      builder: (_, state) {
        final scheduleId = state.pathParameters['scheduleId']!;
        return CallPlanScreen(scheduleId: scheduleId);
      },
    ),
    // ── Phase 7 routes ──────────────────────────────────────────────────────
    GoRoute(
      path: '/search',
      builder: (_, _) => const SearchScreen(),
    ),
    GoRoute(
      path: '/export',
      builder: (_, state) {
        final filter = state.extra as LeadFilter?;
        return ExportScreen(activeFilter: filter);
      },
    ),
    GoRoute(
      path: '/import',
      builder: (_, _) => const ImportWizardScreen(),
    ),
    // ── Phase 8 routes ──────────────────────────────────────────────────────
    GoRoute(
      path: '/pin-setup',
      builder: (_, state) {
        final isChanging = state.uri.queryParameters['mode'] == 'change';
        return PinSetupScreen(
          isChanging: isChanging,
          onComplete: () {},
          allowSkip: !isChanging,
        );
      },
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('Not Found')),
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
