// Pure Dart — no Flutter imports.
//
// Normalises phone numbers to E.164 format with a default region of Ethiopia
// (ET, country code +251).
//
// ── Ethiopian number facts (section 6.2) ─────────────────────────────────────
//
//  Mobile operators use 09x and 07x prefixes:
//    09[0-9]{8}   →  Ethio Telecom, Safaricom ET (10 digits local)
//    07[0-9]{8}   →  Safaricom ET (10 digits local)
//
//  Fixed-line uses 011 prefix (Addis Ababa) or 02x–05x (regional):
//    011[0-9]{7}  →  Addis Ababa landline  (10 digits local)
//    0[2-5][0-9]{8} →  Regional landline   (10 digits local)
//
//  International representations:
//    +251XXXXXXXXX   →  already E.164
//    00251XXXXXXXXX  →  IDD prefix variant
//    251XXXXXXXXX    →  country code without +
//
//  Subscriber number (without leading 0):
//    9XXXXXXXX or 7XXXXXXXX (9 digits) → prepend +251
//
// ─────────────────────────────────────────────────────────────────────────────

class PhoneNormalizationException implements Exception {
  PhoneNormalizationException(this.input, this.reason);
  final String input;
  final String reason;
  @override
  String toString() => 'PhoneNormalizationException: "$input" — $reason';
}

class PhoneNormalizer {
  const PhoneNormalizer({this.defaultRegion = 'ET'});

  /// ISO 3166-1 alpha-2 region used when no country code is present.
  final String defaultRegion;

  // ── Country codes for supported default regions ───────────────────────────
  static const Map<String, String> _regionToCallingCode = {
    'ET': '251', // Ethiopia
    'US': '1',
    'GB': '44',
    'KE': '254', // Kenya
    'NG': '234', // Nigeria
    'ZA': '27',  // South Africa
  };

  /// Normalise [raw] to E.164 (e.g. "+251911234567").
  ///
  /// Returns null when the input is clearly not a phone number
  /// (too short, contains only letters, etc.) rather than throwing,
  /// so callers can skip invalid tokens gracefully.
  String? tryNormalize(String raw) {
    try {
      return normalize(raw);
    } on PhoneNormalizationException {
      return null;
    }
  }

  /// Normalise [raw] to E.164.  Throws [PhoneNormalizationException] on failure.
  String normalize(String raw) {
    // 1. Strip everything that is not a digit or leading '+'.
    final cleaned = _clean(raw);

    if (cleaned.isEmpty) {
      throw PhoneNormalizationException(raw, 'no digits found');
    }

    // 2. Resolve the number to E.164.
    return _resolve(cleaned, raw);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// Remove formatting characters, keeping digits and a leading '+'.
  static String _clean(String raw) {
    final trimmed = raw.trim();
    final buffer = StringBuffer();
    bool first = true;
    for (final ch in trimmed.runes) {
      final char = String.fromCharCode(ch);
      if (first && char == '+') {
        buffer.write('+');
        first = false;
        continue;
      }
      first = false;
      if (_isDigit(ch)) buffer.write(char);
    }
    return buffer.toString();
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;

  String _resolve(String cleaned, String original) {
    // Case A: already has '+' → treat as complete E.164 candidate.
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1);
      _assertLength(digits, original, min: 7, max: 15);
      return cleaned; // trust the caller's explicit '+' prefix
    }

    // Case B: IDD prefix 00 → strip and treat as international.
    if (cleaned.startsWith('00')) {
      final digits = cleaned.substring(2);
      _assertLength(digits, original, min: 7, max: 15);
      return '+$digits';
    }

    final callingCode = _regionToCallingCode[defaultRegion];
    if (callingCode == null) {
      throw PhoneNormalizationException(
          original, 'unsupported region: $defaultRegion');
    }

    // Case C: starts with the bare calling code (no 00 prefix, no +).
    //   e.g. "251911234567" for ET
    if (cleaned.startsWith(callingCode) &&
        cleaned.length == callingCode.length + 9) {
      _assertLength(cleaned, original, min: 7, max: 15);
      return '+$cleaned';
    }

    // Case D: local number with leading 0 (e.g. "0911234567" for ET).
    if (cleaned.startsWith('0')) {
      final withoutLeadingZero = cleaned.substring(1);
      _assertLength(withoutLeadingZero, original, min: 7, max: 12);
      return '+$callingCode$withoutLeadingZero';
    }

    // Case E: subscriber number only — no leading 0, no country code.
    //   ET: 9 digits starting with 9 or 7 (mobile) or 8 digits (landline area).
    _assertLength(cleaned, original, min: 7, max: 12);
    return '+$callingCode$cleaned';
  }

  static void _assertLength(
      String digits, String original, {required int min, required int max}) {
    if (digits.length < min || digits.length > max) {
      throw PhoneNormalizationException(
        original,
        'digit count ${digits.length} out of range [$min, $max]',
      );
    }
  }
}
