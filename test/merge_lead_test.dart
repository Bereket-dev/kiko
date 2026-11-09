// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/app/providers.dart';
import 'package:kiko/core/db/database.dart';
import 'package:kiko/core/db/leads_repository.dart';
import 'package:kiko/core/models/lead_status.dart';
import 'package:kiko/features/leads/duplicate_detection_dialog.dart';
import 'package:kiko/features/leads/lead_draft.dart';
import 'package:kiko/features/leads/merge_lead_screen.dart';
import 'package:kiko/features/leads/sections_crud_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Creates an in-memory AppDatabase without encryption for tests.
AppDatabase _openTestDb() => AppDatabase(openInMemoryDatabase());

/// Returns an override scope backed by an in-memory DB.
List<Override> _dbOverrides(AppDatabase db) => [
      appDatabaseProvider.overrideWithValue(db),
    ];

// ─────────────────────────────────────────────────────────────────────────────
// Repository unit tests (no widgets required)
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late LeadsRepository repo;

  setUp(() async {
    db = _openTestDb();
    repo = LeadsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ── Fixtures ───────────────────────────────────────────────────────────────

  Future<Lead> _seedLead({
    String name = 'Abebe Kebede',
    String? businessType = 'Retailer',
    List<String> e164s = const ['+251911000001'],
    List<({String title, String body})> sections = const [],
    String status = 'NEW',
  }) async {
    return repo.createLead(
      name: name,
      businessType: businessType,
      status: status,
      phones: e164s
          .asMap()
          .entries
          .map((e) => (
                e164: e.value,
                label: null as String?,
                isPrimary: e.key == 0,
              ))
          .toList(),
      sections: sections,
    );
  }

  // ── findDuplicatesByPhones ─────────────────────────────────────────────────

  group('findDuplicatesByPhones', () {
    test('returns empty when no leads exist', () async {
      final result = await repo.findDuplicatesByPhones(['+251911000001']);
      expect(result, isEmpty);
    });

    test('detects single duplicate', () async {
      final existing = await _seedLead(e164s: ['+251911000001']);
      final dupes =
          await repo.findDuplicatesByPhones(['+251911000001']);
      expect(dupes.length, 1);
      expect(dupes.first.id, existing.id);
    });

    test('detects duplicate from multiple phones', () async {
      final existing = await _seedLead(
          e164s: ['+251911000001', '+251922000002']);
      final dupes =
          await repo.findDuplicatesByPhones(['+251922000002']);
      expect(dupes.length, 1);
      expect(dupes.first.id, existing.id);
    });

    test('excludes self when editing (excludeLeadId)', () async {
      final existing = await _seedLead(e164s: ['+251911000001']);
      final dupes = await repo.findDuplicatesByPhones(
        ['+251911000001'],
        excludeLeadId: existing.id,
      );
      expect(dupes, isEmpty);
    });

    test('returns multiple duplicates when several leads share numbers', () async {
      final l1 = await _seedLead(name: 'A', e164s: ['+251911000001']);
      final l2 = await _seedLead(name: 'B', e164s: ['+251922000002']);
      final dupes = await repo.findDuplicatesByPhones(
          ['+251911000001', '+251922000002']);
      final ids = dupes.map((d) => d.id).toSet();
      expect(ids, containsAll([l1.id, l2.id]));
    });

    test('returns empty for phones not in DB', () async {
      await _seedLead(e164s: ['+251911000001']);
      final dupes =
          await repo.findDuplicatesByPhones(['+251999999999']);
      expect(dupes, isEmpty);
    });
  });

  // ── mergeLead ─────────────────────────────────────────────────────────────

  group('mergeLead', () {
    test('overwrites name when provided', () async {
      final target = await _seedLead(name: 'Old Name');
      await repo.mergeLead(
        targetLeadId: target.id,
        name: 'New Name',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [],
      );
      final updated = await repo.getLeadById(target.id);
      expect(updated!.name, 'New Name');
    });

    test('keeps existing name when name is null', () async {
      final target = await _seedLead(name: 'Existing Name');
      await repo.mergeLead(
        targetLeadId: target.id,
        name: null, // no override
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [],
      );
      final updated = await repo.getLeadById(target.id);
      expect(updated!.name, 'Existing Name');
    });

    test('replaces phones with merged set', () async {
      final target = await _seedLead(
          e164s: ['+251911000001', '+251922000002']);
      await repo.mergeLead(
        targetLeadId: target.id,
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true),
          (e164: '+251933000003', label: 'Work', isPrimary: false),
        ],
        mergedSections: [],
      );
      final phones = await repo.getPhonesForLead(target.id);
      final e164s = phones.map((p) => p.e164).toSet();
      expect(e164s, equals({'+251911000001', '+251933000003'}));
      expect(phones.where((p) => p.isPrimary).length, 1);
    });

    test('replaces sections with ordered merged list', () async {
      final target = await _seedLead(sections: [
        (title: 'Old Section', body: 'Old body'),
      ]);
      await repo.mergeLead(
        targetLeadId: target.id,
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [
          (title: 'Section A', body: 'Body A'),
          (title: 'Section B', body: 'Body B'),
        ],
      );
      final sections = await repo.getSectionsForLead(target.id);
      expect(sections.length, 2);
      expect(sections[0].title, 'Section A');
      expect(sections[1].title, 'Section B');
    });

    test('updates status when provided', () async {
      final target = await _seedLead(status: 'NEW');
      await repo.mergeLead(
        targetLeadId: target.id,
        status: 'WON',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [],
      );
      final updated = await repo.getLeadById(target.id);
      expect(updated!.status, 'WON');
    });

    test('returns a valid MergeSnapshot capturing pre-merge state', () async {
      final target = await _seedLead(
        name: 'Before',
        businessType: 'Retailer',
        e164s: ['+251911000001'],
        sections: [(title: 'Notes', body: 'Important')],
      );

      final snapshot = await repo.mergeLead(
        targetLeadId: target.id,
        name: 'After',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true),
          (e164: '+251922000002', label: null, isPrimary: false),
        ],
        mergedSections: [(title: 'Draft Section', body: 'New body')],
      );

      // Snapshot should hold PRE-merge values.
      expect(snapshot.name, 'Before');
      expect(snapshot.businessType, 'Retailer');
      expect(snapshot.phones.length, 1);
      expect(snapshot.phones.first.e164, '+251911000001');
      expect(snapshot.sections.length, 1);
      expect(snapshot.sections.first.title, 'Notes');
    });
  });

  // ── undoMerge ─────────────────────────────────────────────────────────────

  group('undoMerge', () {
    test('restores lead to pre-merge state (name, status, phones, sections)',
        () async {
      final target = await _seedLead(
        name: 'Original',
        status: 'CONTACTED',
        e164s: ['+251911000001'],
        sections: [
          (title: 'Address', body: 'Merkato'),
        ],
      );

      // Perform a merge that changes everything.
      final snapshot = await repo.mergeLead(
        targetLeadId: target.id,
        name: 'Merged Name',
        status: 'WON',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true),
          (e164: '+251922000002', label: null, isPrimary: false),
        ],
        mergedSections: [
          (title: 'New Section', body: 'New Body'),
        ],
      );

      // Verify the merge took effect.
      final merged = await repo.getLeadById(target.id);
      expect(merged!.name, 'Merged Name');
      expect(merged.status, 'WON');

      // Undo.
      await repo.undoMerge(snapshot);

      // Verify rollback.
      final restored = await repo.getLeadById(target.id);
      expect(restored!.name, 'Original');
      expect(restored.status, 'CONTACTED');

      final phones = await repo.getPhonesForLead(target.id);
      expect(phones.length, 1);
      expect(phones.first.e164, '+251911000001');

      final sections = await repo.getSectionsForLead(target.id);
      expect(sections.length, 1);
      expect(sections.first.title, 'Address');
      expect(sections.first.body, 'Merkato');
    });

    test('undo is idempotent: second undo from same snapshot re-restores',
        () async {
      final target = await _seedLead(name: 'Start');
      final snap = await repo.mergeLead(
        targetLeadId: target.id,
        name: 'After Merge',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [],
      );

      await repo.undoMerge(snap);
      await repo.undoMerge(snap); // second undo from same snapshot

      final lead = await repo.getLeadById(target.id);
      // After a second undo from the same snapshot the lead should
      // still have the snapshot's values (idempotent re-application).
      expect(lead!.name, 'Start');
    });

    test('FTS row is rebuilt after undo (lead name reverts)', () async {
      // This test verifies _rebuildFts is called inside undoMerge by confirming
      // the lead's name is correctly restored, which requires the FTS transaction
      // to commit without error. A full FTS5 MATCH test requires a device with
      // SQLCipher; see Phase 10 integration tests.
      final target = await _seedLead(name: 'FindMe');
      final snap = await repo.mergeLead(
        targetLeadId: target.id,
        name: 'NotFindMe',
        mergedPhones: [
          (e164: '+251911000001', label: null, isPrimary: true)
        ],
        mergedSections: [],
      );

      // After merge the name should be 'NotFindMe'.
      final afterMerge = await repo.getLeadById(target.id);
      expect(afterMerge!.name, 'NotFindMe');

      // After undo the name should revert to 'FindMe'.
      await repo.undoMerge(snap);
      final afterUndo = await repo.getLeadById(target.id);
      expect(afterUndo!.name, 'FindMe');
    });
  });

  // ── DuplicateDetectionDialog widget tests ─────────────────────────────────

  group('DuplicateDetectionDialog', () {
    late Lead fakeLead;

    setUp(() async {
      fakeLead = await _seedLead(
          name: 'Existing Lead', e164s: ['+251911000001']);
    });

    testWidgets('shows lead name in dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DuplicateDetectionDialog.show(
                  context,
                  draft: LeadDraft(name: 'Draft Lead'),
                  duplicates: [fakeLead],
                  canSaveAsSeparate: false,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Duplicate phone detected'), findsOneWidget);
      expect(find.text('Existing Lead'), findsWidgets);
    });

    testWidgets('cancel button returns DuplicateAction.cancel', (tester) async {
      DuplicateDetectionResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await DuplicateDetectionDialog.show(
                    context,
                    draft: LeadDraft(name: 'Draft'),
                    duplicates: [fakeLead],
                    canSaveAsSeparate: false,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(captured?.action, DuplicateAction.cancel);
    });

    testWidgets('Review & merge button returns reviewAndMerge action',
        (tester) async {
      DuplicateDetectionResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await DuplicateDetectionDialog.show(
                    context,
                    draft: LeadDraft(name: 'Draft'),
                    duplicates: [fakeLead],
                    canSaveAsSeparate: false,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review & merge'));
      await tester.pumpAndSettle();

      expect(captured?.action, DuplicateAction.reviewAndMerge);
      expect(captured?.chosenTargetLeadId, fakeLead.id);
    });

    testWidgets('Keep existing button returns keepExisting action',
        (tester) async {
      DuplicateDetectionResult? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured = await DuplicateDetectionDialog.show(
                    context,
                    draft: LeadDraft(name: 'Draft'),
                    duplicates: [fakeLead],
                    canSaveAsSeparate: false,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep existing'));
      await tester.pumpAndSettle();

      expect(captured?.action, DuplicateAction.keepExisting);
    });

    testWidgets(
        'Save as separate button only visible when canSaveAsSeparate=true',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DuplicateDetectionDialog.show(
                  context,
                  draft: LeadDraft(name: 'Draft'),
                  duplicates: [fakeLead],
                  canSaveAsSeparate: false,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save as separate'), findsNothing);
    });

    testWidgets(
        'Save as separate button visible when canSaveAsSeparate=true',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DuplicateDetectionDialog.show(
                  context,
                  draft: LeadDraft(name: 'Draft'),
                  duplicates: [fakeLead],
                  canSaveAsSeparate: true,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Save as separate'), findsOneWidget);
    });

    testWidgets('radio selector shown for multiple duplicates', (tester) async {
      final lead2 = await _seedLead(
          name: 'Second Lead', e164s: ['+251922000002']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _dbOverrides(db),
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DuplicateDetectionDialog.show(
                  context,
                  draft: LeadDraft(name: 'Draft'),
                  duplicates: [fakeLead, lead2],
                  canSaveAsSeparate: false,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(RadioListTile<int>), findsNWidgets(2));
    });
  });

  // ── MergeLeadScreen widget tests ─────────────────────────────────────────

  group('MergeLeadScreen', () {
    late Lead targetLead;
    late List<LeadPhone> existingPhones;
    late List<LeadSection> existingSections;

    setUp(() async {
      targetLead = await _seedLead(
        name: 'Target Lead',
        businessType: 'Wholesaler',
        status: 'CONTACTED',
        e164s: ['+251911000001'],
        sections: [(title: 'Info', body: 'Some info')],
      );
      existingPhones = await repo.getPhonesForLead(targetLead.id);
      existingSections = await repo.getSectionsForLead(targetLead.id);
    });

    Widget _buildScreen({
      LeadDraft? draft,
      List<({String e164, String? label, bool isPrimary})>? draftPhones,
    }) {
      return ProviderScope(
        overrides: _dbOverrides(db),
        child: MaterialApp(
          home: MergeLeadScreen(
            targetLead: targetLead,
            existingPhones: existingPhones,
            existingSections: existingSections,
            draft: draft ??
                LeadDraft(
                  name: 'Draft Lead',
                  businessType: 'Retailer',
                  status: LeadStatus.won,
                  notes: 'Draft notes',
                  phones: [
                    PhoneEntry(raw: '+251922000002', isPrimary: true),
                  ],
                  sections: [
                    SectionEntry(title: 'Draft Section', body: 'Draft body'),
                  ],
                ),
            draftPhones: draftPhones ??
                [(e164: '+251922000002', label: null, isPrimary: true)],
            draftSections: [
              (title: 'Draft Section', body: 'Draft body')
            ],
          ),
        ),
      );
    }

    testWidgets('renders AppBar with Merge title', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Merge Lead'), findsOneWidget);
    });

    testWidgets('displays existing and draft column headers', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Existing'), findsWidgets);
      expect(find.text('Draft'), findsWidgets);
    });

    testWidgets('shows both existing and draft phone in phone list',
        (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('+251911000001'), findsOneWidget);
      expect(find.text('+251922000002'), findsOneWidget);
    });

    testWidgets('shows existing section in sections panel', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      // Scroll down to find sections
      await tester.scrollUntilVisible(
        find.text('Info'),
        200,
      );
      expect(find.text('Info'), findsOneWidget);
    });

    testWidgets('quick action chips are rendered', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Keep existing'), findsOneWidget);
      expect(find.text('Take from draft'), findsOneWidget);
      expect(find.text('Merge all'), findsOneWidget);
    });

    testWidgets('Merge button exists in AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('Merge'), findsOneWidget);
    });
  });
}
