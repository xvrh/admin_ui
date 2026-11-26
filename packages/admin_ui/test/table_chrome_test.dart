import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/l10n/ar.dart';
import 'package:admin_ui/l10n/fr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// A table's chrome, from the theme's AdminTableMetrics: what the header row
// is filled and written with, and the rules under the header and the rows.

/// Each shipped theme's table chrome, from its reference: the header's
/// fill, ink and rule, and the row rule.
const _expected = {
  // a quiet band under muted labels; a card's edge, then subtle rules
  'Iris': (
    TableHeaderFill.muted,
    TableHeaderInk.muted,
    TableRule.border,
    TableRule.subtle,
  ),
  // M3 has no data table: the kit's own chrome
  'Material': (
    TableHeaderFill.muted,
    TableHeaderInk.muted,
    TableRule.border,
    TableRule.subtle,
  ),
  // TableHead text-foreground on no fill, border-b under every row
  'shadcn': (
    TableHeaderFill.surface,
    TableHeaderInk.foreground,
    TableRule.border,
    TableRule.border,
  ),
  // headerBg under colorTextHeading, colorBorderSecondary under every row
  'Ant': (
    TableHeaderFill.muted,
    TableHeaderInk.foreground,
    TableRule.subtle,
    TableRule.subtle,
  ),
  // no background, colorNeutralStroke2 under every row
  'Fluent': (
    TableHeaderFill.surface,
    TableHeaderInk.foreground,
    TableRule.subtle,
    TableRule.subtle,
  ),
  // $layer-accent under $text-primary, $border-subtle-01 under every row
  'Carbon': (
    TableHeaderFill.strong,
    TableHeaderInk.foreground,
    TableRule.border,
    TableRule.border,
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

const _rows = ['Alpha', 'Bravo'];

Widget _host(AdminTokens tokens) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: _kitLanguages.locales,
  localizationsDelegates: _kitLanguages.delegates,
  home: Scaffold(
    body: SizedBox(
      width: 800,
      height: 400,
      child: CollectionTable<String>(
        rows: _rows,
        rowKey: (r) => r,
        sort: const TableSort('name'),
        onSort: (_, _) {},
        columns: [
          const TableColumn(label: 'Name', cell: Text.new, sortKey: 'name'),
          TableColumn(label: 'Note', cell: (r) => Text('$r note')),
        ],
      ),
    ),
  ),
);

TableCellBuilderDelegate _delegate(WidgetTester tester) =>
    tester
            .widget<TwoDimensionalScrollView>(
              find.byWidgetPredicate((w) => w is TwoDimensionalScrollView),
            )
            .delegate
        as TableCellBuilderDelegate;

TableSpanDecoration _row(WidgetTester tester, int row) =>
    _delegate(tester).buildRow(row)!.backgroundDecoration!;

TextStyle _label(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  test("the defaults are the kit's own: a muted band, muted labels", () {
    const m = defaultTableMetrics;
    expect(m.headerFill, TableHeaderFill.muted);
    expect(m.headerInk, TableHeaderInk.muted);
    expect(m.headerRule, TableRule.border);
    expect(m.rowRule, TableRule.subtle);
  });

  test('copyWith, lerp, == and toString carry the chrome', () {
    const a = defaultTableMetrics;
    final b = a.copyWith(
      headerText: TableHeaderText.body,
      headerFill: TableHeaderFill.strong,
      headerInk: TableHeaderInk.foreground,
      headerRule: TableRule.subtle,
      rowRule: TableRule.border,
    );
    expect(b, isNot(a));
    expect(b.hashCode, isNot(a.hashCode));
    expect(b.copyWith(), b);
    expect(b.rowStandard, a.rowStandard);
    for (final one in [
      a.copyWith(headerFill: TableHeaderFill.surface),
      a.copyWith(headerInk: TableHeaderInk.foreground),
      a.copyWith(headerRule: TableRule.subtle),
      a.copyWith(rowRule: TableRule.border),
    ]) {
      expect(one, isNot(a));
    }
    final early = AdminTableMetrics.lerp(a, b, 0.25);
    final late = AdminTableMetrics.lerp(a, b, 0.75);
    expect(
      (early.headerFill, early.headerInk, early.headerRule, early.rowRule),
      (a.headerFill, a.headerInk, a.headerRule, a.rowRule),
    );
    expect(
      (late.headerFill, late.headerInk, late.headerRule, late.rowRule),
      (b.headerFill, b.headerInk, b.headerRule, b.rowRule),
    );
    expect(
      '$b',
      allOf(
        contains('body in foreground on strong'),
        contains('subtle rule'),
        contains('border row rules'),
      ),
    );
  });

  test('what the chrome is drawn in', () {
    final p = irisPalette;
    const m = defaultTableMetrics;
    expect(m.headerFillOf(p), p.surfaceMuted);
    expect(
      m.copyWith(headerFill: TableHeaderFill.surface).headerFillOf(p),
      p.surface,
    );
    expect(
      m.copyWith(headerFill: TableHeaderFill.strong).headerFillOf(p),
      p.border,
    );
    expect(m.headerRuleOf(p), p.border);
    expect(m.rowRuleOf(p), p.borderSubtle);
    expect(
      m.copyWith(headerRule: TableRule.subtle).headerRuleOf(p),
      p.borderSubtle,
    );
    expect(m.copyWith(rowRule: TableRule.border).rowRuleOf(p), p.border);

    final strong = m.copyWith(headerInk: TableHeaderInk.foreground);
    expect(strong.headerInkOf(p), p.foreground);
    expect(strong.headerInkOf(p, sorted: true), p.foreground);
    // A muted ink is the palette's, moved only as far as its fill asks.
    expect(
      m.headerInkOf(p),
      p.readableOn(p.foregroundMuted, surfaces: [p.surfaceMuted]),
    );
    expect(
      m.copyWith(headerFill: TableHeaderFill.surface).headerInkOf(p),
      p.foregroundMuted,
    );
  });

  test('a header’s text: the caption at semibold, the body strong, or the '
      'body', () {
    final type = defaultTokens.typography;
    const m = defaultTableMetrics;
    final caption = m.headerStyleOf(type);
    expect(caption.fontSize, type.caption.fontSize);
    expect(caption.fontWeight, FontWeight.w600);
    expect(
      m.copyWith(headerText: TableHeaderText.label).headerStyleOf(type),
      type.bodyStrong,
    );
    expect(
      m.copyWith(headerText: TableHeaderText.body).headerStyleOf(type),
      type.body,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system’s chrome', () {
        final expected = _expected[theme.name];
        expect(expected, isNotNull, reason: 'a theme with no expectation');
        final m = theme.tokens.table;
        expect((m.headerFill, m.headerInk, m.headerRule, m.rowRule), expected);
        expect(theme.dark!.table, m);
      });
    }
  });

  group('each theme writes its header at 4.5:1 on its fill', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          test('${theme.name} $mode $brand', () {
            final t = seed == null ? tokens : tokens.branded(seed);
            final p = t.palette;
            final m = t.table;
            final fill = m.headerFillOf(p);
            for (final sorted in [false, true]) {
              expect(
                contrastRatio(m.headerInkOf(p, sorted: sorted), fill),
                greaterThanOrEqualTo(4.5),
                reason: sorted ? 'the sorted header' : 'a header',
              );
            }
            // The sort arrow and a column's menu glyph are drawn on it too.
            expect(
              contrastRatio(p.foreground, fill),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }
    }
  });

  group('a CollectionTable draws the theme’s chrome', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        testWidgets('${theme.name} $mode', (tester) async {
          final p = tokens.palette;
          final m = tokens.table;
          await tester.pumpWidget(_host(tokens));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final header = _row(tester, 0);
          expect(header.color, m.headerFillOf(p));
          expect(header.border!.trailing.color, m.headerRuleOf(p));
          for (final row in [1, 2]) {
            expect(_row(tester, row).border!.trailing.color, m.rowRuleOf(p));
          }

          final rest = _label(tester, 'Note');
          expect(rest.color, m.headerInkOf(p));
          final style = m.headerStyleOf(tokens.typography);
          expect(rest.fontSize, style.fontSize);
          expect(rest.fontWeight, style.fontWeight);
          expect(_label(tester, 'Name').color, m.headerInkOf(p, sorted: true));
        });
      }
    }

    testWidgets('a custom chrome reaches the header and the rows', (
      tester,
    ) async {
      final p = irisPalette;
      final m = defaultTableMetrics.copyWith(
        headerText: TableHeaderText.body,
        headerFill: TableHeaderFill.strong,
        headerInk: TableHeaderInk.foreground,
        headerRule: TableRule.subtle,
        rowRule: TableRule.border,
      );
      await tester.pumpWidget(_host(AdminTokens.from(palette: p, table: m)));
      await tester.pumpAndSettle();
      final header = _row(tester, 0);
      expect(header.color, p.border);
      expect(header.border!.trailing.color, p.borderSubtle);
      expect(_row(tester, 1).border!.trailing.color, p.border);
      expect(_label(tester, 'Note').color, p.foreground);
      expect(
        _label(tester, 'Note').fontWeight,
        defaultTokens.typography.body.fontWeight,
      );
    });
  });
}
