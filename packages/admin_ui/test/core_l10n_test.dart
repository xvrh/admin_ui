import 'package:admin_ui/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps an app in [locale] and returns a context inside it.
Future<BuildContext> _pumpApp(
  WidgetTester tester, {
  Locale? locale,
  List<Locale> supported = const [Locale('en'), Locale('fr'), Locale('ar')],
  bool delegates = true,
}) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: supported,
      localizationsDelegates: delegates
          ? AdminLocalizations.localizationsDelegates
          : null,
      home: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

void main() {
  group('of', () {
    testWidgets('answers English without the delegate, without asserting', (
      tester,
    ) async {
      final context = await _pumpApp(tester, delegates: false);
      expect(AdminLocalizations.of(context), isA<AdminLocalizationsEn>());
      expect(context.adminL10n.apply, 'Apply');
      expect(tester.takeException(), isNull);
    });

    testWidgets('answers English with no Localizations at all', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      );
      expect(context.adminL10n.retry, 'Retry');
    });

    testWidgets('loads French', (tester) async {
      final context = await _pumpApp(tester, locale: const Locale('fr'));
      final l10n = context.adminL10n;
      expect(l10n, isA<AdminLocalizationsFr>());
      expect(l10n.apply, 'Appliquer');
      expect(l10n.inputs, isA<InputsMessagesFr>());
      expect(l10n.display, isA<DisplayMessagesFr>());
      expect(l10n.collection, isA<CollectionMessagesFr>());
      expect(l10n.fields, isA<FieldsMessagesFr>());
      expect(l10n.shell, isA<ShellMessagesFr>());
      expect(l10n.assets, isA<AssetsMessagesFr>());
      // Material's strings come with it.
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'Annuler');
    });

    testWidgets('loads Arabic, right to left', (tester) async {
      final context = await _pumpApp(tester, locale: const Locale('ar'));
      expect(context.adminL10n, isA<AdminLocalizationsAr>());
      expect(context.adminL10n.apply, 'تطبيق');
      expect(context.adminL10n.inputs, isA<InputsMessagesAr>());
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets('matches on the language: fr_CA gets French', (tester) async {
      final context = await _pumpApp(
        tester,
        locale: const Locale('fr', 'CA'),
        supported: const [Locale('en'), Locale('fr', 'CA')],
      );
      expect(Localizations.localeOf(context), const Locale('fr', 'CA'));
      expect(context.adminL10n, isA<AdminLocalizationsFr>());
    });

    testWidgets(
      'a language without kit strings gets English strings but its own '
      'numbers, and no missing-delegate warning',
      (tester) async {
        final context = await _pumpApp(
          tester,
          locale: const Locale('de'),
          supported: const [Locale('en'), Locale('de')],
        );
        expect(tester.takeException(), isNull);
        expect(context.adminL10n, isA<AdminLocalizationsEn>());
        expect(context.adminFormats.locale, 'de');
        expect(context.adminFormats.decimal(1234.5), '1.234,5');
        expect(context.adminFormats.bytes(1500), '1,5 kB');
      },
    );
  });

  testWidgets('an app overrides strings with a delegate listed first', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          _AppL10nDelegate(),
          ...AdminLocalizations.localizationsDelegates,
        ],
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(context.adminL10n, isA<_AppL10n>());
    expect(context.adminL10n.apply, 'Go');
    expect(context.adminL10n.retry, 'Retry');
    expect(context.adminL10n.inputs, isA<_AppInputs>());
  });

  test('the delegate loads synchronously and accepts every locale', () {
    const delegate = AdminLocalizations.delegate;
    for (final (locale, type) in [
      (const Locale('en'), AdminLocalizationsEn),
      (const Locale('fr', 'CA'), AdminLocalizationsFr),
      (const Locale('ar', 'EG'), AdminLocalizationsAr),
      (const Locale('ja'), AdminLocalizationsEn),
    ]) {
      expect(delegate.isSupported(locale), isTrue);
      final loaded = delegate.load(locale);
      expect(loaded, isA<SynchronousFuture<AdminLocalizations>>());
      late AdminLocalizations value;
      loaded.then((v) => value = v);
      expect(value.runtimeType, type, reason: '$locale');
    }
    expect(AdminLocalizations.supportedLocales.map((l) => l.languageCode), [
      'en',
      'fr',
      'ar',
    ]);
    expect(
      AdminLocalizations.localizationsDelegates,
      containsAll(<Object>[delegate, ...GlobalMaterialLocalizations.delegates]),
    );
  });

  group('plurals', () {
    test('Arabic uses all six categories', () {
      const ar = AdminLocalizationsAr();
      String category(int n) => ar.plural(
        n,
        zero: 'zero',
        one: 'one',
        two: 'two',
        few: 'few',
        many: 'many',
        other: 'other',
      );
      expect(
        {
          for (final n in [0, 1, 2, 3, 10, 11, 99, 100, 102]) n: category(n),
        },
        {
          0: 'zero',
          1: 'one',
          2: 'two',
          3: 'few',
          10: 'few',
          11: 'many',
          99: 'many',
          100: 'other',
          102: 'other',
        },
      );
      expect(ar.selectedCount(0), 'لم يُحدَّد أي عنصر');
      expect(ar.selectedCount(1), 'عنصر واحد محدد');
      expect(ar.selectedCount(2), 'عنصران محددان');
      expect(ar.selectedCount(3), '3 عناصر محددة');
      expect(ar.selectedCount(11), '11 عنصرًا محددًا');
      expect(ar.selectedCount(100), '100 عنصر محدد');
    });

    test('French counts zero and one alike', () {
      const fr = AdminLocalizationsFr();
      expect(fr.plural(0, one: 'one', other: 'other'), 'one');
      expect(fr.plural(1, one: 'one', other: 'other'), 'one');
      expect(fr.plural(2, one: 'one', other: 'other'), 'other');
      expect(fr.selectedCount(0), 'Aucune sélection');
      expect(fr.selectedCount(1), '1 sélectionné');
      expect(fr.selectedCount(1200), '1\u202F200 sélectionnés');
    });

    test('English', () {
      const en = AdminLocalizationsEn();
      expect(en.selectedCount(0), 'Nothing selected');
      expect(en.selectedCount(1), '1 selected');
      expect(en.selectedCount(1200), '1,200 selected');
      expect(en.countOf(3, 1200), '3 of 1,200');
    });
  });

  test('every locale fills the shared vocabulary', () {
    const locales = [
      AdminLocalizationsEn(),
      AdminLocalizationsFr(),
      AdminLocalizationsAr(),
    ];
    final messages = <String, String Function(AdminLocalizations)>{
      'apply': (l) => l.apply,
      'retry': (l) => l.retry,
      'remove': (l) => l.remove,
      'removeItem': (l) => l.removeItem('X'),
      'reset': (l) => l.reset,
      'loading': (l) => l.loading,
      'saving': (l) => l.saving,
      'edited': (l) => l.edited,
      'unsavedChanges': (l) => l.unsavedChanges,
      'noResults': (l) => l.noResults,
      'noMatches': (l) => l.noMatches,
      'couldNotLoad': (l) => l.couldNotLoad,
      'searchFailed': (l) => l.searchFailed,
      'loadMore': (l) => l.loadMore,
      'searching': (l) => l.searching,
      'somethingWentWrong': (l) => l.somethingWentWrong,
      'somethingWentWrongTryAgain': (l) => l.somethingWentWrongTryAgain,
      'moreActions': (l) => l.moreActions,
      'clearSelection': (l) => l.clearSelection,
      'moveUp': (l) => l.moveUp,
      'moveDown': (l) => l.moveDown,
      'selectPlaceholder': (l) => l.selectPlaceholder,
      'filterPlaceholder': (l) => l.filterPlaceholder,
      'searchPlaceholder': (l) => l.searchPlaceholder,
      'addItem': (l) => l.addItem,
      'addRow': (l) => l.addRow,
      'keyLabel': (l) => l.keyLabel,
      'valueLabel': (l) => l.valueLabel,
      'linkPlaceholder': (l) => l.linkPlaceholder,
      'restoreLiveVersion': (l) => l.restoreLiveVersion,
      'assetNotFound': (l) => l.assetNotFound,
      'assetPreview': (l) => l.assetPreview,
      'uploadFailed': (l) => l.uploadFailed,
      'dropPrompt': (l) {
        final p = l.dropPrompt(multiple: true);
        return '${p.before}${p.link}${p.after}';
      },
      'selectedCount': (l) => l.selectedCount(5),
      'countOf': (l) => l.countOf(1, 2),
      'byteSize': (l) => l.byteSize('1', 1),
    };
    for (final MapEntry(key: name, value: read) in messages.entries) {
      final [en, fr, ar] = [for (final l in locales) read(l)];
      expect(en, isNotEmpty, reason: name);
      expect(fr, isNot(en), reason: '$name is not translated to French');
      expect(ar, isNot(en), reason: '$name is not translated to Arabic');
    }
  });

  test('the drop prompt reads as one sentence around its link', () {
    const en = AdminLocalizationsEn();
    final one = en.dropPrompt(multiple: false);
    expect(
      '${one.before}${one.link}${one.after}',
      'Drag & drop a file, or browse',
    );
    final images = en.dropPrompt(multiple: true, images: true);
    expect(images.before, 'Drag & drop images, or ');
  });

  group('shortcutLabel', () {
    testWidgets(
      'Apple platforms write glyphs',
      (tester) async {
        final context = await _pumpApp(tester);
        final save = primaryModifierActivator(LogicalKeyboardKey.keyK);
        expect(save.meta, isTrue);
        expect(save.control, isFalse);
        expect(shortcutLabel(context, save), '⌘K');
        expect(
          shortcutLabel(
            context,
            primaryModifierActivator(LogicalKeyboardKey.keyP, shift: true),
          ),
          '⇧⌘P',
        );
        expect(
          shortcutLabel(
            context,
            const SingleActivator(LogicalKeyboardKey.enter, control: true),
          ),
          '⌃↩',
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.iOS,
      }),
    );

    testWidgets(
      'other platforms write Ctrl+K',
      (tester) async {
        final context = await _pumpApp(tester);
        final save = primaryModifierActivator(LogicalKeyboardKey.keyK);
        expect(save.control, isTrue);
        expect(save.meta, isFalse);
        expect(shortcutLabel(context, save), 'Ctrl+K');
        expect(
          shortcutLabel(
            context,
            primaryModifierActivator(LogicalKeyboardKey.keyP, shift: true),
          ),
          'Ctrl+Shift+P',
        );
        expect(
          shortcutLabel(
            context,
            const SingleActivator(LogicalKeyboardKey.escape),
          ),
          'Esc',
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.android,
      }),
    );

    testWidgets('modifier names follow the app language', (tester) async {
      final context = await _pumpApp(tester, locale: const Locale('fr'));
      expect(
        shortcutLabel(
          context,
          primaryModifierActivator(LogicalKeyboardKey.keyS, shift: true),
        ),
        'Ctrl+Maj+S',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });
}

class _AppInputs extends InputsMessagesEn {
  const _AppInputs();
}

class _AppL10n extends AdminLocalizationsEn {
  const _AppL10n();

  @override
  String get apply => 'Go';

  @override
  InputsMessages get inputs => const _AppInputs();
}

class _AppL10nDelegate extends LocalizationsDelegate<AdminLocalizations> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AdminLocalizations> load(Locale locale) => SynchronousFuture(
    locale.languageCode == 'en'
        ? const _AppL10n()
        : AdminLocalizations.lookup(locale),
  );

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}
