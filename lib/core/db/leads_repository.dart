import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../features/search/lead_filter.dart';
import '../db/database.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MergeSnapshot — captures lead state before a merge for undo
// ─────────────────────────────────────────────────────────────────────────────

class MergeSnapshot {
  const MergeSnapshot({
    required this.leadId,
    required this.name,
    required this.businessType,
    required this.status,
    required this.notes,
    required this.phones,
    required this.sections,
  });

  final String leadId;
  final String name;
  final String? businessType;
  final String status;
  final String? notes;
  final List<({String e164, String? label, bool isPrimary})> phones;
  final List<({String title, String body})> sections;
}

// ─────────────────────────────────────────────────────────────────────────────
// LeadsRepository
// ─────────────────────────────────────────────────────────────────────────────
//
// All mutations that affect search fields rebuild the FTS5 row in the SAME
// transaction (spec requirement, Phase 1).
// ─────────────────────────────────────────────────────────────────────────────

class LeadsRepository {
  LeadsRepository(this._db);

  final AppDatabase _db;
  final _uuid = const Uuid();

  // ── Create ────────────────────────────────────────────────────────────────

  Future<Lead> createLead({
    required String name,
    String? businessType,
    String status = 'NEW',
    String source = 'MANUAL',
    String? notes,
    List<({String e164, String? label, bool isPrimary})> phones = const [],
    List<({String title, String body})> sections = const [],
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    return _db.transaction(() async {
      await _db.into(_db.leads).insert(
            LeadsCompanion.insert(
              id: id,
              name: name,
              businessType: Value(businessType),
              status: Value(status),
              source: Value(source),
              notes: Value(notes),
              createdAt: now,
              updatedAt: now,
            ),
          );

      for (final (index, phone) in phones.indexed) {
        await _db.into(_db.leadPhones).insert(
              LeadPhonesCompanion.insert(
                leadId: id,
                e164: phone.e164,
                label: Value(phone.label),
                isPrimary: Value(index == 0 || phone.isPrimary),
              ),
            );
      }

      for (final (index, section) in sections.indexed) {
        await _db.into(_db.leadSections).insert(
              LeadSectionsCompanion.insert(
                leadId: id,
                title: section.title,
                body: section.body,
                position: Value(index),
              ),
            );
      }

      await _rebuildFts(id);
      return (await (_db.select(_db.leads)..where((t) => t.id.equals(id)))
          .getSingle());
    });
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<Lead?> getLeadById(String id) {
    return (_db.select(_db.leads)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<Lead>> watchAllLeads({bool includeArchived = false}) {
    return (_db.select(_db.leads)
          ..where((t) => includeArchived
              ? const Constant(true)
              : t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<LeadPhone>> getPhonesForLead(String leadId) {
    return (_db.select(_db.leadPhones)
          ..where((t) => t.leadId.equals(leadId)))
        .get();
  }

  Future<List<LeadSection>> getSectionsForLead(String leadId) {
    return (_db.select(_db.leadSections)
          ..where((t) => t.leadId.equals(leadId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  Future<List<LeadImage>> getImagesForLead(String leadId) {
    return (_db.select(_db.leadImages)
          ..where((t) => t.leadId.equals(leadId))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<Lead> updateLead(
    String id, {
    Value<String> name = const Value.absent(),
    Value<String?> businessType = const Value.absent(),
    Value<String> status = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<bool> archived = const Value.absent(),
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    return _db.transaction(() async {
      await (_db.update(_db.leads)..where((t) => t.id.equals(id))).write(
        LeadsCompanion(
          name: name,
          businessType: businessType,
          status: status,
          notes: notes,
          archived: archived,
          updatedAt: Value(now),
        ),
      );

      await _rebuildFts(id);

      return (await (_db.select(_db.leads)..where((t) => t.id.equals(id)))
          .getSingle());
    });
  }

  Future<void> updateLastContactAt(String leadId, int timestampMs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.leads)..where((t) => t.id.equals(leadId))).write(
      LeadsCompanion(
        lastContactAt: Value(timestampMs),
        updatedAt: Value(now),
      ),
    );
  }

  // ── Phone mutations ───────────────────────────────────────────────────────

  Future<void> upsertPhone(
    String leadId,
    String e164, {
    String? label,
    bool isPrimary = false,
  }) async {
    await _db.transaction(() async {
      await _db.into(_db.leadPhones).insertOnConflictUpdate(
            LeadPhonesCompanion.insert(
              leadId: leadId,
              e164: e164,
              label: Value(label),
              isPrimary: Value(isPrimary),
            ),
          );
      await _rebuildFts(leadId);
    });
  }

  Future<void> removePhone(String leadId, String e164) async {
    await _db.transaction(() async {
      await (_db.delete(_db.leadPhones)
            ..where((t) => t.leadId.equals(leadId) & t.e164.equals(e164)))
          .go();
      await _rebuildFts(leadId);
    });
  }

  // ── Image mutations ───────────────────────────────────────────────────────

  /// Max 3 images enforced here. Throws [StateError] if limit reached.
  Future<LeadImage> addImage(String leadId, String filePath) async {
    return _db.transaction(() async {
      final count = await (_db.selectOnly(_db.leadImages)
            ..where(_db.leadImages.leadId.equals(leadId))
            ..addColumns([_db.leadImages.id.count()]))
          .map((row) => row.read(_db.leadImages.id.count())!)
          .getSingle();

      if (count >= 3) {
        throw StateError('A lead may have at most 3 images.');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final rowId = await _db.into(_db.leadImages).insert(
            LeadImagesCompanion.insert(
              leadId: leadId,
              filePath: filePath,
              position: Value(count),
              createdAt: now,
            ),
          );

      return (_db.select(_db.leadImages)
            ..where((t) => t.id.equals(rowId)))
          .getSingle();
    });
  }

  Future<void> removeImage(int imageId) async {
    await (_db.delete(_db.leadImages)
          ..where((t) => t.id.equals(imageId)))
        .go();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteLead(String id) async {
    await _db.transaction(() async {
      await _db.removeFtsRow(id);
      await (_db.delete(_db.leads)..where((t) => t.id.equals(id))).go();
    });
  }

  // ── Business types autocomplete ───────────────────────────────────────────

  Future<List<String>> getDistinctBusinessTypes() async {
    final rows = await _db.customSelect(
      'SELECT DISTINCT TRIM(business_type) AS bt FROM leads '
      'WHERE business_type IS NOT NULL AND TRIM(business_type) != \'\' '
      'ORDER BY bt COLLATE NOCASE',
    ).get();
    return rows.map((r) => r.read<String>('bt')).toList();
  }

  // ── Full sections/phones replace (used by Add/Edit save) ─────────────────

  Future<void> replaceAllPhones(
    String leadId,
    List<({String e164, String? label, bool isPrimary})> phones,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.leadPhones)
            ..where((t) => t.leadId.equals(leadId)))
          .go();
      for (final (i, ph) in phones.indexed) {
        await _db.into(_db.leadPhones).insert(
              LeadPhonesCompanion.insert(
                leadId: leadId,
                e164: ph.e164,
                label: Value(ph.label),
                isPrimary: Value(i == 0 || ph.isPrimary),
              ),
            );
      }
      await _rebuildFts(leadId);
    });
  }

  Future<void> replaceAllSections(
    String leadId,
    List<({String title, String body})> sections,
  ) async {
    await _db.transaction(() async {
      await (_db.delete(_db.leadSections)
            ..where((t) => t.leadId.equals(leadId)))
          .go();
      for (final (i, s) in sections.indexed) {
        await _db.into(_db.leadSections).insert(
              LeadSectionsCompanion.insert(
                leadId: leadId,
                title: s.title,
                body: s.body,
                position: Value(i),
              ),
            );
      }
      await _rebuildFts(leadId);
    });
  }

  // ── Duplicate detection ───────────────────────────────────────────────────

  /// Returns all leads whose stored e164 phones conflict with any phone in
  /// [e164s], excluding [excludeLeadId] (the lead currently being edited).
  Future<List<Lead>> findDuplicatesByPhones(
    List<String> e164s, {
    String? excludeLeadId,
  }) async {
    if (e164s.isEmpty) return [];

    // Build placeholders: (?, ?, ...)
    final placeholders = List.filled(e164s.length, '?').join(', ');
    final variables = <Variable>[
      for (final e in e164s) Variable.withString(e),
    ];

    String sql;
    if (excludeLeadId != null) {
      sql = 'SELECT DISTINCT lead_id FROM lead_phones '
          'WHERE e164 IN ($placeholders) AND lead_id != ?';
      variables.add(Variable.withString(excludeLeadId));
    } else {
      sql = 'SELECT DISTINCT lead_id FROM lead_phones '
          'WHERE e164 IN ($placeholders)';
    }

    final rows = await _db.customSelect(sql, variables: variables).get();
    final ids = rows.map((r) => r.read<String>('lead_id')).toList();
    if (ids.isEmpty) return [];

    return (_db.select(_db.leads)..where((t) => t.id.isIn(ids))).get();
  }

  // ── Merge ─────────────────────────────────────────────────────────────────

  /// Merges the draft data (from the new/edited lead) into [targetLeadId].
  ///
  /// Steps performed in a single transaction:
  /// 1. Snapshot the current target lead + phones + sections (returned as
  ///    [MergeSnapshot] so the caller can offer an undo).
  /// 2. Overwrite target lead fields that the user chose from the draft.
  /// 3. Union phones: keep all existing, add draft phones not already present.
  ///    [draftPhoneE164s] lists every e164 the user kept checked.
  /// 4. Replace sections with the ordered list the user confirmed.
  /// 5. Rebuild FTS row.
  /// 6. Return the [MergeSnapshot] for undo.
  Future<MergeSnapshot> mergeLead({
    required String targetLeadId,
    // Fields to overwrite (null = keep existing):
    String? name,
    String? businessType,
    String? status,
    String? notes,
    // Phones: full union list as e164 → (label, isPrimary)
    required List<({String e164, String? label, bool isPrimary})> mergedPhones,
    // Sections: ordered final list
    required List<({String title, String body})> mergedSections,
  }) async {
    return _db.transaction(() async {
      // 1. Snapshot
      final targetLead = await (_db.select(_db.leads)
            ..where((t) => t.id.equals(targetLeadId)))
          .getSingle();
      final existingPhones = await (_db.select(_db.leadPhones)
            ..where((t) => t.leadId.equals(targetLeadId)))
          .get();
      final existingSections = await (_db.select(_db.leadSections)
            ..where((t) => t.leadId.equals(targetLeadId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

      final snapshot = MergeSnapshot(
        leadId: targetLeadId,
        name: targetLead.name,
        businessType: targetLead.businessType,
        status: targetLead.status,
        notes: targetLead.notes,
        phones: existingPhones
            .map((p) => (
                  e164: p.e164,
                  label: p.label,
                  isPrimary: p.isPrimary,
                ))
            .toList(),
        sections: existingSections
            .map((s) => (title: s.title, body: s.body))
            .toList(),
      );

      // 2. Update lead fields
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.leads)
            ..where((t) => t.id.equals(targetLeadId)))
          .write(
        LeadsCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          businessType: businessType != null
              ? Value(businessType.isEmpty ? null : businessType)
              : const Value.absent(),
          status:
              status != null ? Value(status) : const Value.absent(),
          notes: notes != null
              ? Value(notes.isEmpty ? null : notes)
              : const Value.absent(),
          updatedAt: Value(now),
        ),
      );

      // 3. Replace phones with merged list
      await (_db.delete(_db.leadPhones)
            ..where((t) => t.leadId.equals(targetLeadId)))
          .go();
      for (final (i, ph) in mergedPhones.indexed) {
        await _db.into(_db.leadPhones).insert(
              LeadPhonesCompanion.insert(
                leadId: targetLeadId,
                e164: ph.e164,
                label: Value(ph.label),
                isPrimary: Value(i == 0 || ph.isPrimary),
              ),
            );
      }

      // 4. Replace sections with merged/reordered list
      await (_db.delete(_db.leadSections)
            ..where((t) => t.leadId.equals(targetLeadId)))
          .go();
      for (final (i, s) in mergedSections.indexed) {
        await _db.into(_db.leadSections).insert(
              LeadSectionsCompanion.insert(
                leadId: targetLeadId,
                title: s.title,
                body: s.body,
                position: Value(i),
              ),
            );
      }

      // 5. Rebuild FTS
      await _rebuildFts(targetLeadId);

      return snapshot;
    });
  }

  /// Restores a lead to the state captured in [snapshot].
  Future<void> undoMerge(MergeSnapshot snapshot) async {
    await _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await (_db.update(_db.leads)
            ..where((t) => t.id.equals(snapshot.leadId)))
          .write(
        LeadsCompanion(
          name: Value(snapshot.name),
          businessType: Value(snapshot.businessType),
          status: Value(snapshot.status),
          notes: Value(snapshot.notes),
          updatedAt: Value(now),
        ),
      );

      await (_db.delete(_db.leadPhones)
            ..where((t) => t.leadId.equals(snapshot.leadId)))
          .go();
      for (final (i, ph) in snapshot.phones.indexed) {
        await _db.into(_db.leadPhones).insert(
              LeadPhonesCompanion.insert(
                leadId: snapshot.leadId,
                e164: ph.e164,
                label: Value(ph.label),
                isPrimary: Value(i == 0 || ph.isPrimary),
              ),
            );
      }

      await (_db.delete(_db.leadSections)
            ..where((t) => t.leadId.equals(snapshot.leadId)))
          .go();
      for (final (i, s) in snapshot.sections.indexed) {
        await _db.into(_db.leadSections).insert(
              LeadSectionsCompanion.insert(
                leadId: snapshot.leadId,
                title: s.title,
                body: s.body,
                position: Value(i),
              ),
            );
      }

      await _rebuildFts(snapshot.leadId);
    });
  }

  // ── FTS search ────────────────────────────────────────────────────────────

  /// Keyword-only FTS5 search (no structural filters).
  Future<List<Lead>> searchLeads(String query) {
    return queryLeads(LeadFilter(keyword: query));
  }

  /// Combined FTS5 keyword search + structural filters (Phase 7).
  ///
  /// Returns leads ordered by `updated_at DESC`. When [filter.keyword] is set,
  /// FTS rank is preferred for the matching subset, then remaining filtered
  /// leads follow by `updated_at`.
  Future<List<Lead>> queryLeads(LeadFilter filter) async {
    final variables = <Variable>[];
    final where = <String>[];

    if (!filter.includeArchived) {
      where.add('l.archived = 0');
    }

    if (filter.statuses.isNotEmpty) {
      final placeholders =
          List.filled(filter.statuses.length, '?').join(', ');
      where.add('l.status IN ($placeholders)');
      for (final s in filter.statuses) {
        variables.add(Variable.withString(s.dbValue));
      }
    }

    if (filter.sources.isNotEmpty) {
      final placeholders =
          List.filled(filter.sources.length, '?').join(', ');
      where.add('l.source IN ($placeholders)');
      for (final s in filter.sources) {
        variables.add(Variable.withString(s.dbValue));
      }
    }

    if (filter.createdRange.startMs != null) {
      where.add('l.created_at >= ?');
      variables.add(Variable.withInt(filter.createdRange.startMs!));
    }
    if (filter.createdRange.endMs != null) {
      where.add('l.created_at <= ?');
      variables.add(Variable.withInt(filter.createdRange.endMs!));
    }

    if (filter.lastContactRange.startMs != null) {
      where.add('l.last_contact_at IS NOT NULL AND l.last_contact_at >= ?');
      variables.add(Variable.withInt(filter.lastContactRange.startMs!));
    }
    if (filter.lastContactRange.endMs != null) {
      where.add('l.last_contact_at IS NOT NULL AND l.last_contact_at <= ?');
      variables.add(Variable.withInt(filter.lastContactRange.endMs!));
    }

    if (filter.hasReminder == true) {
      where.add(
        'EXISTS (SELECT 1 FROM reminders r '
        "WHERE r.lead_id = l.id AND r.state = 'PENDING')",
      );
    } else if (filter.hasReminder == false) {
      where.add(
        'NOT EXISTS (SELECT 1 FROM reminders r '
        "WHERE r.lead_id = l.id AND r.state = 'PENDING')",
      );
    }

    if (filter.callDirection != null) {
      where.add(
        'EXISTS (SELECT 1 FROM call_events c '
        'WHERE c.lead_id = l.id AND c.call_type = ?)',
      );
      variables.add(Variable.withString(filter.callDirection!.dbValue));
    }

    List<String>? ftsOrderedIds;
    final keyword = filter.keyword.trim();
    if (keyword.isNotEmpty) {
      ftsOrderedIds = await _ftsMatchIds(keyword);
      if (ftsOrderedIds.isEmpty) return [];
      final placeholders =
          List.filled(ftsOrderedIds.length, '?').join(', ');
      where.add('l.id IN ($placeholders)');
      for (final id in ftsOrderedIds) {
        variables.add(Variable.withString(id));
      }
    }

    final sql = StringBuffer('SELECT l.id FROM leads l');
    if (where.isNotEmpty) {
      sql.write(' WHERE ${where.join(' AND ')}');
    }
    sql.write(' ORDER BY l.updated_at DESC');

    final rows = await _db
        .customSelect(sql.toString(), variables: variables)
        .get();
    final ids = rows
        .map((r) => r.readNullable<String>('id'))
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return [];

    final leads = await (_db.select(_db.leads)..where((t) => t.id.isIn(ids)))
        .get();
    final byId = {for (final l in leads) l.id: l};

    // Preserve FTS rank when keyword used; otherwise keep updated_at order.
    final order = ftsOrderedIds ?? ids;
    return [
      for (final id in order)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  Future<List<String>> _ftsMatchIds(String query) async {
    final sanitised = query.trim().replaceAll('"', '""');
    // Prefer prefix match; fall back to plain token for Ethiopic scripts
    // where the tokenizer may not treat characters as Latin word units.
    final rows = await _db.customSelect(
      'SELECT lead_id FROM lead_search WHERE lead_search MATCH ? ORDER BY rank',
      variables: [Variable.withString('"$sanitised"*')],
    ).get();

    if (rows.isNotEmpty) {
      return rows
          .map((r) => r.readNullable<String>('lead_id'))
          .whereType<String>()
          .toList();
    }

    // Fallback without prefix wildcard (helps some Amharic token cases).
    final fallback = await _db.customSelect(
      'SELECT lead_id FROM lead_search WHERE lead_search MATCH ? ORDER BY rank',
      variables: [Variable.withString(sanitised)],
    ).get();
    return fallback
        .map((r) => r.readNullable<String>('lead_id'))
        .whereType<String>()
        .toList();
  }

  /// Returns every lead id that has a phone in [e164s], mapped e164 → leadId.
  Future<Map<String, String>> mapPhonesToLeadIds(List<String> e164s) async {
    if (e164s.isEmpty) return {};
    final placeholders = List.filled(e164s.length, '?').join(', ');
    final rows = await _db.customSelect(
      'SELECT e164, lead_id FROM lead_phones WHERE e164 IN ($placeholders)',
      variables: [for (final e in e164s) Variable.withString(e)],
    ).get();
    return {
      for (final r in rows)
        r.read<String>('e164'): r.read<String>('lead_id'),
    };
  }

  // ── Internal: FTS rebuild (must be called inside a transaction) ───────────

  Future<void> _rebuildFts(String leadId) async {
    final lead = await (_db.select(_db.leads)
          ..where((t) => t.id.equals(leadId)))
        .getSingleOrNull();
    if (lead == null) return;

    final phones = await (_db.select(_db.leadPhones)
          ..where((t) => t.leadId.equals(leadId)))
        .get();
    final sections = await (_db.select(_db.leadSections)
          ..where((t) => t.leadId.equals(leadId)))
        .get();

    await _db.rebuildFtsRow(
      leadId: leadId,
      name: lead.name,
      businessType: lead.businessType,
      notes: lead.notes,
      phones: phones.map((p) => p.e164).toList(),
      sections: sections.expand((s) => [s.title, s.body]).toList(),
    );
  }
}
