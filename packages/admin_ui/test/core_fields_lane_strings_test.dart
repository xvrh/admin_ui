import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lane words the fields section carries, in every language the kit
/// ships.
List<String> _laneWords(FieldsMessages m) => [
  m.translationSource,
  m.translationUpToDate,
  m.translationNeedsReview,
  m.translationOutdated,
  m.translationMissing,
  m.retranslate,
  m.retranslateLanguage('Espagnol'),
  m.sourceChanged,
  m.sourceIn('Espagnol'),
  m.fieldInLanguage('Titre', 'Espagnol'),
  m.languages,
  m.languageMenuHint,
  m.compareLanguage('Espagnol'),
  m.switchToLanguage('Espagnol'),
  m.editing,
  m.inherited,
  m.custom,
  m.inheritedDescription('EN'),
  m.customDescription('slug'),
  m.customDescription(null),
];

void main() {
  const sections = {
    'en': FieldsMessagesEn(),
    'fr': FieldsMessagesFr(),
    'ar': FieldsMessagesAr(),
  };

  for (final MapEntry(key: code, value: messages) in sections.entries) {
    test('$code: every lane word is there', () {
      for (final word in _laneWords(messages)) {
        expect(word.trim(), isNotEmpty);
      }
    });
  }

  test('the lane words carry their values', () {
    for (final messages in sections.values) {
      expect(messages.sourceIn('Espagnol'), contains('Espagnol'));
      expect(messages.fieldInLanguage('Titre', 'Espagnol'), contains('Titre'));
      expect(messages.compareLanguage('Espagnol'), contains('Espagnol'));
      expect(messages.inheritedDescription('EN'), contains('EN'));
    }
  });

  test('French and Arabic are translated, not English', () {
    final en = _laneWords(sections['en']!);
    for (final code in ['fr', 'ar']) {
      final other = _laneWords(sections[code]!);
      final same = [
        for (var i = 0; i < en.length; i++)
          if (en[i] == other[i]) en[i],
      ];
      // French writes "Source" and the field-and-language pair as English
      // does.
      expect(
        same,
        code == 'fr' ? ['Source', 'Titre, Espagnol'] : isEmpty,
        reason: code,
      );
    }
  });

  test('the fields section holds the same words the lanes read before', () {
    const en = FieldsMessagesEn();
    expect(en.translationUpToDate, 'Up to date');
    expect(en.translationNeedsReview, 'Needs review');
    expect(en.translationOutdated, 'Outdated');
    expect(en.translationMissing, 'Missing');
    expect(en.sourceIn('French'), 'French source');
    expect(en.retranslate, 'Re-translate');
    expect(
      const FieldsMessagesFr().sourceChanged,
      'La source a changé depuis cette traduction',
    );
  });

  test('AdminLocalizations hands out each language’s fields section', () {
    expect(const AdminLocalizationsFr().fields.languages, 'Langues');
    expect(const AdminLocalizationsAr().fields, isA<FieldsMessagesAr>());
    expect(const AdminLocalizationsEn().fields.editing, 'editing');
  });
}
