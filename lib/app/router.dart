import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/leads/leads_list_screen.dart';
import '../features/leads/lead_detail_screen.dart';
import '../features/leads/add_edit_lead_screen.dart';
import '../features/leads/paste_preview_screen.dart';

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
// ─────────────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
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
  ],
  errorBuilder: (_, state) => Scaffold(
    appBar: AppBar(title: const Text('Not Found')),
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
