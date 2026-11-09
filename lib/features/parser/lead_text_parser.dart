// Pure Dart — no Flutter imports.
//
// Parses a free-form text paste (e.g. from WhatsApp, SMS, a notes app) into
// a structured [ParsedLead].
//
// ── Parsing rules (spec section 6.3) ─────────────────────────────────────────
//
//  1. PHONES — scan every line for phone-number tokens.
//     • A token is a run of digits (and +, -, spaces, parentheses) that
//       PhoneNormalizer can resolve to a valid E.164 number.
//     • The first resolved phone becomes the primary.
//     • Lines that consist *only* of phone tokens are removed from the body.
//     • Inline phones embedded in text lines are stripped from those lines
//       but the rest of the line is kept.
//
//  2. NAME — first non-phone line that looks like a name:
//     • Matches Latin words (Title Case preferred, ALL CAPS accepted) or
//     • Matches Amharic (Ethiopic Unicode block U+1200–U+137F, U+AB01–U+AB2F).
//     • Must not match known label keywords (Business:, Type:, etc.).
//
//  3. BUSINESS TYPE — a line matching the pattern:
//       "Business[:]? <value>", "Type[:]? <value>",
//       "ዓይነት[:]? <value>", "ቢዝነስ[:]? <value>"
//     The extracted value becomes [ParsedLead.businessType].
//     The entire line is removed from the body.
//
//  4. SECTIONS — after phones, name, and business-type lines are removed,
//     the remaining text is split on blank lines.  Each chunk becomes a
//     [ParsedSection].  If a chunk's first line is short (≤ 40 chars) and
//     the chunk has more than one line, the first line is the section title
//     and the rest is the body.  Otherwise title = '' and body = full chunk.
//
// ─────────────────────────────────────────────────────────────────────────────

import 'parsed_lead.dart';
import 'phone_normalizer.dart';

class LeadTextParser {
  LeadTextParser({PhoneNormalizer? normalizer})
      : _normalizer = normalizer ?? const PhoneNormalizer();

  final PhoneNormalizer _normalizer;

  // Ethiopic Unicode range: U+1200–U+137F (main block) + U+AB01–U+AB2F (extended)
  static final _amharicRe = RegExp(r'[\u1200-\u137F\uAB01-\uAB2F]');

  // Known business-type label prefixes (case-insensitive Latin + Amharic).
  static final _businessLabelRe = RegExp(
    r'^(?:business|type|biz|ቢዝነስ|ዓይነት)\s*:?\s*(.+)$',
    caseSensitive: false,
  );

  // A token that could be a phone number: starts with + or digit,
  // contains only digits, spaces, dashes, dots, parentheses.
  static final _phoneTokenRe = RegExp(
    r'(?<![a-zA-Z\d])(\+?[\d][\d\s\-().]{5,20})(?![a-zA-Z\d])',
  );

  // ── Public API ───────────────────────────────────────────────────────────

  ParsedLead parse(String text) {
    if (text.trim().isEmpty) return const ParsedLead();

    final lines = text.split('\n');

    // Pass 1: Extract phones, annotate which lines are "phone-only".
    final phones = <ParsedPhone>[];
    final phoneOnlyLines = <int>{};
    final linePhoneSpans = <int, List<String>>{}; // line index → raw tokens

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final tokens = _extractPhoneTokens(line);
      if (tokens.isEmpty) continue;

      final resolved = <String>[];
      for (final token in tokens) {
        final e164 = _normalizer.tryNormalize(token);
        if (e164 != null) {
          resolved.add(token);
          final isPrimary = phones.isEmpty;
          phones.add(ParsedPhone(e164: e164, raw: token, isPrimary: isPrimary));
        }
      }
      if (resolved.isEmpty) continue;

      linePhoneSpans[i] = resolved;

      // A line is "phone-only" if every non-whitespace character belongs to
      // a resolved phone token.
      final strippedLine = _stripPhoneTokens(line, resolved).trim();
      if (strippedLine.isEmpty) {
        phoneOnlyLines.add(i);
      }
    }

    // Pass 2: Build cleaned lines (remove phone tokens from lines, keep rest).
    final cleanedLines = List<String>.from(lines);
    for (final i in linePhoneSpans.keys) {
      if (phoneOnlyLines.contains(i)) {
        cleanedLines[i] = ''; // mark for removal
      } else {
        cleanedLines[i] = _stripPhoneTokens(lines[i], linePhoneSpans[i]!).trim();
      }
    }

    // Pass 3: Extract business type.
    String? businessType;
    for (var i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i].trim();
      if (line.isEmpty) continue;
      final match = _businessLabelRe.firstMatch(line);
      if (match != null) {
        businessType = match.group(1)?.trim();
        cleanedLines[i] = '';
        break;
      }
    }

    // Pass 4: Extract name — first non-empty, non-phone-only line that looks
    //         like a name (not a label keyword).
    String? name;
    for (var i = 0; i < cleanedLines.length; i++) {
      final line = cleanedLines[i].trim();
      if (line.isEmpty) continue;
      if (_looksLikeName(line)) {
        name = line;
        cleanedLines[i] = '';
        break;
      }
    }

    // Pass 5: Build remaining body from non-empty cleaned lines.
    final bodyLines = cleanedLines.map((l) => l.trimRight()).toList();

    // Pass 6: Split body into sections on blank lines.
    final sections = _buildSections(bodyLines);

    // Compute remainingBody for convenience.
    final remaining = bodyLines
        .where((l) => l.isNotEmpty)
        .join('\n')
        .trim();

    return ParsedLead(
      name: name,
      businessType: businessType,
      phones: phones,
      sections: sections,
      remainingBody: remaining,
    );
  }

  // ── Name detection ────────────────────────────────────────────────────────

  bool _looksLikeName(String line) {
    // Reject lines with business-type label keywords.
    if (_businessLabelRe.hasMatch(line)) return false;
    // Reject lines that contain colons (likely key: value pairs).
    if (line.contains(':')) return false;
    // Reject lines with digits (phone fragments, numbers).
    if (line.contains(RegExp(r'\d'))) return false;

    // Accept if line contains Amharic characters.
    if (_amharicRe.hasMatch(line)) return true;

    // Latin name heuristic:
    //   - 1–4 words
    //   - Each word is purely alphabetic (no punctuation mid-word)
    //   - At least one word starts with an uppercase letter (Title Case or ALL CAPS)
    //   - Not all words are common lowercase connectors
    final words = line.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.length > 4) return false;

    final allAlpha = words.every((w) => RegExp(r'^[a-zA-Z]+$').hasMatch(w));
    if (!allAlpha) return false;

    // At least one word starts uppercase.
    final hasUpperStart = words.any((w) => w[0] == w[0].toUpperCase() &&
        RegExp(r'[A-Z]').hasMatch(w[0]));
    if (!hasUpperStart) return false;

    return true;
  }

  // ── Phone token extraction ────────────────────────────────────────────────

  List<String> _extractPhoneTokens(String line) {
    final matches = _phoneTokenRe.allMatches(line);
    return matches.map((m) => m.group(1)!.trim()).toList();
  }

  String _stripPhoneTokens(String line, List<String> tokens) {
    var result = line;
    for (final token in tokens) {
      // Escape for literal replacement.
      final escaped = RegExp.escape(token);
      result = result.replaceAll(RegExp(escaped), '').trim();
    }
    // Collapse multiple spaces left behind.
    return result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  // ── Section building ──────────────────────────────────────────────────────

  List<ParsedSection> _buildSections(List<String> lines) {
    // Split on runs of blank lines.
    final chunks = <List<String>>[];
    var current = <String>[];

    for (final line in lines) {
      if (line.isEmpty) {
        if (current.isNotEmpty) {
          chunks.add(List.from(current));
          current = [];
        }
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) chunks.add(current);

    final sections = <ParsedSection>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) continue;
      if (chunk.length == 1) {
        sections.add(ParsedSection(title: '', body: chunk.first));
      } else if (chunk.first.length <= 40) {
        // First short line is the title; rest is body.
        final title = chunk.first;
        final body = chunk.sublist(1).join('\n');
        sections.add(ParsedSection(title: title, body: body));
      } else {
        sections.add(ParsedSection(title: '', body: chunk.join('\n')));
      }
    }
    return sections;
  }
}
