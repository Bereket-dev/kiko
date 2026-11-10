// ignore_for_file: lines_longer_than_80_chars
// Integration test: merge undo round-trip
//
// Verifies the full merge + undo cycle:
//   1. Create a lead with phones and sections.
//   2. Merge draft into the target lead (snapshot captured).
//   3. Assert merge took effect (name, status, phones, sections changed).
//   4. Undo using the snapshot.
//   5. Assert everything restored to pre-merge state.
//   6. Assert FTS is still usable after undo (search returns the restored lead).

import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/db/leads_repository.dart';

AppDatabase _openTestDb() => AppDatabase(openInMemoryDatabase());

void main() {
  late AppDatabase db;
  late LeadsRepository repo;

  setUp(() {
    db = _openTestDb();
    repo = LeadsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── Full round-trip ───────────────────────────────────────────────────────

  test('merge then undo fully restores lead to pre-merge state', () async {
    // 1. Seed target lead.
    final original = await repo.createLead(
      name: 'Abebe Kebede',
      businessType: 'Retailer',
      status: 'NEW',
      notes: 'Original notes',
      phones: [
        (e164: '+251911000001', label: null, isPrimary: true),
        (e164: '+251922000001', label: 'Office', isPrimary: false),
      ],
      sections: [
        (title: 'Address', body: 'Merkato, Addis Ababa'),
        (title: 'Tags', body: 'wholesale'),
      ],
    );

    final originalPhones = await repo.getPhonesForLead(original.id);
    final originalSections = await repo.getSectionsForLead(original.id);

    // 2. Merge.
    final snapshot = await repo.mergeLead(
      targetLeadId: original.id,
      name: 'Abebe Kebede (Merged)',
      businessType: 'Wholesaler',
      status: 'CONTACTED',
      notes: 'Merged notes',
      mergedPhones: [
        (e164: '+251911000001', label: null, isPrimary: true),
        (e164: '+251933000001', label: 'Mobile', isPrimary: false),
      ],
      mergedSections: [
        (title: 'Address', body: 'Bole, Addis Ababa'),
        (title: 'Tags', body: 'wholesale, coffee'),
        (title: 'Draft Section', body: 'Extra info from draft'),
      ],
    );

    // 3. Verify merge took effect.
    final merged = await repo.getLeadById(original.id);
    expect(merged!.name, 'Abebe Kebede (Merged)');
    expect(merged.businessType, 'Wholesaler');
    expect(merged.status, 'CONTACTED');
    expect(merged.notes, 'Merged notes');

    final mergedPhones = await repo.getPhonesForLead(original.id);
    expect(mergedPhones.map((p) => p.e164).toSet(),
        equals({'+251911000001', '+251933000001'}));

    final mergedSections = await repo.getSectionsForLead(original.id);
    expect(mergedSections.length, 3);
    expect(mergedSections[0].title, 'Address');
    expect(mergedSections[0].body, 'Bole, Addis Ababa');

    // 4. Undo.
    await repo.undoMerge(snapshot);

    // 5. Verify full restoration.
    final restored = await repo.getLeadById(original.id);
    expect(restored!.name, original.name,
        reason: 'name must revert to pre-merge value');
    expect(restored.businessType, original.businessType,
        reason: 'businessType must revert');
    expect(restored.status, original.status,
        reason: 'status must revert');
    expect(restored.notes, original.notes,
        reason: 'notes must revert');

    final restoredPhones = await repo.getPhonesForLead(original.id);
    expect(
      restoredPhones.map((p) => p.e164).toSet(),
      equals(originalPhones.map((p) => p.e164).toSet()),
      reason: 'phones must revert to original set',
    );

    final restoredSections = await repo.getSectionsForLead(original.id);
    expect(restoredSections.length, originalSections.length,
        reason: 'section count must revert');
    for (var i = 0; i < originalSections.length; i++) {
      expect(restoredSections[i].title, originalSections[i].title,
          reason: 'section[$i].title must revert');
      expect(restoredSections[i].body, originalSections[i].body,
          reason: 'section[$i].body must revert');
    }
  });

  // ── Snapshot captures pre-merge state precisely ───────────────────────────

  test('snapshot exactly captures pre-merge name, phones, and sections', () async {
    final lead = await repo.createLead(
      name: 'Before',
      businessType: 'Cafe',
      status: 'NEW',
      phones: [
        (e164: '+251911000010', label: null, isPrimary: true),
      ],
      sections: [
        (title: 'Note', body: 'Important contact'),
      ],
    );

    final snapshot = await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'After',
      mergedPhones: [(e164: '+251911000010', label: null, isPrimary: true)],
      mergedSections: [(title: 'Different Note', body: 'Changed')],
    );

    expect(snapshot.name, 'Before');
    expect(snapshot.businessType, 'Cafe');
    expect(snapshot.status, 'NEW');
    expect(snapshot.phones.length, 1);
    expect(snapshot.phones.first.e164, '+251911000010');
    expect(snapshot.sections.length, 1);
    expect(snapshot.sections.first.title, 'Note');
    expect(snapshot.sections.first.body, 'Important contact');
  });

  // ── Undo with no sections ─────────────────────────────────────────────────

  test('undo restores lead with no original sections', () async {
    final lead = await repo.createLead(
      name: 'Simple Lead',
      phones: [(e164: '+251911000020', label: null, isPrimary: true)],
    );

    final snapshot = await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'Complex Lead',
      mergedPhones: [(e164: '+251911000020', label: null, isPrimary: true)],
      mergedSections: [
        (title: 'Added Section', body: 'Added body'),
      ],
    );

    final afterMerge = await repo.getSectionsForLead(lead.id);
    expect(afterMerge.length, 1);

    await repo.undoMerge(snapshot);

    final afterUndo = await repo.getSectionsForLead(lead.id);
    expect(afterUndo.length, 0,
        reason: 'Sections added during merge should be removed by undo');
  });

  // ── FTS still works after undo ────────────────────────────────────────────

  test('FTS search finds lead by original name after undo', () async {
    final lead = await repo.createLead(
      name: 'UniqueNameXYZ',
      phones: [(e164: '+251911000030', label: null, isPrimary: true)],
    );

    final snapshot = await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'DifferentNameABC',
      mergedPhones: [(e164: '+251911000030', label: null, isPrimary: true)],
      mergedSections: [],
    );

    // Before undo: searching original name finds nothing.
    final beforeUndo = await repo.searchLeads('UniqueNameXYZ');
    expect(beforeUndo, isEmpty,
        reason: 'After merge, original name should no longer match FTS');

    // After undo: original name should match again.
    await repo.undoMerge(snapshot);
    final afterUndo = await repo.searchLeads('UniqueNameXYZ');
    expect(afterUndo.map((l) => l.id), contains(lead.id),
        reason: 'After undo, original name should be searchable again');

    // And the merged name should no longer match.
    final mergedSearch = await repo.searchLeads('DifferentNameABC');
    expect(mergedSearch, isEmpty,
        reason: 'After undo, merged name should not appear in FTS');
  });

  // ── Multiple merges with single undo restores pre-first-merge state ───────

  test('undo after two sequential merges restores snapshot state', () async {
    final lead = await repo.createLead(
      name: 'Step Zero',
      phones: [(e164: '+251911000040', label: null, isPrimary: true)],
    );

    final snapshot = await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'Step One',
      mergedPhones: [(e164: '+251911000040', label: null, isPrimary: true)],
      mergedSections: [],
    );

    // A second merge (simulating a second user action before undo).
    await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'Step Two',
      mergedPhones: [(e164: '+251911000040', label: null, isPrimary: true)],
      mergedSections: [],
    );

    final atStepTwo = await repo.getLeadById(lead.id);
    expect(atStepTwo!.name, 'Step Two');

    // Undo to the snapshot (Step Zero state).
    await repo.undoMerge(snapshot);

    final restored = await repo.getLeadById(lead.id);
    expect(restored!.name, 'Step Zero',
        reason: 'Undo should restore to the snapshot, regardless of intermediate merges');
  });

  // ── isPrimary preserved on undo ───────────────────────────────────────────

  test('phone isPrimary flag is preserved correctly on undo', () async {
    final lead = await repo.createLead(
      name: 'PrimaryCheck',
      phones: [
        (e164: '+251911000050', label: null, isPrimary: true),
        (e164: '+251922000050', label: 'Work', isPrimary: false),
      ],
    );

    final snapshot = await repo.mergeLead(
      targetLeadId: lead.id,
      name: 'PrimaryCheck',
      mergedPhones: [
        (e164: '+251911000050', label: null, isPrimary: false),
        (e164: '+251922000050', label: 'Work', isPrimary: true),
      ],
      mergedSections: [],
    );

    await repo.undoMerge(snapshot);

    final phones = await repo.getPhonesForLead(lead.id);
    final primary = phones.firstWhere((p) => p.isPrimary);
    expect(primary.e164, '+251911000050',
        reason: 'Original primary phone must be restored after undo');
  });
}
