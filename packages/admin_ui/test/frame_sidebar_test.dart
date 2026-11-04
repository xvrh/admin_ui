import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

Widget _host(Widget sidebar, {AdminPalette palette = irisPalette}) =>
    MaterialApp(
      theme: buildAppTheme(AdminTokens.from(palette: palette)),
      home: Scaffold(
        body: Row(
          children: [
            sidebar,
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );

/// The node a tile announces as: the one its tap target sits in.
SemanticsNode _tileNode(WidgetTester tester, String label) =>
    tester.getSemantics(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(Tappable),
        ),
        matching: find.byType(GestureDetector),
      ),
    );

/// The fill a tile paints: its decorated box right under the [Tappable].
Color? _tileFill(WidgetTester tester, String label) {
  final tile = find.ancestor(
    of: find.text(label),
    matching: find.byType(Container),
  );
  final box = tester
      .widgetList<Container>(tile)
      .firstWhere((c) => c.decoration is BoxDecoration);
  return (box.decoration! as BoxDecoration).color;
}

Color _textColor(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;

void main() {
  late List<String> tapped;
  List<NavEntry> entries({String selected = 'Pages'}) => [
    const NavSection('Content'),
    for (final label in ['Dashboard', 'Pages', 'Archive', 'Media'])
      NavItem(
        label,
        icon: Icons.circle_outlined,
        selected: label == selected,
        // An inert item in the middle, which the arrow keys step over.
        onTap: label == 'Archive' ? null : () => tapped.add(label),
      ),
  ];

  setUp(() => tapped = []);

  group('keyboard', () {
    testWidgets('Tab reaches each live item and Enter opens it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Sidebar(entries: entries())));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(tapped, ['Dashboard']);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(tapped, ['Dashboard', 'Pages']);

      // The inert item is no Tab stop.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(tapped.last, 'Media');
    });

    testWidgets('the arrows, Home and End rove between the live items', (
      tester,
    ) async {
      await tester.pumpWidget(_host(Sidebar(entries: entries())));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      Future<void> press(LogicalKeyboardKey key) async {
        await tester.sendKeyEvent(key);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }

      await press(LogicalKeyboardKey.arrowDown);
      await press(LogicalKeyboardKey.arrowDown);
      // Past the end the focus stays put.
      await press(LogicalKeyboardKey.arrowDown);
      await press(LogicalKeyboardKey.arrowUp);
      await press(LogicalKeyboardKey.home);
      await press(LogicalKeyboardKey.end);
      expect(tapped, [
        'Pages',
        'Media',
        'Media',
        'Pages',
        'Dashboard',
        'Media',
      ]);
    });

    testWidgets('keyboard focus rings the tile', (tester) async {
      await tester.pumpWidget(_host(Sidebar(entries: entries())));
      FocusRing ring() => tester.widget<FocusRing>(
        find.ancestor(
          of: find.text('Dashboard'),
          matching: find.byType(FocusRing),
        ),
      );
      expect(ring().focused, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(ring().focused, isTrue);
      expect(ring().radius, defaultRadii.radiusSmall);
    });
  });

  group('semantics', () {
    testWidgets('a navigation landmark named Navigation', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Sidebar(entries: entries())));
      final data = tester.getSemantics(find.byType(Sidebar)).getSemanticsData();
      expect(data.role, SemanticsRole.navigation);
      expect(data.label, 'Navigation');
      handle.dispose();
    });

    testWidgets('items are buttons; only the current one is selected', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(Sidebar(entries: entries())));
      expect(
        _tileNode(tester, 'Pages'),
        isSemantics(
          label: 'Pages',
          isButton: true,
          isSelected: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        _tileNode(tester, 'Dashboard'),
        isNot(isSemantics(isSelected: true)),
      );
      expect(
        _tileNode(tester, 'Archive'),
        isSemantics(label: 'Archive', isButton: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('the collapsed rail names each item and keeps its tooltip', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Sidebar(collapsed: true, entries: entries())),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Pages'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is Tip && w.message == 'Pages'),
        findsOneWidget,
      );
      final node = tester.getSemantics(
        find.descendant(
          of: find.byWidgetPredicate((w) => w is Tip && w.message == 'Pages'),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(node, isSemantics(label: 'Pages', isSelected: true));
      handle.dispose();
    });
  });

  group('geometry', () {
    testWidgets('tiles are 36 tall, 4 apart, with 16px icons', (tester) async {
      await tester.pumpWidget(_host(Sidebar(entries: entries())));
      Rect tile(String label) => tester.getRect(
        find.ancestor(of: find.text(label), matching: find.byType(Tappable)),
      );
      expect(tile('Dashboard').height, 36);
      expect(tile('Pages').top - tile('Dashboard').bottom, 4);
      expect(
        tester.getSize(find.byIcon(Icons.circle_outlined).first),
        const Size.square(16),
      );
    });
  });

  group('selection and hover across the shipped palettes', () {
    const brands = <String, Color?>{
      '': null,
      ' + Violet': Color(0xFF7C3AED),
      ' + Amber': Color(0xFFD97706),
    };
    for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
      for (final MapEntry(key: brand, value: seed) in brands.entries) {
        final palette = seed == null ? base : base.branded(seed);
        testWidgets('$name$brand', (tester) async {
          await tester.pumpWidget(
            _host(Sidebar(entries: entries()), palette: palette),
          );
          final rail = palette.background;

          final selected = _tileFill(tester, 'Pages')!;
          expect(selected, palette.navSelectedFill);
          expect(
            contrastRatio(_textColor(tester, 'Pages'), selected),
            greaterThanOrEqualTo(4.5),
            reason: 'selected label on its fill',
          );

          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(
            location: tester.getCenter(find.text('Media')),
          );
          await tester.pump();
          final hover = _tileFill(tester, 'Media')!;
          expect(hover, palette.navHoverFill);
          expect(
            contrastRatio(selected, rail),
            greaterThanOrEqualTo(contrastRatio(hover, rail) - 0.001),
            reason: 'selection reads at least as strong as hover',
          );

          // Hovering the selected item keeps its fill.
          await mouse.moveTo(tester.getCenter(find.text('Pages')));
          await tester.pump();
          expect(_tileFill(tester, 'Pages'), selected);
          await mouse.removePointer();

          expect(
            contrastRatio(_textColor(tester, 'CONTENT'), rail),
            greaterThanOrEqualTo(4.5),
            reason: 'section label on the rail',
          );

          final bar = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color ==
                    palette.navIndicator &&
                w.constraints?.maxWidth == 3,
          );
          expect(bar, palette.navIndicator.a == 0 ? findsNothing : findsOne);
        });
      }
    }
  });
}
