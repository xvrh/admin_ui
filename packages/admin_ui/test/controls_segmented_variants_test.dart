import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/segmented.dart' show SegmentToggle;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s light tokens in the default type, so no font loads.
AdminTokens _tokens(AdminTheme theme) {
  final source = theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    sizes: source.sizes,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    field: source.field,
    segmented: source.segmented,
  );
}

AdminTheme _theme(String name) =>
    adminThemes.firstWhere((theme) => theme.name == name);

Widget _host(AdminTokens tokens, Widget child, {bool reduced = false}) =>
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: Scaffold(
            body: Center(child: SizedBox(width: 480, child: child)),
          ),
        ),
      ),
    );

/// A Segmented that keeps its own value.
class _Live extends StatefulWidget {
  final List<SegmentOption<String>> segments;
  final String initial;

  const _Live(this.segments, this.initial);

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => Segmented<String>(
    value: value,
    onChanged: (v) => setState(() => value = v),
    segments: widget.segments,
  );
}

const _three = [
  SegmentOption('a', 'One'),
  SegmentOption('b', 'Two'),
  SegmentOption('c', 'Three'),
];

/// The knob a track draws behind its selected segment: the one box in the
/// Segmented that holds no label.
Finder _knob() {
  final boxes = find.descendant(
    of: find.byWidgetPredicate((w) => w is Segmented),
    matching: find.byType(DecoratedBox),
  );
  final knob = boxes.evaluate().firstWhere(
    (box) => find
        .descendant(
          of: find.byElementPredicate((e) => e == box),
          matching: find.byType(Text),
        )
        .evaluate()
        .isEmpty,
  );
  return find.byElementPredicate((e) => e == knob);
}

/// Where the segment labelled [label] draws its wash: its own box.
Rect _drawn(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(DecoratedBox))
      .first,
);

/// The tap target of the segment labelled [label].
Finder _target(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Tappable)).first;

void main() {
  group('the knob', () {
    testWidgets('slides from one segment to the next', (tester) async {
      await tester.pumpWidget(_host(defaultTokens, const _Live(_three, 'a')));
      expect(tester.getRect(_knob()), _drawn(tester, 'One'));

      await tester.tap(find.text('Three'));
      await tester.pump();
      await tester.pump(defaultTokens.motion.medium ~/ 2);
      final halfway = tester.getRect(_knob());
      expect(halfway.left, greaterThan(_drawn(tester, 'One').left));
      expect(halfway.left, lessThan(_drawn(tester, 'Three').left));

      await tester.pumpAndSettle();
      expect(tester.getRect(_knob()), _drawn(tester, 'Three'));
    });

    testWidgets('jumps at once with animations disabled', (tester) async {
      await tester.pumpWidget(
        _host(defaultTokens, const _Live(_three, 'a'), reduced: true),
      );
      await tester.tap(find.text('Three'));
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(_knob()), _drawn(tester, 'Three'));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('sits the inset in from the track, and a tap in that band '
        'picks the segment', (tester) async {
      await tester.pumpWidget(_host(defaultTokens, const _Live(_three, 'a')));
      final inset = defaultTokens.segmented.inset;
      final track = tester.getRect(find.byType(Segmented<String>));
      expect(
        tester.getRect(_knob()).topLeft,
        track.topLeft.translate(inset, inset),
      );
      final target = tester.getRect(_target('Three'));
      expect(target.height, track.height, reason: 'the full height');

      await tester.tapAt(target.bottomRight.translate(-1, -1));
      await tester.pumpAndSettle();
      expect(tester.getRect(_knob()), _drawn(tester, 'Three'));
    });

    testWidgets("Fluent's pill sits on its foot, 16 wide, in the accent", (
      tester,
    ) async {
      final tokens = _tokens(_theme('Fluent'));
      await tester.pumpWidget(_host(tokens, const _Live(_three, 'b')));
      final pill = find.descendant(
        of: _knob(),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxWidth == 16,
        ),
      );
      expect(pill, findsOneWidget);
      final knob = tester.getRect(_knob());
      final bar = tester.getRect(pill);
      expect(bar.bottom, knob.bottom);
      expect(bar.center.dx, knob.center.dx);
      expect(bar.height, tokens.stroke.indicator);
      expect(
        (tester.widget<Container>(pill).decoration! as BoxDecoration).color,
        tokens.palette.controlAccent,
      );
    });
  });

  group("M3's check", () {
    testWidgets('comes before the selected label and moves no segment', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_tokens(_theme('Material')), const _Live(_three, 'a')),
      );
      List<double> widths() => [
        for (final label in ['One', 'Two', 'Three'])
          tester.getSize(_target(label)).width,
      ];
      Finder check(String label) => find.descendant(
        of: _target(label),
        matching: find.byIcon(Icons.check_rounded),
      );
      expect(check('One'), findsOneWidget);
      expect(check('Two'), findsNothing);
      expect(
        tester.getTopRight(check('One')).dx,
        lessThan(tester.getTopLeft(find.text('One')).dx),
      );
      final before = widths();

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(check('One'), findsNothing);
      expect(check('Two'), findsOneWidget);
      expect(widths(), before, reason: 'the check has its room either way');
    });

    testWidgets("takes a segment's icon's place", (tester) async {
      await tester.pumpWidget(
        _host(
          _tokens(_theme('Material')),
          const _Live([
            SegmentOption('a', 'List', icon: Icons.view_list_rounded),
            SegmentOption('b', 'Grid', icon: Icons.grid_view_rounded),
          ], 'a'),
        ),
      );
      expect(find.byIcon(Icons.view_list_rounded), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    });
  });

  group('a SegmentToggle is a lone segment', () {
    for (final theme in adminThemes) {
      testWidgets(theme.name, (tester) async {
        final tokens = _tokens(theme);
        final colors = tokens.palette;
        final style = tokens.segmented;
        for (final active in [true, false]) {
          await tester.pumpWidget(
            _host(
              tokens,
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentToggle(
                  key: ValueKey(active),
                  label: 'Unchanged',
                  active: active,
                  onTap: () {},
                ),
              ),
            ),
          );
          expect(
            tester.getSize(find.byType(SegmentToggle)).height,
            tokens.sizes.medium,
            reason: 'a medium control',
          );
          final label = tester.widget<Text>(find.text('Unchanged'));
          final drawn =
              tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: find.text('Unchanged'),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration;
          if (style.variant == SegmentedVariant.track) {
            expect(
              drawn.color,
              active ? colors.surface : const Color(0x00000000),
              reason: active ? 'its knob raised' : 'the bare track',
            );
            expect(
              label.style!.color,
              active ? colors.foreground : colors.foregroundMutedOnTint,
            );
          } else {
            expect(
              drawn.color,
              active
                  ? (style.inverse ? colors.foreground : colors.softFill)
                  : colors.surface,
            );
            expect(
              label.style!.color,
              active
                  ? (style.inverse
                        ? colors.foregroundOn(colors.foreground)
                        : colors.onSoft)
                  : colors.foregroundMuted,
            );
          }
          expect(
            tester.getSemantics(find.text('Unchanged')),
            isSemantics(isSelected: active, hasSelectedState: true),
          );
        }
      });
    }
  });
}
