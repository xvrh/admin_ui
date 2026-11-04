import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

TableColumn<int> _column(String id) =>
    TableColumn(id: id, label: id.toUpperCase(), cell: (_) => const Text(''));

void main() {
  test('round-trips through JSON, leaving out what is empty', () {
    const layout = ColumnLayout(
      order: ['name', 'price'],
      hidden: {'price'},
      widths: {'name': 240},
      pins: {'price': true, 'name': false},
    );
    final json = layout.toJson();
    expect(ColumnLayout.fromJson(json), layout);
    expect(const ColumnLayout(order: ['a']).toJson(), {
      'order': ['a'],
    });
  });

  test('an old or partial blob still decodes', () {
    expect(ColumnLayout.fromJson(const {}), const ColumnLayout());
    expect(
      ColumnLayout.fromJson(const {
        'order': ['a', 'b'],
        'widths': {'a': 120},
        'unknown': true,
      }),
      const ColumnLayout(order: ['a', 'b'], widths: {'a': 120.0}),
    );
  });

  test('a column added after the layout was saved shows, after the others', () {
    final columns = [_column('a'), _column('b'), _column('new')];
    const saved = ColumnLayout(order: ['b', 'a'], hidden: {'a'});
    expect([for (final c in saved.apply(columns)) c.key], ['b', 'new']);
    expect(saved.resolvedOrder(columns), ['b', 'a', 'new']);
  });

  test('pinned columns still lead after a column moves above them', () {
    final columns = [
      TableColumn<int>(
        id: 'id',
        label: 'ID',
        pinned: true,
        cell: (_) => const Text(''),
      ),
      _column('name'),
      _column('price'),
    ];
    const moved = ColumnLayout(order: ['price', 'name', 'id']);
    expect(
      [for (final c in moved.apply(columns)) c.key],
      ['id', 'price', 'name'],
    );
  });

  test('pins override the declared pinning, and pinned columns lead', () {
    final columns = [
      TableColumn<int>(
        id: 'id',
        label: 'ID',
        pinned: true,
        cell: (_) => const Text(''),
      ),
      _column('name'),
      _column('price'),
    ];
    final layout = const ColumnLayout().withPinned('price', true);
    final applied = layout.apply(columns);
    expect([for (final c in applied) c.key], ['id', 'price', 'name']);
    expect([for (final c in applied) c.pinned], [true, true, false]);

    final unpinned = layout.withPinned('id', false).apply(columns);
    expect([for (final c in unpinned) c.key], ['price', 'id', 'name']);
    expect(unpinned.first.pinned, isTrue);
    expect(unpinned[1].pinned, isFalse);
    expect(
      identical(const ColumnLayout().apply(columns).first, columns.first),
      isTrue,
      reason: 'a column the layout leaves alone is the same column',
    );
  });

  test('a saved key whose column is gone is skipped', () {
    final columns = [_column('a')];
    const saved = ColumnLayout(order: ['gone', 'a'], hidden: {'gone'});
    expect([for (final c in saved.apply(columns)) c.key], ['a']);
    expect(saved.resolvedOrder(columns), ['a']);
  });

  test('edits keep the other fields', () {
    const layout = ColumnLayout(
      order: ['a', 'b'],
      hidden: {'b'},
      widths: {'a': 100},
    );
    expect(
      layout.withVisible('b', true),
      const ColumnLayout(order: ['a', 'b'], widths: {'a': 100}),
    );
    expect(
      layout.withOrder(['b', 'a']),
      const ColumnLayout(order: ['b', 'a'], hidden: {'b'}, widths: {'a': 100}),
    );
    expect(layout.withWidth('b', 80).widths, {'a': 100, 'b': 80});
    final pinned = layout.withPinned('b', true);
    expect(pinned.pins, {'b': true});
    expect(pinned.withVisible('b', true).pins, {'b': true});
    expect(pinned.withOrder(['b', 'a']).pins, {'b': true});
    expect(pinned.withWidth('a', 90).pins, {'b': true});
  });
}
