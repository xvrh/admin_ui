import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _p = irisPalette;

Widget _host(Widget child, {AdminRadii? radii}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: _p, radii: radii)),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(40),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

/// An in-memory library of [assets]; an id it lacks resolves to null, one in
/// [failing] throws.
class _Source implements AssetSource {
  final Map<String, Asset> assets;
  final Set<String> failing;
  final resolved = <String>[];

  _Source(this.assets, {this.failing = const {}});

  @override
  Future<Asset?> resolve(String id) async {
    resolved.add(id);
    if (failing.contains(id)) throw StateError('offline');
    return assets[id];
  }

  @override
  Future<AssetBrowseResult> browse({
    int index = 0,
    int size = 24,
    String? query,
    AssetType? filter,
    List<FilterCondition> where = const [],
  }) async => AssetBrowseResult(assets.values.toList(), assets.length);

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

const _hero = Asset(id: '1', name: 'hero.jpg', swatch: Color(0xFF0F9D8F));
const _other = Asset(id: '1', name: 'other.jpg', swatch: Color(0xFFD24B3E));

/// The accessible names of the image tiles.
Iterable<String> _tiles(WidgetTester tester) => tester
    .widgetList<Tappable>(find.byType(Tappable))
    .map((t) => t.semanticLabel)
    .nonNulls;

void main() {
  group('AssetBody', () {
    testWidgets('mounts with a value inside a scope and resolves it', (
      tester,
    ) async {
      final source = _Source({'1': _hero});
      await tester.pumpWidget(
        _host(
          AssetSourceScope(
            source: source,
            child: AssetBody(value: '1', onChanged: (_) {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(source.resolved, ['1']);
      expect(_tiles(tester), contains('hero.jpg'));
    });

    testWidgets('an id the source no longer has shows a missing asset that '
        'can still be cleared', (tester) async {
      String? cleared = 'unset';
      await tester.pumpWidget(
        _host(
          AssetSourceScope(
            source: _Source({}),
            child: AssetBody(value: '7', onChanged: (v) => cleared = v),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Asset not found'), findsOneWidget);
      expect(find.text('Loading…'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Remove Asset not found'));
      expect(cleared, isNull);
    });

    testWidgets('a failed resolve offers a retry', (tester) async {
      final source = _Source({'2': _hero}, failing: {'2'});
      await tester.pumpWidget(
        _host(
          AssetSourceScope(
            source: source,
            child: AssetBody(value: '2', onChanged: (_) {}),
          ),
        ),
      );
      await tester.pump();
      expect(_tiles(tester), contains('Retry Asset preview'));

      source.failing.remove('2');
      await tester.tap(find.bySemanticsLabel('Retry Asset preview'));
      await tester.pump();
      expect(_tiles(tester), contains('hero.jpg'));
    });

    testWidgets('swapping the scope re-resolves through the new source', (
      tester,
    ) async {
      final first = _Source({'1': _hero});
      final second = _Source({'1': _other});
      Widget build(AssetSource source) => _host(
        AssetSourceScope(
          source: source,
          child: AssetBody(value: '1', onChanged: (_) {}),
        ),
      );
      await tester.pumpWidget(build(first));
      await tester.pump();
      expect(_tiles(tester), contains('hero.jpg'));

      await tester.pumpWidget(build(second));
      await tester.pump();
      expect(second.resolved, ['1']);
      expect(_tiles(tester), contains('other.jpg'));
    });

    testWidgets('a new value re-resolves; a rebuild with the same one does '
        'not', (tester) async {
      final source = _Source({'1': _hero, '2': _other});
      Widget build(String value) => _host(
        AssetSourceScope(
          source: source,
          child: AssetBody(value: value, onChanged: (_) {}),
        ),
      );
      await tester.pumpWidget(build('1'));
      await tester.pump();
      await tester.pumpWidget(build('1'));
      await tester.pump();
      expect(source.resolved, ['1']);

      await tester.pumpWidget(build('2'));
      await tester.pump();
      expect(source.resolved, ['1', '2']);
    });

    testWidgets('a null onChanged is read-only: no remove', (tester) async {
      await tester.pumpWidget(
        _host(
          AssetSourceScope(
            source: _Source({'1': _hero}),
            child: const AssetBody(value: '1'),
          ),
        ),
      );
      await tester.pump();
      expect(_tiles(tester), contains('hero.jpg'));
      expect(find.bySemanticsLabel('Remove hero.jpg'), findsNothing);
    });

    testWidgets('a read-only empty body keeps its box', (tester) async {
      await tester.pumpWidget(
        _host(
          AssetSourceScope(
            source: _Source({}),
            child: const AssetBody(value: null),
          ),
        ),
      );
      expect(find.text('No media'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('No media'),
          matching: find.byType(FieldChrome),
        ),
        findsOneWidget,
      );
    });
  });

  group('ColorBody', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byType(FieldTrigger));
      await tester.pumpAndSettle();
    }

    TextField hexField(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byType(PopoverMenuSurface),
        matching: find.byType(TextField),
      ),
    );

    testWidgets('the hex input shows one "#": the glyph, digits after it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ColorBody(value: '#5B5BD6', onChanged: (_) {})),
      );
      await open(tester);
      final field = hexField(tester);
      expect(field.controller!.text, '5B5BD6');
      expect(field.decoration!.hintText, isNot(contains('#')));
      expect(
        find.descendant(
          of: find.byType(PopoverMenuSurface),
          matching: find.byIcon(Icons.tag_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a pasted "#" is dropped and the digits uppercased', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ColorBody(onChanged: (_) {})));
      await open(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(PopoverMenuSurface),
          matching: find.byType(TextField),
        ),
        '#0f9d8f',
      );
      await tester.pump();
      expect(hexField(tester).controller!.text, '0F9D8F');
    });

    testWidgets('an invalid hex is refused with a message and a red outline, '
        'until edited', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(_host(ColorBody(onChanged: picked.add)));
      await open(tester);
      final input = find.descendant(
        of: find.byType(PopoverMenuSurface),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, '12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(picked, isEmpty);
      expect(find.text('Enter 3 or 6 hex digits'), findsOneWidget);
      final border =
          hexField(tester).decoration!.border! as WidgetStateInputBorder;
      expect(border.resolve(const {}).borderSide.color, _p.danger);

      await tester.enterText(input, '123');
      await tester.pump();
      expect(find.text('Enter 3 or 6 hex digits'), findsNothing);
      await tester.tap(find.text('Set'));
      await tester.pumpAndSettle();
      expect(picked, ['#112233']);
    });

    testWidgets('the popover closes when focus moves on past it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(ColorBody(onChanged: (_) {})));
      final popover = tester.widget<Popover>(find.byType(Popover));
      expect(popover.closeOnFocusOut, isTrue);
    });

    testWidgets('the keyboard opens it onto the selected swatch', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(ColorBody(value: '#D24B3E', onChanged: (_) {})),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus!.context!;
      final swatch = focused.findAncestorWidgetOfExactType<Tappable>();
      expect(swatch?.semanticLabel, '#D24B3E');
    });

    testWidgets('read-only shows the value with no chevron and opens nothing', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ColorBody(value: '#D24B3E')));
      expect(find.text('#D24B3E'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      final text = tester.widget<Text>(find.text('#D24B3E'));
      expect(text.style!.color, _p.foreground);

      await tester.tap(find.byType(FieldTrigger));
      await tester.pumpAndSettle();
      expect(find.byType(PopoverMenuSurface), findsNothing);
    });

    testWidgets('the swatches follow the theme radius — square in Carbon', (
      tester,
    ) async {
      const square = AdminRadii(radiusSmall: 0, radius: 2, radiusLarge: 4);
      await tester.pumpWidget(
        _host(
          ColorBody(value: '#5B5BD6', onChanged: (_) {}),
          radii: square,
        ),
      );
      await open(tester);
      final radii = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == const Color(0xFF5B5BD6))
          .map((d) => d.borderRadius)
          .toSet();
      expect(radii, {BorderRadius.zero});
    });
  });
}
