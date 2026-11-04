import 'package:admin_ui/src/fields/ui/repeater.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders one row per item', (tester) async {
    await tester.pumpWidget(
      _host(Repeater(itemCount: 3, itemBuilder: (_, i) => Text('row-$i'))),
    );

    expect(find.text('row-0'), findsOneWidget);
    expect(find.text('row-1'), findsOneWidget);
    expect(find.text('row-2'), findsOneWidget);
  });

  testWidgets('empty shows the default placeholder; add CTA still shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 0,
          itemBuilder: (_, i) => Text('row-$i'),
          onAdd: () {},
        ),
      ),
    );

    expect(find.text('No items yet.'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
  });

  testWidgets('add fires its callback', (tester) async {
    var added = 0;
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 1,
          itemBuilder: (_, i) => Text('row-$i'),
          onAdd: () => added++,
          addLabel: 'Add link',
        ),
      ),
    );

    await tester.tap(find.text('Add link'));
    expect(added, 1);
  });

  testWidgets('remove fires with the row index', (tester) async {
    int? removed;
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 3,
          itemBuilder: (_, i) => Text('row-$i'),
          onRemove: (i) => removed = i,
        ),
      ),
    );

    // Each remove says which row it removes.
    await tester.tap(find.bySemanticsLabel('Remove item 2'));
    expect(removed, 1);
  });

  testWidgets('removeLabel names each row\'s remove', (tester) async {
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 2,
          itemBuilder: (_, i) => Text('row-$i'),
          onRemove: (_) {},
          removeLabel: (i) => 'Remove question ${i + 1}',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Remove question 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove question 2'), findsOneWidget);
  });

  testWidgets('reorderable mounts drag handles; non-reorderable does not', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Repeater(
          itemCount: 2,
          itemBuilder: (_, i) => Text('row-$i'),
          onReorder: (_, _) {},
        ),
      ),
    );
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(2));

    await tester.pumpWidget(
      _host(Repeater(itemCount: 2, itemBuilder: (_, i) => Text('row-$i'))),
    );
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNothing);
  });
}
