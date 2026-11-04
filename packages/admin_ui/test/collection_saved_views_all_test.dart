import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:admin_ui/src/collection/column_layout.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:admin_ui/src/collection/saved_views_controller.dart';
import 'package:admin_ui/src/collection/ui/saved_views_bar.dart';
import 'package:admin_ui/src/l10n/admin_ui_localizations.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A list opens on every row unless a view is marked default, and the bar's
// "All" tab returns to it.

const _published = SavedView(
  id: 'pub',
  name: 'Published',
  state: ViewState(
    filters: [
      OptionsFilter('status', {'Published'}),
    ],
    sortKey: 'price',
    pageSize: 10,
    columns: ColumnLayout(hidden: {'sku'}),
  ),
);
const _drafts = SavedView(
  id: 'draft',
  name: 'Drafts',
  position: 1,
  state: ViewState(
    filters: [
      OptionsFilter('status', {'Draft'}),
    ],
  ),
);

const _initialQuery = CollectionQuery(sortKey: 'name', pageSize: 25);

/// A collection whose fetches are counted in [fetches].
CollectionController<int> _collection(List<CollectionQuery> fetches) =>
    CollectionController<int>(
      initialQuery: _initialQuery,
      fetcher: (q) async {
        fetches.add(q);
        return const CollectionPage(items: [1, 2, 3], total: 3);
      },
    );

SavedViewsController<int> _controller(
  CollectionController<int> collection,
  List<SavedView> views, {
  bool applyDefaultOnLoad = true,
  void Function(ColumnLayout?)? writeColumns,
}) => SavedViewsController<int>(
  collection: collection,
  collectionKey: 'k',
  store: InMemorySavedViewsStore(latency: Duration.zero, seed: {'k': views}),
  readColumns: writeColumns == null ? null : () => const ColumnLayout(),
  writeColumns: writeColumns,
  applyDefaultOnLoad: applyDefaultOnLoad,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<void> _pumpBar(
  WidgetTester tester,
  SavedViewsBar bar, {
  String locale = 'en',
  double width = 900,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: Locale(locale),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: bar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SavedViewsBar _bar({
  String? activeId,
  VoidCallback? onSelectAll,
  String? allLabel,
  ValueChanged<SavedView>? onSelect,
  SavedViewsLayout layout = SavedViewsLayout.auto,
}) => SavedViewsBar(
  views: const [_published, _drafts],
  activeId: activeId,
  dirty: false,
  layout: layout,
  onSelect: onSelect ?? (_) {},
  onSelectAll: onSelectAll,
  allLabel: allLabel,
);

/// Expects the tab labelled [label] announced as [selected].
void _expectSelected(WidgetTester tester, String label, bool selected) =>
    expect(
      tester.getSemantics(find.text(label)),
      isSemantics(isSelected: selected),
      reason: label,
    );

void main() {
  group('controller', () {
    test(
      'with no default view, load leaves every row and reads once',
      () async {
        final fetches = <CollectionQuery>[];
        final collection = _collection(fetches);
        addTearDown(collection.dispose);
        final views = _controller(collection, const [_published, _drafts]);
        addTearDown(views.dispose);
        await _settle();
        await _settle();

        expect(views.views, hasLength(2));
        expect(views.activeId, isNull);
        expect(views.active, isNull);
        expect(views.dirty, isFalse);
        expect(collection.query.filters, isEmpty);
        expect(fetches, hasLength(1), reason: 'the first view is not applied');
      },
    );

    test('load applies a view marked default', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final views = _controller(collection, [
        _published,
        _drafts.copyWith(isDefault: true),
      ]);
      addTearDown(views.dispose);
      await _settle();

      expect(views.activeId, 'draft');
      expect(
        collection.query.filters.whereType<OptionsFilter>().single.selected,
        {'Draft'},
      );
    });

    test('applyDefaultOnLoad false leaves even a default view', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final views = _controller(collection, [
        _published.copyWith(isDefault: true),
      ], applyDefaultOnLoad: false);
      addTearDown(views.dispose);
      await _settle();

      expect(views.activeId, isNull);
      expect(collection.query.filters, isEmpty);
    });

    test('clearView restores the query the collection started with, and '
        'the columns', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final written = <ColumnLayout?>[];
      final views = _controller(collection, const [
        _published,
      ], writeColumns: written.add);
      addTearDown(views.dispose);
      await _settle();

      views.select(views.views.single);
      await _settle();
      expect(collection.query.sortKey, 'price');
      expect(collection.query.pageSize, 10);
      expect(written.last, const ColumnLayout(hidden: {'sku'}));

      var notified = 0;
      views.addListener(() => notified++);
      views.clearView();
      await _settle();
      expect(views.activeId, isNull);
      expect(collection.query.filters, isEmpty);
      expect(collection.query.sortKey, _initialQuery.sortKey);
      expect(collection.query.ascending, _initialQuery.ascending);
      expect(collection.query.pageSize, _initialQuery.pageSize);
      expect(written.last, isNull, reason: 'the columns go back to their own');
      expect(notified, greaterThan(0));
      expect(views.dirty, isFalse);
    });

    test('clearView keeps the search typed into the collection', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final views = _controller(collection, const [_published]);
      addTearDown(views.dispose);
      await _settle();
      views.select(views.views.single);
      collection.searchController.text = 'coat';
      collection.setSearch('coat');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(collection.query.search, 'coat');

      views.clearView();
      expect(collection.query.search, 'coat');
    });

    test('with no view active, a changed query is dirty and Reset returns '
        'to every row', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final views = _controller(collection, const [_published]);
      addTearDown(views.dispose);
      await _settle();
      expect(views.dirty, isFalse);

      collection.setFilters([
        const OptionsFilter('status', {'Draft'}),
      ]);
      await _settle();
      expect(views.dirty, isTrue);

      views.discardChanges();
      await _settle();
      expect(views.dirty, isFalse);
      expect(views.activeId, isNull);
      expect(collection.query.filters, isEmpty);
      expect(collection.query.sortKey, _initialQuery.sortKey);
    });

    test('a reload with no default view leaves the active one', () async {
      final collection = _collection([]);
      addTearDown(collection.dispose);
      final views = _controller(collection, const [_published]);
      addTearDown(views.dispose);
      await _settle();
      views.select(views.views.single);

      await views.load();
      expect(views.activeId, isNull);
      expect(collection.query.filters, isEmpty);
    });
  });

  group('bar', () {
    testWidgets('onSelectAll leads with an "All" tab, selected while no view '
        'is active', (tester) async {
      final semantics = tester.ensureSemantics();
      var all = 0;
      await _pumpBar(tester, _bar(onSelectAll: () => all++));

      final tabs = [
        for (final label in ['All', 'Published', 'Drafts'])
          tester.getCenter(find.text(label)).dx,
      ];
      expect(tabs, orderedEquals([...tabs]..sort()), reason: 'All leads');
      _expectSelected(tester, 'All', true);
      _expectSelected(tester, 'Published', false);

      await _pumpBar(tester, _bar(activeId: 'pub', onSelectAll: () => all++));
      _expectSelected(tester, 'All', false);
      _expectSelected(tester, 'Published', true);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(all, 1);
      semantics.dispose();
    });

    testWidgets('picking a view past the "All" tab selects that view', (
      tester,
    ) async {
      SavedView? picked;
      await _pumpBar(
        tester,
        _bar(onSelectAll: () {}, onSelect: (v) => picked = v),
      );
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(picked?.id, 'draft');
    });

    testWidgets('without onSelectAll there is no "All" tab, and no tab is '
        'selected while no view is active', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpBar(tester, _bar());
      expect(find.text('All'), findsNothing);
      _expectSelected(tester, 'Published', false);
      _expectSelected(tester, 'Drafts', false);
      semantics.dispose();
    });

    testWidgets('drifted from every row, the "All" tab shows the dot and '
        'Reset, but no Save', (tester) async {
      var reset = 0;
      await _pumpBar(
        tester,
        SavedViewsBar(
          views: const [_published, _drafts],
          activeId: null,
          dirty: true,
          onSelect: (_) {},
          onSelectAll: () {},
          onSaveChanges: () {},
          onDiscardChanges: () => reset++,
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Unsaved changes',
        ),
        findsOneWidget,
      );
      expect(find.text('Save'), findsNothing);
      await tester.tap(find.text('Reset'));
      expect(reset, 1);
    });

    testWidgets('allLabel renames the tab', (tester) async {
      await _pumpBar(
        tester,
        _bar(onSelectAll: () {}, allLabel: 'Every product'),
      );
      expect(find.text('Every product'), findsOneWidget);
      expect(find.text('All'), findsNothing);
    });

    for (final (locale, label) in [('fr', 'Tout'), ('ar', 'الكل')]) {
      testWidgets('the "All" tab reads "$label" in $locale', (tester) async {
        await _pumpBar(tester, _bar(onSelectAll: () {}), locale: locale);
        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('right to left, the "All" tab leads on the right', (
      tester,
    ) async {
      await _pumpBar(tester, _bar(onSelectAll: () {}), locale: 'ar');
      expect(
        tester.getCenter(find.text('الكل')).dx,
        greaterThan(tester.getCenter(find.text('Published')).dx),
      );
    });

    testWidgets('the menu form offers "All" first, checked while no view is '
        'active', (tester) async {
      final semantics = tester.ensureSemantics();
      var all = 0;
      SavedView? picked;
      await _pumpBar(
        tester,
        _bar(onSelectAll: () => all++, onSelect: (v) => picked = v),
        width: 360,
      );
      // The trigger names the active choice.
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('All').last),
        isSemantics(
          label: 'All',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(
        tester.getTopLeft(find.text('All').last).dy,
        lessThan(tester.getTopLeft(find.text('Published')).dy),
      );
      // Picking the active choice again changes nothing.
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(all, 0);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(picked?.id, 'draft');

      await _pumpBar(
        tester,
        _bar(activeId: 'draft', onSelectAll: () => all++),
        width: 360,
      );
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(all, 1);
      semantics.dispose();
    });
  });
}
