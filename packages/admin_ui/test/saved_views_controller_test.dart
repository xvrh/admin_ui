import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:admin_ui/src/collection/saved_views_controller.dart';
import 'package:flutter_test/flutter_test.dart';

CollectionController<int> _collection() => CollectionController<int>(
  fetcher: (q) async => const CollectionPage(items: [1, 2, 3], total: 3),
);

SavedViewsController<int> _controller(CollectionController<int> c) =>
    SavedViewsController<int>(
      collection: c,
      collectionKey: 'k',
      store: InMemorySavedViewsStore(
        latency: Duration.zero,
        seed: {
          'k': [
            const SavedView(id: 'all', name: 'All', isDefault: true),
            const SavedView(
              id: 'pub',
              name: 'Published',
              state: ViewState(
                filters: [
                  OptionsFilter('status', {'Published'}),
                ],
              ),
            ),
          ],
        },
      ),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('loads views and applies the default on start', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    expect(ctl.views.length, 2);
    expect(ctl.activeId, 'all');
    expect(ctl.dirty, isFalse);
  });

  test('selecting a view applies its query', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    ctl.select(ctl.views.firstWhere((v) => v.id == 'pub'));
    await _settle();

    expect(col.query.filters.whereType<OptionsFilter>().single.selected, {
      'Published',
    });
    expect(ctl.dirty, isFalse);
  });

  test('editing the query off a view goes dirty; discard reverts', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    col.setFilters([
      const OptionsFilter('status', {'Draft'}),
    ]);
    await _settle();
    expect(ctl.dirty, isTrue);

    ctl.discardChanges();
    await _settle();
    expect(ctl.dirty, isFalse);
    expect(col.query.filters, isEmpty); // 'All' has none
  });

  test('saveAsNew adds a view, makes it active and clean', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    col.setFilters([
      const OptionsFilter('status', {'Archived'}),
    ]);
    await _settle();
    final created = (await ctl.saveAsNew(
      'Archived',
      scope: SavedViewScope.shared,
    ))!;

    expect(ctl.views.length, 3);
    expect(ctl.activeId, created.id);
    expect(created.scope, SavedViewScope.shared);
    expect(ctl.dirty, isFalse);
  });

  test('saveChanges persists the edited query into the active view', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    col.sortBy('price', false);
    await _settle();
    expect(ctl.dirty, isTrue);

    await ctl.saveChanges();
    expect(ctl.dirty, isFalse);
    expect(ctl.active!.state.sortKey, 'price');
    expect(ctl.active!.state.ascending, isFalse);
  });

  test('deleting the active view falls back to the default one', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    ctl.select(ctl.views.firstWhere((v) => v.id == 'pub'));
    await ctl.delete(ctl.active!);
    await _settle();
    expect(ctl.views.length, 1);
    expect(ctl.activeId, 'all');
    expect(col.query.filters, isEmpty);
  });

  test('deleting the active default view leaves no view active', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    await ctl.delete(ctl.active!);
    await _settle();
    expect(ctl.views.length, 1);
    expect(ctl.activeId, isNull);
    expect(ctl.dirty, isFalse);
  });

  test('rename keeps the view active under its new name', () async {
    final col = _collection();
    final ctl = _controller(col);
    await _settle();

    await ctl.rename(ctl.active!, 'Everything');
    expect(ctl.active!.name, 'Everything');
    expect(ctl.views.map((v) => v.name), ['Everything', 'Published']);
  });
}
