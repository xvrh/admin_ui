import 'package:admin_ui/src/collection/filter.dart';
import 'package:admin_ui/src/collection/ui/filter_bar.dart';
import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('a long option list scrolls inside its popover', (tester) async {
    List<FilterCondition> active = const [];
    final options = [
      for (var i = 0; i < 40; i++) FilterOption('zone$i', 'Zone $i'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => FilterBar(
              fields: [OptionsFilterField('zone', 'Zone', options)],
              active: active,
              onChanged: (next) => setState(() => active = next),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Zone'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Zone 0'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Zone 39'), 200);
    // The label sits under IgnorePointer; the row around it takes the tap.
    await tester.tap(find.text('Zone 39'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(active, [
      isA<OptionsFilter>().having((f) => f.selected, 'selected', {'zone39'}),
    ]);
  });

  testWidgets('popover inputs keep the small radius in every border state', (
    tester,
  ) async {
    const radii = AdminRadii(radiusSmall: 2, radius: 9, radiusLarge: 12);
    final tokens = AdminTokens.from(palette: irisPalette, radii: radii);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens),
        home: Scaffold(
          body: FilterBar(
            fields: const [
              TextFilterField('name', 'Name'),
              NumberRangeFilterField('price', 'Price'),
            ],
            active: const [],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    void expectSmall(String what) {
      for (final field in tester.widgetList<InputDecorator>(
        find.byType(InputDecorator),
      )) {
        final d = field.decoration;
        // One stateful border resolves every state.
        for (final states in const [
          <WidgetState>{},
          {WidgetState.hovered},
          {WidgetState.focused},
          {WidgetState.disabled},
          {WidgetState.error},
          {WidgetState.error, WidgetState.focused},
        ]) {
          expect(
            WidgetStateProperty.resolveAs(d.border, states),
            isA<OutlineInputBorder>().having(
              (b) => b.borderRadius,
              'radius',
              BorderRadius.circular(radii.radiusSmall),
            ),
            reason: '$what: $states border',
          );
        }
      }
    }

    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.byType(InputDecorator), findsOneWidget);
    expectSmall('text filter');
    // The text editor autofocuses: the focus ring is the palette's.
    final focused = WidgetStateProperty.resolveAs(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration
          .border,
      {WidgetState.focused},
    )!;
    expect(focused.borderSide.color, irisPalette.focusRing);

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    expect(find.byType(InputDecorator), findsNWidgets(2));
    expectSmall('range filter');
  });

  group('an options menu', () {
    // The test font draws each character as a square: 13px at field size.
    const live = 'Northwind / Web shop (live)';
    const test = 'Northwind / Web shop (test)';
    const long = 'Northwind Trading (main account) / Web shop (live)';

    Future<void> open(WidgetTester tester, List<String> labels) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Scaffold(
            body: FilterBar(
              fields: [
                OptionsFilterField('account', 'Account', [
                  for (final label in labels) FilterOption(label, label),
                ]),
              ],
              active: const [],
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
    }

    RenderParagraph paragraph(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text));

    bool oneLine(RenderParagraph p) =>
        p.getMaxIntrinsicWidth(double.infinity) <= p.size.width;

    double menuWidth(WidgetTester tester) =>
        tester.getSize(find.byType(PopoverMenuSurface)).width;

    testWidgets('grows past its pill to show each option whole', (
      tester,
    ) async {
      await open(tester, const [live, test]);
      for (final label in [live, test]) {
        expect(oneLine(paragraph(tester, label)), isTrue, reason: label);
      }
      expect(menuWidth(tester), greaterThan(ListboxMenu.minWidth));
    });

    testWidgets('stops at its widest and wraps a longer option', (
      tester,
    ) async {
      await open(tester, const [live, long]);
      expect(menuWidth(tester), ListboxMenu.maxWidth);
      final p = paragraph(tester, long);
      expect(oneLine(p), isFalse);
      expect(p.didExceedMaxLines, isFalse, reason: 'two lines hold it');
      expect(oneLine(paragraph(tester, live)), isTrue);
    });

    testWidgets('stays inside a phone’s screen', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await open(tester, const [long]);
      final menu = tester.getRect(find.byType(PopoverMenuSurface));
      expect(menu.left, greaterThanOrEqualTo(0));
      expect(menu.right, lessThanOrEqualTo(360));
      expect(menu.width, lessThan(ListboxMenu.maxWidth));
    });
  });
}
