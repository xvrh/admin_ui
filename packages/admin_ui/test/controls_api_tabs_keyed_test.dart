import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 600, child: child),
    ),
  ),
);

const _tabs = {
  'details': TabItem('Details'),
  'pricing': TabItem('Pricing'),
  'seo': TabItem('SEO'),
};

bool _isSelected(WidgetTester tester, String label) => tester
    .getSemantics(find.text(label))
    .flagsCollection
    .isSelected
    .toBoolOrNull()!;

void main() {
  testWidgets('shows the selection\'s active id', (tester) async {
    final selection = TabSelection('pricing');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(Tabs.keyed(tabs: _tabs, selection: selection)),
    );
    final tabs = tester.widget<Tabs>(find.byType(Tabs));
    expect(tabs.selected, 1);
    expect(tabs.ids, ['details', 'pricing', 'seo']);
    expect(_isSelected(tester, 'Pricing'), isTrue);
    expect(_isSelected(tester, 'Details'), isFalse);
  });

  testWidgets('a tap selects the tab\'s id', (tester) async {
    final selection = TabSelection('details');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(Tabs.keyed(tabs: _tabs, selection: selection)),
    );
    await tester.tap(find.text('SEO'));
    await tester.pump();
    expect(selection.active, 'seo');
    expect(_isSelected(tester, 'SEO'), isTrue);
  });

  testWidgets('follows a selection changed elsewhere, as a TabScope '
      'reveal does', (tester) async {
    final selection = TabSelection('details');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            Tabs.keyed(tabs: _tabs, selection: selection),
            TabScope(
              tabId: 'seo',
              selection: selection,
              child: Builder(
                builder: (context) => Button(
                  'Reveal',
                  onPressed: () => TabScope.maybeOf(context)!.activate(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Reveal'));
    await tester.pump();
    expect(_isSelected(tester, 'SEO'), isTrue);
    expect(_isSelected(tester, 'Details'), isFalse);
  });

  testWidgets('the arrow keys move the selection by id', (tester) async {
    final selection = TabSelection('details');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(Tabs.keyed(tabs: _tabs, selection: selection)),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selection.active, 'pricing');
  });

  testWidgets('an id no tab has selects none', (tester) async {
    final selection = TabSelection('missing');
    addTearDown(selection.dispose);
    await tester.pumpWidget(
      _host(Tabs.keyed(tabs: _tabs, selection: selection)),
    );
    expect(tester.widget<Tabs>(find.byType(Tabs)).selected, -1);
    for (final label in ['Details', 'Pricing', 'SEO']) {
      expect(_isSelected(tester, label), isFalse);
    }
  });

  testWidgets('swapping the selection listens to the new one', (tester) async {
    final first = TabSelection('details');
    final second = TabSelection('pricing');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(_host(Tabs.keyed(tabs: _tabs, selection: first)));
    await tester.pumpWidget(_host(Tabs.keyed(tabs: _tabs, selection: second)));
    expect(_isSelected(tester, 'Pricing'), isTrue);
    first.select('seo');
    await tester.pump();
    expect(_isSelected(tester, 'Pricing'), isTrue);
    second.select('seo');
    await tester.pump();
    expect(_isSelected(tester, 'SEO'), isTrue);
  });
}
