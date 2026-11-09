// Pure Dart — no Flutter imports.

// ─────────────────────────────────────────────────────────────────────────────
// ParsedPhone
// ─────────────────────────────────────────────────────────────────────────────

class ParsedPhone {
  const ParsedPhone({
    required this.e164,
    required this.raw,
    this.isPrimary = false,
  });

  /// Normalised E.164 form (e.g. "+251911234567").
  final String e164;

  /// The original string as it appeared in the pasted text.
  final String raw;

  /// True for the first phone number found in the text.
  final bool isPrimary;

  @override
  String toString() => 'ParsedPhone(e164: $e164, raw: $raw, isPrimary: $isPrimary)';

  @override
  bool operator ==(Object other) =>
      other is ParsedPhone && other.e164 == e164 && other.raw == raw;

  @override
  int get hashCode => Object.hash(e164, raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// ParsedSection
// ─────────────────────────────────────────────────────────────────────────────

class ParsedSection {
  const ParsedSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  String toString() => 'ParsedSection(title: $title, body: $body)';

  @override
  bool operator ==(Object other) =>
      other is ParsedSection && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(title, body);
}

// ─────────────────────────────────────────────────────────────────────────────
// ParsedLead
// ─────────────────────────────────────────────────────────────────────────────

class ParsedLead {
  const ParsedLead({
    this.name,
    this.businessType,
    this.phones = const [],
    this.sections = const [],
    this.remainingBody = '',
  });

  /// Contact name (may be Amharic or Latin).  Null if not detected.
  final String? name;

  /// Business / lead type (e.g. "Retailer", "Wholesale").  Null if not found.
  final String? businessType;

  /// All phones found; first entry has [ParsedPhone.isPrimary] == true.
  final List<ParsedPhone> phones;

  /// Body sections separated by blank lines after phones/name are stripped.
  final List<ParsedSection> sections;

  /// Any remaining text that didn't fit into named sections.
  final String remainingBody;

  @override
  String toString() =>
      'ParsedLead(name: $name, businessType: $businessType, '
      'phones: $phones, sections: $sections)';
}
