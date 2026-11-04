import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An iPhone 16's screen and insets: the camera island's status bar on
/// top, the home indicator below.
const _phone = Size(393, 852);
const _top = 59.0;
const _bottom = 34.0;

const _footer = ValueKey('footer');

Widget _frame(AdminTokens tokens, {bool topBar = true}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: AdminScope(
    child: Shell(
      topBar: topBar ? const TopBar(leading: Text('Acme')) : null,
      sidebar: Sidebar(
        entries: [
          NavItem('Pages', icon: Icons.description_outlined, onTap: () {}),
        ],
        footer: const SizedBox(key: _footer, height: 40),
      ),
      child: const SizedBox.expand(),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget app, {
  Size size = _phone,
  double top = _top,
  double bottom = _bottom,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
  tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// The screen as drawn, to read its pixels.
Future<ByteData> _pixels(WidgetTester tester) async {
  final image = (await tester.runAsync(
    () => captureImage(tester.binding.rootElement!),
  ))!;
  addTearDown(image.dispose);
  return (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
}

/// The colour at [at] in [pixels], a screen [width] wide.
Color _at(ByteData pixels, Offset at, {double width = 393}) {
  final i = ((at.dy.floor() * width.floor()) + at.dx.floor()) * 4;
  return Color.fromARGB(
    pixels.getUint8(i + 3),
    pixels.getUint8(i),
    pixels.getUint8(i + 1),
    pixels.getUint8(i + 2),
  );
}

/// The fill of the nearest box above [finder] that paints one.
Color _fillAbove(WidgetTester tester, Finder finder) => tester
    .widgetList<Container>(
      find.ancestor(of: finder, matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((d) => d.color != null)
    .color!;

void main() {
  group('the frame', () {
    testWidgets('the top bar runs under the status bar in its own colour, '
        'its content below it', (tester) async {
      await _pump(tester, _frame(irisTheme.tokens));
      final bar = tester.getRect(find.byType(TopBar));
      final height = irisTheme.tokens.shell.topBarHeight;
      expect(bar.top, 0);
      expect(bar.height, height + _top);
      final logo = tester.getRect(find.text('Acme'));
      expect(logo.top, greaterThan(_top));
      expect(logo.center.dy, closeTo(_top + (height - 1) / 2, 0.5));
      final pixels = await _pixels(tester);
      expect(
        _at(pixels, const Offset(200, _top / 2)),
        irisTheme.tokens.palette.surface,
        reason: 'the band is the bar',
      );
    });

    testWidgets('Carbon\'s g100 header fills the band in g100', (tester) async {
      final tokens = carbonTheme.tokens;
      await _pump(tester, _frame(tokens));
      final pixels = await _pixels(tester);
      expect(
        _at(pixels, const Offset(200, _top / 2)),
        tokens.shell.topBarPalette!.surface,
      );
    });

    testWidgets('beside the page, the sidebar keeps the bottom inset under '
        'its footer, in its own colour', (tester) async {
      final tokens = antTheme.tokens;
      await _pump(tester, _frame(tokens), size: const Size(1000, 700));
      final sidebar = tester.getRect(find.byType(Sidebar));
      expect(sidebar.top, tester.getRect(find.byType(TopBar)).bottom);
      expect(sidebar.bottom, 700);
      expect(tester.getRect(find.byKey(_footer)).bottom, 700 - _bottom);
      final pixels = await _pixels(tester);
      expect(
        _at(pixels, const Offset(20, 700 - _bottom / 2), width: 1000),
        tokens.shell.sidebarPalette!.background,
      );
    });

    testWidgets('without a top bar the sidebar keeps the top inset too', (
      tester,
    ) async {
      await _pump(
        tester,
        _frame(defaultTokens, topBar: false),
        size: const Size(1000, 700),
      );
      final sidebar = tester.getRect(find.byType(Sidebar));
      expect(sidebar.top, 0);
      expect(tester.getRect(find.text('Pages')).top, greaterThan(_top));
    });
  });

  group('the drawer', () {
    for (final (name, tokens) in [
      ('Iris', irisTheme.tokens),
      ('Ant', antTheme.tokens),
      ('Carbon dark', carbonTheme.dark!),
    ]) {
      testWidgets('$name: the sidebar fills it, both insets in its colour', (
        tester,
      ) async {
        await _pump(tester, _frame(tokens));
        await tester.tap(find.byType(ShellMenuButton));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byType(Sidebar)),
          const Rect.fromLTWH(0, 0, Shell.drawerWidth, 852),
        );
        final rail = (tokens.shell.sidebarPalette ?? tokens.palette).background;
        expect(_fillAbove(tester, find.text('Pages')), rail);
        // The head sits under the status bar, level with the top bar's.
        final logos = find.text('Acme');
        expect(
          tester.getCenter(logos.last).dy,
          tester.getCenter(logos.first).dy,
        );
        expect(tester.getRect(find.byKey(_footer)).bottom, 852 - _bottom);
        final pixels = await _pixels(tester);
        for (final y in [_top / 2, 852 - _bottom / 2]) {
          expect(
            _at(pixels, Offset(Shell.drawerWidth / 2, y)),
            rail,
            reason: 'no band in the sheet\'s surface at $y',
          );
        }
      });
    }
  });

  group('SideSheet', () {
    Widget sheet({bool safeArea = true, bool header = true, bool? footer}) =>
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 320,
              child: SideSheet(
                title: header ? 'Sheet' : null,
                safeArea: safeArea,
                footer: (footer ?? true) ? const Text('Footer') : null,
                child: Builder(
                  builder: (context) => Text(
                    'body ${MediaQuery.paddingOf(context).top} '
                    '${MediaQuery.paddingOf(context).bottom}',
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('the header takes the top inset and the footer the bottom, '
        'the body told of neither', (tester) async {
      await _pump(tester, sheet());
      expect(tester.getRect(find.text('Sheet')).top, greaterThan(_top));
      expect(
        tester.getRect(find.text('Footer')).bottom,
        lessThanOrEqualTo(852 - _bottom - AdminSpacing.lg),
      );
      expect(find.text('body 0.0 0.0'), findsOneWidget);
    });

    testWidgets('without a header or footer the body keeps clear itself', (
      tester,
    ) async {
      await _pump(tester, sheet(header: false, footer: false));
      final body = tester.getRect(find.textContaining('body'));
      expect(body.top, _top);
      expect(find.text('body 0.0 0.0'), findsOneWidget);
    });

    testWidgets('safeArea false leaves the body its insets', (tester) async {
      await _pump(tester, sheet(safeArea: false, header: false, footer: false));
      expect(find.text('body $_top $_bottom'), findsOneWidget);
      expect(tester.getRect(find.textContaining('body')).top, 0);
    });
  });
}
