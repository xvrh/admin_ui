import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

const _field = OptionsFilterField('status', 'Status', [
  FilterOption('draft', 'Draft'),
  FilterOption('live', 'Live'),
  FilterOption('archived', 'Archived'),
]);

Future<void> _pump(
  WidgetTester tester,
  List<FilterCondition> active, {
  List<FilterField> fields = const [_field],
  ValueChanged<List<FilterCondition>>? onChanged,
  AdminTokens? tokens,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tokens == null ? null : buildAppTheme(tokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 800,
              child: FilterBar(
                fields: fields,
                active: active,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _pill(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Tappable)).first;

/// The fill behind the pill's label.
Color _fill(WidgetTester tester, String label) {
  final box = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  group('active text reads at 4.5:1 on the pill', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        if (dark && !theme.hasDark) continue;
        final source = dark ? theme.dark! : theme.tokens;
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          final palette = seed == null
              ? source.palette
              : source.palette.branded(seed);
          final mode = dark ? 'Dark' : 'Light';
          testWidgets('${theme.name} $mode, brand $brand', (tester) async {
            final tokens = AdminTokens.from(
              palette: palette,
              radii: source.radii,
              sizes: source.sizes,
            );
            await _pump(tester, const [
              OptionsFilter('status', {'draft'}, label: 'Status'),
            ], tokens: tokens);
            final fill = _fill(tester, 'Status');
            expect(fill, palette.primarySubtle);
            final surfaces = [
              fill,
              Color.alphaBlend(palette.hoverOverlay, fill),
              Color.alphaBlend(palette.pressedOverlay, fill),
            ];
            for (final text in ['Status', ': ', 'Draft']) {
              final color = tester.widget<Text>(find.text(text)).style!.color!;
              for (final surface in surfaces) {
                expect(
                  contrastRatio(color, surface),
                  greaterThanOrEqualTo(4.5),
                  reason: '"$text" on $surface',
                );
              }
            }
            final clear = tester.widget<IconAction>(find.byType(IconAction));
            for (final surface in surfaces) {
              expect(
                contrastRatio(clear.color!, surface),
                greaterThanOrEqualTo(4.5),
              );
            }
          });
        }
      }
    }
  });

  testWidgets('a long summary ellipsizes at 200px', (tester) async {
    await _pump(
      tester,
      [TextFilter('name', 'x' * 120, label: 'Name')],
      fields: const [TextFilterField('name', 'Name')],
    );
    expect(tester.takeException(), isNull);
    final summary = find.text('“${'x' * 120}”');
    final text = tester.widget<Text>(summary);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
    expect(tester.getSize(summary).width, lessThanOrEqualTo(200));
  });

  testWidgets('more than two options collapse to the first and a count', (
    tester,
  ) async {
    await _pump(tester, const [
      OptionsFilter('status', {'draft', 'live'}, label: 'Status'),
    ]);
    expect(find.text('Draft, Live'), findsOneWidget);
    await _pump(tester, const [
      OptionsFilter('status', {'draft', 'live', 'archived'}, label: 'Status'),
    ]);
    expect(find.text('Draft +2'), findsOneWidget);
  });

  testWidgets('the separator is body text, like its neighbours', (
    tester,
  ) async {
    await _pump(tester, const [
      OptionsFilter('status', {'draft'}, label: 'Status'),
    ]);
    final label = tester.widget<Text>(find.text('Status')).style!;
    final separator = tester.widget<Text>(find.text(': ')).style!;
    expect(separator.fontSize, label.fontSize);
    expect(separator.height, label.height);
    expect(separator.fontFamily, label.fontFamily);
  });

  testWidgets('the clear × is its own 24px, named Tab stop', (tester) async {
    final handle = tester.ensureSemantics();
    List<FilterCondition> active = const [
      OptionsFilter('status', {'draft'}, label: 'Status'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FilterBar(
              fields: const [_field],
              active: active,
              onChanged: (next) => setState(() => active = next),
            ),
          ),
        ),
      ),
    );
    expect(find.semantics.byLabel('Clear Status filter'), findsOne);
    expect(find.semantics.byLabel('Status: Draft'), findsOne);
    final clear = find.byType(IconAction);
    expect(tester.getSize(clear), const Size(24, 24));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(of: clear, matching: find.byWidget(focused.widget)),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(active, isEmpty);
    handle.dispose();
  });

  testWidgets('padding mirrors right to left, glyph inset like the text', (
    tester,
  ) async {
    const active = [
      OptionsFilter('status', {'draft'}, label: 'Status'),
    ];
    for (final direction in TextDirection.values) {
      await _pump(tester, active, direction: direction);
      final pill = tester.getRect(_pill('Status'));
      final label = tester.getRect(find.text('Status'));
      final glyph = tester.getRect(
        find.descendant(
          of: find.byType(IconAction),
          matching: find.byIcon(Icons.close),
        ),
      );
      final padX = defaultControlSizes.medium / 2 - 4;
      if (direction == TextDirection.ltr) {
        expect(label.left - pill.left, closeTo(padX, 0.5));
        expect(pill.right - glyph.right, closeTo(padX, 0.5));
      } else {
        expect(pill.right - label.right, closeTo(padX, 0.5));
        expect(glyph.left - pill.left, closeTo(padX, 0.5));
      }
    }

    // Inactive, the chevron sits at the same inset.
    await _pump(tester, const []);
    final pill = tester.getRect(_pill('Status'));
    final chevron = tester.getRect(find.byIcon(Icons.expand_more));
    expect(
      pill.right - chevron.right,
      closeTo(defaultControlSizes.medium / 2 - 4, 0.5),
    );
  });
}
