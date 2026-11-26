import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/ar.dart';
import 'package:admin_ui/l10n/fr.dart';
import 'package:admin_ui/src/common/ui/popover.dart' show PopoverArrowPainter;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// Whether an overlay is ringed in a hairline as well as lifted on its
// shadow: the theme's AdminOverlayStyle.modalOutline and popoverOutline,
// which every overlay reads through modalEdge and popoverEdge. A dark
// palette always rings it.

/// Each shipped theme's outlines, from its reference.
const _expected = {
  // the kit's own: a hairline around both
  'Iris': (modal: true, popover: true),
  // Flutter's M3 dialog and menu: a container and an elevation, no side
  'Material': (modal: false, popover: false),
  // DialogContent, PopoverContent, DropdownMenuContent, SelectContent:
  // `border`
  'shadcn': (modal: true, popover: true),
  // a Modal's content is `border: 0`; a Dropdown's and a Select's stand on
  // boxShadowSecondary
  'Ant': (modal: false, popover: false),
  // DialogSurface, PopoverSurface, MenuPopover: colorTransparentStroke
  'Fluent': (modal: false, popover: false),
  // the modal container: `border: 1px solid $border-subtle-01`; a menu, a
  // list box's menu and a popover: a shadow, an outline only on request
  'Carbon': (modal: true, popover: false),
};

/// Every shipped theme in both modes.
final _looks = [
  for (final theme in adminThemes) ...[
    (name: '${theme.name} light', theme: theme.name, tokens: theme.tokens),
    (name: '${theme.name} dark', theme: theme.name, tokens: theme.dark!),
  ],
];

/// The edge an overlay of the given kind takes in [tokens]: a hairline of
/// the palette's border where the theme rings it or the palette is dark.
BorderSide _edge(String theme, AdminTokens tokens, {required bool modal}) {
  final look = _expected[theme]!;
  final ringed =
      (modal ? look.modal : look.popover) ||
      tokens.palette.brightness == Brightness.dark;
  return ringed ? BorderSide(color: tokens.palette.border) : BorderSide.none;
}

/// A library with nothing in it.
class _NoAssets implements AssetSource {
  @override
  Future<Asset?> resolve(String id) async => null;

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult.empty;

  @override
  Future<Asset?> upload(
    Uint8List bytes, {
    required String mime,
    String? filename,
    void Function(double progress)? onProgress,
    Future<void>? cancelled,
  }) async => null;

  @override
  Future<Asset?> updateAlt(String id, Map<String, String> alt) async => null;
}

Widget _app(AdminTokens tokens, Widget body) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  builder: (context, navigator) => ToastScope(child: navigator!),
  home: Scaffold(body: ModalAnchor(child: body)),
);

/// A button that runs [open] with a context under the app.
Widget _opener(void Function(BuildContext context) open) => Center(
  child: Builder(
    builder: (context) =>
        TextButton(onPressed: () => open(context), child: const Text('Open')),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// The side of the first rounded [Material] under a widget of type [T]: the
/// surface it draws itself on.
BorderSide _sideUnder<T extends Widget>(WidgetTester tester) {
  final surface = tester
      .widgetList<Material>(
        find.descendant(of: find.byType(T), matching: find.byType(Material)),
      )
      .firstWhere((m) => m.shape is RoundedRectangleBorder);
  return (surface.shape! as RoundedRectangleBorder).side;
}

Widget _menu() => Center(
  child: Menu(
    entries: [
      MenuItem('Rename', onSelect: () {}),
      MenuItem('Duplicate', onSelect: () {}),
    ],
    builder: (context, c) =>
        TextButton(onPressed: c.toggle, child: const Text('Open')),
  ),
);

Widget _modal() => _opener(
  (context) => showModal<void>(
    context,
    builder: (context) => Modal(
      title: 'Delete page?',
      message: 'It cannot be restored.',
      onDismiss: () => Navigator.of(context).pop(),
    ),
  ),
);

void main() {
  group('AdminOverlayStyle', () {
    test('by default rings a modal and a popover', () {
      const style = AdminOverlayStyle();
      expect(style.modalOutline, isTrue);
      expect(style.popoverOutline, isTrue);
    });

    test('an edge is a hairline of the palette\'s border, or none', () {
      const ringed = AdminOverlayStyle();
      const bare = AdminOverlayStyle(
        modalOutline: false,
        popoverOutline: false,
      );
      final hairline = BorderSide(color: irisPalette.border);
      expect(ringed.modalEdge(irisPalette), hairline);
      expect(ringed.popoverEdge(irisPalette), hairline);
      expect(ringed.modalEdge(irisPalette).width, 1);
      expect(bare.modalEdge(irisPalette), BorderSide.none);
      expect(bare.popoverEdge(irisPalette), BorderSide.none);
    });

    test('each flag rules its own kind', () {
      const modalOnly = AdminOverlayStyle(popoverOutline: false);
      const popoverOnly = AdminOverlayStyle(modalOutline: false);
      expect(modalOnly.modalEdge(irisPalette).style, BorderStyle.solid);
      expect(modalOnly.popoverEdge(irisPalette), BorderSide.none);
      expect(popoverOnly.modalEdge(irisPalette), BorderSide.none);
      expect(popoverOnly.popoverEdge(irisPalette).style, BorderStyle.solid);
    });

    test('a dark palette is ringed whatever the flags say', () {
      const bare = AdminOverlayStyle(
        modalOutline: false,
        popoverOutline: false,
      );
      for (final dark in [irisDarkPalette, antDarkPalette, antSiderPalette]) {
        expect(dark.brightness, Brightness.dark);
        expect(bare.modalEdge(dark), BorderSide(color: dark.border));
        expect(bare.popoverEdge(dark), BorderSide(color: dark.border));
      }
    });

    test('copyWith, lerp, == and toString', () {
      const ringed = AdminOverlayStyle();
      const bare = AdminOverlayStyle(
        modalOutline: false,
        popoverOutline: false,
      );
      expect(ringed.copyWith(), ringed);
      expect(ringed.copyWith(modalOutline: false, popoverOutline: false), bare);
      expect(
        ringed.copyWith(modalOutline: false, popoverOutline: false).hashCode,
        bare.hashCode,
      );
      expect(bare.copyWith(tooltipArrow: true).modalOutline, isFalse);
      expect(bare.copyWith(tooltipArrow: true).popoverOutline, isFalse);
      expect(ringed, isNot(ringed.copyWith(modalOutline: false)));
      expect(ringed, isNot(ringed.copyWith(popoverOutline: false)));

      // A flag has no half way: it is the nearer side's.
      for (final (t, near) in [(0.0, ringed), (0.49, ringed), (0.5, bare)]) {
        final mixed = AdminOverlayStyle.lerp(ringed, bare, t);
        expect(mixed.modalOutline, near.modalOutline, reason: 'at $t');
        expect(mixed.popoverOutline, near.popoverOutline, reason: 'at $t');
      }

      expect('$ringed', contains('modals AdminOverlayMotion(a fade, medium)'));
      expect('$ringed', contains('medium), outlined; popovers at once, '));
      expect('$ringed', endsWith('popovers at once, outlined)'));
      expect('$bare', contains('medium), no outline; popovers at once, '));
      expect('$bare', endsWith('popovers at once, no outline)'));
    });
  });

  group('each shipped theme', () {
    test('is listed here', () {
      expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
    });

    for (final theme in adminThemes) {
      test('${theme.name} rings what its reference rings, in both modes', () {
        final look = _expected[theme.name]!;
        for (final tokens in [theme.tokens, theme.dark!]) {
          expect(tokens.overlay.modalOutline, look.modal);
          expect(tokens.overlay.popoverOutline, look.popover);
        }
      });
    }

    for (final look in _looks) {
      test('${look.name}: the edges, and the stock Material overlays', () {
        final tokens = look.tokens;
        final modal = _edge(look.theme, tokens, modal: true);
        final popover = _edge(look.theme, tokens, modal: false);
        expect(tokens.overlay.modalEdge(tokens.palette), modal);
        expect(tokens.overlay.popoverEdge(tokens.palette), popover);

        // What a stock dialog, popup menu, menu anchor and dropdown menu
        // take from the kit's theme.
        final theme = buildAppTheme(tokens);
        expect(
          (theme.dialogTheme.shape! as RoundedRectangleBorder).side,
          modal,
        );
        expect(
          (theme.popupMenuTheme.shape! as RoundedRectangleBorder).side,
          popover,
        );
        for (final style in [
          theme.menuTheme.style!,
          theme.dropdownMenuTheme.menuStyle!,
        ]) {
          final shape = style.shape!.resolve(const {});
          expect((shape! as RoundedRectangleBorder).side, popover);
        }
        // A card is not an overlay: it keeps its hairline.
        expect(
          (theme.cardTheme.shape! as RoundedRectangleBorder).side,
          BorderSide(color: tokens.palette.border),
        );
      });
    }
  });

  group('a popover', () {
    for (final look in _looks) {
      testWidgets('${look.name}: a menu\'s surface', (tester) async {
        await tester.pumpWidget(_app(look.tokens, _menu()));
        await _open(tester);
        expect(find.text('Rename'), findsOneWidget);
        expect(
          _sideUnder<PopoverMenuSurface>(tester),
          _edge(look.theme, look.tokens, modal: false),
        );
      });

      testWidgets('${look.name}: a surface\'s arrow', (tester) async {
        final tokens = look.tokens;
        await tester.pumpWidget(
          _app(
            tokens,
            Center(
              child: Popover(
                showArrow: true,
                anchor: (context, c) =>
                    TextButton(onPressed: c.toggle, child: const Text('Open')),
                content: (context, c) => const PopoverMenuSurface(
                  width: 200,
                  child: SizedBox(height: 60),
                ),
              ),
            ),
          ),
        );
        await _open(tester);
        final arrow =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.foregroundPainter is PopoverArrowPainter,
                      ),
                    )
                    .foregroundPainter!
                as PopoverArrowPainter;
        final edge = _edge(look.theme, tokens, modal: false);
        expect(arrow.fill, tokens.palette.popoverSurface);
        // Its slanted edges are stroked in the surface's edge, or not at
        // all; its base reaches a pixel into the surface either way.
        expect(
          arrow.border,
          edge == BorderSide.none ? const Color(0x00000000) : edge.color,
        );
        expect(arrow.hairline, 1);
        expect(arrow.shadow, tokens.elevation.md);
      });
    }
  });

  group('a modal', () {
    for (final look in _looks) {
      final tokens = look.tokens;
      final edge = _edge(look.theme, tokens, modal: true);

      testWidgets('${look.name}: the card', (tester) async {
        await tester.pumpWidget(_app(tokens, _modal()));
        await _open(tester);
        expect(_sideUnder<Modal>(tester), edge);
      });

      testWidgets('${look.name}: a side sheet\'s inner edge', (tester) async {
        for (final side in SideSheetSide.values) {
          await tester.pumpWidget(
            _app(
              tokens,
              _opener(
                (context) => showSideSheet<void>(
                  context,
                  side: side,
                  builder: (context) => SideSheet(
                    title: 'Filters',
                    side: side,
                    child: const SizedBox(height: 40),
                  ),
                ),
              ),
            ),
          );
          await _open(tester);
          final sheet = tester
              .widgetList<Material>(
                find.descendant(
                  of: find.byType(SideSheet),
                  matching: find.byType(Material),
                ),
              )
              .firstWhere((m) => m.shape is Border);
          final border = sheet.shape! as Border;
          // In left-to-right text a sheet at the end stands on the right,
          // and its inner edge is its left one.
          final atEnd = side == SideSheetSide.end;
          expect(atEnd ? border.left : border.right, edge, reason: '$side');
          expect(
            atEnd ? border.right : border.left,
            BorderSide.none,
            reason: '$side',
          );
          await tester.pumpWidget(const SizedBox());
        }
      });

      testWidgets('${look.name}: the command palette', (tester) async {
        await tester.pumpWidget(
          _app(
            tokens,
            _opener(
              (context) => showCommandPalette(
                context,
                items: [
                  PaletteItem(
                    id: 'pages',
                    title: 'Manage pages',
                    icon: Icons.article_outlined,
                    group: 'Commands',
                    onSelect: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        await _open(tester);
        expect(_sideUnder<CommandPalette>(tester), edge);
      });

      testWidgets('${look.name}: the asset picker', (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            tokens,
            _opener((context) => showAssetPicker(context, source: _NoAssets())),
          ),
        );
        await _open(tester);
        final corners = BorderRadius.circular(tokens.radii.radiusDialog);
        final frame = tester
            .widgetList<DecoratedBox>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is DecoratedBox &&
                    widget.position == DecorationPosition.foreground,
              ),
            )
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .firstWhere((d) => d.borderRadius == corners && d.border != null);
        expect(frame.border, Border.fromBorderSide(edge));
      });
    }
  });

  group('an edge takes no room', () {
    // The hairline is painted over the surface, so a theme that drops it
    // moves nothing.
    for (final theme in adminThemes) {
      testWidgets('${theme.name}: a menu and a modal keep their boxes', (
        tester,
      ) async {
        final tokens = theme.tokens;
        final other = tokens.copyWith(
          overlay: tokens.overlay.copyWith(
            modalOutline: !tokens.overlay.modalOutline,
            popoverOutline: !tokens.overlay.popoverOutline,
          ),
        );

        Future<List<Rect>> boxes(AdminTokens tokens) async {
          await tester.pumpWidget(_app(tokens, _menu()));
          await _open(tester);
          final menu = [
            tester.getRect(find.byType(PopoverMenuSurface)),
            tester.getRect(find.text('Rename')),
            tester.getRect(find.text('Duplicate')),
          ];
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(_app(tokens, _modal()));
          await _open(tester);
          final modal = [
            tester.getRect(find.byType(Modal)),
            tester.getRect(find.text('Delete page?')),
            tester.getRect(find.text('It cannot be restored.')),
          ];
          await tester.pumpWidget(const SizedBox());
          return [...menu, ...modal];
        }

        expect(await boxes(other), await boxes(tokens));
      });
    }
  });
}
