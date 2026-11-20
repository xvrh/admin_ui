import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// What an overlay is filled with: the palette's popoverSurface, modalSurface
// and sheetSurface, each the surface unless the theme's reference gives what
// it lifts off the page a tone of its own. An overlay's content is drawn in
// AdminPalette.withSurface's palette, where `surface` is that fill.

/// Each shipped theme's raised fills, from its reference: a popover's, a
/// modal's and a sheet's. Null is the palette's surface.
const _expected = <String, ({Color? popover, Color? modal, Color? sheet})>{
  // the kit's own: every overlay in the card's colour
  'Iris light': (popover: null, modal: null, sheet: null),
  'Iris dark': (popover: null, modal: null, sheet: null),
  // a menu is surfaceContainer, a dialog surfaceContainerHigh and a sheet
  // surfaceContainerLow: neutral94, 92 and 96, and neutral12, 17 and 10
  'Material light': (
    popover: Color(0xFFF3EDF7),
    modal: Color(0xFFECE6F0),
    sheet: Color(0xFFF7F2FA),
  ),
  // surfaceContainer is the card's colour in the dark palette
  'Material dark': (
    popover: null,
    modal: Color(0xFF2B2930),
    sheet: Color(0xFF1D1B20),
  ),
  // --popover is --card; DialogContent and SheetContent are bg-background,
  // which is the card's white in light mode
  'shadcn light': (popover: null, modal: null, sheet: null),
  'shadcn dark': (
    popover: null,
    modal: Color(0xFF09090B),
    sheet: Color(0xFF09090B),
  ),
  // colorBgElevated: colorBgContainer's white in the light algorithm, a
  // step above it in the dark one
  'Ant light': (popover: null, modal: null, sheet: null),
  'Ant dark': (
    popover: Color(0xFF1F1F1F),
    modal: Color(0xFF1F1F1F),
    sheet: Color(0xFF1F1F1F),
  ),
  // colorNeutralBackground1, the card's
  'Fluent light': (popover: null, modal: null, sheet: null),
  'Fluent dark': (popover: null, modal: null, sheet: null),
  // $layer, the card's
  'Carbon light': (popover: null, modal: null, sheet: null),
  'Carbon dark': (popover: null, modal: null, sheet: null),
};

/// Every shipped theme in both modes.
final _looks = [
  for (final theme in adminThemes) ...[
    (name: '${theme.name} light', tokens: theme.tokens),
    (name: '${theme.name} dark', tokens: theme.dark!),
  ],
];

/// The looks whose fills are not all the surface.
final _raised = [
  for (final look in _looks)
    if (_expected[look.name] != (popover: null, modal: null, sheet: null)) look,
];

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
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
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

Future<void> _open(WidgetTester tester, [String label = 'Open']) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// The fill of the first rounded [Material] under a widget of type [T]: the
/// surface it draws itself on.
Color? _fillUnder<T extends Widget>(WidgetTester tester) => tester
    .widgetList<Material>(
      find.descendant(of: find.byType(T), matching: find.byType(Material)),
    )
    .firstWhere((m) => m.shape is RoundedRectangleBorder)
    .color;

/// The palette the widget showing [text] is drawn in.
AdminPalette _paletteAt(WidgetTester tester, String text) =>
    tester.element(find.text(text)).colors;

Widget _menu({String label = 'Open'}) => Menu(
  entries: [
    MenuItem('Rename', onSelect: () {}),
    MenuItem('Duplicate', onSelect: () {}),
  ],
  builder: (context, c) => TextButton(onPressed: c.toggle, child: Text(label)),
);

void main() {
  group('AdminPalette', () {
    test('by default fills every overlay with its surface', () {
      expect(irisPalette.popoverSurface, irisPalette.surface);
      expect(irisPalette.modalSurface, irisPalette.surface);
      expect(irisPalette.sheetSurface, irisPalette.surface);
    });

    test('a sheet follows the modal unless it has a fill of its own', () {
      const modal = Color(0xFFEEEEEE);
      const sheet = Color(0xFFDDDDDD);
      final one = irisPalette.copyWith(modalSurface: modal);
      expect(one.modalSurface, modal);
      expect(one.sheetSurface, modal);
      expect(one.popoverSurface, irisPalette.surface);
      final both = one.copyWith(sheetSurface: sheet);
      expect(both.modalSurface, modal);
      expect(both.sheetSurface, sheet);
    });

    test('copyWith, ==, lerp and branded carry the fills', () {
      const popover = Color(0xFFF0F0F0);
      const modal = Color(0xFFE0E0E0);
      final raised = irisPalette.copyWith(
        popoverSurface: popover,
        modalSurface: modal,
      );
      expect(raised, isNot(irisPalette));
      expect(
        raised,
        irisPalette
            .copyWith(popoverSurface: popover)
            .copyWith(modalSurface: modal),
      );
      expect(
        raised.hashCode,
        irisPalette
            .copyWith(popoverSurface: popover, modalSurface: modal)
            .hashCode,
      );
      expect(
        raised.copyWith(primary: const Color(0xFF123456)).modalSurface,
        modal,
      );

      // A fill neither side authors stays the surface; one either authors
      // is interpolated from what each resolves to.
      final plain = AdminPalette.lerp(irisPalette, irisDarkPalette, 0.5);
      expect(plain.popoverSurface, plain.surface);
      final half = AdminPalette.lerp(irisPalette, raised, 0.5);
      expect(
        half.popoverSurface,
        Color.lerp(irisPalette.surface, popover, 0.5),
      );
      expect(half.modalSurface, Color.lerp(irisPalette.surface, modal, 0.5));
      expect(half.sheetSurface, half.modalSurface);

      final branded = raised.branded(const Color(0xFF0D9488));
      expect(branded.popoverSurface, popover);
      expect(branded.modalSurface, modal);
      expect(branded.sheetSurface, modal);
    });

    group('withSurface', () {
      const fill = Color(0xFFECE6F0);

      test('is the palette itself on its own surface', () {
        expect(
          identical(irisPalette.withSurface(irisPalette.surface), irisPalette),
          isTrue,
        );
        final on = materialPalette.withSurface(fill);
        expect(identical(on.withSurface(fill), on), isTrue);
      });

      test('reads the fill as its surface, and is kept', () {
        final on = materialPalette.withSurface(fill);
        expect(on.surface, fill);
        expect(on.background, materialPalette.background);
        expect(on.surfaceMuted, materialPalette.surfaceMuted);
        expect(identical(materialPalette.withSurface(fill), on), isTrue);
      });

      test('what derives from the surface follows it', () {
        final on = materialPalette.withSurface(fill);
        expect(
          on.listHighlight,
          Color.alphaBlend(on.foreground.withValues(alpha: 0.06), fill),
        );
        expect(on.listHighlight, isNot(materialPalette.listHighlight));
        expect(on.fieldFill, fill);
        expect(on.statusFill(on.danger), Color.lerp(on.danger, fill, 0.88));
      });

      test('the authored roles are kept', () {
        final on = materialPalette.withSurface(fill);
        for (final role in <Color Function(AdminPalette)>[
          (p) => p.primary,
          (p) => p.primarySubtle,
          (p) => p.foreground,
          (p) => p.foregroundSecondary,
          (p) => p.foregroundMuted,
          (p) => p.border,
          (p) => p.borderSubtle,
          (p) => p.danger,
          (p) => p.controlBorder,
          (p) => p.focusRing,
          (p) => p.inverseSurface,
          (p) => p.softFill,
        ]) {
          expect(role(on), role(materialPalette));
        }
        expect(on.stateLayer, materialPalette.stateLayer);
        // An input keeps Ant's container colour on the elevated one.
        final ant = antDarkPalette.withSurface(antDarkPalette.modalSurface);
        expect(ant.fieldFill, const Color(0xFF141414));
        expect(ant.fieldFill, antDarkPalette.fieldFill);
      });

      test('an authored role that no longer reads on the fill is moved', () {
        // M3's surfaceContainer is darker than the card: the warning text
        // that reads on the card is a shade short on its tint there.
        final popover = materialPalette.popoverSurface;
        final on = materialPalette.withSurface(popover);
        expect(on.warningText, isNot(materialPalette.warningText));
        final onTint = [popover, on.statusFill(on.warning)];
        // readableOn returns what already reads unchanged.
        expect(on.readableOn(on.warningText, surfaces: onTint), on.warningText);
        expect(
          materialPalette.readableOn(
            materialPalette.warningText,
            surfaces: onTint,
          ),
          isNot(materialPalette.warningText),
        );

        // The dark dialog is lighter than the card: two chart colours move.
        final dialog = materialDarkPalette.withSurface(
          materialDarkPalette.modalSurface,
        );
        expect(dialog.chart, hasLength(materialDarkPalette.chart.length));
        expect(dialog.chart, isNot(materialDarkPalette.chart));
        for (final color in dialog.chart) {
          expect(
            dialog.readableOn(
              color,
              surfaces: [dialog.surface],
              minContrast: 3,
            ),
            color,
          );
        }
      });

      test('the raised fills stay what they were on the page', () {
        for (final page in [
          materialPalette,
          materialDarkPalette,
          antDarkPalette,
          shadcnDarkPalette,
        ]) {
          for (final fill in [
            page.popoverSurface,
            page.modalSurface,
            page.sheetSurface,
          ]) {
            final on = page.withSurface(fill);
            expect(on.popoverSurface, page.popoverSurface);
            expect(on.modalSurface, page.modalSurface);
            expect(on.sheetSurface, page.sheetSurface);
            // From a dialog's palette, a menu's is the page's menu palette.
            expect(
              on.withSurface(on.popoverSurface),
              page.withSurface(page.popoverSurface),
            );
          }
        }
      });
    });
  });

  group('each shipped theme', () {
    test('is listed here', () {
      expect(_expected.keys.toSet(), {for (final look in _looks) look.name});
    });

    for (final look in _looks) {
      test('${look.name}: its fills, and the stock Material overlays', () {
        final palette = look.tokens.palette;
        final fills = _expected[look.name]!;
        expect(palette.popoverSurface, fills.popover ?? palette.surface);
        expect(palette.modalSurface, fills.modal ?? palette.surface);
        expect(palette.sheetSurface, fills.sheet ?? palette.surface);

        // What a stock dialog, popup menu, menu anchor and dropdown menu
        // take from the kit's theme.
        final theme = buildAppTheme(look.tokens);
        expect(theme.dialogTheme.backgroundColor, palette.modalSurface);
        expect(theme.popupMenuTheme.color, palette.popoverSurface);
        for (final style in [
          theme.menuTheme.style!,
          theme.dropdownMenuTheme.menuStyle!,
        ]) {
          expect(
            style.backgroundColor!.resolve(const {}),
            palette.popoverSurface,
          );
        }
        // A card is not an overlay: it keeps the surface.
        expect(theme.cardTheme.color, palette.surface);
      });
    }
  });

  group('an overlay is filled with its fill, and its content drawn on it', () {
    for (final look in _looks) {
      final tokens = look.tokens;
      final palette = tokens.palette;

      testWidgets('${look.name}: a menu', (tester) async {
        await tester.pumpWidget(_app(tokens, Center(child: _menu())));
        await _open(tester);
        expect(_fillUnder<PopoverMenuSurface>(tester), palette.popoverSurface);
        expect(
          _paletteAt(tester, 'Rename'),
          palette.withSurface(palette.popoverSurface),
        );
        // The page under it is still drawn in the page's palette.
        expect(_paletteAt(tester, 'Open'), palette);
      });

      testWidgets('${look.name}: what a popover builds above its surface', (
        tester,
      ) async {
        late AdminPalette builders;
        await tester.pumpWidget(
          _app(
            tokens,
            Center(
              child: Popover(
                anchor: (context, c) =>
                    TextButton(onPressed: c.toggle, child: const Text('Open')),
                content: (context, c) {
                  // A content builder, and a State above the surface it
                  // returns, read the popover's palette too.
                  builders = context.colors;
                  return const PopoverMenuSurface(
                    width: 200,
                    child: SizedBox(height: 60),
                  );
                },
              ),
            ),
          ),
        );
        await _open(tester);
        expect(builders, palette.withSurface(palette.popoverSurface));
      });

      testWidgets('${look.name}: a modal', (tester) async {
        late AdminPalette builders;
        await tester.pumpWidget(
          _app(
            tokens,
            _opener(
              (context) => showModal<void>(
                context,
                builder: (context) {
                  // What a caller builds above its Modal reads the modal's
                  // palette too.
                  builders = context.colors;
                  return Modal(
                    title: 'Delete page?',
                    message: 'It cannot be restored.',
                    onDismiss: () => Navigator.of(context).pop(),
                  );
                },
              ),
            ),
          ),
        );
        await _open(tester);
        final on = palette.withSurface(palette.modalSurface);
        expect(_fillUnder<Modal>(tester), palette.modalSurface);
        expect(_paletteAt(tester, 'It cannot be restored.'), on);
        expect(builders, on);
      });

      testWidgets('${look.name}: a side sheet', (tester) async {
        late AdminPalette builders;
        await tester.pumpWidget(
          _app(
            tokens,
            _opener(
              (context) => showSideSheet<void>(
                context,
                builder: (context) {
                  builders = context.colors;
                  return const SideSheet(
                    title: 'Filters',
                    child: Text('Status'),
                  );
                },
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
        final on = palette.withSurface(palette.sheetSurface);
        expect(sheet.color, palette.sheetSurface);
        expect(_paletteAt(tester, 'Status'), on);
        expect(builders, on);
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
        // Filled as a popover is: shadcn's Command is bg-popover.
        expect(_fillUnder<CommandPalette>(tester), palette.popoverSurface);
        expect(
          tester
              .element(
                find.descendant(
                  of: find.byType(CommandPalette),
                  matching: find.byType(TextField),
                ),
              )
              .colors,
          palette.withSurface(palette.popoverSurface),
        );
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
        final surface = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .firstWhere(
              (d) =>
                  d.borderRadius == corners &&
                  d.color != null &&
                  d.boxShadow != null,
            );
        expect(surface.color, palette.modalSurface);
      });
    }
  });

  group('one overlay inside another keeps its own fill', () {
    for (final look in _raised) {
      final tokens = look.tokens;
      final palette = tokens.palette;

      testWidgets('${look.name}: a menu opened in a modal', (tester) async {
        await tester.pumpWidget(
          _app(
            tokens,
            _opener(
              (context) => showModal<void>(
                context,
                builder: (context) => Modal(
                  title: 'Page',
                  body: _menu(label: 'Actions'),
                ),
              ),
            ),
          ),
        );
        await _open(tester);
        await _open(tester, 'Actions');
        expect(_fillUnder<Modal>(tester), palette.modalSurface);
        expect(_fillUnder<PopoverMenuSurface>(tester), palette.popoverSurface);
        expect(
          _paletteAt(tester, 'Rename'),
          palette.withSurface(palette.popoverSurface),
        );
        expect(
          _paletteAt(tester, 'Actions'),
          palette.withSurface(palette.modalSurface),
        );
      });

      testWidgets('${look.name}: a modal opened from a side sheet', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            tokens,
            _opener(
              (context) => showSideSheet<void>(
                context,
                builder: (context) => SideSheet(
                  title: 'Filters',
                  child: Center(
                    child: TextButton(
                      onPressed: () => showModal<void>(
                        context,
                        builder: (context) => const Modal(
                          title: 'Discard?',
                          message: 'Your filters are not saved.',
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await _open(tester);
        await _open(tester, 'Close');
        expect(_fillUnder<Modal>(tester), palette.modalSurface);
        expect(
          _paletteAt(tester, 'Your filters are not saved.'),
          palette.withSurface(palette.modalSurface),
        );
        expect(
          _paletteAt(tester, 'Close'),
          palette.withSurface(palette.sheetSurface),
        );
      });
    }
  });

  group('the theme an overlay draws its content in', () {
    testWidgets('is the page\'s own where the fill is the surface', (
      tester,
    ) async {
      await tester.pumpWidget(_app(irisTheme.tokens, Center(child: _menu())));
      await _open(tester);
      expect(
        identical(
          Theme.of(tester.element(find.text('Rename'))),
          Theme.of(tester.element(find.byType(Scaffold))),
        ),
        isTrue,
      );
    });

    testWidgets('is built once for a set of tokens and a fill', (tester) async {
      final tokens = materialTheme.tokens;
      await tester.pumpWidget(_app(tokens, Center(child: _menu())));
      await _open(tester);
      final first = Theme.of(tester.element(find.text('Rename')));
      expect(
        identical(first, Theme.of(tester.element(find.byType(Scaffold)))),
        isFalse,
      );
      expect(
        first.extension<AdminTokens>()!.palette.surface,
        const Color(0xFFF3EDF7),
      );
      // The rest of the tokens are the page's.
      expect(
        first.extension<AdminTokens>(),
        tokens.copyWith(
          palette: tokens.palette.withSurface(tokens.palette.popoverSurface),
        ),
      );

      // Closed and opened again, and in another app on the same tokens.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Rename'), findsNothing);
      await _open(tester);
      expect(
        identical(Theme.of(tester.element(find.text('Rename'))), first),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(tokens, Center(child: _menu())));
      await _open(tester);
      expect(
        identical(Theme.of(tester.element(find.text('Rename'))), first),
        isTrue,
      );
    });

    testWidgets('a field in a Material dialog is filled with the dialog', (
      tester,
    ) async {
      final palette = materialTheme.tokens.palette;
      await tester.pumpWidget(
        _app(
          materialTheme.tokens,
          _opener(
            (context) => showModal<void>(
              context,
              builder: (context) =>
                  const Modal(title: 'Rename', body: TextField()),
            ),
          ),
        ),
      );
      await _open(tester);
      final context = tester.element(find.byType(TextField));
      expect(context.colors.fieldFill, palette.modalSurface);
      expect(context.colors.fieldFill, isNot(palette.fieldFill));
      // The stock decoration theme under it was built for that palette.
      expect(
        Theme.of(context).extension<AdminTokens>()!.palette.surface,
        palette.modalSurface,
      );
    });
  });
}
