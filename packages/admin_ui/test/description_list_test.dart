import 'package:admin_ui/src/common/ui/description_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('renders labels, values and the placeholder for blanks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const DescriptionList(
          items: [
            DescriptionItem('Title', value: 'Hello'),
            DescriptionItem('Reviewer'),
          ],
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Reviewer'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('child takes precedence and renders', (tester) async {
    await tester.pumpWidget(
      _host(
        const DescriptionList(
          items: [DescriptionItem('Status', child: Text('CUSTOM'))],
        ),
      ),
    );

    expect(find.text('CUSTOM'), findsOneWidget);
  });

  testWidgets('a widget child hugs its content instead of filling the slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 600,
          child: DescriptionList(
            items: [
              DescriptionItem(
                'Status',
                child: SizedBox(key: Key('v'), width: 40, height: 10),
              ),
            ],
          ),
        ),
      ),
    );

    // Without hugging, the child would be stretched to the whole value column.
    expect(tester.getSize(find.byKey(const Key('v'))).width, 40);
  });

  testWidgets('fill lets a widget child take the whole slot', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 600,
          child: DescriptionList(
            items: [
              DescriptionItem(
                'Progress',
                child: SizedBox(key: Key('v'), height: 10),
                fill: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('v'))).width, greaterThan(100));
  });

  testWidgets('two-column grid keeps a span item on its own row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 600,
          child: DescriptionList(
            columns: 2,
            items: [
              DescriptionItem('A', value: '1'),
              DescriptionItem('B', value: '2'),
              DescriptionItem('Bio', value: 'wide', span: true),
            ],
          ),
        ),
      ),
    );

    // A and B share a row; the span item is full-width and lower than both.
    final aY = tester.getTopLeft(find.text('1')).dy;
    final bY = tester.getTopLeft(find.text('2')).dy;
    final bioY = tester.getTopLeft(find.text('wide')).dy;
    expect(aY, bY);
    expect(bioY, greaterThan(aY));
  });
}
