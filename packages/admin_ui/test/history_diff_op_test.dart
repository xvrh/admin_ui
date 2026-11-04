import 'dart:math' as math;

import 'package:admin_ui/src/common/ui/severity.dart';
import 'package:admin_ui/src/history/diff_model.dart';
import 'package:admin_ui/src/history/ui/block_diff.dart';
import 'package:admin_ui/src/history/ui/diff_op_style.dart';
import 'package:admin_ui/src/history/ui/diff_view.dart';
import 'package:admin_ui/src/history/ui/quick_diff.dart';
import 'package:admin_ui/theme.dart';
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

const _ops = [DiffOp.added, DiffOp.removed, DiffOp.changed, DiffOp.moved];

/// How far apart [a] and [b] sit in hue and colourfulness, ignoring
/// lightness: their distance on OKLab's a/b plane, where about 0.02 is a
/// just-noticeable difference between small patches.
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

Widget _host(AdminPalette palette, Widget child) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Scaffold(body: child),
);

const _vBase = VersionRef(
  id: 'v1',
  label: 'Published v1',
  author: 'Ada Park',
  initials: 'AP',
  timestamp: 'last week',
  status: VersionStatus.published,
);
const _vDraft = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  timestamp: 'now',
  status: VersionStatus.draft,
);

void main() {
  group('tones', () {
    for (final theme in adminThemes) {
      for (final (mode, palette) in [
        ('Light', theme.palette),
        ('Dark', theme.darkPalette!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          final p = seed == null ? palette : palette.branded(seed);
          test('${theme.name} $mode, brand $brand', () {
            final styles = {
              for (final op in _ops) op: DiffOpStyle.resolve(p, op),
            };

            for (var i = 0; i < _ops.length; i++) {
              for (var j = i + 1; j < _ops.length; j++) {
                final a = styles[_ops[i]]!;
                final b = styles[_ops[j]]!;
                final pair = '${a.label}/${b.label}';
                // Material's dark accents share one tone, so lightness can't
                // tell them apart there; every pair differs in hue instead,
                // by at least five times a just-noticeable step.
                expect(
                  _hueDistance(a.accent, b.accent),
                  greaterThanOrEqualTo(0.1),
                  reason: '$pair accents',
                );
                expect(
                  _hueDistance(a.text, b.text),
                  greaterThanOrEqualTo(0.1),
                  reason: '$pair text',
                );
                // The fills sit behind whole blocks, so they part by hue
                // too, not only by their gutters.
                expect(
                  _hueDistance(a.fill, b.fill),
                  greaterThanOrEqualTo(0.015),
                  reason: '$pair fills',
                );
              }
            }

            // The pair that used to collide wherever info is the primary.
            final changed = styles[DiffOp.changed]!;
            final moved = styles[DiffOp.moved]!;
            expect(
              _hueDistance(changed.accent, moved.accent),
              greaterThanOrEqualTo(0.2),
            );
            expect(changed.accent, isNot(p.primary));
            // A darkened yellow reads as olive beside added's green.
            expect(
              _hueDistance(changed.fill, styles[DiffOp.added]!.fill),
              greaterThanOrEqualTo(0.02),
              reason: 'changed and added fills',
            );

            for (final style in styles.values) {
              for (final (name, surface) in [
                ('fill', style.fill),
                ('surface', p.surface),
                ('background', p.background),
              ]) {
                expect(
                  contrastRatio(style.text, surface),
                  greaterThanOrEqualTo(4.5),
                  reason: '${style.label} text on $name',
                );
              }
            }
          });
        }
      }
    }
  });

  group('vocabulary', () {
    final p = adminThemes.first.palette;

    test('one word, glyph, symbol and severity per op', () {
      final styles = [
        for (final op in DiffOp.values) DiffOpStyle.resolve(p, op),
      ];
      expect(
        {for (final s in styles) s.op: s.label},
        {
          DiffOp.added: 'Added',
          DiffOp.removed: 'Removed',
          DiffOp.changed: 'Changed',
          DiffOp.moved: 'Moved',
          DiffOp.unchanged: 'Unchanged',
        },
      );
      expect(styles.map((s) => s.icon).toSet(), hasLength(styles.length));
      expect(styles.map((s) => s.symbol).toSet(), hasLength(styles.length));
      expect(
        {for (final s in styles) s.op: s.severity},
        {
          DiffOp.added: Severity.success,
          DiffOp.removed: Severity.danger,
          DiffOp.changed: Severity.warning,
          DiffOp.moved: Severity.info,
          DiffOp.unchanged: null,
        },
      );
    });

    testWidgets('BlockDiff and DiffOpTag speak the table', (tester) async {
      await tester.pumpWidget(
        _host(
          p,
          const Column(
            children: [
              DiffOpTag(DiffOp.added),
              DiffOpTag(DiffOp.changed),
              BlockDiff(
                blocks: [
                  BlockChange(
                    id: 'a',
                    type: 'paragraph',
                    op: DiffOp.changed,
                    before: 'one',
                    after: 'two',
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      final changed = DiffOpStyle.resolve(p, DiffOp.changed);
      expect(find.text('Added'), findsOneWidget);
      expect(find.text('New'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Changed')).style?.color,
        changed.text,
      );
      expect(
        tester.widget<Text>(find.text('CHANGED')).style?.color,
        changed.text,
      );
    });

    testWidgets('DiffView names a changed record and field "Changed"', (
      tester,
    ) async {
      const diff = VersionDiff(
        base: _vBase,
        compare: _vDraft,
        fields: [
          FieldDiff(
            label: 'Title',
            fieldKey: 'title',
            kind: DiffFieldKind.text,
            locales: [
              LocaleDiff(
                locale: '',
                op: DiffOp.changed,
                before: 'old',
                after: 'new',
              ),
            ],
          ),
          FieldDiff(
            label: 'Sections',
            fieldKey: 'sections',
            kind: DiffFieldKind.recordList,
            locales: [],
            records: [
              RecordChange(
                id: 'a',
                op: DiffOp.changed,
                label: 'Pricing',
                fields: [],
              ),
              RecordChange(id: 'b', op: DiffOp.moved, label: 'FAQ', fields: []),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        _host(
          p,
          const SizedBox(width: 900, height: 700, child: DiffView(diff: diff)),
        ),
      );

      expect(find.text('Edited'), findsNothing);
      expect(find.text('Changed'), findsNWidgets(2));
      expect(find.text('Moved'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('~1')).style?.color,
        p.readableOn(
          DiffOpStyle.resolve(p, DiffOp.changed).text,
          surfaces: [p.surfaceMuted],
        ),
      );
    });

    testWidgets('every revert says Restore, its tooltip names the scope', (
      tester,
    ) async {
      var field = 0;
      var block = 0;
      await tester.pumpWidget(
        _host(
          p,
          Column(
            children: [
              FieldQuickDiff(
                const FieldDiff(
                  label: 'Title',
                  fieldKey: 'title',
                  kind: DiffFieldKind.text,
                  locales: [
                    LocaleDiff(
                      locale: '',
                      op: DiffOp.changed,
                      before: 'a',
                      after: 'b',
                    ),
                  ],
                ),
                onRevert: () => field++,
              ),
              BlockQuickDiff(
                const BlockChange(
                  id: 'x',
                  type: 'paragraph',
                  op: DiffOp.added,
                  after: 'Hello',
                ),
                onRevert: () => block++,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Revert to live'), findsNothing);
      expect(find.text('Restore'), findsNWidgets(2));
      await tester.tap(
        find.byTooltip('Restore the live version of this field'),
      );
      await tester.tap(
        find.byTooltip('Restore the live version of this block'),
      );
      expect((field, block), (1, 1));
    });
  });
}
