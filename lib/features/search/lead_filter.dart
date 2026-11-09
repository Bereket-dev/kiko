import '../../core/models/lead_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeadFilter — Phase 7 search / filter model
// ─────────────────────────────────────────────────────────────────────────────
//
// Combined with FTS5 keyword search. All fields are optional; an empty filter
// returns every non-archived lead (unless [includeArchived] is true).
// ─────────────────────────────────────────────────────────────────────────────

/// Call direction used by the "has call of type" filter.
enum CallDirectionFilter {
  incoming('INCOMING'),
  outgoing('OUTGOING'),
  missed('MISSED');

  const CallDirectionFilter(this.dbValue);
  final String dbValue;

  String get label {
    switch (this) {
      case CallDirectionFilter.incoming:
        return 'Incoming';
      case CallDirectionFilter.outgoing:
        return 'Outgoing';
      case CallDirectionFilter.missed:
        return 'Missed';
    }
  }
}

class DateRangeMs {
  const DateRangeMs({this.startMs, this.endMs});

  final int? startMs;
  final int? endMs;

  bool get isEmpty => startMs == null && endMs == null;
  bool get isNotEmpty => !isEmpty;

  DateRangeMs copyWith({int? startMs, int? endMs, bool clearStart = false, bool clearEnd = false}) {
    return DateRangeMs(
      startMs: clearStart ? null : (startMs ?? this.startMs),
      endMs: clearEnd ? null : (endMs ?? this.endMs),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeMs &&
          other.startMs == startMs &&
          other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);
}

class LeadFilter {
  const LeadFilter({
    this.statuses = const {},
    this.sources = const {},
    this.createdRange = const DateRangeMs(),
    this.lastContactRange = const DateRangeMs(),
    this.hasReminder,
    this.callDirection,
    this.includeArchived = false,
    this.keyword = '',
  });

  /// Empty filter — all active (non-archived) leads.
  static const empty = LeadFilter();

  final Set<LeadStatus> statuses;
  final Set<LeadSource> sources;
  final DateRangeMs createdRange;
  final DateRangeMs lastContactRange;

  /// null = any; true = has PENDING reminder; false = no PENDING reminder.
  final bool? hasReminder;

  /// null = any call direction; otherwise lead must have at least one call
  /// of this type.
  final CallDirectionFilter? callDirection;

  /// When false (default), archived leads are excluded.
  final bool includeArchived;

  /// FTS5 keyword (may be empty).
  final String keyword;

  bool get hasActiveFilters =>
      statuses.isNotEmpty ||
      sources.isNotEmpty ||
      createdRange.isNotEmpty ||
      lastContactRange.isNotEmpty ||
      hasReminder != null ||
      callDirection != null ||
      includeArchived ||
      keyword.trim().isNotEmpty;

  LeadFilter copyWith({
    Set<LeadStatus>? statuses,
    Set<LeadSource>? sources,
    DateRangeMs? createdRange,
    DateRangeMs? lastContactRange,
    bool? hasReminder,
    CallDirectionFilter? callDirection,
    bool? includeArchived,
    String? keyword,
    bool clearHasReminder = false,
    bool clearCallDirection = false,
  }) {
    return LeadFilter(
      statuses: statuses ?? this.statuses,
      sources: sources ?? this.sources,
      createdRange: createdRange ?? this.createdRange,
      lastContactRange: lastContactRange ?? this.lastContactRange,
      hasReminder: clearHasReminder ? null : (hasReminder ?? this.hasReminder),
      callDirection:
          clearCallDirection ? null : (callDirection ?? this.callDirection),
      includeArchived: includeArchived ?? this.includeArchived,
      keyword: keyword ?? this.keyword,
    );
  }

  LeadFilter clear() => LeadFilter.empty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeadFilter &&
          _setEq(other.statuses, statuses) &&
          _setEq(other.sources, sources) &&
          other.createdRange == createdRange &&
          other.lastContactRange == lastContactRange &&
          other.hasReminder == hasReminder &&
          other.callDirection == callDirection &&
          other.includeArchived == includeArchived &&
          other.keyword == keyword;

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(statuses),
        Object.hashAllUnordered(sources),
        createdRange,
        lastContactRange,
        hasReminder,
        callDirection,
        includeArchived,
        keyword,
      );
}

bool _setEq<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);
