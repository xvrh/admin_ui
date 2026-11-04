import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s tokens in [dark] or light mode, in the platform's font: its
/// palette, geometry and anatomy, with a type spec that names no Google
/// Font, so re-deriving it for a chrome palette loads nothing.
AdminTokens _tokens(AdminTheme theme, {required bool dark}) {
  final source = dark ? theme.dark! : theme.tokens;
  final spec = source.typography.spec;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    type: AdminTypeSpec(
      ramp: spec.ramp,
      scale: spec.scale,
      heading: spec.heading,
      label: spec.label,
      strong: spec.strong,
      body: spec.body,
      tracking: spec.tracking,
      uppercaseLabels: spec.uppercaseLabels,
    ),
    elevation: source.elevation,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    field: source.field,
    button: source.button,
    shell: source.shell,
  );
}

/// The catalog's brand accents.
const _brands = <String, Color>{
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

const _size = Size(1200, 700);

/// A frame: a top bar with a title, a bare text and an action over a sidebar
/// whose second item is selected and carries a count, and whose third is
/// pinned hovered.
Widget _frame(
  AdminTokens tokens, {
  bool collapsed = false,
  WidgetStatesController? hovered,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: AdminScope(
    child: Shell(
      topBar: TopBar(
        title: 'Workspace',
        leading: const Text('Bare'),
        actions: [
          IconAction(Icons.add_rounded, label: 'Add', onPressed: () {}),
        ],
      ),
      sidebar: Sidebar(
        collapsed: collapsed,
        entries: [
          const NavSection('Content'),
          NavItem('Dashboard', icon: Icons.dashboard_outlined, onTap: () {}),
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
            statesController: hovered,
            onTap: () {},
          ),
          const NavItem('Archive', icon: Icons.archive_outlined),
        ],
      ),
      child: const SizedBox.expand(),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  AdminTokens tokens, {
  bool collapsed = false,
  WidgetStatesController? hovered,
  Size size = _size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _frame(tokens, collapsed: collapsed, hovered: hovered),
  );
  await tester.pumpAndSettle();
}

/// The tap target of the item that shows [icon].
Finder _tile(IconData icon) =>
    find.ancestor(of: find.byIcon(icon), matching: find.byType(Tappable)).first;

/// The decoration the item that shows [icon] paints: its box right under
/// the [Tappable].
BoxDecoration _tileBox(WidgetTester tester, IconData icon) => tester
    .widgetList<Container>(
      find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .first;

/// The rail's fill: the sidebar's own decorated box.
Color _rail(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(Sidebar),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

/// The top bar's fill.
Color _bar(WidgetTester tester) =>
    (tester
                .widget<Container>(
                  find
                      .descendant(
                        of: find.byType(TopBar),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration)
        .color!;

Color _ink(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;

/// The opaque colour [fill] makes laid over [under].
Color _over(Color? fill, Color under) =>
    fill == null ? under : Color.alphaBlend(fill, under);

/// The fill of the pill behind [text], over [under].
Color _pill(WidgetTester tester, String text, Color under) {
  final fill = tester
      .widgetList<Container>(
        find.ancestor(of: find.text(text), matching: find.byType(Container)),
      )
      .map((c) => (c.decoration as BoxDecoration?)?.color)
      .firstWhere((c) => c != null)!;
  return _over(fill, under);
}

/// The palette a descendant of [finder] draws with.
AdminPalette _colorsIn(WidgetTester tester, Finder finder) =>
    tester.element(finder).colors;

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      if (dark && !theme.hasDark) continue;
      final mode = dark ? 'Dark' : 'Light';
      final tokens = _tokens(theme, dark: dark);
      final style = tokens.shell;

      group('${theme.name} $mode', () {
        testWidgets('the sidebar and top bar take the style', (tester) async {
          await _pump(tester, tokens);
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(Sidebar)).width,
            style.sidebarWidth,
          );
          expect(
            tester.getSize(find.byType(TopBar)).height,
            style.topBarHeight,
          );

          final first = tester.getRect(_tile(Icons.dashboard_outlined));
          final second = tester.getRect(_tile(Icons.description_outlined));
          expect(first.height, style.itemHeight);
          expect(second.top - first.top, style.itemHeight + style.itemGap);
          expect(
            _tileBox(tester, Icons.description_outlined).borderRadius,
            BorderRadius.circular(style.itemRadiusOf(tokens.radii)),
          );
          expect(
            tester.getSize(find.byIcon(Icons.dashboard_outlined)),
            Size.square(style.itemIconSizeOf(tokens.iconSizes)),
          );

          // A focus ring outside the tile keeps inside the rail; otherwise
          // the content starts under the top bar's leading slot.
          final context = tester.element(_tile(Icons.dashboard_outlined));
          final reach = FocusRing.reachOf(context);
          expect(first.left, greaterThanOrEqualTo(reach));
          final margin = style.itemMarginX;
          if (margin != null) {
            expect(first.left, math.max(margin, reach));
          } else if (Shell.inset - style.itemPaddingX >= reach) {
            expect(
              tester.getRect(find.byIcon(Icons.dashboard_outlined)).left,
              Shell.inset,
            );
          }
          expect(
            tester.getRect(find.text('CONTENT')).left,
            first.left + style.itemPaddingX,
          );
        });

        testWidgets('the selected item is marked as the style says', (
          tester,
        ) async {
          await _pump(tester, tokens);
          final colors = _colorsIn(tester, _tile(Icons.description_outlined));
          final mark = colors.navIndicator.a == 0
              ? NavIndicator.none
              : style.indicatorOf(colors, tokens.radii);
          final bar = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color == colors.navIndicator &&
                w.constraints?.maxWidth == style.indicatorWidth,
          );
          if (mark == NavIndicator.none) {
            expect(bar, findsNothing);
            return;
          }
          expect(bar, findsOneWidget);
          final tile = tester.getRect(_tile(Icons.description_outlined));
          final rect = tester.getRect(bar);
          expect(rect.left, tile.left);
          expect(
            rect.height,
            mark == NavIndicator.edge
                ? tile.height
                : style.itemIconSizeOf(tokens.iconSizes),
          );
        });

        testWidgets('the rail takes the style\'s width, the glyph centred', (
          tester,
        ) async {
          await _pump(tester, tokens, collapsed: true);
          expect(tester.takeException(), isNull);
          final rail = tester.getRect(find.byType(Sidebar));
          expect(rail.width, style.railWidth);
          expect(
            tester.getCenter(find.byIcon(Icons.dashboard_outlined)).dx,
            closeTo((rail.width - 1) / 2, 0.5),
          );
          expect(
            tester.getSize(find.byIcon(Icons.dashboard_outlined)),
            Size.square(style.itemIconSizeOf(tokens.iconSizes)),
          );
        });

        final brands = <String, AdminTokens>{
          '': tokens,
          for (final MapEntry(key: name, value: seed) in _brands.entries)
            ' + $name': tokens.branded(seed),
        };
        for (final MapEntry(key: brand, value: branded) in brands.entries) {
          testWidgets('labels, captions and counts read at 4.5:1$brand', (
            tester,
          ) async {
            final hovered = WidgetStatesController({WidgetState.hovered});
            addTearDown(hovered.dispose);
            await _pump(tester, branded, hovered: hovered);
            final rail = _rail(tester);
            final colors = _colorsIn(tester, _tile(Icons.description_outlined));
            expect(rail, colors.background);

            void reads(String text, Color on, String what) => expect(
              contrastRatio(_ink(tester, text), on),
              greaterThanOrEqualTo(4.5),
              reason: '$what on ${_hex(on)}',
            );

            reads('CONTENT', rail, 'section label');
            reads('Dashboard', rail, 'item');
            final selected = _over(
              _tileBox(tester, Icons.description_outlined).color,
              rail,
            );
            reads('Pages', selected, 'selected item');
            reads('3', _pill(tester, '3', selected), 'selected count');
            final hover = _over(
              _tileBox(tester, Icons.photo_library_outlined).color,
              rail,
            );
            expect(hover, isNot(rail), reason: 'the pinned hover fills');
            reads('Media', hover, 'hovered item');
            reads('12', _pill(tester, '12', hover), 'count');

            final bar = _bar(tester);
            expect(bar, _colorsIn(tester, find.text('Workspace')).surface);
            reads('Workspace', bar, 'top bar title');
            reads('Bare', bar, 'unstyled text in the top bar');
          });
        }

        testWidgets('keyboard focus reads at 3:1 on the rail and the bar', (
          tester,
        ) async {
          await _pump(tester, tokens);
          final railRing = _colorsIn(
            tester,
            _tile(Icons.dashboard_outlined),
          ).focusRing;
          expect(
            contrastRatio(railRing, _rail(tester)),
            greaterThanOrEqualTo(3),
          );
          final barRing = _colorsIn(tester, find.byType(IconAction)).focusRing;
          expect(contrastRatio(barRing, _bar(tester)), greaterThanOrEqualTo(3));
        });
      });
    }
  }

  group('chrome palettes', () {
    final carbon = _tokens(carbonTheme, dark: false);
    final carbonDark = _tokens(carbonTheme, dark: true);
    final ant = _tokens(antTheme, dark: false);
    final antDark = _tokens(antTheme, dark: true);

    testWidgets('Carbon: a 48px g100 header in light and dark', (tester) async {
      for (final tokens in [carbon, carbonDark]) {
        await _pump(tester, tokens);
        expect(tester.getSize(find.byType(TopBar)).height, 48);
        expect(_bar(tester), const Color(0xFF161616));
        final line = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(TopBar),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (line.decoration! as BoxDecoration).border,
          const Border(bottom: BorderSide(color: Color(0xFF393939))),
        );
        // The page keeps its own palette.
        expect(_rail(tester), tokens.palette.background);
      }
    });

    testWidgets('Carbon: a 256px side nav of 32px square links, the current '
        'one ruled down its leading edge', (tester) async {
      await _pump(tester, carbon);
      expect(tester.getSize(find.byType(Sidebar)).width, 256);
      final tile = tester.getRect(_tile(Icons.description_outlined));
      expect(tile.height, 32);
      expect(tile.left, 0, reason: 'a link spans the side nav');
      expect(
        _tileBox(tester, Icons.description_outlined).borderRadius,
        BorderRadius.zero,
      );
      final rule = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 3 &&
            (w.decoration as BoxDecoration?)?.color ==
                carbon.palette.navIndicator,
      );
      expect(tester.getRect(rule), Rect.fromLTWH(0, tile.top, 3, 32));
    });

    testWidgets('Ant: a 200px dark sider in light, its selection on the '
        'primary under white', (tester) async {
      await _pump(tester, ant);
      expect(tester.getSize(find.byType(Sidebar)).width, 200);
      expect(_rail(tester), const Color(0xFF001529));
      final fill = _tileBox(tester, Icons.description_outlined).color!;
      expect(fill, ant.palette.primary);
      expect(_ink(tester, 'Pages'), const Color(0xFFFFFFFF));
      expect(
        contrastRatio(_ink(tester, 'Pages'), fill),
        greaterThanOrEqualTo(4.5),
      );
      // The count turns over rather than vanish into the primary fill.
      expect(_pill(tester, '3', fill), isNot(fill));
      final line = tester.renderObject<RenderDecoratedBox>(
        find
            .descendant(
              of: find.byType(Sidebar),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (line.decoration as BoxDecoration).border,
        const BorderDirectional(end: BorderSide(color: Color(0xFF1F3143))),
      );
      // The top bar keeps the page's palette: the classic layout's header.
      expect(_bar(tester), ant.palette.surface);

      await _pump(tester, ant, collapsed: true);
      expect(tester.getSize(find.byType(Sidebar)).width, 80);
    });

    testWidgets('Ant: the sider follows the page in dark', (tester) async {
      await _pump(tester, antDark);
      expect(_rail(tester), antDark.palette.background);
    });

    testWidgets('a brand reaches the chrome', (tester) async {
      const crimson = Color(0xFFE11D48);
      await _pump(tester, carbon.branded(crimson));
      expect(
        _colorsIn(tester, find.byType(IconAction)).primary,
        carbonShellPalette.branded(crimson).primary,
      );
    });

    testWidgets('the chrome keeps the app\'s scopes', (tester) async {
      await _pump(tester, carbon);
      final inBar = tester.element(find.byType(IconAction));
      final inPage = tester.element(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == double.infinity,
        ),
      );
      expect(ModalAnchor.of(inBar), same(ModalAnchor.of(inPage)));
      expect(ToastScope.of(inBar), same(ToastScope.of(inPage)));
      expect(
        find.descendant(
          of: find.byType(TopBar),
          matching: find.byType(AdminScope),
        ),
        findsNothing,
      );
    });

    testWidgets('the chrome theme is built once while the tokens hold', (
      tester,
    ) async {
      await _pump(tester, ant);
      ThemeData inSider() =>
          Theme.of(tester.element(_tile(Icons.dashboard_outlined)));
      final before = inSider();
      expect(before.extension<AdminTokens>()!.palette, antSiderPalette);
      await tester.pumpWidget(_frame(ant));
      expect(inSider(), same(before));
    });
  });

  group('Iris and shadcn keep the kit\'s frame', () {
    for (final theme in [irisTheme, shadcnTheme]) {
      for (final dark in [false, true]) {
        testWidgets('${theme.name} ${dark ? 'Dark' : 'Light'}', (tester) async {
          final tokens = _tokens(theme, dark: dark);
          expect(tokens.shell, const AdminShellStyle());
          await _pump(tester, tokens);
          expect(
            tester.getSize(find.byType(Sidebar)).width,
            Sidebar.expandedWidth,
          );
          expect(tester.getSize(find.byType(TopBar)).height, TopBar.height);
          final first = tester.getRect(_tile(Icons.dashboard_outlined));
          final second = tester.getRect(_tile(Icons.description_outlined));
          expect(first.height, 36);
          expect(second.top - first.bottom, 4);
          expect(first.left, 8);
          expect(first.width, Sidebar.expandedWidth - 1 - 16);
          expect(
            tester.getRect(find.byIcon(Icons.dashboard_outlined)).left,
            Shell.inset,
          );
          expect(
            tester.getSize(find.byIcon(Icons.dashboard_outlined)),
            const Size.square(16),
          );
          await _pump(tester, tokens, collapsed: true);
          expect(
            tester.getSize(find.byType(Sidebar)).width,
            Sidebar.collapsedWidth,
          );
          final rail = tester.getRect(_tile(Icons.dashboard_outlined));
          expect(rail.left, 8);
          expect(rail.size, const Size(Sidebar.collapsedWidth - 1 - 16, 36));
        });
      }
    }
  });

  group('a narrow window and the rail', () {
    final material = _tokens(materialTheme, dark: false);
    double width(WidgetTester tester) =>
        tester.getSize(find.byType(Sidebar)).width;

    testWidgets('a wide drawer keeps to its share of a narrow window', (
      tester,
    ) async {
      await _pump(tester, material);
      expect(width(tester), 360);
      await _pump(tester, material, size: const Size(800, 700));
      expect(width(tester), 800 * Sidebar.maxWindowShare);
      await _pump(tester, material, size: const Size(600, 700));
      expect(width(tester), Sidebar.expandedWidth);
      expect(tester.takeException(), isNull);
      // No narrower than the kit's own sidebar, whose width a window never
      // takes from it.
      for (final (theme, expected) in [(irisTheme, 240.0), (antTheme, 200.0)]) {
        await _pump(
          tester,
          _tokens(theme, dark: false),
          size: const Size(600, 700),
        );
        expect(width(tester), expected, reason: theme.name);
      }
      // Narrower, the frame is compact and the sidebar leaves it.
      await _pump(tester, material, size: const Size(599, 700));
      expect(find.byType(Sidebar), findsNothing);
    });

    testWidgets('a rail tile is as wide as tall where the rail allows it, '
        'and spans a rail it fills', (tester) async {
      for (final (theme, size) in [
        (fluentTheme, const Size(40, 40)),
        (materialTheme, const Size(56, 56)),
        (carbonTheme, const Size(47, 32)),
        (antTheme, const Size(71, 40)),
      ]) {
        final tokens = _tokens(theme, dark: false);
        await _pump(tester, tokens, collapsed: true);
        final tile = tester.getRect(_tile(Icons.dashboard_outlined));
        expect(tile.size, size, reason: theme.name);
        // Centred in the rail inside its hairline.
        expect(
          tile.center.dx,
          moreOrLessEquals((tokens.shell.railWidth - 1) / 2),
          reason: theme.name,
        );
      }
    });

    testWidgets('a brand keeps the selection\'s anatomy', (tester) async {
      // Ant's dark sider fills the selection with the primary under its
      // on-colour: so it does with a brand's.
      final ant = _tokens(antTheme, dark: false).branded(_brands['Teal']!);
      await _pump(tester, ant);
      final sider = _colorsIn(tester, _tile(Icons.description_outlined));
      final fill = _tileBox(tester, Icons.description_outlined).color!;
      expect(fill, sider.primary);
      expect(_ink(tester, 'Pages'), sider.foregroundOn(fill));
      expect(
        contrastRatio(_ink(tester, 'Pages'), fill),
        greaterThanOrEqualTo(4.5),
      );

      // Carbon's neutral selection stays; its rule takes the brand.
      final carbon = _tokens(
        carbonTheme,
        dark: false,
      ).branded(_brands['Amber']!);
      await _pump(tester, carbon);
      final colors = _colorsIn(tester, _tile(Icons.description_outlined));
      expect(
        _tileBox(tester, Icons.description_outlined).color,
        carbonPalette.navSelectedFill,
      );
      expect(_ink(tester, 'Pages'), carbonPalette.navSelectedText);
      expect(colors.navIndicator, isNot(carbonPalette.navIndicator));
      expect(
        contrastRatio(colors.navIndicator, colors.navSelectedFill),
        greaterThanOrEqualTo(3),
      );
    });
  });
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
