import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in an app running in [locale], with the kit's and Material's
/// delegates.
Future<void> _pump(WidgetTester tester, String locale, Widget child) async {
  tester.view.physicalSize = const Size(1000, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 900, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BulkActionBar _bar(int count, {String Function(int)? label}) => BulkActionBar(
  count: count,
  onClear: () {},
  actions: const [],
  selectedLabel: label,
);

class _Row {
  final String name;
  const _Row(this.name);
}

void main() {
  testWidgets('the pager reads its range in Material\'s French', (
    tester,
  ) async {
    await _pump(
      tester,
      'fr',
      const Pager(from: 1, to: 10, total: 1234, hasPrev: false, hasNext: true),
    );
    final material = MaterialLocalizations.of(
      tester.element(find.byType(Pager)),
    );
    // "1 – 10 sur 1 234", its group separator a narrow no-break space.
    final range = material.pageRowsInfoTitle(1, 10, 1234, false);
    expect(range, '1 – 10 sur 1${material.formatDecimal(1234)[1]}234');
    expect(find.text(range), findsOneWidget);

    await _pump(
      tester,
      'fr',
      const Pager(from: 0, to: 0, total: 20, hasPrev: false, hasNext: false),
    );
    expect(find.text('0 sur 20'), findsOneWidget);
  });

  testWidgets('the selection count takes each of the six Arabic forms', (
    tester,
  ) async {
    final forms = {
      0: 'لم يُحدَّد أي عنصر',
      1: 'عنصر واحد محدد',
      2: 'عنصران محددان',
      3: '3 عناصر محددة',
      11: '11 عنصرًا محددًا',
      100: '100 عنصر محدد',
    };
    for (final MapEntry(key: count, value: text) in forms.entries) {
      await _pump(tester, 'ar', _bar(count));
      expect(find.text(text), findsOneWidget, reason: '$count');
    }
  });

  testWidgets('French counts in the plural from 2, "Aucune sélection" at 0', (
    tester,
  ) async {
    for (final (count, text) in [
      (0, 'Aucune sélection'),
      (1, '1 sélectionné'),
      (2, '2 sélectionnés'),
    ]) {
      await _pump(tester, 'fr', _bar(count));
      expect(find.text(text), findsOneWidget, reason: '$count');
    }
    expect(find.text('Effacer'), findsOneWidget, reason: 'the clear button');
  });

  testWidgets('a selectedLabel wins over the localised count', (tester) async {
    await _pump(tester, 'fr', _bar(3, label: (n) => '$n produits choisis'));
    expect(find.text('3 produits choisis'), findsOneWidget);
    expect(find.text('3 sélectionnés'), findsNothing);
  });

  testWidgets('a selectedLabel counts the whole query as all of it', (
    tester,
  ) async {
    await _pump(
      tester,
      'fr',
      BulkActionBar(
        count: 25,
        onClear: () {},
        actions: const [],
        selectedLabel: (n) => '$n produits choisis',
        matchingTotal: 137,
        allMatchingSelected: true,
      ),
    );
    expect(
      find.text('Tous les résultats\u00A0: 137 produits choisis'),
      findsOneWidget,
    );
  });

  testWidgets('filter chips show dates and numbers in the app\'s locale', (
    tester,
  ) async {
    await _pump(
      tester,
      'fr',
      FilterBar(
        fields: const [
          DateRangeFilterField('updated', 'Modifié'),
          NumberRangeFilterField('price', 'Prix'),
          TextFilterField('name', 'Nom'),
        ],
        active: [
          DateRangeFilter(
            'updated',
            from: DateTime(2026, 1, 5),
            to: DateTime(2026, 2, 20),
            label: 'Modifié',
          ),
          const NumberRangeFilter('price', min: 1234.5, label: 'Prix'),
          const TextFilter('name', 'laine', label: 'Nom'),
        ],
        onChanged: (_) {},
      ),
    );
    expect(find.text('5 janv. 2026 – 20 févr. 2026'), findsOneWidget);
    expect(
      find.text('≥ ${AdminFormats('fr').decimal(1234.5)}'),
      findsOneWidget,
    );
    expect(find.text('« laine »'), findsOneWidget);
    // French sets its colon apart, and the rest of the bar is French.
    expect(find.text(' : '), findsNWidgets(3));
    expect(find.text('Tout effacer'), findsOneWidget);
  });

  testWidgets('a number range is typed and shown in French notation', (
    tester,
  ) async {
    final changes = <List<FilterCondition>>[];
    await _pump(
      tester,
      'fr',
      FilterBar(
        fields: const [NumberRangeFilterField('price', 'Prix')],
        active: const [NumberRangeFilter('price', max: 2500, label: 'Prix')],
        onChanged: changes.add,
      ),
    );
    await tester.tap(find.text('Prix'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(
      tester.widget<TextField>(fields.last).controller!.text,
      AdminFormats('fr').decimal(2500),
      reason: 'the bound it opens with, grouped the French way',
    );
    await tester.enterText(fields.first, '12,5');
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    final range = changes.single.single as NumberRangeFilter;
    expect((range.min, range.max), (12.5, 2500));
  });

  testWidgets('a bound that is no number is flagged, not applied as none', (
    tester,
  ) async {
    final changes = <List<FilterCondition>>[];
    await _pump(
      tester,
      'en',
      FilterBar(
        fields: const [NumberRangeFilterField('price', 'Price')],
        active: const [NumberRangeFilter('price', max: 2500, label: 'Price')],
        onChanged: changes.add,
      ),
    );
    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1,5');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('Enter a number like 1,234.5'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1.5');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    final range = changes.single.single as NumberRangeFilter;
    expect((range.min, range.max), (1.5, 2500));
  });

  testWidgets('the number cell editor reads a French decimal comma', (
    tester,
  ) async {
    num price = 10.5;
    await _pump(
      tester,
      'fr',
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          height: 300,
          child: CollectionTable<_Row>(
            rows: const [_Row('a')],
            rowKey: (r) => r.name,
            columns: [
              TableColumn(
                id: 'price',
                label: 'Prix',
                numeric: true,
                cell: (_) => Text('$price'),
                editBuilder: (_, session) => TableTextEditor.number(
                  session: session,
                  value: price,
                  onCommit: (v) => setState(() => price = v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('10.5'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.controller!.text, '10,5');
    await tester.enterText(find.byType(TextField), '25,75');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(price, 25.75);
  });

  testWidgets('an empty table and a filtered one speak the app\'s language', (
    tester,
  ) async {
    Widget table({bool filtered = false}) => SizedBox(
      height: 300,
      child: CollectionTable<_Row>(
        rows: const [],
        filtered: filtered,
        onClearFilters: () {},
        columns: [TableColumn(label: 'Nom', cell: (r) => Text(r.name))],
      ),
    );
    await _pump(tester, 'fr', table());
    expect(find.text('Rien pour l’instant'), findsOneWidget);
    await _pump(tester, 'fr', table(filtered: true));
    expect(find.text('Aucun résultat'), findsOneWidget);
    expect(find.text('Effacer les filtres'), findsOneWidget);
  });

  test('a compareText gives text a language’s own order', () {
    // Swedish sorts å, ä and ö after z.
    const alphabet = 'abcdefghijklmnopqrstuvwxyzåäö';
    int swedish(String a, String b) {
      for (var i = 0; i < a.length && i < b.length; i++) {
        final order = alphabet
            .indexOf(a[i].toLowerCase())
            .compareTo(alphabet.indexOf(b[i].toLowerCase()));
        if (order != 0) return order;
      }
      return a.length.compareTo(b.length);
    }

    final source = LocalCollectionSource<_Row>(
      [
        for (final n in ['Östersund', 'Arvika', 'Ystad']) _Row(n),
      ],
      fields: {'name': (r) => r.name},
      compareText: swedish,
    );
    expect(
      [
        for (final r in source.matching(const CollectionQuery(sortKey: 'name')))
          r.name,
      ],
      ['Arvika', 'Ystad', 'Östersund'],
    );
  });

  test('text sorts with its accents, not after "z"', () {
    final rows = [
      for (final name in [
        'Zoé',
        'École',
        'eclair',
        'Ecole',
        'abricot',
        'Émile',
      ])
        _Row(name),
    ];
    final source = LocalCollectionSource<_Row>(
      rows,
      fields: {'name': (r) => r.name},
    );
    List<String> sorted({required bool ascending}) => [
      for (final r in source.matching(
        CollectionQuery(sortKey: 'name', ascending: ascending),
      ))
        r.name,
    ];
    expect(sorted(ascending: true), [
      'abricot',
      'eclair',
      'Ecole',
      'École',
      'Émile',
      'Zoé',
    ]);
    expect(sorted(ascending: false), [
      'Zoé',
      'Émile',
      'École',
      'Ecole',
      'eclair',
      'abricot',
    ]);
    // Beyond Latin-1: Central European letters fold too.
    final polish = LocalCollectionSource<_Row>(
      [
        for (final n in ['Żaneta', 'Łukasz', 'Zenon', 'Lech']) _Row(n),
      ],
      fields: {'name': (r) => r.name},
    );
    expect(
      [
        for (final r in polish.matching(const CollectionQuery(sortKey: 'name')))
          r.name,
      ],
      ['Lech', 'Łukasz', 'Żaneta', 'Zenon'],
    );
  });

  test('a duplicated view is named in intl\'s current language', () async {
    final collection = CollectionController<int>(
      fetcher: (q) async => const CollectionPage(items: [], total: 0),
    );
    addTearDown(collection.dispose);
    final views = await Intl.withLocale('fr', () async {
      final controller = SavedViewsController<int>(
        store: InMemorySavedViewsStore(
          seed: {
            'k': [const SavedView(id: 'a', name: 'Tout')],
          },
          latency: Duration.zero,
        ),
        collectionKey: 'k',
        collection: collection,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.duplicate(controller.views.first);
      return controller.views;
    });
    expect(views.last.name, 'Tout (copie)');
  });
}
