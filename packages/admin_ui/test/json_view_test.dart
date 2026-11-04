import 'package:admin_ui/src/common/ui/json_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// The path of every row, in order, with closing rows suffixed `}` / `]`.
List<String> _paths(List<JsonRow> rows) => [
  for (final r in rows) r.closing ? '${r.node.path}<' : r.node.path,
];

void main() {
  group('buildJsonTree', () {
    test('classifies scalars, objects and arrays', () {
      final root = buildJsonTree({
        'a': 'x',
        'b': 1,
        'c': true,
        'd': null,
        'e': [1, 2],
        'f': {'g': 1},
      });
      expect(root.kind, JsonNodeKind.object);
      expect(root.path, r'$');
      final byKey = {for (final c in root.children) c.key: c};
      expect(byKey['a']!.kind, JsonNodeKind.string);
      expect(byKey['b']!.kind, JsonNodeKind.number);
      expect(byKey['c']!.kind, JsonNodeKind.boolean);
      expect(byKey['d']!.kind, JsonNodeKind.nul);
      expect(byKey['e']!.kind, JsonNodeKind.array);
      expect(byKey['f']!.kind, JsonNodeKind.object);
    });

    test('builds stable, unique paths for nesting and indices', () {
      final root = buildJsonTree({
        'items': [
          {'id': 1},
          {'id': 2},
        ],
      });
      final items = root.children.single;
      expect(items.path, r'$.items');
      expect(items.children[0].path, r'$.items[0]');
      expect(items.children[1].path, r'$.items[1]');
      expect(items.children[1].children.single.path, r'$.items[1].id');
    });

    test('empty containers report isEmpty', () {
      final root = buildJsonTree({'o': {}, 'a': []});
      expect(root.children.every((c) => c.isEmpty), isTrue);
    });

    test('encoded keeps quotes and escapes; depth increments', () {
      final root = buildJsonTree({'k': 'he"llo'});
      final leaf = root.children.single;
      expect(leaf.depth, 1);
      expect(leaf.encoded, r'"he\"llo"');
    });
  });

  group('flattenJson', () {
    final root = buildJsonTree({
      'a': 1,
      'b': {'c': 2},
    });

    test('a collapsed container folds to a single row', () {
      // Root itself collapses when absent from the expanded set.
      expect(_paths(flattenJson(root, expanded: {})), [r'$']);
      // Root open (so it also emits its closing row), nested b folded.
      final rows = flattenJson(root, expanded: {r'$'});
      expect(_paths(rows), [r'$', r'$.a', r'$.b', r'$<']);
      expect(
        rows.firstWhere((r) => r.node.path == r'$.b' && !r.closing).collapsed,
        isTrue,
      );
    });

    test('expanded container emits open + children + closing rows', () {
      final rows = flattenJson(root, expanded: {r'$', r'$.b'});
      expect(_paths(rows), [r'$', r'$.a', r'$.b', r'$.b.c', r'$.b<', r'$<']);
    });

    test('last sibling drops its trailing comma', () {
      final rows = flattenJson(root, expanded: {r'$'});
      final a = rows.firstWhere((r) => r.node.path == r'$.a');
      final b = rows.firstWhere((r) => r.node.path == r'$.b' && !r.closing);
      expect(a.last, isFalse);
      expect(b.last, isTrue);
    });

    test('empty container never opens even when in the expanded set', () {
      final e = buildJsonTree({'x': []});
      final rows = flattenJson(e, expanded: {r'$', r'$.x'});
      expect(_paths(rows), [r'$', r'$.x', r'$<']);
    });
  });

  group('jsonSearch', () {
    final root = buildJsonTree({
      'user': {'name': 'Ada', 'role': 'admin'},
      'tags': ['draft', 'review'],
      'count': 42,
    });

    test('matches keys and leaf values, case-insensitively', () {
      expect(jsonSearch(root, 'ADA').matched, contains(r'$.user.name'));
      expect(jsonSearch(root, 'role').matched, contains(r'$.user.role'));
    });

    test('keep set is the closure of matches and their ancestors', () {
      final res = jsonSearch(root, 'admin');
      expect(res.matched, {r'$.user.role'});
      expect(res.keep, containsAll([r'$', r'$.user', r'$.user.role']));
      expect(res.keep, isNot(contains(r'$.tags')));
    });

    test('flatten with the keep set reveals matches and prunes the rest', () {
      final res = jsonSearch(root, 'review');
      final rows = flattenJson(root, expanded: {}, visible: res.keep);
      final paths = _paths(rows);
      expect(paths, contains(r'$.tags[1]'));
      expect(paths, isNot(contains(r'$.user')));
      // The kept array is forced open despite the empty expansion set.
      expect(paths, contains(r'$.tags'));
    });

    test('no match yields an empty keep set and no rows', () {
      final res = jsonSearch(root, 'zzz');
      expect(res.keep, isEmpty);
      expect(flattenJson(root, expanded: {}, visible: res.keep), isEmpty);
    });
  });
}
