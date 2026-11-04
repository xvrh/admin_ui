import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'readme/routing.dart' as recipe;

/// Whether the sidebar announces [label] as the current item.
bool _current(WidgetTester tester, String label) =>
    isSemantics(isSelected: true).matches(
      tester.getSemantics(
        find.descendant(of: find.byType(Sidebar), matching: find.text(label)),
      ),
      {},
    );

void main() {
  testWidgets('the README\'s routing recipe: one frame, its body and the '
      'lit item following the route', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const recipe.MyAdmin());
    await tester.pumpAndSettle();
    final shell = tester.state(find.byType(Shell));
    expect(_current(tester, 'Home'), isTrue);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeader, 'Orders'), findsOneWidget);
    expect(_current(tester, 'Orders'), isTrue);
    expect(_current(tester, 'Home'), isFalse);
    expect(tester.state(find.byType(Shell)), same(shell), reason: 'one frame');

    final router =
        tester
                .widget<Router<Object?>>(
                  find.byWidgetPredicate((w) => w is Router),
                )
                .routerDelegate
            as recipe.AppRouter;
    await router.setNewRoutePath(const recipe.OrderRoute(42));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PageHeader, 'Order 42'), findsOneWidget);
    expect(_current(tester, 'Orders'), isTrue);
    semantics.dispose();
  });
}
