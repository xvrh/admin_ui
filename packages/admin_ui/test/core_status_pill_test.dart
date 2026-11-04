import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('a dot without a label stays out of the semantics tree', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const StatusDot(color: Color(0xFF16A34A), size: 8)),
    );
    expect(
      find.descendant(
        of: find.byType(StatusDot),
        matching: find.byType(Semantics),
      ),
      findsNothing,
    );
    expect(tester.getSize(find.byType(StatusDot)), const Size(8, 8));
    handle.dispose();
  });

  testWidgets('a labelled dot reads its state in place of the colour', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: Color(0xFF16A34A), semanticLabel: 'Online'),
            StatusDot(
              color: Color(0xFF6B7280),
              ring: true,
              semanticLabel: 'Offline',
            ),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Online'), findsOneWidget);
    expect(find.bySemanticsLabel('Offline'), findsOneWidget);
    // The label adds no box: the dot keeps its size.
    expect(tester.getSize(find.byType(StatusDot).first), const Size.square(7));
    handle.dispose();
  });

  testWidgets('StatusDot.of takes a label too', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        StatusDot.of(
          const StatusMeta('Scheduled', Color(0xFF2563EB)),
          semanticLabel: 'Scheduled',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Scheduled'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a pill reads its word, its dot adds nothing', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const StatusPill(StatusMeta('Scheduled', Color(0xFF2563EB)))),
    );
    expect(find.bySemanticsLabel('Scheduled'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StatusDot),
        matching: find.byType(Semantics),
      ),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('a ring is hollow and a filled dot is not', (tester) async {
    await tester.pumpWidget(
      _host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusDot(color: Color(0xFF16A34A)),
            StatusDot(color: Color(0xFF6B7280), ring: true),
          ],
        ),
      ),
    );
    final [filled, ring] = [
      for (final c in tester.widgetList<Container>(find.byType(Container)))
        c.decoration! as BoxDecoration,
    ];
    expect(filled.color, const Color(0xFF16A34A));
    expect(filled.border, isNull);
    expect(ring.color, Colors.transparent);
    expect((ring.border! as Border).top.color, const Color(0xFF6B7280));
  });
}
