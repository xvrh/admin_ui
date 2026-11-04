import 'package:admin_ui/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// The lane words of the fields section, read with sample arguments.
final _fields = <String, String Function(FieldsMessages)>{
  'translationSource': (m) => m.translationSource,
  'translationUpToDate': (m) => m.translationUpToDate,
  'translationNeedsReview': (m) => m.translationNeedsReview,
  'translationOutdated': (m) => m.translationOutdated,
  'translationMissing': (m) => m.translationMissing,
  'retranslate': (m) => m.retranslate,
  'retranslateLanguage': (m) => m.retranslateLanguage('Svenska'),
  'sourceChanged': (m) => m.sourceChanged,
  'sourceIn': (m) => m.sourceIn('Svenska'),
  'fieldInLanguage': (m) => m.fieldInLanguage('Titel', 'Svenska'),
  'languages': (m) => m.languages,
  'languageMenuHint': (m) => m.languageMenuHint,
  'compareLanguage': (m) => m.compareLanguage('Svenska'),
  'switchToLanguage': (m) => m.switchToLanguage('Svenska'),
  'editing': (m) => m.editing,
  'inherited': (m) => m.inherited,
  'custom': (m) => m.custom,
  'inheritedDescription': (m) => m.inheritedDescription('SV'),
  'customDescription': (m) => m.customDescription('slug'),
  'customDescription(null)': (m) => m.customDescription(null),
};

/// The insert picker's words in the display section.
final _display = <String, String Function(DisplayMessages)>{
  'preview': (m) => m.preview,
  'previewHeading': (m) => m.previewHeading,
  'noPreviewHeading': (m) => m.noPreviewHeading,
  'insertsInline': (m) => m.insertsInline,
  'nothingMatches': (m) => m.nothingMatches('hero'),
  'choices': (m) => m.choices,
};

/// Members French writes exactly as English does, each with the reason.
const _sameInFrench = {
  'translationSource': 'French says "Source" too',
  'fieldInLanguage': 'both join the field and the language with a comma',
};

const _locales = [
  AdminLocalizationsEn(),
  AdminLocalizationsFr(),
  AdminLocalizationsAr(),
];

/// Each of [messages] read from every locale's section: non-empty, and
/// translated in French (unless [sameInFrench] says why not) and in Arabic.
void _expectTranslated<S>(
  Map<String, String Function(S)> messages,
  S Function(AdminLocalizations) section, {
  Map<String, String> sameInFrench = const {},
}) {
  for (final MapEntry(key: name, value: read) in messages.entries) {
    final [en, fr, ar] = [for (final l in _locales) read(section(l))];
    for (final text in [en, fr, ar]) {
      expect(text.trim(), isNotEmpty, reason: name);
    }
    if (sameInFrench.containsKey(name)) {
      expect(fr, en, reason: '$name: ${sameInFrench[name]}');
    } else {
      expect(fr, isNot(en), reason: '$name is not translated to French');
    }
    expect(ar, isNot(en), reason: '$name is not translated to Arabic');
  }
}

void main() {
  test('every language section is its own language’s', () {
    for (final (l, fields, display) in [
      (_locales[0], FieldsMessagesEn, DisplayMessagesEn),
      (_locales[1], FieldsMessagesFr, DisplayMessagesFr),
      (_locales[2], FieldsMessagesAr, DisplayMessagesAr),
    ]) {
      expect(l.fields.runtimeType, fields);
      expect(l.display.runtimeType, display);
      expect(l.fields.localeName, l.localeName);
      expect(l.display.localeName, l.localeName);
    }
  });

  test('the fields section translates every lane word', () {
    _expectTranslated(_fields, (l) => l.fields, sameInFrench: _sameInFrench);
  });

  test('the display section translates every block-picker word', () {
    _expectTranslated(_display, (l) => l.display);
  });

  test('a message with a value places it', () {
    for (final l in _locales) {
      final fields = l.fields;
      expect(fields.retranslateLanguage('Svenska'), contains('Svenska'));
      expect(fields.sourceIn('Svenska'), contains('Svenska'));
      expect(fields.fieldInLanguage('Titel', 'Svenska'), contains('Titel'));
      expect(fields.fieldInLanguage('Titel', 'Svenska'), contains('Svenska'));
      expect(fields.compareLanguage('Svenska'), contains('Svenska'));
      expect(fields.switchToLanguage('Svenska'), contains('Svenska'));
      expect(fields.inheritedDescription('SV'), contains('SV'));
      expect(fields.customDescription('slug'), contains('slug'));
      expect(l.display.nothingMatches('hero'), contains('hero'));
    }
  });

  test('the preview heading is the preview word in capitals', () {
    for (final l in _locales) {
      final display = l.display;
      expect(display.previewHeading, display.preview.toUpperCase());
      expect(display.noPreviewHeading, display.noPreviewHeading.toUpperCase());
    }
  });

  test('the insert picker reads its neutral words', () {
    const en = DisplayMessagesEn();
    expect(en.nothingMatches('hero'), 'Nothing matches “hero”');
    expect(en.previewHeading, 'PREVIEW');
    expect(en.insertsInline, 'Inserts inline — no preview needed.');
    expect(
      const DisplayMessagesFr().nothingMatches('hero'),
      'Rien ne correspond à «\u00A0hero\u00A0»',
    );
  });
}
