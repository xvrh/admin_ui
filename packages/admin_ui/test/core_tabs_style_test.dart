import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's tab strip, from its reference: its heights, what the
/// labels are written in and how heavily, the indicator, and the rule.
const _expected = {
  // 32 / 40 / 48, the accent over a square bar as wide as the tab
  'Iris': AdminTabsStyle(),
  // primary tabs: 48dp, titleSmall, a 3dp indicator as wide as the label,
  // rounded at the top
  'Material': AdminTabsStyle(
    heightSmall: 40,
    heightMedium: 48,
    heightLarge: 56,
    restInk: TabsRestInk.secondary,
    labelWeight: FontWeight.w500,
    indicatorWidth: TabsIndicatorWidth.label,
    indicatorShape: TabsIndicatorShape.roundedTop,
    indicatorThickness: 3,
  ),
  // the line variant: h-9, font-medium, text-foreground on no rule
  'shadcn': AdminTabsStyle(
    heightSmall: 32,
    heightMedium: 36,
    heightLarge: 40,
    selectedInk: TabsSelectedInk.foreground,
    labelWeight: FontWeight.w500,
    rule: TabsRule.none,
  ),
  // 38 / 46 / 56, regular labels in colorText, an ink bar as wide as the
  // label
  'Ant': AdminTabsStyle(
    heightSmall: 38,
    heightMedium: 46,
    heightLarge: 56,
    restInk: TabsRestInk.foreground,
    labelWeight: FontWeight.w400,
    indicatorWidth: TabsIndicatorWidth.label,
  ),
  // 32 / 44 / 52, the selected tab semibold in the foreground over an inset,
  // round-ended brand indicator, on no rule
  'Fluent': AdminTabsStyle(
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
  ),
  // line tabs: the selected one semibold in $text-primary, on a 2px rule
  'Carbon': AdminTabsStyle(
    selectedInk: TabsSelectedInk.foreground,
    restInk: TabsRestInk.secondary,
    labelWeight: FontWeight.w400,
    selectedLabelWeight: FontWeight.w600,
    rule: TabsRule.indicator,
  ),
};

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own", () {
    const style = AdminTabsStyle();
    expect(
      [for (final size in ControlSize.values) style.heightOf(size)],
      [32, 40, 48],
    );
    expect(style.selectedInk, TabsSelectedInk.accent);
    expect(style.restInk, TabsRestInk.muted);
    expect((style.labelWeight, style.selectedLabelWeight), (null, null));
    expect(style.indicatorWidth, TabsIndicatorWidth.tab);
    expect(style.indicatorShape, TabsIndicatorShape.square);
    expect(style.indicatorThickness, isNull);
    expect(style.rule, TabsRule.hairline);
  });

  test('a strip with no height, or an indicator with no thickness, is '
      'refused', () {
    expect(() => AdminTabsStyle(heightMedium: 0), throwsAssertionError);
    expect(() => AdminTabsStyle(indicatorThickness: 0), throwsAssertionError);
  });

  test('copyWith, lerp, == and toString', () {
    const style = AdminTabsStyle();
    final material = _expected['Material']!;
    final fluent = _expected['Fluent']!;
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(
      style.copyWith(
        heightSmall: 40,
        heightMedium: 48,
        heightLarge: 56,
        restInk: TabsRestInk.secondary,
        labelWeight: FontWeight.w500,
        indicatorWidth: TabsIndicatorWidth.label,
        indicatorShape: TabsIndicatorShape.roundedTop,
        indicatorThickness: 3,
      ),
      material,
    );
    expect(
      style.copyWith(
        heightMedium: 44,
        heightLarge: 52,
        selectedInk: TabsSelectedInk.foreground,
        restInk: TabsRestInk.secondary,
        labelWeight: FontWeight.w400,
        selectedLabelWeight: FontWeight.w600,
        indicatorWidth: TabsIndicatorWidth.label,
        indicatorShape: TabsIndicatorShape.pill,
        rule: TabsRule.none,
      ),
      fluent,
    );
    expect(material, isNot(style));
    expect(material.hashCode, isNot(style.hashCode));

    expect(AdminTabsStyle.lerp(style, material, 0), style);
    expect(AdminTabsStyle.lerp(style, material, 1), material);
    final mid = AdminTabsStyle.lerp(style, material, 0.5);
    expect((mid.heightSmall, mid.heightMedium, mid.heightLarge), (36, 44, 52));
    expect(mid.indicatorShape, TabsIndicatorShape.roundedTop);
    // one side authors no thickness: the nearer side's, not a blend
    expect(mid.indicatorThickness, 3);
    expect(AdminTabsStyle.lerp(style, material, 0.4).indicatorThickness, null);
    expect(
      AdminTabsStyle.lerp(
        material,
        material.copyWith(indicatorThickness: 5),
        0.5,
      ).indicatorThickness,
      4,
    );
    expect(AdminTabsStyle.lerp(style, fluent, 0.4).rule, TabsRule.hairline);
    expect(AdminTabsStyle.lerp(style, fluent, 0.6).rule, TabsRule.none);

    expect('$style', allOf(contains('button weight'), contains('hairline')));
    expect(
      '$fluent',
      allOf(contains('w400/w600'), contains('pill'), contains('none rule')),
    );
    expect('$material', contains('3.0 thick'));
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    final fluent = _expected['Fluent']!;
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, tabs: fluent);
    expect(plain.tabs, const AdminTabsStyle());
    expect(tokens.tabs, fluent);
    expect(plain.copyWith(tabs: fluent), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(tabs: fluent).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).tabs, fluent);
    expect(plain.lerp(tokens, 0.5).tabs.heightMedium, 42);
  });

  test('AdminTheme.from gives both modes the tabs anatomy', () {
    final style = _expected['Carbon']!;
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      tabs: style,
    );
    expect(theme.tokens.tabs, style);
    expect(theme.dark!.tabs, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.tabs,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        expect(theme.tokens.tabs, expected);
        expect(theme.dark!.tabs, expected);
        // a strip grows with its size
        final heights = [
          for (final size in ControlSize.values) expected!.heightOf(size),
        ];
        expect(heights, [...heights]..sort());
      });
    }
  });

  testWidgets('context.tabsStyle reads the active theme’s', (tester) async {
    const style = AdminTabsStyle(rule: TabsRule.none);
    late AdminTabsStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(
          AdminTokens.from(palette: irisPalette, tabs: style),
        ),
        child: Builder(
          builder: (context) {
            read = context.tabsStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });

  test('what the labels are written in, at rest and under the pointer', () {
    final p = irisPalette;
    const style = AdminTabsStyle();
    expect(style.selectedInkOf(p), p.primaryText);
    expect(
      style.copyWith(selectedInk: TabsSelectedInk.foreground).selectedInkOf(p),
      p.foreground,
    );
    for (final (ink, rest, hovered) in [
      (TabsRestInk.muted, p.foregroundMuted, p.foregroundSecondary),
      (TabsRestInk.secondary, p.foregroundSecondary, p.foreground),
      (TabsRestInk.foreground, p.foreground, p.primaryText),
    ]) {
      final s = style.copyWith(restInk: ink);
      expect(s.restInkOf(p), rest, reason: ink.name);
      expect(s.restInkOf(p, hovered: true), hovered, reason: ink.name);
    }
  });

  group('each theme writes its tab labels at 4.5:1', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          test('${theme.name} $mode $brand', () {
            final t = seed == null ? tokens : tokens.branded(seed);
            final p = t.palette;
            final style = t.tabs;
            for (final (name, ground) in [
              ('surface', p.surface),
              ('background', p.background),
            ]) {
              for (final (what, ink) in [
                ('the selected label', style.selectedInkOf(p)),
                ('a label at rest', style.restInkOf(p)),
                ('a hovered label', style.restInkOf(p, hovered: true)),
              ]) {
                expect(
                  contrastRatio(ink, ground),
                  greaterThanOrEqualTo(4.5),
                  reason: '$what on the $name',
                );
              }
              expect(
                contrastRatio(p.controlAccent, ground),
                greaterThanOrEqualTo(3),
                reason: 'the indicator on the $name',
              );
            }
          });
        }
      }
    }
  });
}
