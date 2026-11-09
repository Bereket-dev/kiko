import 'dart:developer' as dev;

import 'package:drift/drift.dart' show Variable;

import 'call_events_repository.dart';
import 'database.dart';
import 'leads_repository.dart';
import '../utils/lookup_index_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PendingDrainService
// ─────────────────────────────────────────────────────────────────────────────
//
// Orchestrates draining the native pending-events queue and keeping the
// native lookup index in sync.
//
// Usage (called from AppLifecycleObserver on AppLifecycleState.resumed):
//   await pendingDrainService.drain();
// ─────────────────────────────────────────────────────────────────────────────

class PendingDrainService {
  PendingDrainService({
    required CallEventsRepository callEventsRepository,
    required LeadsRepository leadsRepository,
    required LookupIndexService lookupIndexService,
    required AppDatabase db,
  })  : _callEvents = callEventsRepository,
        _leads = leadsRepository,
        _lookupIndex = lookupIndexService,
        _db = db;

  final CallEventsRepository _callEvents;
  final LeadsRepository _leads;
  final LookupIndexService _lookupIndex;
  final AppDatabase _db;

  /// Drains the native pending-events queue, persists them to Drift, then
  /// refreshes the native lookup index for all affected leads.
  ///
  /// Errors are caught, logged, and swallowed — this must never crash the app.
  Future<void> drain() async {
    try {
      final count = await _callEvents.drainAndPersistPending();
      if (count == 0) return;

      dev.log(
        'PendingDrainService: persisted $count event(s); '
        'refreshing lookup index for affected leads.',
        name: 'PendingDrainService',
      );

      // Upsert the lookup index for all leads that have recently had calls
      // drained — we rebuild by fetching leads whose lastContactAt is within
      // the last hour (a conservative window that covers all freshly drained
      // events without requiring us to track individual lead IDs here).
      await _upsertLookupIndexForRecentLeads();
    } catch (e, st) {
      dev.log(
        'PendingDrainService.drain() error: $e',
        name: 'PendingDrainService',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Refreshes the native lookup index for leads updated in the last hour.
  Future<void> _upsertLookupIndexForRecentLeads() async {
    try {
      final sinceMs =
          DateTime.now().millisecondsSinceEpoch - const Duration(hours: 1).inMilliseconds;

      final recentLeads = await _db.customSelect(
        'SELECT id FROM leads WHERE last_contact_at >= ?',
        variables: [Variable.withInt(sinceMs)],
      ).get();

      for (final row in recentLeads) {
        final leadId = row.read<String>('id');
        final lead = await _leads.getLeadById(leadId);
        if (lead == null) continue;

        final phones = await _leads.getPhonesForLead(leadId);
        await _lookupIndex.upsertLead(lead: lead, phones: phones);
      }
    } catch (e, st) {
      dev.log(
        'PendingDrainService._upsertLookupIndexForRecentLeads() error: $e',
        name: 'PendingDrainService',
        error: e,
        stackTrace: st,
      );
    }
  }
}
