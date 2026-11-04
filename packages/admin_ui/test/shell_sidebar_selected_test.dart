import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

enum _Nav { pages, media, settings }

/// A sidebar of three items valued by [_Nav], [marked] marking itself.
Widget _sidebar({Object? selected, _Nav? marked, bool valued = true}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Scaffold(
        body: Row(
          children: [
            Sidebar(
              selected: selected,
              entries: [
                for (final nav in _Nav.values)
                  NavItem(
                    nav.name,
                    icon: Icons.circle_outlined,
                    value: valued ? nav : null,
                    selected: nav == marked,
                    onTap: () {},
                  ),
              ],
            ),
          ],
        ),
      ),
    );

/// The items announced as selected.
List<String> _selected(WidgetTester tester) => [
  for (final nav in _Nav.values)
    if (isSemantics(isSelected: true)
        .matches(tester.getSemantics(find.bySemanticsLabel(nav.name)), {}))
      nav.name,
];

void main() {
  testWidgets('the item whose value is the selection is current', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_sidebar(selected: _Nav.media));
    expect(_selected(tester), ['media']);
    await tester.pumpWidget(_sidebar(selected: _Nav.settings));
    expect(_selected(tester), ['settings']);
    semantics.dispose();
  });

  testWidgets('it draws as the current item does', (tester) async {
    await tester.pumpWidget(_sidebar(selected: _Nav.media));
    final label = tester.widget<Text>(find.text('media'));
    final current = defaultTokens.palette.navSelectedText;
    expect(label.style!.color, current);
    expect(
      tester.widget<Text>(find.text('pages')).style!.color,
      isNot(current),
    );
  });

  testWidgets('an item marked selected stays current whatever the '
      'selection', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_sidebar(selected: _Nav.media, marked: _Nav.pages));
    expect(_selected(tester), ['pages', 'media']);
    semantics.dispose();
  });

  testWidgets('no selection, or no values, leaves every item as it marks '
      'itself', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_sidebar());
    expect(_selected(tester), isEmpty);
    await tester.pumpWidget(_sidebar(selected: _Nav.media, valued: false));
    expect(_selected(tester), isEmpty, reason: 'a null value matches nothing');
    semantics.dispose();
  });

  testWidgets('the selection holds in the collapsed rail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: Scaffold(
          body: Row(
            children: [
              Sidebar(
                collapsed: true,
                selected: _Nav.media,
                entries: [
                  for (final nav in _Nav.values)
                    NavItem(
                      nav.name,
                      icon: Icons.circle_outlined,
                      value: nav,
                      onTap: () {},
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final icons = tester.widgetList<Icon>(find.byIcon(Icons.circle_outlined));
    expect(
      [for (final icon in icons) icon.color],
      [
        defaultTokens.palette.foregroundSecondary,
        defaultTokens.palette.navSelectedText,
        defaultTokens.palette.foregroundSecondary,
      ],
    );
  });
}
