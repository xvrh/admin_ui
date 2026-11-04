import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A record keyed by a string slug, not an integer id.
class _Tag {
  final String slug;
  final String name;
  const _Tag(this.slug, this.name);
}

const _tags = {
  'alpha': _Tag('alpha', 'Alpha'),
  'beta': _Tag('beta', 'Beta'),
  'gamma': _Tag('gamma', 'Gamma'),
};

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 480,
        child: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('a reference keyed by strings resolves, adds and removes', (
    tester,
  ) async {
    final scope = LocalScope();
    addTearDown(scope.dispose);
    final cell = scope.list('tags')..set(['beta', 'gamma']);
    final resolved = <List<String>>[];
    await tester.pumpWidget(
      _host(
        ReferenceField<_Tag, String>(
          cell,
          label: 'Tags',
          addLabel: 'Add tag',
          idOf: (t) => t.slug,
          resolve: (ids) async {
            resolved.add(ids.toList());
            return [for (final id in ids) ?_tags[id]];
          },
          search: (query, {cursor}) async =>
              ReferencePage(_tags.values.toList()),
          tile: (context, t) => Text(t.name),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(resolved.expand((ids) => ids), containsAll(['beta', 'gamma']));
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);

    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(cell.value, ['beta', 'gamma', 'alpha']);

    // Close the picker, then remove the first row.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();
    expect(cell.value, ['gamma', 'alpha']);
    expect(find.text('Beta'), findsNothing);
  });
}
