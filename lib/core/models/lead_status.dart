import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeadStatus  (fixed enum, spec section 3)
// ─────────────────────────────────────────────────────────────────────────────

enum LeadStatus {
  newLead('NEW'),
  contacted('CONTACTED'),
  interested('INTERESTED'),
  negotiating('NEGOTIATING'),
  won('WON'),
  lost('LOST'),
  followUp('FOLLOW_UP');

  const LeadStatus(this.dbValue);

  /// The string stored in the database CHECK constraint.
  final String dbValue;

  static LeadStatus fromDb(String value) {
    return LeadStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => LeadStatus.newLead,
    );
  }

  String get label {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.contacted:
        return 'Contacted';
      case LeadStatus.interested:
        return 'Interested';
      case LeadStatus.negotiating:
        return 'Negotiating';
      case LeadStatus.won:
        return 'Won';
      case LeadStatus.lost:
        return 'Lost';
      case LeadStatus.followUp:
        return 'Follow Up';
    }
  }

  Color get color {
    switch (this) {
      case LeadStatus.newLead:
        return const Color(0xFF1565C0); // blue
      case LeadStatus.contacted:
        return const Color(0xFF6A1B9A); // purple
      case LeadStatus.interested:
        return const Color(0xFF00838F); // teal
      case LeadStatus.negotiating:
        return const Color(0xFFE65100); // deep orange
      case LeadStatus.won:
        return const Color(0xFF2E7D32); // green
      case LeadStatus.lost:
        return const Color(0xFFC62828); // red
      case LeadStatus.followUp:
        return const Color(0xFF558B2F); // light green
    }
  }

  Color get backgroundColor => color.withValues(alpha: 0.12);
}

// ─────────────────────────────────────────────────────────────────────────────
// LeadSource  (fixed enum)
// ─────────────────────────────────────────────────────────────────────────────

enum LeadSource {
  paste('PASTE'),
  import_('IMPORT'),
  call('CALL'),
  manual('MANUAL');

  const LeadSource(this.dbValue);
  final String dbValue;

  static LeadSource fromDb(String value) {
    return LeadSource.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => LeadSource.manual,
    );
  }

  String get label {
    switch (this) {
      case LeadSource.paste:
        return 'Paste';
      case LeadSource.import_:
        return 'Import';
      case LeadSource.call:
        return 'Call';
      case LeadSource.manual:
        return 'Manual';
    }
  }
}
