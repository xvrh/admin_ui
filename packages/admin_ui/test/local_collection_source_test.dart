import 'package:admin_ui/src/collection/collection_controller.dart';
import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/collection/local_source.dart';
import 'package:flutter_test/flutter_test.dart';

enum Plan { free, team, enterprise }

class Member {
  final String name;
  final String email;
  final Plan plan;
  final int? seats;
  final DateTime? lastSeen;
  final bool verified;
  final String? city;

  const Member(
    this.name,
    this.email, {
    this.plan = Plan.free,
    this.seats,
    this.lastSeen,
    this.verified = false,
    this.city,
  });

  @override
  String toString() => name;
}

final _members = [
  Member(
    'dana',
    'dana@example.com',
    plan: Plan.team,
    seats: 5,
    lastSeen: DateTime(2026, 3, 2, 18, 30),
    verified: true,
    city: 'Oslo',
  ),
  Member(
    'Ari',
    'ari@example.org',
    plan: Plan.enterprise,
    seats: 40,
    lastSeen: DateTime(2026, 3, 1, 9),
    city: 'Lima',
  ),
  const Member('Cleo', 'cleo@example.com', verified: true),
  Member(
    'Bo',
    'bo@example.net',
    plan: Plan.team,
    seats: 5,
    lastSeen: DateTime(2026, 2, 20),
    city: 'Oslo',
  ),
];

final _source = LocalCollectionSource<Member>(
  _members,
  fields: {
    'name': (m) => m.name,
    'email': (m) => m.email,
    'plan': (m) => m.plan,
    'seats': (m) => m.seats,
    'lastSeen': (m) => m.lastSeen,
    'verified': (m) => m.verified,
    'city': (m) => m.city,
  },
  searchFields: {'name', 'email'},
);

List<String> _names(
  List<FilterCondition> filters, {
  String search = '',
  String? sortKey,
  bool ascending = true,
}) => [
  for (final m in _source.matching(
    CollectionQuery(
      filters: filters,
      search: search,
      sortKey: sortKey,
      ascending: ascending,
    ),
  ))
    m.name,
];

void main() {
  test('no query keeps every row in its order', () {
    expect(_names(const []), ['dana', 'Ari', 'Cleo', 'Bo']);
  });

  test('search looks only in the search fields, ignoring case', () {
    expect(_names(const [], search: ' EXAMPLE.COM '), ['dana', 'Cleo']);
    expect(_names(const [], search: 'oslo'), isEmpty);
  });

  test('search looks in every field when none are named', () {
    final everywhere = LocalCollectionSource<Member>(
      _members,
      fields: {'name': (m) => m.name, 'city': (m) => m.city},
    );
    expect(
      everywhere
          .matching(const CollectionQuery(search: 'oslo'))
          .map((m) => m.name),
      ['dana', 'Bo'],
    );
  });

  test('a text filter matches a substring, ignoring case', () {
    expect(_names(const [TextFilter('email', '.COM')]), ['dana', 'Cleo']);
  });

  test('an options filter matches by id, and never a missing value', () {
    expect(
      _names(const [
        OptionsFilter('plan', {'team'}),
      ]),
      ['dana', 'Bo'],
    );
    expect(
      _names(const [
        OptionsFilter('city', {'Oslo', 'Lima'}),
      ]),
      ['dana', 'Ari', 'Bo'],
    );
  });

  test('a number range is inclusive on both ends', () {
    expect(_names(const [NumberRangeFilter('seats', min: 5, max: 5)]), [
      'dana',
      'Bo',
    ]);
    expect(_names(const [NumberRangeFilter('seats', min: 6)]), ['Ari']);
  });

  test('a bare date as the upper bound covers that whole day', () {
    expect(
      _names([
        DateRangeFilter(
          'lastSeen',
          from: DateTime(2026, 3, 1),
          to: DateTime(2026, 3, 2),
        ),
      ]),
      ['dana', 'Ari'],
    );
    expect(
      _names([DateRangeFilter('lastSeen', to: DateTime(2026, 3, 2, 12))]),
      ['Ari', 'Bo'],
    );
  });

  test('a bool filter matches that value', () {
    expect(_names(const [BoolFilter('verified', true)]), ['dana', 'Cleo']);
    expect(_names(const [BoolFilter('verified', false)]), ['Ari', 'Bo']);
  });

  test('conditions combine with and', () {
    expect(
      _names(const [
        OptionsFilter('city', {'Oslo'}),
        BoolFilter('verified', false),
      ], search: 'b'),
      ['Bo'],
    );
  });

  test('strings sort ignoring case', () {
    expect(_names(const [], sortKey: 'name'), ['Ari', 'Bo', 'Cleo', 'dana']);
    expect(_names(const [], sortKey: 'name', ascending: false), [
      'dana',
      'Cleo',
      'Bo',
      'Ari',
    ]);
  });

  test('missing values sort last in both directions', () {
    expect(_names(const [], sortKey: 'lastSeen'), [
      'Bo',
      'Ari',
      'dana',
      'Cleo',
    ]);
    expect(_names(const [], sortKey: 'lastSeen', ascending: false), [
      'dana',
      'Ari',
      'Bo',
      'Cleo',
    ]);
  });

  test('ties keep their order, and enums sort by declaration', () {
    expect(_names(const [], sortKey: 'plan'), ['Cleo', 'dana', 'Bo', 'Ari']);
    expect(_names(const [], sortKey: 'verified'), [
      'Ari',
      'Bo',
      'dana',
      'Cleo',
    ]);
  });

  test('fetch pages the matching rows and reports their total', () async {
    final page = await _source.fetch(
      const CollectionQuery(sortKey: 'name', pageIndex: 1, pageSize: 3),
    );
    expect(page.items.map((m) => m.name), ['dana']);
    expect(page.total, 4);
  });

  test('options are the distinct values, sorted, with the ids filters use', () {
    expect(
      [for (final o in _source.options('city')) (o.id, o.label)],
      [('Lima', 'Lima'), ('Oslo', 'Oslo')],
    );
    expect(
      [
        for (final o in _source.options(
          'plan',
          label: (p) => (p as Plan).name.toUpperCase(),
        ))
          (o.id, o.label),
      ],
      [('free', 'FREE'), ('team', 'TEAM'), ('enterprise', 'ENTERPRISE')],
    );
  });

  test('a field the source cannot read is refused, not ignored', () {
    expect(
      () => _names(const [TextFilter('phone', '555')]),
      throwsArgumentError,
    );
    expect(() => _names(const [], sortKey: 'phone'), throwsArgumentError);
  });

  test('drives a controller, and selects every match across pages', () async {
    final controller = CollectionController<Member>(
      fetcher: _source.fetch,
      rowKey: (m) => m.email,
      initialQuery: const CollectionQuery(sortKey: 'name', pageSize: 1),
    );
    addTearDown(controller.dispose);
    controller.setFilters(const [
      OptionsFilter('city', {'Oslo'}),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(controller.items.map((m) => m.name), ['Bo']);
    expect(controller.total, 2);

    controller.setSelected(_source.matching(controller.query).toSet());
    expect(controller.selected.map((m) => m.name), {'Bo', 'dana'});
  });
}
