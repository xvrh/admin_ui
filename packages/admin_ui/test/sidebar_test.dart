import 'package:admin_ui/src/shell/ui/sidebar.dart';
import 'package:admin_ui/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Row(children: [child])),
);

void main() {
  testWidgets('renders section headers and items; tapping fires onTap', (
    tester,
  ) async {
    var tapped = '';
    await tester.pumpWidget(
      _host(
        Sidebar(
          entries: [
            const NavSection('Content'),
            NavItem(
              'Pages',
              icon: Icons.description_outlined,
              selected: true,
              onTap: () => tapped = 'Pages',
            ),
            NavItem(
              'Media',
              icon: Icons.photo_library_outlined,
              onTap: () => tapped = 'Media',
            ),
          ],
        ),
      ),
    );

    expect(find.text('CONTENT'), findsOneWidget);
    expect(find.text('Pages'), findsOneWidget);

    await tester.tap(find.text('Media'));
    expect(tapped, 'Media');
  });

  testWidgets('collapsed hides item labels (kept only as tooltips)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Sidebar(
          collapsed: true,
          entries: [
            NavItem('Pages', icon: Icons.description_outlined, onTap: () {}),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200)); // settle width anim

    // Label is gone from the row; the icon remains.
    expect(find.text('Pages'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });

  testWidgets('a neutral badge stays a pill on the hovered tile', (
    tester,
  ) async {
    const colors = irisPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: colors)),
        home: Scaffold(
          body: Row(
            children: [
              Sidebar(
                entries: [
                  NavItem(
                    'Pages',
                    icon: Icons.description_outlined,
                    badge: '3',
                    selected: true,
                    onTap: () {},
                  ),
                  NavItem(
                    'Media',
                    icon: Icons.photo_library_outlined,
                    badge: '12',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    Color fillBehind(String text) => tester
        .widgetList<Container>(
          find.ancestor(of: find.text(text), matching: find.byType(Container)),
        )
        .map((c) => (c.decoration as BoxDecoration?)?.color)
        .firstWhere((c) => c != null && c.a > 0)!;
    Color textColor(String text) => tester
        .renderObject<RenderParagraph>(find.text(text))
        .text
        .style!
        .color!;

    expect(textColor('Pages'), colors.navSelectedText);
    expect(fillBehind('3'), colors.primary);
    expect(textColor('3'), colors.onPrimary);
    expect(textColor('12'), colors.foregroundSecondary);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Media')));
    await tester.pump();
    final tile = fillBehind('Media');
    expect(tile, colors.navHoverFill);
    final badge = Color.alphaBlend(fillBehind('12'), tile);
    expect(contrastRatio(badge, tile), greaterThan(1.1));
    expect(contrastRatio(textColor('12'), badge), greaterThanOrEqualTo(4.5));
    await mouse.removePointer();
  });
}
