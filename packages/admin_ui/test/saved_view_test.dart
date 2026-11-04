import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/collection/saved_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filter codec', () {
    test('every variant round-trips through JSON', () {
      final originals = <FilterCondition>[
        const TextFilter('name', 'wool', label: 'Name'),
        const OptionsFilter('status', {'Published', 'Draft'}, label: 'Status'),
        const NumberRangeFilter('price', min: 10, max: 99, label: 'Price'),
        DateRangeFilter(
          'updated',
          from: DateTime(2026, 1, 2),
          to: DateTime(2026, 3, 4),
          label: 'Updated',
        ),
        const BoolFilter('featured', true, label: 'Featured'),
      ];
      for (final f in originals) {
        final back = filterConditionFromJson(f.toJson());
        expect(back.runtimeType, f.runtimeType);
        expect(back!.toJson(), f.toJson());
      }
    });

    test('unknown type decodes to null (schema-drift safe)', () {
      expect(
        filterConditionFromJson({'field': 'x', 'type': 'mystery'}),
        isNull,
      );
      expect(filterConditionFromJson({'type': 'text', 'value': 'a'}), isNull);
    });
  });

  group('ViewState', () {
    test('round-trips through JSON', () {
      final v = const ViewState(
        filters: [
          OptionsFilter('status', {'Published'}, label: 'Status'),
        ],
        sortKey: 'price',
        ascending: false,
        pageSize: 25,
      );
      expect(ViewState.fromJson(v.toJson()).toJson(), v.toJson());
    });

    test('matchesQuery ignores search and is filter-order independent', () {
      final state = const ViewState(
        filters: [
          OptionsFilter('status', {'Published'}, label: 'Status'),
          NumberRangeFilter('price', min: 10, label: 'Price'),
        ],
        sortKey: 'name',
      );
      final q = const CollectionQuery(
        search: 'transient text',
        sortKey: 'name',
        filters: [
          NumberRangeFilter('price', min: 10, label: 'Price'),
          OptionsFilter('status', {'Published'}, label: 'Status'),
        ],
      );
      expect(state.matchesQuery(q), isTrue);
    });

    test('matchesQuery is false when a filter value differs', () {
      final state = const ViewState(
        filters: [
          OptionsFilter('status', {'Published'}),
        ],
        sortKey: 'name',
      );
      final q = const CollectionQuery(
        sortKey: 'name',
        filters: [
          OptionsFilter('status', {'Draft'}),
        ],
      );
      expect(state.matchesQuery(q), isFalse);
    });

    test('pageSize is ignored when the view does not pin one', () {
      const state = ViewState(sortKey: 'name');
      const q = CollectionQuery(sortKey: 'name', pageSize: 99);
      expect(state.matchesQuery(q), isTrue);
    });

    test('a filter label difference does not make a view dirty', () {
      final state = const ViewState(
        filters: [
          OptionsFilter('status', {'Published'}, label: 'Status'),
        ],
      );
      final q = const CollectionQuery(
        filters: [
          OptionsFilter('status', {'Published'}, label: 'Statut'), // localized
        ],
      );
      expect(state.matchesQuery(q), isTrue);
    });

    test('label is not persisted in the payload', () {
      final state = const ViewState(
        filters: [
          OptionsFilter('status', {'Published'}, label: 'Status'),
        ],
      );
      final filters = state.toJson()['filters'] as List;
      expect((filters.single as Map).containsKey('label'), isFalse);
    });

    test('direction is ignored when there is no sort key', () {
      const state = ViewState(ascending: false);
      const q = CollectionQuery(ascending: true); // no sortKey on either
      expect(state.matchesQuery(q), isTrue);
    });
  });
}
