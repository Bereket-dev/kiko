// ─────────────────────────────────────────────────────────────────────────────
// LookupIndexService
// ─────────────────────────────────────────────────────────────────────────────
//
// Dart-side wrapper around the Pigeon LookupIndexApi.
// After every lead save/update/delete, Dart must upsert/remove the native
// encrypted lookup store so the Kotlin CallScreeningService can find it.
//
// During Phase 3 the Pigeon-generated code is not yet compiled into the app
// (we haven't run `dart run pigeon ...`), so this service is a no-op stub
// that will be wired up properly in Phase 5 when Pigeon codegen runs.
//
// The interface is identical to what the real implementation will use, so
// call-sites need no changes after Phase 5.
// ─────────────────────────────────────────────────────────────────────────────

import '../db/database.dart';

class LookupIndexService {
  const LookupIndexService();

  /// Upsert a single lead's E.164 numbers into the native lookup index.
  Future<void> upsertLead({
    required Lead lead,
    required List<LeadPhone> phones,
  }) async {
    // Stub — Pigeon implementation wired in Phase 5.
    // Real implementation will call:
    //   for (final phone in phones) {
    //     await LookupIndexApi().upsertEntry(LookupEntry(
    //       e164: phone.e164,
    //       name: lead.name,
    //       statusCode: lead.status,
    //       lastNote: lead.notes?.substring(0, min(80, lead.notes!.length)),
    //       lastCallAt: lead.lastContactAt,
    //     ));
    //   }
  }

  /// Remove all phone entries for a lead from the native lookup index.
  Future<void> removeLead(List<String> e164Numbers) async {
    // Stub — Pigeon implementation wired in Phase 5.
    // Real implementation:
    //   for (final e164 in e164Numbers) {
    //     await LookupIndexApi().removeEntry(e164);
    //   }
  }

  /// Full rebuild of the native index (after import/restore).
  Future<void> rebuildIndex({
    required List<Lead> leads,
    required Map<String, List<LeadPhone>> phonesByLeadId,
  }) async {
    // Stub — Pigeon implementation wired in Phase 5.
  }
}
