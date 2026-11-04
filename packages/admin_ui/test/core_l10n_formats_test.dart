import 'package:admin_ui/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Locale;

/// The group separator French writes: a narrow no-break space.
const _frGroup = '\u202F';

void main() {
  AdminFormats formats(String locale) => AdminFormats(
    locale,
    messages: AdminLocalizations.lookup(_locale(locale)),
  );

  group('locale', () {
    test('falls back to the language, then to English', () {
      expect(AdminFormats('de_DE').locale, 'de');
      expect(AdminFormats('fr_CA').locale, 'fr_CA');
      expect(AdminFormats('xx').locale, 'en');
    });
  });

  group('decimal', () {
    final cases = <String, List<(num, int?, int?, String)>>{
      'en': [
        (1234.5, null, null, '1,234.5'),
        (2, 2, null, '2.00'),
        (1.23456, null, 2, '1.23'),
        (-9876543.21, null, null, '-9,876,543.21'),
      ],
      'fr': [
        (1234.5, null, null, '1${_frGroup}234,5'),
        (2, 2, null, '2,00'),
        (1.23456, null, 2, '1,23'),
      ],
      'de': [(1234.5, null, null, '1.234,5'), (2, 2, null, '2,00')],
      'ar': [(1234.5, null, null, '1,234.5')],
    };
    for (final MapEntry(key: locale, value: rows) in cases.entries) {
      test(locale, () {
        for (final (value, fixed, max, expected) in rows) {
          expect(
            formats(locale)
                .decimal(value, fractionDigits: fixed, maxFractionDigits: max),
            expected,
            reason: '$value',
          );
        }
      });
    }
  });

  test('integer groups thousands', () {
    expect(formats('en').integer(12345), '12,345');
    expect(formats('fr').integer(12345), '12${_frGroup}345');
    expect(formats('de').integer(12345), '12.345');
  });

  test('compact abbreviates', () {
    expect(formats('en').compact(1234), '1.23K');
    expect(formats('en').compact(3400000), '3.4M');
    expect(formats('fr').compact(1234), '1,23\u00A0k');
    expect(formats('de').compact(3400000), '3,4\u00A0Mio.');
  });

  test('percent follows the locale pattern', () {
    expect(formats('en').percent(0.42), '42%');
    expect(formats('en').percent(0.425, decimals: 1), '42.5%');
    expect(formats('fr').percent(0.42), '42\u00A0%');
    expect(formats('de').percent(0.425, decimals: 1), '42,5\u00A0%');
    expect(formats('ar').percent(0.42), '42\u200E%\u200E');
  });

  group('bytes', () {
    test('en: SI units, one decimal below ten', () {
      final en = formats('en');
      expect(en.bytes(0), '0 B');
      expect(en.bytes(512), '512 B');
      expect(en.bytes(1000), '1 kB');
      expect(en.bytes(1500), '1.5 kB');
      expect(en.bytes(757760), '758 kB');
      expect(en.bytes(999499), '999 kB');
      // Rounds up into the next unit rather than reading "1,000 kB".
      expect(en.bytes(999999), '1 MB');
      expect(en.bytes(12300000), '12 MB');
      expect(en.bytes(2500000000), '2.5 GB');
      expect(en.bytes(3 * 1000 * 1000 * 1000 * 1000), '3 TB');
    });

    test('fr writes octets', () {
      expect(formats('fr').bytes(757760), '758\u00A0ko');
      expect(formats('fr').bytes(1500), '1,5\u00A0ko');
    });

    test('de takes German digits with the English units', () {
      expect(
        AdminFormats('de').bytes(1500),
        '1,5 kB',
        reason: 'no German kit strings: English units, German number',
      );
    });

    test('ar names the unit', () {
      expect(formats('ar').bytes(757760), '758 كيلوبايت');
    });
  });

  group('parseDecimal', () {
    final cases = <String, Map<String, num?>>{
      'en': {
        '1,234.5': 1234.5,
        '1234.5': 1234.5,
        ' 12 ': 12,
        '-12': -12,
        '+3': 3,
        '.5': 0.5,
        '5.': 5,
        '1,234,567': 1234567,
        // Ambiguous or malformed.
        '1,5': null,
        '12,34': null,
        '1.234,5': null,
        '1.2.3': null,
        '1,234.5.6': null,
        '': null,
        '-': null,
        '.': null,
        'abc': null,
        '1e3': null,
        '1 234': null,
      },
      'de': {
        '1.234,5': 1234.5,
        '1234,5': 1234.5,
        '1,5': 1.5,
        '1.500': 1500,
        '1.5': null,
        '1,234.5': null,
      },
      'fr': {
        '1${_frGroup}234,5': 1234.5,
        '1\u00A0234,5': 1234.5,
        '1 234,5': 1234.5,
        '1234,5': 1234.5,
        '1234.5': 1234.5,
        '1,234.5': null,
        '1 23,5': null,
      },
      'ar': {'1,234.5': 1234.5, '\u200E-12': -12},
      'ar_EG': {'١٬٢٣٤٫٥': 1234.5, '١٢٣': 123, '12': 12},
      'en_IN': {'1,23,456': 123456, '12,345': 12345, '123,456': null},
      'de_CH': {"1'234.5": 1234.5, '1’234.5': 1234.5},
    };
    for (final MapEntry(key: locale, value: rows) in cases.entries) {
      test(locale, () {
        final f = AdminFormats(locale);
        for (final MapEntry(key: input, value: expected) in rows.entries) {
          expect(f.parseDecimal(input), expected, reason: '"$input"');
        }
      });
    }

    test('reads back what decimal wrote', () {
      for (final locale in ['en', 'fr', 'de', 'ar', 'ar_EG', 'en_IN']) {
        final f = AdminFormats(locale);
        for (final value in [0, 7, 1234.5, -9876543.21, 0.001, 1000000]) {
          expect(
            f.parseDecimal(f.decimal(value)),
            value,
            reason: '$locale: ${f.decimal(value)}',
          );
        }
      }
    });
  });
}

Locale _locale(String name) {
  final parts = name.split('_');
  return Locale(parts.first, parts.length > 1 ? parts[1] : null);
}
