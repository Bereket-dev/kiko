// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter_test/flutter_test.dart';
import 'package:kiko/features/parser/lead_text_parser.dart';
import 'package:kiko/features/parser/parsed_lead.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeadTextParser tests — spec section 6.3
//
// Covers the canonical paste example and surrounding edge cases.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final parser = LeadTextParser();

  // ── Section 6.3 canonical paste example ────────────────────────────────────
  //
  //  Abebe Kebede
  //  0911 23 45 67
  //  0922 33 44 55
  //  Business: Retailer
  //
  //  Products
  //  Sells mobile accessories and spare parts
  //
  //  Location
  //  Merkato, Addis Ababa
  //  near the big mosque
  //
  // ────────────────────────────────────────────────────────────────────────────

  const canonicalPaste = '''
Abebe Kebede
0911 23 45 67
0922 33 44 55
Business: Retailer

Products
Sells mobile accessories and spare parts

Location
Merkato, Addis Ababa
near the big mosque
''';

  group('Section 6.3 canonical paste example', () {
    late ParsedLead result;

    setUpAll(() => result = parser.parse(canonicalPaste));

    test('name is extracted correctly', () {
      expect(result.name, 'Abebe Kebede');
    });

    test('businessType is extracted correctly', () {
      expect(result.businessType, 'Retailer');
    });

    test('exactly two phones are found', () {
      expect(result.phones.length, 2);
    });

    test('first phone is primary and normalises to E.164', () {
      expect(result.phones.first.isPrimary, isTrue);
      expect(result.phones.first.e164, '+251911234567');
    });

    test('second phone is not primary and normalises to E.164', () {
      expect(result.phones[1].isPrimary, isFalse);
      expect(result.phones[1].e164, '+251922334455');
    });

    test('two sections are created', () {
      expect(result.sections.length, 2);
    });

    test('first section title is "Products"', () {
      expect(result.sections[0].title, 'Products');
    });

    test('first section body contains the product text', () {
      expect(result.sections[0].body,
          contains('Sells mobile accessories'));
    });

    test('second section title is "Location"', () {
      expect(result.sections[1].title, 'Location');
    });

    test('second section body contains both location lines', () {
      expect(result.sections[1].body, contains('Merkato'));
      expect(result.sections[1].body, contains('near the big mosque'));
    });
  });

  // ── Amharic name ─────────────────────────────────────────────────────────

  group('Amharic name detection', () {
    test('pure Amharic name is extracted', () {
      final result = parser.parse('''
አበበ ከበደ
0911234567
Business: Wholesale
''');
      expect(result.name, 'አበበ ከበደ');
    });

    test('mixed Amharic+Latin name is extracted', () {
      final result = parser.parse('''
Dawit ዳዊት Tesfaye
0911234567
''');
      // Mixed — starts with Latin word, contains Amharic
      expect(result.name, isNotNull);
    });

    test('Amharic business type label', () {
      final result = parser.parse('''
Almaz Tadesse
0922334455
ዓይነት: ጅምላ
''');
      expect(result.businessType, 'ጅምላ');
    });

    test('Amharic business type without colon', () {
      final result = parser.parse('''
Mulugeta
0911223344
ቢዝነስ ኤጀንሲ
''');
      // "ቢዝነስ" is the prefix but without a separator — won't match the label
      // pattern; businessType remains null in this case.
      // Just verifying it doesn't crash.
      expect(result, isNotNull);
    });
  });

  // ── Phone extraction edge cases ──────────────────────────────────────────

  group('Phone extraction edge cases', () {
    test('single phone only', () {
      final result = parser.parse('0911234567');
      expect(result.phones.length, 1);
      expect(result.phones.first.e164, '+251911234567');
    });

    test('phone with +251 prefix', () {
      final result = parser.parse('+251911234567\nAbebe');
      expect(result.phones.first.e164, '+251911234567');
    });

    test('phone with 00251 prefix', () {
      final result = parser.parse('00251922334455');
      expect(result.phones.first.e164, '+251922334455');
    });

    test('inline phone in text line strips phone, keeps rest', () {
      final result = parser.parse(
          'Call me at 0911234567 for more info\nAbebe Kebede\nBusiness: Retail');
      // Phone found
      expect(result.phones.first.e164, '+251911234567');
      // "Call me at  for more info" — text should appear in body/sections
      expect(result.remainingBody, contains('Call me at'));
      expect(result.remainingBody, contains('for more info'));
    });

    test('multiple phones on one line', () {
      final result = parser.parse('0911234567 / 0922334455');
      expect(result.phones.length, 2);
    });

    test('duplicate phones are both captured', () {
      final result = parser.parse('0911234567\n+251911234567');
      // Both raw tokens resolve to the same E.164 — both stored
      expect(result.phones.length, 2);
    });

    test('no phones → empty list', () {
      final result = parser.parse('Abebe Kebede\nBusiness: Retailer');
      expect(result.phones, isEmpty);
    });

    test('invalid phone token is ignored', () {
      final result = parser.parse('123\nAbebe\n0911234567');
      expect(result.phones.length, 1);
      expect(result.phones.first.e164, '+251911234567');
    });
  });

  // ── Name detection edge cases ────────────────────────────────────────────

  group('Name detection edge cases', () {
    test('ALL CAPS name is accepted', () {
      final result = parser.parse('ABEBE KEBEDE\n0911234567');
      expect(result.name, 'ABEBE KEBEDE');
    });

    test('single word name', () {
      final result = parser.parse('Dawit\n0911234567');
      expect(result.name, 'Dawit');
    });

    test('no name in text', () {
      final result = parser.parse('0911234567');
      expect(result.name, isNull);
    });

    test('business label line is not misidentified as a name', () {
      final result = parser.parse('Business: Retailer\n0911234567');
      expect(result.name, isNull);
      expect(result.businessType, 'Retailer');
    });
  });

  // ── Business type edge cases ─────────────────────────────────────────────

  group('Business type edge cases', () {
    test('Type: label variant', () {
      final result = parser.parse('Abebe\n0911234567\nType: Wholesaler');
      expect(result.businessType, 'Wholesaler');
    });

    test('Biz: label variant', () {
      final result = parser.parse('Abebe\n0911234567\nBiz: Distributor');
      expect(result.businessType, 'Distributor');
    });

    test('business type label without colon', () {
      final result = parser.parse('Abebe\n0911234567\nBusiness Retailer');
      expect(result.businessType, 'Retailer');
    });

    test('no business type → null', () {
      final result = parser.parse('Abebe Kebede\n0911234567');
      expect(result.businessType, isNull);
    });
  });

  // ── Section building ─────────────────────────────────────────────────────

  group('Section building', () {
    test('single paragraph → one section with empty title', () {
      final result = parser.parse('''
Abebe
0911234567

Just some notes about this lead
''');
      expect(result.sections.length, 1);
      expect(result.sections.first.title, isEmpty);
      expect(result.sections.first.body, contains('Just some notes'));
    });

    test('multi-paragraph → multiple sections', () {
      final result = parser.parse('''
Abebe
0911234567

Notes
first note here

Address
Addis Ababa downtown
''');
      expect(result.sections.length, 2);
      expect(result.sections[0].title, 'Notes');
      expect(result.sections[1].title, 'Address');
    });

    test('long first-line paragraph → no title extracted', () {
      final longLine =
          'This is a very long first line that exceeds forty characters easily';
      final result = parser.parse('0911234567\n\n$longLine\nsecond line here');
      expect(result.sections.length, 1);
      expect(result.sections.first.title, isEmpty);
      expect(result.sections.first.body, contains(longLine));
    });

    test('no remaining text → empty sections', () {
      final result = parser.parse('Abebe Kebede\n0911234567\nBusiness: Retail');
      expect(result.sections, isEmpty);
    });
  });

  // ── Empty / whitespace input ─────────────────────────────────────────────

  group('Edge cases: empty / whitespace', () {
    test('empty string returns empty ParsedLead', () {
      final result = parser.parse('');
      expect(result.name, isNull);
      expect(result.phones, isEmpty);
      expect(result.sections, isEmpty);
    });

    test('only whitespace returns empty ParsedLead', () {
      final result = parser.parse('   \n\n\t  ');
      expect(result.name, isNull);
      expect(result.phones, isEmpty);
    });

    test('only blank lines', () {
      final result = parser.parse('\n\n\n');
      expect(result.phones, isEmpty);
    });
  });

  // ── Real-world paste variants ────────────────────────────────────────────

  group('Real-world paste variants', () {
    test('WhatsApp-style: name then phone then text', () {
      final result = parser.parse('''
Sara Haile
+251 91 234 5678
Type: Agent

She is interested in bulk orders.
Contact in the evening.
''');
      expect(result.name, 'Sara Haile');
      expect(result.phones.first.e164, '+251912345678');
      expect(result.businessType, 'Agent');
      // Two lines in one paragraph: first short line becomes title,
      // second becomes body.
      expect(result.sections.length, 1);
      expect(result.sections.first.title, contains('bulk orders'));
      expect(result.sections.first.body, contains('Contact in the evening'));
    });

    test('SMS-style: phone first then name', () {
      final result = parser.parse('''
0922 11 22 33
Tigist Alemu
Business: Importer
''');
      expect(result.phones.first.e164, '+251922112233');
      expect(result.name, 'Tigist Alemu');
      expect(result.businessType, 'Importer');
    });

    test('only phones and no other data', () {
      final result = parser.parse('''
0911 11 11 11
0922 22 22 22
0933 33 33 33
''');
      expect(result.phones.length, 3);
      expect(result.name, isNull);
      expect(result.businessType, isNull);
    });

    test('number with country code in raw text matches', () {
      final result = parser.parse('''
Bekele Mamo
+251 9 11 22 33 44
Business: Retailer
''');
      expect(result.phones.first.e164, '+251911223344');
    });
  });
}
