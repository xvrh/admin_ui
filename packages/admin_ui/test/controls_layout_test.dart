import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [child] in a [width]-wide column that stretches its children, like a form.
Widget _host(Widget child, {double width = 400}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  ),
);

/// The segments' tap targets, left to right.
List<Rect> _segments(WidgetTester tester) => [
  for (final e
      in find
          .descendant(
            of: find.byType(Segmented<String>),
            matching: find.byType(Tappable),
          )
          .evaluate())
    tester.getRect(find.byElementPredicate((x) => x == e)),
];

const _three = [
  SegmentOption('list', 'List', icon: Icons.view_list_rounded),
  SegmentOption('grid', 'Grid', icon: Icons.grid_view_rounded),
  SegmentOption('board', 'Board', icon: Icons.view_column_rounded),
];

void main() {
  group('Segmented', () {
    testWidgets('hugs its segments in a stretching column', (tester) async {
      await tester.pumpWidget(
        _host(
          Segmented<String>(value: 'list', onChanged: (_) {}, segments: _three),
        ),
      );
      final segments = _segments(tester);
      final content = segments.last.right - segments.first.left;
      expect(content, lessThan(400));
      final group = tester.getRect(
        find
            .ancestor(of: find.text('List'), matching: find.byType(FocusRing))
            .last,
      );
      expect(group.width, content);
      expect(group.left, tester.getTopLeft(find.byType(Column)).dx);
    });

    testWidgets('is 36 tall, 28 small, 40 large, like a Button', (
      tester,
    ) async {
      for (final (size, height) in [
        (ControlSize.medium, 36.0),
        (ControlSize.small, 28.0),
        (ControlSize.large, 40.0),
      ]) {
        await tester.pumpWidget(
          _host(
            Segmented<String>(
              value: 'list',
              size: size,
              onChanged: (_) {},
              segments: _three,
            ),
          ),
        );
        for (final rect in _segments(tester)) {
          expect(rect.height, height);
        }
      }
    });

    testWidgets('selecting keeps every segment the same width', (tester) async {
      Future<List<double>> widths(String value) async {
        await tester.pumpWidget(
          _host(
            Segmented<String>(
              value: value,
              onChanged: (_) {},
              segments: _three,
            ),
          ),
        );
        return [for (final r in _segments(tester)) r.width];
      }

      expect(await widths('grid'), await widths('list'));
    });

    testWidgets('expand splits the width equally', (tester) async {
      await tester.pumpWidget(
        _host(
          Segmented<String>(
            value: 'list',
            expand: true,
            onChanged: (_) {},
            segments: _three,
          ),
        ),
      );
      final segments = _segments(tester);
      expect(segments.last.right - segments.first.left, 400);
      for (final r in segments) {
        expect(r.width, closeTo(segments.first.width, 0.01));
      }
    });

    for (final width in [250.0, 160.0]) {
      testWidgets('never overflows at ${width.round()}px', (tester) async {
        await tester.pumpWidget(
          _host(
            width: width,
            Segmented<String>(
              value: 'grid',
              onChanged: (_) {},
              segments: const [
                SegmentOption('list', 'All', icon: Icons.view_list_rounded),
                SegmentOption('grid', 'Published', icon: Icons.public_rounded),
                SegmentOption(
                  'board',
                  'Scheduled for review',
                  icon: Icons.schedule_rounded,
                ),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final group = tester.getRect(
          find
              .ancestor(of: find.text('All'), matching: find.byType(FocusRing))
              .last,
        );
        expect(group.width, lessThanOrEqualTo(width));
      });
    }

    testWidgets('short of room, the widest label gives way first', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          width: 250,
          Segmented<String>(
            value: 'a',
            onChanged: (_) {},
            segments: const [
              SegmentOption('a', 'All'),
              SegmentOption('b', 'Live'),
              SegmentOption('c', 'Scheduled for review by the legal team'),
            ],
          ),
        ),
      );
      final [all, live, long] = _segments(tester);
      expect(all.width, lessThan(live.width));
      expect(long.right - all.left, 250);
      // The short labels keep their natural width.
      expect(
        all.width,
        closeTo(tester.getSize(find.text('All')).width + 32, 1),
      );
    });

    testWidgets('a font that loads late re-measures the labels', (
      tester,
    ) async {
      // Laid out first in the fallback font; each segment then fits its label
      // in the font that arrived.
      const family = 'SegmentedLateFont';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(
            AdminTokens.from(
              palette: irisPalette,
              type: const AdminTypeSpec(fontFamily: family),
            ),
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Segmented<String>(
                value: 'b',
                onChanged: (_) {},
                segments: const [
                  SegmentOption('a', 'Inline'),
                  SegmentOption('b', 'Focus card'),
                ],
              ),
            ),
          ),
        ),
      );
      final font = File('example/assets/fonts/IBMPlexSans-Medium.ttf')
          .readAsBytesSync();
      await tester.runAsync(
        () => (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(font)))).load(),
      );
      await tester.pump();
      await tester.pump();

      final segments = _segments(tester);
      for (final (i, label) in ['Inline', 'Focus card'].indexed) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
        )..layout();
        expect(
          segments[i].width,
          closeTo(painter.width + 32, 1),
          reason: label,
        );
        painter.dispose();
      }
    });

    testWidgets('an icon-only segment is square', (tester) async {
      await tester.pumpWidget(
        _host(
          Segmented<String>(
            value: 'a',
            onChanged: (_) {},
            segments: const [
              SegmentOption(
                'a',
                'Grid',
                icon: Icons.grid_view,
                showLabel: false,
              ),
              SegmentOption('b', 'List', icon: Icons.list, showLabel: false),
            ],
          ),
        ),
      );
      for (final r in _segments(tester)) {
        expect(r.size, const Size(36, 36));
      }
    });

    testWidgets('lays out under an unbounded width', (tester) async {
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Segmented<String>(
              value: 'list',
              onChanged: (_) {},
              segments: _three,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_segments(tester), hasLength(3));
    });
  });

  group('Choice', () {
    testWidgets('cards keep one height whichever is selected', (tester) async {
      Future<List<double>> heights(String value) async {
        await tester.pumpWidget(
          _host(
            Choice<String>(
              value: value,
              onChanged: (_) {},
              style: ChoiceStyle.card,
              options: const [
                ChoiceOption('a', 'Automatic', description: 'As soon as ready'),
                ChoiceOption('b', 'Scheduled', description: 'At a set time'),
                ChoiceOption(
                  'c',
                  'Manual',
                  description: 'When someone publishes',
                  enabled: false,
                ),
              ],
            ),
          ),
        );
        return [
          for (final label in ['Automatic', 'Scheduled', 'Manual'])
            tester
                .getSize(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(Container),
                      )
                      .last,
                )
                .height,
        ];
      }

      final a = await heights('a');
      expect(a.toSet(), hasLength(1));
      expect(await heights('b'), a);
    });

    testWidgets('a plain option hugs its label', (tester) async {
      await tester.pumpWidget(
        _host(
          Choice<String>(
            value: 'a',
            onChanged: (_) {},
            options: const [ChoiceOption('a', 'Alpha')],
          ),
        ),
      );
      final target = tester.getRect(find.byType(Tappable));
      expect(target.right, tester.getRect(find.text('Alpha')).right);
    });

    testWidgets('a disabled card dims its description', (tester) async {
      await tester.pumpWidget(
        _host(
          Choice<String>(
            value: 'a',
            onChanged: (_) {},
            style: ChoiceStyle.card,
            options: const [
              ChoiceOption('a', 'On', description: 'live'),
              ChoiceOption('b', 'Off', description: 'dimmed', enabled: false),
            ],
          ),
        ),
      );
      Color colour(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;
      expect(colour('live'), defaultTokens.palette.foregroundMutedOnTint);
      expect(colour('dimmed'), defaultTokens.palette.foregroundSubtle);
    });
  });

  group('Toggle and Check', () {
    for (final (name, control) in [
      ('Toggle', Toggle(value: true, onChanged: (_) {}, label: 'Label')),
      ('Check', Check(value: true, onChanged: (_) {}, label: 'Label')),
    ]) {
      testWidgets('$name hugs its label in a stretching column', (
        tester,
      ) async {
        await tester.pumpWidget(_host(control));
        final target = tester.getRect(find.byType(Tappable));
        expect(target.right, tester.getRect(find.text('Label')).right);
      });
    }

    for (final (name, height) in [('Toggle', 20.0), ('Check', 18.0)]) {
      testWidgets('$name sits on the first line of a wrapped label', (
        tester,
      ) async {
        const label = 'A label long enough to wrap onto a second line here';
        await tester.pumpWidget(
          _host(
            width: 200,
            name == 'Toggle'
                ? Toggle(value: true, onChanged: (_) {}, label: label)
                : Check(value: true, onChanged: (_) {}, label: label),
          ),
        );
        // The visible label, and the one-line copy the control's slot is
        // measured by.
        final text = tester.getRect(find.text(label));
        final line = tester
            .getRect(
              find.descendant(
                of: find.byType(Opacity),
                matching: find.byType(RichText),
              ),
            )
            .height;
        expect(text.height, greaterThan(line * 1.5));
        final control = tester.getRect(
          find
              .descendant(
                of: find.byType(Tappable),
                matching: find.byType(FocusRing),
              )
              .first,
        );
        expect(control.height, height);
        expect(control.center.dy, closeTo(text.top + line / 2, 0.01));
      });
    }
  });

  testWidgets('BooleanBody is 36 tall and all of it toggles', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => BooleanBody(
            value: value,
            onChanged: (v) => setState(() => value = v),
            description: 'Pin',
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(BooleanBody));
    expect(box.height, 36);
    expect(box.width, 400);
    // The far end of the row, well past the text.
    await tester.tapAt(box.centerRight - const Offset(4, 0));
    await tester.pump();
    expect(value, isTrue);
    await tester.tap(find.text('Pin'));
    await tester.pump();
    expect(value, isFalse);
  });

  for (final width in [60.0, 70.0, 80.0]) {
    testWidgets('Tag and StatusPill ellipsize in ${width.round()}px', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          width: width,
          Builder(
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag('Needs review by legal', dot: true),
                Tag('Needs review by legal', onRemove: () {}),
                StatusPill(localeStatusMeta(context)[LocaleStatus.review]!),
                Row(
                  children: [
                    const Flexible(child: Tag('Needs review by legal')),
                    Flexible(
                      child: StatusPill(
                        StatusMeta(
                          'Waiting on legal review',
                          context.colors.warning,
                          text: context.colors.warningText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Tag and StatusPill take the theme pill radius', (tester) async {
    for (final tokens in [irisTheme.tokens, antTheme.tokens]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  const Tag('Tag'),
                  StatusPill(
                    localeStatusMeta(context)[LocaleStatus.translated]!,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Past the theme change's cross-fade.
      await tester.pump(const Duration(seconds: 1));
      final expected = BorderRadius.circular(tokens.radii.radiusPill);
      for (final text in ['Tag', 'Up to date']) {
        final box = tester.widget<Container>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Container))
              .first,
        );
        expect((box.decoration! as BoxDecoration).borderRadius, expected);
      }
    }
    expect(antTheme.tokens.radii.radiusPill, 4);
  });

  group('Button', () {
    for (final (name, rest, loading) in [
      (
        'no icon',
        const Button.primary('Save changes', onPressed: _noop),
        const Button.primary('Save changes', loading: true, onPressed: _noop),
      ),
      (
        'an icon',
        const Button('Refresh', icon: Icons.refresh, onPressed: _noop),
        const Button(
          'Refresh',
          icon: Icons.refresh,
          loading: true,
          onPressed: _noop,
        ),
      ),
      (
        'small',
        const Button('Go', size: ControlSize.small, onPressed: _noop),
        const Button(
          'Go',
          size: ControlSize.small,
          loading: true,
          onPressed: _noop,
        ),
      ),
    ]) {
      testWidgets('loading keeps the resting size ($name)', (tester) async {
        await tester.pumpWidget(_host(Center(child: rest)));
        final resting = tester.getSize(find.byType(Button));
        await tester.pumpWidget(_host(Center(child: loading)));
        expect(tester.getSize(find.byType(Button)), resting);
        final spinner = tester.getRect(find.byType(Spinner));
        final button = tester.getRect(find.byType(Button));
        expect(spinner.center.dy, closeTo(button.center.dy, 0.5));
      });
    }

    testWidgets('loading without an icon centres the spinner', (tester) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: Button.primary(
              'Save changes',
              loading: true,
              onPressed: _noop,
            ),
          ),
        ),
      );
      expect(
        tester.getCenter(find.byType(Spinner)),
        tester.getCenter(find.byType(Button)),
      );
    });
  });

  group('CountBadge', () {
    for (final (name, badge) in [
      (
        'count',
        const CountBadge(count: 3, child: SizedBox.square(dimension: 24)),
      ),
      (
        'wide count',
        const CountBadge(count: 128, child: SizedBox.square(dimension: 24)),
      ),
      (
        'dot',
        const CountBadge(dot: true, child: SizedBox.square(dimension: 24)),
      ),
    ]) {
      testWidgets('centres the $name on the child top-end corner', (
        tester,
      ) async {
        await tester.pumpWidget(_host(Center(child: badge)));
        final child = tester.getRect(find.byType(SizedBox).last);
        final bubble = tester.getRect(
          find
              .descendant(
                of: find.byType(CountBadge),
                matching: find.byType(Container),
              )
              .last,
        );
        expect(bubble.center.dx, closeTo(child.topRight.dx, 0.01));
        expect(bubble.center.dy, closeTo(child.topRight.dy, 0.01));
      });
    }

    testWidgets('the overlaid bubble is the standalone size', (tester) async {
      await tester.pumpWidget(_host(const Center(child: CountBadge(count: 3))));
      final standalone = tester.getSize(find.byType(Container).last);
      await tester.pumpWidget(
        _host(
          const Center(
            child: CountBadge(count: 3, child: SizedBox.square(dimension: 24)),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Container).last), standalone);
    });

    testWidgets('the ring takes the surface it sits on', (tester) async {
      const surface = Color(0xFF123456);
      await tester.pumpWidget(
        _host(
          const ColoredBox(
            color: surface,
            child: Center(
              child: CountBadge(
                count: 3,
                child: SizedBox.square(dimension: 24),
              ),
            ),
          ),
        ),
      );
      final bubble = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CountBadge),
              matching: find.byType(Container),
            )
            .last,
      );
      final ring =
          ((bubble.decoration! as BoxDecoration).border! as Border).top;
      expect(ring.color, surface);

      await tester.pumpWidget(
        _host(
          const Center(
            child: CountBadge(
              count: 3,
              ringColor: Color(0xFFABCDEF),
              child: SizedBox.square(dimension: 24),
            ),
          ),
        ),
      );
      final pinned = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CountBadge),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(
        ((pinned.decoration! as BoxDecoration).border! as Border).top.color,
        const Color(0xFFABCDEF),
      );
    });
  });

  group('ValueSlider', () {
    testWidgets('the track runs from the column edge', (tester) async {
      await tester.pumpWidget(
        _host(ValueSlider(value: 0.5, onChanged: (_) {})),
      );
      final theme = SliderTheme.of(tester.element(find.byType(Slider)));
      expect(theme.padding?.horizontal, 0);
      expect(
        tester.getTopLeft(find.byType(Slider)).dx,
        tester.getTopLeft(find.byType(Column)).dx,
      );
      expect(tester.getSize(find.byType(Slider)).height, 36);
    });

    testWidgets('a long readout stays on one line', (tester) async {
      await tester.pumpWidget(
        _host(
          ValueSlider(
            value: 1200,
            max: 5000,
            onChanged: (_) {},
            format: (v) => '${v.round()} words per page',
          ),
        ),
      );
      final line = tester.getSize(find.text('1200 words per page'));
      expect(line.height, lessThan(24));
      expect(line.width, greaterThan(48));
    });
  });
}

void _noop() {}
