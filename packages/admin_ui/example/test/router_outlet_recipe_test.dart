import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'readme/router_outlet.dart' as recipe;

/// Whether the sidebar announces [label] as the current item.
bool _current(WidgetTester tester, String label) =>
    isSemantics(isSelected: true).matches(
      tester.getSemantics(
        find.descendant(of: find.byType(Sidebar), matching: find.text(label)),
      ),
      {},
    );

void main() {
  testWidgets('admin_ui README\'s router_outlet recipe: one frame, its body '
      'and the lit item following the URL', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const recipe.MyAdmin());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeader, 'Home'), findsOneWidget);
    expect(_current(tester, 'Home'), isTrue);
    final shell = tester.state(find.byType(Shell));

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeader, 'Orders'), findsOneWidget);
    expect(_current(tester, 'Orders'), isTrue);
    expect(_current(tester, 'Home'), isFalse);

    await tester.tap(find.text('Order 42'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeader, 'Order 42'), findsOneWidget);
    expect(_current(tester, 'Orders'), isTrue);
    expect(tester.state(find.byType(Shell)), same(shell), reason: 'one frame');
    semantics.dispose();
  });
}
