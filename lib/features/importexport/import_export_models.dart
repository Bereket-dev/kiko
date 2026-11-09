import '../../core/models/lead_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Import / export models — Phase 7
// ─────────────────────────────────────────────────────────────────────────────

enum ExportFormat { csv, xlsx }

enum ExportScope { all, filtered }

/// Canonical column keys used for import mapping and CSV headers.
abstract final class ExportColumns {
  static const name = 'name';
  static const businessType = 'business_type';
  static const status = 'status';
  static const source = 'source';
  static const phones = 'phones';
  static const notes = 'notes';
  static const createdAt = 'created_at';
  static const lastContactAt = 'last_contact_at';
  static const archived = 'archived';

  static const leadHeaders = <String>[
    name,
    businessType,
    status,
    source,
    phones,
    notes,
    createdAt,
    lastContactAt,
    archived,
  ];

  static const callHeaders = <String>[
    'lead_name',
    'lead_id',
    'e164',
    'call_type',
    'started_at',
    'duration_sec',
    'notes',
  ];

  static const reminderHeaders = <String>[
    'lead_name',
    'lead_id',
    'due_at',
    'state',
    'notes',
  ];

  /// Synonyms accepted when auto-mapping import headers (lowercased).
  static const Map<String, String> headerAliases = {
    'name': name,
    'full_name': name,
    'fullname': name,
    'contact': name,
    'business_type': businessType,
    'business': businessType,
    'type': businessType,
    'category': businessType,
    'status': status,
    'source': source,
    'phones': phones,
    'phone': phones,
    'phone_number': phones,
    'phone_numbers': phones,
    'mobile': phones,
    'notes': notes,
    'note': notes,
    'created_at': createdAt,
    'created': createdAt,
    'last_contact_at': lastContactAt,
    'last_contact': lastContactAt,
    'archived': archived,
  };
}

class ExportBundle {
  const ExportBundle({
    required this.leadsCsv,
    required this.callsCsv,
    required this.remindersCsv,
    this.xlsxBytes,
  });

  final String leadsCsv;
  final String callsCsv;
  final String remindersCsv;

  /// Present when format is XLSX (three sheets in one workbook).
  final List<int>? xlsxBytes;
}

/// One validated (or invalid) import row before persistence.
class ImportRow {
  ImportRow({
    required this.rowIndex,
    required this.name,
    required this.phonesE164,
    required this.rawPhones,
    this.businessType,
    this.status = LeadStatus.newLead,
    this.notes,
    this.errors = const [],
  });

  final int rowIndex;
  final String name;
  final String? businessType;
  final LeadStatus status;
  final String? notes;
  final List<String> phonesE164;
  final List<String> rawPhones;
  final List<String> errors;

  bool get isValid => errors.isEmpty && name.trim().isNotEmpty;
}

enum ImportConflictAction {
  /// Open merge UI for this row (interactive).
  reviewAndMerge,

  /// Leave the existing lead unchanged; skip the import row.
  keepExisting,

  /// Merge all fields from import into existing (union phones/sections).
  mergeAll,

  /// Skip this row without changing anything.
  skip,

  /// Create a new lead after removing conflicting phones from the row.
  saveAsSeparate,
}

/// Bulk policy applied to remaining conflicts after the user picks
/// "Apply to all remaining".
enum ImportApplyAllPolicy {
  keepExisting,
  mergeAll,
  skip,
}

class ImportResult {
  const ImportResult({
    this.created = 0,
    this.merged = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  final int created;
  final int merged;
  final int skipped;
  final List<String> errors;

  ImportResult copyWith({
    int? created,
    int? merged,
    int? skipped,
    List<String>? errors,
  }) {
    return ImportResult(
      created: created ?? this.created,
      merged: merged ?? this.merged,
      skipped: skipped ?? this.skipped,
      errors: errors ?? this.errors,
    );
  }
}
