import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
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

/// Each shipped theme's table, from its design system: rows compact /
/// standard / comfortable, header, cell padding, selection column, header
/// text.
const _metrics = {
  'Iris': (40.0, 52.0, 64.0, 44.0, 12.0, 44.0, TableHeaderText.caption),
  'Material': (36.0, 52.0, 64.0, 56.0, 16.0, 48.0, TableHeaderText.label),
  'shadcn': (40.0, 48.0, 56.0, 40.0, 8.0, 40.0, TableHeaderText.label),
  'Ant': (40.0, 48.0, 56.0, 48.0, 8.0, 32.0, TableHeaderText.label),
  'Fluent': (32.0, 44.0, 52.0, 44.0, 8.0, 44.0, TableHeaderText.label),
  'Carbon': (40.0, 48.0, 64.0, 48.0, 16.0, 48.0, TableHeaderText.label),
};

/// How far apart [a] and [b] sit in hue and colourfulness, ignoring
/// lightness: their distance on OKLab's a/b plane, where about 0.02 is a
/// just-noticeable difference between small patches (less across a row).
double _hueDistance(Color a, Color b) {
  (double, double) ab(Color c) {
    double linear(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    final (r, g, bl) = (linear(c.r), linear(c.g), linear(c.b));
    double cbrt(double v) => math.pow(v, 1 / 3).toDouble();
    final l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * bl);
    final m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * bl);
    final s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * bl);
    return (
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  final (a1, b1) = ab(a);
  final (a2, b2) = ab(b);
  return math.sqrt(math.pow(a1 - a2, 2) + math.pow(b1 - b2, 2));
}

double _hueGap(Color a, Color b) {
  final gap = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
  return math.min(gap, 360 - gap);
}

/// The table row roles of every shipped palette, in both modes and under
/// every demo brand, and the table metrics of every theme.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('table row roles', () {
    for (final theme in adminThemes) {
      for (final (mode, palette) in [
        ('Light', theme.palette),
        ('Dark', theme.darkPalette!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          final p = seed == null ? palette : palette.branded(seed);
          test('${theme.name} $mode, brand $brand', () {
            final stripe = p.tableRowStripe;
            final hover = p.tableRowHover;
            final selected = p.tableRowSelected;
            final selectedHover = p.tableRowSelectedHover;
            final hoverOnSurface = Color.alphaBlend(hover, p.surface);
            final hoverOnStripe = Color.alphaBlend(hover, stripe);
            double fromSurface(Color c) => contrastRatio(c, p.surface);

            expect(stripe.a, 1, reason: 'the stripe is opaque');
            expect(selected.a, 1, reason: 'the selection is opaque');
            expect(hover.a, lessThan(1), reason: 'hover is a wash');
            expect(selectedHover, Color.alphaBlend(hover, selected));

            expect(
              fromSurface(stripe),
              greaterThan(1.03),
              reason: 'stripe shows',
            );
            expect(
              contrastRatio(hoverOnStripe, stripe),
              greaterThan(1.05),
              reason: 'hover shows on a stripe',
            );
            expect(
              contrastRatio(selectedHover, selected),
              greaterThan(1.05),
              reason: 'hover shows on a selected row',
            );

            expect(
              contrastRatio(selected, hoverOnSurface),
              greaterThan(1.05),
              reason: 'a hovered row never passes for a selected one',
            );
            // A chromatic primary carries its hue into the selection; a
            // neutral one (shadcn's zinc) can only differ by lightness.
            if (HSLColor.fromColor(p.primary).saturation >= 0.2) {
              expect(
                _hueDistance(selected, hoverOnSurface),
                greaterThanOrEqualTo(0.012),
                reason: 'the selection is tinted, hover is not',
              );
              expect(
                _hueGap(selected, p.primary),
                lessThan(20),
                reason: 'the selection takes the primary hue',
              );
            }
            expect(
              fromSurface(selected),
              greaterThan(fromSurface(stripe)),
              reason: 'selected stands further from the page than the stripe',
            );
            expect(
              fromSurface(selected),
              greaterThan(fromSurface(hoverOnStripe)),
              reason: 'selected stands further out than a hovered stripe',
            );

            for (final (name, surface) in [
              ('stripe', stripe),
              ('selected', selected),
              ('selectedHover', selectedHover),
            ]) {
              expect(
                contrastRatio(p.foreground, surface),
                greaterThanOrEqualTo(4.5),
                reason: 'foreground on $name',
              );
              expect(
                contrastRatio(p.foregroundSecondary, surface),
                greaterThanOrEqualTo(4.5),
                reason: 'foregroundSecondary on $name',
              );
            }
            final muted = p.readableOn(
              p.foregroundMuted,
              surfaces: [stripe, selected],
            );
            for (final surface in [stripe, selected]) {
              expect(contrastRatio(muted, surface), greaterThanOrEqualTo(4.5));
            }

            final unbranded = palette;
            expect(
              stripe,
              unbranded.tableRowStripe,
              reason: 'the stripe carries no brand',
            );
            expect(hover, unbranded.tableRowHover);
          });
        }
      }
    }

    test('an authored role wins; copyWith, lerp and a brand keep it', () {
      const x = Color(0xFF123456);
      const wash = Color(0x0F000000);
      final base = irisPalette;
      final authored = base.copyWith(
        tableRowStripe: x,
        tableRowHover: wash,
        tableRowSelected: x,
        tableRowSelectedHover: x,
      );
      expect(authored.tableRowStripe, x);
      expect(authored.tableRowHover, wash);
      expect(authored.tableRowSelected, x);
      expect(authored.tableRowSelectedHover, x);
      expect(authored.copyWith().tableRowSelected, x);

      final branded = authored.branded(const Color(0xFF0D9488));
      expect(branded.tableRowStripe, x, reason: 'neutral roles are kept');
      expect(branded.tableRowHover, wash);
      expect(branded.tableRowSelected, isNot(x), reason: 'selection rebrands');
      expect(
        branded.tableRowSelectedHover,
        Color.alphaBlend(wash, branded.tableRowSelected),
      );

      expect(AdminPalette.lerp(authored, irisDarkPalette, 0).tableRowStripe, x);
      expect(
        AdminPalette.lerp(authored, irisDarkPalette, 1).tableRowStripe,
        irisDarkPalette.tableRowStripe,
      );
      final mid = AdminPalette.lerp(base, irisDarkPalette, 0.5);
      expect(
        mid.tableRowSelectedHover,
        Color.alphaBlend(mid.tableRowHover, mid.tableRowSelected),
        reason: 'unauthored on both sides, the role stays derived',
      );
    });

    test('the defaults derive from the base', () {
      final p = irisPalette;
      expect(
        p.tableRowStripe,
        Color.alphaBlend(p.foreground.withValues(alpha: 0.025), p.surface),
      );
      expect(p.tableRowHover, p.foreground.withValues(alpha: 0.04));
      final d = irisDarkPalette;
      expect(
        d.tableRowStripe,
        Color.alphaBlend(d.foreground.withValues(alpha: 0.035), d.surface),
      );
      expect(d.tableRowHover, d.foreground.withValues(alpha: 0.06));
    });
  });

  group('table metrics', () {
    for (final theme in adminThemes) {
      test('${theme.name} follows its design system', () {
        final light = theme.tokens;
        final dark = theme.dark!;
        final m = light.table;
        expect(dark.table, m, reason: 'both modes share one table');
        final (compact, standard, comfortable, header, padX, selection, text) =
            _metrics[theme.name]!;
        expect(m.rowCompact, compact);
        expect(m.rowStandard, standard);
        expect(m.rowComfortable, comfortable);
        expect(m.headerHeight, header);
        expect(m.cellPaddingX, padX);
        expect(m.selectionColumnWidth, selection);
        expect(m.headerText, text);
      });

      test('${theme.name} keeps the grid and holds its controls', () {
        final tokens = theme.tokens;
        final m = tokens.table;
        for (final (name, value) in [
          ('rowCompact', m.rowCompact),
          ('rowStandard', m.rowStandard),
          ('rowComfortable', m.rowComfortable),
          ('headerHeight', m.headerHeight),
          ('cellPaddingX', m.cellPaddingX),
          ('selectionColumnWidth', m.selectionColumnWidth),
          ('resizeHandleWidth', m.resizeHandleWidth),
          ('sortIconSize', m.sortIconSize),
          ('sortIconGap', m.sortIconGap),
        ]) {
          expect(value % 4, 0, reason: '$name $value is on the 4px grid');
        }
        expect(m.rowCompact, lessThan(m.rowStandard));
        expect(m.rowStandard, lessThan(m.rowComfortable));

        final sizes = tokens.sizes;
        expect(
          m.rowStandard,
          greaterThanOrEqualTo(sizes.medium + 8),
          reason: 'a standard row holds a medium control with room',
        );
        expect(
          m.rowCompact,
          greaterThanOrEqualTo(sizes.small + 4),
          reason: 'a compact row holds a small control',
        );
        expect(m.headerHeight, greaterThanOrEqualTo(sizes.medium));
        // The row checkbox (18) with its focus ring on both sides.
        final focus = tokens.focus;
        expect(
          m.selectionColumnWidth,
          greaterThanOrEqualTo(
            18 + 2 * (focus.width + math.max(0, focus.offset)),
          ),
          reason: 'the selection column holds a focused checkbox',
        );
        expect(m.resizeHandleWidth, 8);
        expect(m.sortIconSize, 16);
        expect(m.sortIconGap, 4);
      });
    }

    test('a brand keeps the table', () {
      final branded = irisTheme.branded('Iris Teal', const Color(0xFF0D9488));
      expect(branded.tokens.table, irisTheme.tokens.table);
    });

    test('rowHeight reads the density', () {
      const m = defaultTableMetrics;
      expect(m.rowHeight(TableDensity.compact), 40);
      expect(m.rowHeight(TableDensity.standard), 52);
      expect(m.rowHeight(TableDensity.comfortable), 64);
    });

    test('copyWith, lerp and equality', () {
      const a = defaultTableMetrics;
      final b = a.copyWith(
        rowStandard: 60,
        headerHeight: 56,
        headerText: TableHeaderText.label,
      );
      expect(b.rowStandard, 60);
      expect(b.rowCompact, a.rowCompact);
      expect(b, isNot(a));
      expect(a.copyWith(), a);
      expect(a.copyWith().hashCode, a.hashCode);
      final mid = AdminTableMetrics.lerp(a, b, 0.5);
      expect(mid.rowStandard, 56);
      expect(mid.headerHeight, 50);
      expect(mid.headerText, TableHeaderText.label);
      expect(AdminTableMetrics.lerp(a, b, 0.25).headerText, a.headerText);
      expect('$a', contains('40.0/52.0/64.0'));
    });

    test('AdminTokens carries the table: default, copyWith and lerp', () {
      final tokens = AdminTokens.from(palette: irisPalette);
      expect(tokens.table, defaultTableMetrics);
      const custom = AdminTableMetrics(
        rowCompact: 32,
        rowStandard: 48,
        rowComfortable: 56,
        headerHeight: 48,
        cellPaddingX: 16,
        selectionColumnWidth: 48,
      );
      final withTable = tokens.copyWith(table: custom);
      expect(withTable.table, custom);
      expect(withTable.copyWith().table, custom);
      expect(
        tokens.lerp(withTable, 0.5).table,
        AdminTableMetrics.lerp(defaultTableMetrics, custom, 0.5),
      );
      expect(
        AdminTokens.from(palette: irisPalette, table: custom).table,
        custom,
      );
    });

    testWidgets('context.tableMetrics reads the active theme', (tester) async {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        table: defaultTableMetrics.copyWith(headerHeight: 48),
      );
      late AdminTableMetrics read;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Builder(
            builder: (context) {
              read = context.tableMetrics;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(read.headerHeight, 48);
    });
  });
}
