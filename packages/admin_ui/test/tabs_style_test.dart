import 'dart:ui' show PointerDeviceKind;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A Tabs strip drawn from the theme's AdminTabsStyle: its height at each
// size, what its labels are written in and how heavily, the selected tab's
// indicator, and the rule a line strip stands on.

const _one = Key('one');
const _two = Key('two');

Widget _host({
  AdminTabsStyle style = const AdminTabsStyle(),
  AdminPalette? palette,
  AdminStroke? stroke,
  int selected = 0,
  ControlSize size = ControlSize.medium,
  TabsVariant variant = TabsVariant.line,
  bool baseline = true,
  ValueChanged<int>? onChanged,
}) => MaterialApp(
  theme: buildAppTheme(
    AdminTokens.from(
      palette: palette ?? irisPalette,
      tabs: style,
      stroke: stroke,
    ),
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tabs(
              tabs: const [
                TabItem('Details', key: _one),
                TabItem('Orders', key: _two),
              ],
              selected: selected,
              onChanged: onChanged ?? (_) {},
              size: size,
              variant: variant,
              baseline: baseline,
            ),
          ],
        ),
      ),
    ),
  ),
);

TextStyle _label(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text).last).style!;

/// The indicator of the tab keyed [key]: the box under its label.
Finder _indicator(Key key) => find.descendant(
  of: find.byKey(key),
  matching: find.byWidgetPredicate(
    (w) => w is Container && w.margin != null && w.decoration is BoxDecoration,
  ),
);

BoxDecoration _indicatorLook(WidgetTester tester, Key key) =>
    tester.widget<Container>(_indicator(key)).decoration! as BoxDecoration;

/// The rule the strip stands on, where it draws one.
final _rule = find.descendant(
  of: find.byType(Tabs),
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    final decoration = w.decoration;
    if (decoration is! BoxDecoration) return false;
    final border = decoration.border;
    return border is Border && border.bottom.width > 0 && border.top.width == 0;
  }),
);

BorderSide _ruleSide(WidgetTester tester) =>
    ((tester.widget<DecoratedBox>(_rule).decoration as BoxDecoration).border!
            as Border)
        .bottom;

const _material = AdminTabsStyle(
  heightSmall: 40,
  heightMedium: 48,
  heightLarge: 56,
  restInk: TabsRestInk.secondary,
  labelWeight: FontWeight.w500,
  indicatorWidth: TabsIndicatorWidth.label,
  indicatorShape: TabsIndicatorShape.roundedTop,
  indicatorThickness: 3,
);

const _fluent = AdminTabsStyle(
  heightSmall: 32,
  heightMedium: 44,
  heightLarge: 52,
  selectedInk: TabsSelectedInk.foreground,
  restInk: TabsRestInk.secondary,
  labelWeight: FontWeight.w400,
  selectedLabelWeight: FontWeight.w600,
  indicatorWidth: TabsIndicatorWidth.label,
  indicatorShape: TabsIndicatorShape.pill,
  rule: TabsRule.none,
);

const _carbon = AdminTabsStyle(
  selectedInk: TabsSelectedInk.foreground,
  restInk: TabsRestInk.secondary,
  labelWeight: FontWeight.w400,
  selectedLabelWeight: FontWeight.w600,
  rule: TabsRule.indicator,
);

void main() {
  testWidgets('the default: 40 tall, the accent over a square bar as wide as '
      'its tab, on a hairline', (tester) async {
    final p = irisPalette;
    await tester.pumpWidget(_host());
    expect(tester.getSize(find.byKey(_one)).height, 40);
    expect(_label(tester, 'Details').color, p.primaryText);
    expect(_label(tester, 'Orders').color, p.foregroundMuted);
    expect(
      _label(tester, 'Details').fontWeight,
      _label(tester, 'Orders').fontWeight,
    );
    final bar = _indicatorLook(tester, _one);
    expect(bar.color, p.controlAccent);
    expect(bar.borderRadius, isNull);
    expect(tester.getSize(_indicator(_one)).height, 2);
    expect(
      tester.getSize(_indicator(_one)).width,
      tester.getSize(find.byKey(_one)).width,
    );
    expect(_indicatorLook(tester, _two).color, const Color(0x00000000));
    expect(_ruleSide(tester).width, 1);
    expect(_ruleSide(tester).color, p.tabDivider);
  });

  testWidgets('a strip is as tall as the style says at each size', (
    tester,
  ) async {
    for (final style in [const AdminTabsStyle(), _material, _fluent]) {
      for (final size in ControlSize.values) {
        await tester.pumpWidget(_host(style: style, size: size));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(_one)).height,
          style.heightOf(size),
          reason: '$style at ${size.name}',
        );
        expect(tester.getSize(find.byType(Tabs)).height, style.heightOf(size));
      }
    }
  });

  testWidgets('labels take the style’s inks, and the next stronger under '
      'the pointer', (tester) async {
    final p = irisPalette;
    for (final style in [const AdminTabsStyle(), _material, _fluent]) {
      await tester.pumpWidget(_host(style: style));
      await tester.pumpAndSettle();
      expect(_label(tester, 'Details').color, style.selectedInkOf(p));
      expect(_label(tester, 'Orders').color, style.restInkOf(p));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(_two)));
      await tester.pump();
      expect(_label(tester, 'Orders').color, style.restInkOf(p, hovered: true));
      await mouse.removePointer();
    }
  });

  testWidgets('an enclosed strip’s selected label stays the foreground', (
    tester,
  ) async {
    final p = irisPalette;
    for (final style in [const AdminTabsStyle(), _fluent]) {
      await tester.pumpWidget(
        _host(style: style, variant: TabsVariant.enclosed),
      );
      await tester.pumpAndSettle();
      expect(_label(tester, 'Details').color, p.foreground);
    }
  });

  testWidgets('every label takes the style’s weight', (tester) async {
    await tester.pumpWidget(_host(style: _material));
    expect(_label(tester, 'Details').fontWeight, FontWeight.w500);
    expect(_label(tester, 'Orders').fontWeight, FontWeight.w500);
    // one weight: no hidden copy to reserve a width
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('a heavier selected label never moves the tabs', (tester) async {
    var selected = 0;
    Future<void> pump() => tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => _host(
          style: _fluent,
          selected: selected,
          onChanged: (i) => setState(() => selected = i),
        ),
      ),
    );
    await pump();
    expect(_label(tester, 'Details').fontWeight, FontWeight.w600);
    expect(_label(tester, 'Orders').fontWeight, FontWeight.w400);
    final before = (
      tester.getRect(find.byKey(_one)),
      tester.getRect(find.byKey(_two)),
    );

    await tester.tap(find.byKey(_two));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(_label(tester, 'Details').fontWeight, FontWeight.w400);
    expect(_label(tester, 'Orders').fontWeight, FontWeight.w600);
    expect((
      tester.getRect(find.byKey(_one)),
      tester.getRect(find.byKey(_two)),
    ), before);
    // A tab is as wide as its label set semibold, selected or not.
    final semibold = TextPainter(
      text: TextSpan(text: 'Details', style: _label(tester, 'Orders')),
      textDirection: TextDirection.ltr,
    )..layout();
    addTearDown(semibold.dispose);
    expect(
      tester.getSize(find.byKey(_one)).width,
      closeTo(semibold.width + 2 * AdminSpacing.lg, 1),
    );
    // The hidden copy is not read twice.
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Details'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an indicator as wide as its label stops short of the tab’s '
      'padding, at each size', (tester) async {
    for (final (size, padding) in [
      (ControlSize.small, AdminSpacing.md),
      (ControlSize.medium, AdminSpacing.lg),
    ]) {
      await tester.pumpWidget(_host(style: _material, size: size));
      await tester.pumpAndSettle();
      final tab = tester.getRect(find.byKey(_one));
      // the painted bar, inside the margin that insets it
      final bar = tester.getRect(
        find.descendant(
          of: _indicator(_one),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(bar.left - tab.left, padding);
      expect(tab.right - bar.right, padding);
      expect(bar.bottom, tab.bottom);
    }
  });

  testWidgets('the indicator is as thick as the style says, or as the '
      'indicator stroke', (tester) async {
    await tester.pumpWidget(_host(style: _material));
    expect(tester.getSize(_indicator(_one)).height, 3);

    await tester.pumpWidget(
      _host(style: _fluent, stroke: const AdminStroke(indicator: 3)),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(_indicator(_one)).height, 3);
    // the label keeps the rest of the strip's height
    expect(tester.getSize(find.byKey(_one)).height, 44);
  });

  testWidgets('the indicator’s ends: square, rounded at the top, or round', (
    tester,
  ) async {
    await tester.pumpWidget(_host(style: _material));
    expect(
      _indicatorLook(tester, _one).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(3)),
    );

    await tester.pumpWidget(
      _host(style: _fluent, stroke: const AdminStroke(indicator: 3)),
    );
    await tester.pumpAndSettle();
    expect(
      _indicatorLook(tester, _one).borderRadius,
      const BorderRadius.all(Radius.circular(3)),
    );

    await tester.pumpWidget(_host(style: _carbon));
    await tester.pumpAndSettle();
    expect(_indicatorLook(tester, _one).borderRadius, isNull);
  });

  testWidgets('the rule: a hairline, as thick as the indicator, or none', (
    tester,
  ) async {
    final p = irisPalette;
    await tester.pumpWidget(_host(style: _material));
    expect(_ruleSide(tester).width, 1);

    await tester.pumpWidget(_host(style: _carbon));
    await tester.pumpAndSettle();
    expect(_ruleSide(tester).width, 2);
    expect(_ruleSide(tester).color, p.tabDivider);
    // the selected tab's indicator lies over the rule, on the same pixels
    expect(
      tester.getRect(_indicator(_one)).bottom,
      tester.getRect(find.byType(Tabs)).bottom,
    );
    expect(tester.getSize(_indicator(_one)).height, 2);

    await tester.pumpWidget(_host(style: _fluent));
    await tester.pumpAndSettle();
    expect(_rule, findsNothing);

    // The widget still turns its own rule off.
    await tester.pumpWidget(_host(style: _carbon, baseline: false));
    await tester.pumpAndSettle();
    expect(_rule, findsNothing);
  });

  group('every shipped theme', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        testWidgets('${theme.name} $mode draws its strip', (tester) async {
          final style = tokens.tabs;
          final p = tokens.palette;
          for (final size in ControlSize.values) {
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(tokens),
                home: Scaffold(
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tabs(
                        tabs: const [
                          TabItem('Details', key: _one),
                          TabItem('Orders', key: _two),
                          TabItem('Archived', enabled: false),
                        ],
                        selected: 0,
                        onChanged: (_) {},
                        size: size,
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              tester.getSize(find.byKey(_one)).height,
              style.heightOf(size),
            );
          }
          expect(_label(tester, 'Details').color, style.selectedInkOf(p));
          expect(_label(tester, 'Orders').color, style.restInkOf(p));
          expect(_label(tester, 'Archived').color, p.foregroundSubtle);
          expect(_indicatorLook(tester, _one).color, p.controlAccent);
          expect(
            tester.getSize(_indicator(_one)).height,
            style.indicatorThickness ?? tokens.stroke.indicator,
          );
        });
      }
    }
  });
}
