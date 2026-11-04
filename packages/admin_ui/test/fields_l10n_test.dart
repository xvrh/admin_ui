import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _theme = buildAppTheme(irisTheme.tokens);

/// [child] in an app running in [locale], with the kit's delegates.
Future<void> _pump(WidgetTester tester, Locale locale, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      locale: locale,
      supportedLocales: const [
        ...AdminLocalizations.supportedLocales,
        Locale('de'),
      ],
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: 360, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A [NumberBody] that keeps its value, like a form field, and records what
/// it reported.
class _Number extends StatefulWidget {
  final num? initial;
  final int decimals;
  final List<num?> reported;

  const _Number({this.initial, this.decimals = 0, required this.reported});

  @override
  State<_Number> createState() => _NumberState();
}

class _NumberState extends State<_Number> {
  late num? _value = widget.initial;

  @override
  Widget build(BuildContext context) => NumberBody(
    value: _value,
    decimals: widget.decimals,
    onChanged: (v) {
      widget.reported.add(v);
      setState(() => _value = v);
    },
  );
}

String _numberText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('placeholders and empty states', () {
    Widget bodies() => Column(
      children: [
        DateBody(onChanged: (_) {}),
        const ColorBody(),
        const TagsBody(),
        const KeyValueBody(),
        const MediaBody(readOnly: true),
        Repeater(itemCount: 0, itemBuilder: (_, _) => const SizedBox()),
      ],
    );

    testWidgets('French', (tester) async {
      await _pump(tester, const Locale('fr'), bodies());
      expect(find.text('Choisir une date…'), findsOneWidget);
      expect(find.text('Choisir une couleur…'), findsOneWidget);
      expect(find.text('Aucune étiquette'), findsOneWidget);
      expect(find.text('Aucune entrée'), findsOneWidget);
      expect(find.text('Aucun média'), findsOneWidget);
      expect(find.text('Aucun élément pour l’instant.'), findsOneWidget);
    });

    testWidgets('Arabic', (tester) async {
      await _pump(tester, const Locale('ar'), bodies());
      expect(find.text('اختر تاريخًا…'), findsOneWidget);
      expect(find.text('اختر لونًا…'), findsOneWidget);
      expect(find.text('لا توجد وسوم'), findsOneWidget);
      expect(find.text('لا توجد إدخالات'), findsOneWidget);
      expect(find.text('لا توجد وسائط'), findsOneWidget);
      expect(find.text('لا توجد عناصر بعد.'), findsOneWidget);
    });

    testWidgets('English uses US spelling and ends each placeholder in an '
        'ellipsis', (tester) async {
      await _pump(
        tester,
        const Locale('en'),
        Column(
          children: [
            DateBody(onChanged: (_) {}),
            DateBody(granularity: DateGranularity.time, onChanged: (_) {}),
            ColorBody(onChanged: (_) {}),
          ],
        ),
      );
      expect(find.text('Select date…'), findsOneWidget);
      expect(find.text('Select time…'), findsOneWidget);
      expect(find.text('Pick a color…'), findsOneWidget);
    });

    testWidgets('a label passed to the body wins over the language', (
      tester,
    ) async {
      await _pump(
        tester,
        const Locale('fr'),
        Column(
          children: [
            SelectBody(
              options: const [SelectOption(value: 'a', label: 'A')],
              hint: 'Pick a section',
              onChanged: (_) {},
            ),
            const TagsBody(emptyLabel: 'Nothing tagged'),
            ColorBody(hint: 'Brand color', onChanged: (_) {}),
            DateBody(hint: 'No embargo', onChanged: (_) {}),
          ],
        ),
      );
      expect(find.text('Pick a section'), findsOneWidget);
      expect(find.text('Sélectionner…'), findsNothing);
      expect(find.text('Nothing tagged'), findsOneWidget);
      expect(find.text('Brand color'), findsOneWidget);
      expect(find.text('No embargo'), findsOneWidget);
    });
  });

  group('number', () {
    testWidgets('German shows and reads its own separators', (tester) async {
      final reported = <num?>[];
      await _pump(
        tester,
        const Locale('de'),
        _Number(initial: 1234.5, decimals: 1, reported: reported),
      );
      expect(_numberText(tester), '1.234,5');

      await tester.enterText(find.byType(TextField), '2.345,6');
      await tester.pump();
      expect(reported.last, 2345.6);

      reported.clear();
      await tester.enterText(find.byType(TextField), '1,234.5');
      await tester.pump();
      expect(reported, isEmpty, reason: 'English separators are not German');
      expect(_numberText(tester), '2.345,6', reason: 'the edit is refused');
    });

    testWidgets('English reads a grouped number', (tester) async {
      final reported = <num?>[];
      await _pump(
        tester,
        const Locale('en'),
        _Number(initial: 0, decimals: 1, reported: reported),
      );
      await tester.enterText(find.byType(TextField), '1,234.5');
      await tester.pump();
      expect(reported.last, 1234.5);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_numberText(tester), '1,234.5');
    });

    testWidgets('French takes a comma or a point as the decimal separator', (
      tester,
    ) async {
      final reported = <num?>[];
      await _pump(
        tester,
        const Locale('fr'),
        _Number(initial: 0, decimals: 2, reported: reported),
      );
      await tester.enterText(find.byType(TextField), '12,5');
      await tester.pump();
      expect(reported.last, 12.5);
      await tester.enterText(find.byType(TextField), '12.75');
      await tester.pump();
      expect(reported.last, 12.75);
    });

    testWidgets('a range message is in the language, with its numbers', (
      tester,
    ) async {
      String? invalid;
      await _pump(
        tester,
        const Locale('fr'),
        NumberBody(
          value: 5000,
          max: 1200,
          onChanged: (_) {},
          onInvalid: (m) => invalid = m,
        ),
      );
      expect(invalid, 'Saisissez 1 200 ou moins');
    });

    testWidgets('digits that are no number in the locale stay as typed, '
        'flagged once committed', (tester) async {
      final reported = <num?>[];
      String? invalid;
      await _pump(
        tester,
        const Locale('en'),
        NumberBody(
          value: 3,
          decimals: 1,
          onChanged: reported.add,
          onInvalid: (m) => invalid = m,
        ),
      );
      await tester.enterText(find.byType(TextField), '1,5');
      await tester.pump();
      expect(reported, isEmpty, reason: "',' groups thousands in English");
      expect(invalid, isNull, reason: 'not judged while being typed');

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(_numberText(tester), '1,5', reason: 'kept, not reverted');
      expect(invalid, 'Enter a number like 1,234.5');
      expect(reported, isEmpty);

      await tester.enterText(find.byType(TextField), '1.5');
      await tester.pump();
      expect(invalid, isNull, reason: 'checked as it is typed once red');
      expect(reported.last, 1.5);
    });
  });

  group('media', () {
    Widget files() => const MediaBody(
      kind: MediaKind.file,
      items: [MediaItem(id: 'a', name: 'report.pdf', bytes: 757760)],
    );

    testWidgets('sizes are in the locale', (tester) async {
      await _pump(tester, const Locale('en'), files());
      expect(find.text('758 kB'), findsOneWidget);

      await _pump(tester, const Locale('fr'), files());
      expect(find.text('758 ko'), findsOneWidget);

      await _pump(tester, const Locale('ar'), files());
      expect(find.text('758 كيلوبايت'), findsOneWidget);
    });

    testWidgets('the drop zone prompt and the tile actions are translated', (
      tester,
    ) async {
      await _pump(
        tester,
        const Locale('fr'),
        Column(
          children: [
            MediaBody(onAddRequested: () {}),
            MediaBody(
              cover: true,
              onRemove: (_) {},
              items: const [
                MediaItem(id: 'a', name: 'a.jpg', swatch: Color(0xFF5B5BD6)),
                MediaItem(id: 'b', name: 'b.jpg', swatch: Color(0xFF0F9D8F)),
              ],
            ),
          ],
        ),
      );
      expect(
        find.text(
          'Glissez-déposez des images ou parcourez',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Couverture'), findsOneWidget);
      expect(find.bySemanticsLabel('Retirer a.jpg'), findsOneWidget);
    });
  });

  group('comments', () {
    testWidgets('the open-thread count takes all six Arabic forms', (
      tester,
    ) async {
      const expected = {
        0: 'علّق على هذا الحقل',
        1: 'نقاش مفتوح واحد',
        2: 'نقاشان مفتوحان',
        3: '3 نقاشات مفتوحة',
        11: '11 نقاشًا مفتوحًا',
        100: '100 نقاش مفتوح',
      };
      await _pump(
        tester,
        const Locale('ar'),
        Column(
          children: [
            for (final count in expected.keys)
              CommentFieldButton(count: count, onTap: () {}),
          ],
        ),
      );
      for (final MapEntry(key: count, value: label) in expected.entries) {
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: '$count');
      }
    });

    testWidgets('French plural and the thread chrome', (tester) async {
      await _pump(
        tester,
        const Locale('fr'),
        Row(
          children: [
            CommentFieldButton(count: 1, onTap: () {}),
            CommentFieldButton(count: 4, onTap: () {}),
            CommentsButton(
              count: 1,
              anchor: 'texte',
              onResolve: () {},
              messages: const [
                CommentEntry(
                  author: 'Ana',
                  initials: 'A',
                  color: Color(0xFF5B5BD6),
                  time: '1 min',
                  body: 'Bien.',
                ),
              ],
            ),
          ],
        ),
      );
      expect(find.bySemanticsLabel('1 discussion ouverte'), findsOneWidget);
      expect(find.bySemanticsLabel('4 discussions ouvertes'), findsOneWidget);
      expect(find.bySemanticsLabel('1 commentaire'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('1 commentaire'));
      await tester.pumpAndSettle();
      expect(find.text('COMMENTAIRES · 1'), findsOneWidget);
      expect(find.text('Résoudre'), findsOneWidget);
      expect(find.text('« …texte… »'), findsOneWidget);
      expect(find.bySemanticsLabel('Envoyer la réponse'), findsOneWidget);
    });
  });

  group('select', () {
    testWidgets('a multi-select offers to create the typed value, quoted the '
        'French way', (tester) async {
      await _pump(
        tester,
        const Locale('fr'),
        MultiSelectBody(
          options: const [SelectOption(value: 'a', label: 'Alpha')],
          creatable: true,
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Sélectionner…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'kiwi');
      await tester.pumpAndSettle();
      expect(find.text('Créer « kiwi »', findRichText: true), findsOneWidget);
      final title = tester.widget<RichText>(
        find.text('Créer « kiwi »', findRichText: true),
      );
      final quoted = (title.text as TextSpan).children!
          .whereType<TextSpan>()
          .expand((s) => s.children ?? [s])
          .whereType<TextSpan>()
          .firstWhere((s) => s.text == '« kiwi »');
      expect(quoted.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('a multi-select at its cap says so', (tester) async {
      await _pump(
        tester,
        const Locale('ar'),
        MultiSelectBody(
          options: const [
            SelectOption(value: 'a', label: 'Alpha'),
            SelectOption(value: 'b', label: 'Beta'),
          ],
          value: const {'a'},
          maxItems: 1,
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      expect(find.text('بلغت الحد الأقصى (1)'), findsOneWidget);
    });
  });

  group('date', () {
    testWidgets('the editor cells are named in the language', (tester) async {
      await _pump(
        tester,
        const Locale('fr'),
        DateBody(
          value: DateTime(2026, 6, 18, 14, 30),
          granularity: DateGranularity.dateTime,
          onChanged: (_) {},
        ),
      );
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();
      for (final name in ['Année', 'Mois', 'Jour', 'Heure', 'Minute']) {
        expect(find.bySemanticsLabel(name), findsOneWidget, reason: name);
      }
      expect(find.bySemanticsLabel('Effacer la date'), findsOneWidget);
    });

    testWidgets('Arabic separates the cells with a slash, not with the bidi '
        'marks around it', (tester) async {
      await _pump(
        tester,
        const Locale('ar'),
        DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {}),
      );
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();
      expect(find.text('/'), findsNWidgets(2));
      expect(find.text('‏'), findsNothing);
    });

    testWidgets('the legend and the empty cells use the language’s letters', (
      tester,
    ) async {
      await _pump(
        tester,
        const Locale('fr'),
        DateBody(granularity: DateGranularity.dateTime, onChanged: (_) {}),
      );
      await tester.tap(find.byType(DateBody));
      await tester.pumpAndSettle();
      expect(find.text('JJ / MM / AAAA · HH : MM'), findsOneWidget);
      expect(find.text('AAAA'), findsOneWidget);
    });

    testWidgets('an Arabic calendar writes its title in the digits of its '
        'days', (tester) async {
      await _pump(
        tester,
        const Locale('ar'),
        Calendar(value: DateTime(2026, 6, 12), onChanged: (_) {}),
      );
      expect(find.text('يونيو 2026'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
    });
  });

  group('capabilities', () {
    testWidgets('history, help and the edited marker', (tester) async {
      await _pump(
        tester,
        const Locale('fr'),
        const FieldShell(
          label: 'Titre',
          help: HelpButton(text: 'Aide.'),
          history: HistoryButton(draft: 'B', baseline: 'A'),
          child: SizedBox(height: 20),
        ),
      );
      expect(find.bySemanticsLabel('Aide : Titre'), findsOneWidget);
      expect(find.text('Modifié'), findsOneWidget);

      await tester.tap(find.text('Modifié'));
      await tester.pumpAndSettle();
      expect(find.text('HISTORIQUE DES VERSIONS'), findsOneWidget);
      expect(find.text('MODIFICATION EN ATTENTE'), findsOneWidget);
      expect(find.text('En ligne'), findsOneWidget);
    });

    testWidgets('a repeater names each remove by position', (tester) async {
      await _pump(
        tester,
        const Locale('ar'),
        Repeater(
          itemCount: 2,
          onRemove: (_) {},
          onAdd: () {},
          itemBuilder: (_, i) => Text('$i'),
        ),
      );
      expect(find.bySemanticsLabel('إزالة العنصر 2'), findsOneWidget);
      expect(find.text('إضافة عنصر'), findsOneWidget);
    });
  });

  testWidgets('key-value placeholders and duplicate message', (tester) async {
    await _pump(
      tester,
      const Locale('fr'),
      KeyValueBody(value: const {}, onChanged: (_) {}),
    );
    await tester.tap(find.text('Ajouter une ligne'));
    await tester.pumpAndSettle();
    expect(find.text('Clé'), findsOneWidget);
    expect(find.text('Valeur'), findsOneWidget);
    expect(find.bySemanticsLabel('Retirer la ligne'), findsOneWidget);

    await _pump(
      tester,
      const Locale('fr'),
      KeyValueBody(value: const {'a': '1'}, onChanged: (_) {}),
    );
    await tester.tap(find.text('Ajouter une ligne'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(2), 'a');
    await tester.pump();
    expect(
      find.text(
        'Clé «\u00A0a\u00A0» en double\u00A0: la dernière ligne l’emporte',
      ),
      findsOneWidget,
    );
  });

  testWidgets('radio arrows follow the reading direction', (tester) async {
    String? value = 'a';
    await _pump(
      tester,
      const Locale('ar'),
      StatefulBuilder(
        builder: (context, setState) => SelectBody(
          appearance: SelectAppearance.radio,
          options: const [
            SelectOption(value: 'a', label: 'A'),
            SelectOption(value: 'b', label: 'B'),
          ],
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(value, 'b', reason: 'left is forward in right-to-left');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 'a');
  });
}
